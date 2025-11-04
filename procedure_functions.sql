-- =========== Helper functions ===========

DELIMITER $$

-- function: calculate_season(date) -> 'Winter'/'Summer'/'Monsoon'/'Spring'
CREATE FUNCTION calculate_season(p_dt DATE) RETURNS ENUM('Winter','Summer','Monsoon','Spring')
DETERMINISTIC
BEGIN
    DECLARE m INT;
    SET m = MONTH(p_dt);
    IF m IN (12,1,2) THEN
        RETURN 'Winter';
    ELSEIF m IN (3,4,5) THEN
        RETURN 'Summer';
    ELSEIF m IN (6,7,8,9) THEN
        RETURN 'Monsoon';
    ELSE
        RETURN 'Spring';
    END IF;
END$$

-- function: validate_email - simple check for '@' and '.'
CREATE FUNCTION validate_email(p_email VARCHAR(255)) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    IF p_email IS NULL OR p_email = '' THEN
        RETURN FALSE;
    END IF;
    IF LOCATE('@', p_email) = 0 THEN
        RETURN FALSE;
    END IF;
    IF LOCATE('.', p_email, LOCATE('@', p_email)) = 0 THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
END$$

-- function: validate_price
CREATE FUNCTION validate_price(p_price DECIMAL(10,2)) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    IF p_price IS NULL OR p_price < 0 THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
END$$

-- function: check_availability(service_type, service_id, tier_id) -> returns INT (available count)
CREATE FUNCTION check_availability(
    p_service_type ENUM('Flight','Train','Bus','Hotel','Activity'),
    p_service_id INT,
    p_tier_id INT
) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE avail INT DEFAULT 0;

    CASE p_service_type
        WHEN 'Flight' THEN
            SELECT COALESCE(ft.available_seats,0) INTO avail
            FROM flight_tiers ft
            WHERE ft.flight_tier_id = p_tier_id AND ft.flight_id = p_service_id;
        WHEN 'Train' THEN
            SELECT COALESCE(tt.available_seats,0) INTO avail
            FROM train_tiers tt
            WHERE tt.train_tier_id = p_tier_id AND tt.train_id = p_service_id;
        WHEN 'Bus' THEN
            SELECT COALESCE(bt.available_seats,0) INTO avail
            FROM bus_tiers bt
            WHERE bt.bus_tier_id = p_tier_id AND bt.bus_id = p_service_id;
        WHEN 'Hotel' THEN
            SELECT COALESCE(ht.available_rooms,0) INTO avail
            FROM hotel_tiers ht
            WHERE ht.room_type_id = p_tier_id AND ht.hotel_id = p_service_id;
        WHEN 'Activity' THEN
            SELECT COALESCE(a.available_slots,0) INTO avail
            FROM activities a
            WHERE a.activity_id = p_service_id;
        ELSE
            SET avail = 0;
    END CASE;

    RETURN avail;
END$$

DELIMITER ;







DELIMITER $$

-- register_user: safely add new user
CREATE PROCEDURE register_user(
    IN p_name VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_phone VARCHAR(15),
    IN p_membership_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error registering user.';
    END;

    IF NOT validate_email(p_email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid email format.';
    END IF;

    START TRANSACTION;
        INSERT INTO users (name, email, phone, membership_id)
        VALUES (p_name, p_email, p_phone, p_membership_id);
    COMMIT;
END$$

-- update_membership: change user's membership
CREATE PROCEDURE update_membership(
    IN p_user_id INT,
    IN p_membership_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error updating membership.';
    END;

    START TRANSACTION;
        UPDATE users SET membership_id = p_membership_id WHERE user_id = p_user_id;
        IF ROW_COUNT() = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found.';
        END IF;
    COMMIT;
END$$

-- create_predefined_package: admin helper to create a package and its components
-- Input: p_name, p_desc, p_base_price, p_duration_days
-- Then provide a simple way to insert package details afterward (or call this and then insert into package_details)
CREATE PROCEDURE create_predefined_package(
    IN p_name VARCHAR(100),
    IN p_desc TEXT,
    IN p_base_price DECIMAL(10,2),
    IN p_duration_days INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error creating package.';
    END;

    IF NOT validate_price(p_base_price) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid base price.';
    END IF;

    START TRANSACTION;
        INSERT INTO packages (name, description, base_price, duration_days)
        VALUES (p_name, p_desc, p_base_price, p_duration_days);
    COMMIT;
END$$

DELIMITER ;






DELIMITER $$

-- process_payment_single:
-- Called after external payment gateway confirms success.
-- It will create a booking for a single service (possibly qty seats), update availability, and record payment.
CREATE PROCEDURE process_payment_single(
    IN p_user_id INT,
    IN p_service_type ENUM('Flight','Train','Bus','Hotel','Activity'),
    IN p_service_id INT,
    IN p_tier_id INT,
    IN p_qty INT,
    IN p_total_amount DECIMAL(10,2),
    IN p_method ENUM('Card','UPI','NetBanking','Wallet','Cash')
)
BEGIN
    DECLARE v_avail INT DEFAULT 0;
    DECLARE v_booking_id INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment or booking failed - transaction rolled back.';
    END;

    IF p_qty <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be >= 1.';
    END IF;

    START TRANSACTION;

    -- Check availability
    SET v_avail = check_availability(p_service_type, p_service_id, p_tier_id);
    IF v_avail < p_qty THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough availability for requested service/tier.';
    END IF;

    -- Insert payment record (initially will be linked later to booking)
    INSERT INTO payments (payer_user_id, amount, method, status)
    VALUES (p_user_id, p_total_amount, p_method, 'Paid');
    SET @payment_id = LAST_INSERT_ID();

    -- Create booking (one row; for qty>1 we increment available seats accordingly and record qty in co_travelers separately)
    INSERT INTO bookings (user_id, package_id, service_type, service_id, tier_id, booking_date, status, total_cost)
    VALUES (p_user_id, NULL, p_service_type, p_service_id, p_tier_id, NOW(), 'Confirmed', p_total_amount);
    SET v_booking_id = LAST_INSERT_ID();

    -- Update availability based on service type
    CASE p_service_type
        WHEN 'Flight' THEN
            UPDATE flight_tiers SET available_seats = available_seats - p_qty
            WHERE flight_tier_id = p_tier_id;
        WHEN 'Train' THEN
            UPDATE train_tiers SET available_seats = available_seats - p_qty
            WHERE train_tier_id = p_tier_id;
        WHEN 'Bus' THEN
            UPDATE bus_tiers SET available_seats = available_seats - p_qty
            WHERE bus_tier_id = p_tier_id;
        WHEN 'Hotel' THEN
            UPDATE hotel_tiers SET available_rooms = available_rooms - p_qty
            WHERE room_type_id = p_tier_id;
        WHEN 'Activity' THEN
            UPDATE activities SET available_slots = available_slots - p_qty
            WHERE activity_id = p_service_id;
    END CASE;

    -- Link payment to this booking
    UPDATE payments SET related_booking_id = v_booking_id WHERE payment_id = @payment_id;

    COMMIT;
END$$


-- process_payment_custom_package:
-- Called after the payment gateway confirms payment for the custom cart.
-- This will:
-- 1) compute total from temp_package for user
-- 2) create a package row (is_custom = TRUE if you added that column; here we reuse packages)
-- 3) copy rows from temp_package -> package_details
-- 4) create bookings for each service
-- 5) update availability for each service/tier
-- 6) create payment referencing related_package_id
-- 7) clear temp_package for that user
CREATE PROCEDURE process_payment_custom_package(
    IN p_user_id INT,
    IN p_package_name VARCHAR(150),
    IN p_package_description TEXT,
    IN p_method ENUM('Card','UPI','NetBanking','Wallet','Cash')
)
BEGIN
    DECLARE v_total DECIMAL(12,2) DEFAULT 0.0;
    DECLARE v_package_id INT DEFAULT 0;
    DECLARE v_temp_id INT;
    DECLARE v_serviceType ENUM('Flight','Train','Bus','Hotel','Activity');
    DECLARE v_serviceId INT;
    DECLARE v_tierId INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE cur CURSOR FOR
        SELECT tempID, serviceType, serviceId, TierID, price
        FROM temp_package
        WHERE userID = p_user_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_temp_id = -1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Failed to process custom package (transaction rolled back).';
    END;

    -- Calculate total of temp_package and ensure there is something to book
    SELECT COALESCE(SUM(price),0) INTO v_total FROM temp_package WHERE userID = p_user_id;
    IF v_total = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cart is empty or price sum is zero.';
    END IF;

    START TRANSACTION;

    -- 1) create package header
    INSERT INTO packages (name, description, base_price, duration_days, popularity_score)
    VALUES (p_package_name, p_package_description, v_total, NULL, 0.0);
    SET v_package_id = LAST_INSERT_ID();

    -- 2) copy rows to package_details
    INSERT INTO package_details (package_id, service_type, service_ref_id)
    SELECT v_package_id, serviceType, serviceId
    FROM temp_package WHERE userID = p_user_id;

    -- 3) iterate temp_package and create bookings + update availability
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_temp_id, v_serviceType, v_serviceId, v_tierId, v_price;
        IF v_temp_id IS NULL OR v_temp_id = -1 THEN
            LEAVE read_loop;
        END IF;

        -- check availability for this service (1 quantity each insert; more complex qty can be handled by adding qty in temp_package)
        IF check_availability(v_serviceType, v_serviceId, v_tierId) <= 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = CONCAT('Service not available: ', v_serviceType, ' id=', v_serviceId);
        END IF;

        -- create booking row
        INSERT INTO bookings (user_id, package_id, service_type, service_id, tier_id, booking_date, status, total_cost)
        VALUES (p_user_id, v_package_id, v_serviceType, v_serviceId, v_tierId, NOW(), 'Confirmed', v_price);

        -- update availability
        CASE v_serviceType
            WHEN 'Flight' THEN
                UPDATE flight_tiers SET available_seats = available_seats - 1
                WHERE flight_tier_id = v_tierId;
            WHEN 'Train' THEN
                UPDATE train_tiers SET available_seats = available_seats - 1
                WHERE train_tier_id = v_tierId;
            WHEN 'Bus' THEN
                UPDATE bus_tiers SET available_seats = available_seats - 1
                WHERE bus_tier_id = v_tierId;
            WHEN 'Hotel' THEN
                UPDATE hotel_tiers SET available_rooms = available_rooms - 1
                WHERE room_type_id = v_tierId;
            WHEN 'Activity' THEN
                UPDATE activities SET available_slots = available_slots - 1
                WHERE activity_id = v_serviceId;
        END CASE;
    END LOOP;
    CLOSE cur;

    -- 4) record payment referencing package
    INSERT INTO payments (payer_user_id, related_package_id, amount, method, status)
    VALUES (p_user_id, v_package_id, v_total, p_method, 'Paid');
    -- optionally store payment id in a variable if needed: SET @payment_id = LAST_INSERT_ID();

    -- 5) clear temp_package for user
    DELETE FROM temp_package WHERE userID = p_user_id;

    COMMIT;
END$$

DELIMITER ;






DELIMITER $$

-- cancel_booking: cancel a single booking. Also increments availability and optionally triggers refund
CREATE PROCEDURE cancel_booking(
    IN p_booking_id INT,
    IN p_requesting_user INT,   -- checking user, optional
    IN p_issue_refund BOOLEAN   -- if TRUE, create refund payment record
)
BEGIN
    DECLARE v_serviceType ENUM('Flight','Train','Bus','Hotel','Activity','Package');
    DECLARE v_serviceId INT;
    DECLARE v_tierId INT;
    DECLARE v_total DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cancellation failed - transaction rolled back.';
    END;

    START TRANSACTION;

    SELECT service_type, service_id, tier_id, total_cost INTO v_serviceType, v_serviceId, v_tierId, v_total
    FROM bookings WHERE booking_id = p_booking_id FOR UPDATE;

    IF v_serviceType IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found.';
    END IF;

    -- Mark booking cancelled
    UPDATE bookings SET status = 'Cancelled' WHERE booking_id = p_booking_id;

    -- restore availability
    CASE v_serviceType
        WHEN 'Flight' THEN
            UPDATE flight_tiers SET available_seats = available_seats + 1 WHERE flight_tier_id = v_tierId;
        WHEN 'Train' THEN
            UPDATE train_tiers SET available_seats = available_seats + 1 WHERE train_tier_id = v_tierId;
        WHEN 'Bus' THEN
            UPDATE bus_tiers SET available_seats = available_seats + 1 WHERE bus_tier_id = v_tierId;
        WHEN 'Hotel' THEN
            UPDATE hotel_tiers SET available_rooms = available_rooms + 1 WHERE room_type_id = v_tierId;
        WHEN 'Activity' THEN
            UPDATE activities SET available_slots = available_slots + 1 WHERE activity_id = v_serviceId;
    END CASE;

    -- issue refund if requested
    IF p_issue_refund THEN
        INSERT INTO payments (payer_user_id, related_booking_id, amount, method, status)
        VALUES (p_requesting_user, p_booking_id, v_total * -1, 'Refund', 'Refunded');
    END IF;

    COMMIT;
END$$

DELIMITER ;







DELIMITER $$

-- add_service_rating: only allowed if booking.status = 'Completed' and rating not already given for that booking by this user
CREATE PROCEDURE add_service_rating(
    IN p_booking_id INT,
    IN p_user_id INT,
    IN p_rating_value DECIMAL(2,1),
    IN p_review TEXT
)
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_serviceType ENUM('Flight','Train','Bus','Hotel','Activity','Package');
    DECLARE v_serviceId INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Failed to add rating - rolled back.';
    END;

    IF p_rating_value < 0 OR p_rating_value > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rating must be between 0 and 5.';
    END IF;

    START TRANSACTION;

    SELECT status, service_type, service_id INTO v_status, v_serviceType, v_serviceId
    FROM bookings WHERE booking_id = p_booking_id;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found.';
    END IF;

    IF v_status <> 'Completed' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot rate until booking is completed.';
    END IF;

    -- check duplicate rating by same user for same booking
    IF EXISTS (SELECT 1 FROM service_ratings WHERE booking_id = p_booking_id AND user_id = p_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rating already exists for this booking by this user.';
    END IF;

    INSERT INTO service_ratings (booking_id, user_id, service_type, service_id, rating_value, review)
    VALUES (p_booking_id, p_user_id, v_serviceType, v_serviceId, p_rating_value, p_review);

    -- Update average rating for that service table (simple approach: compute AVG and update)
    IF v_serviceType = 'Flight' THEN
        UPDATE flights f
        JOIN (
            SELECT b.service_id AS sid, AVG(sr.rating_value) AS avg_r
            FROM service_ratings sr JOIN bookings b ON sr.booking_id = b.booking_id
            WHERE b.service_type = 'Flight' AND b.service_id = v_serviceId
            GROUP BY b.service_id
        ) t ON f.flight_id = t.sid
        SET f.rating = t.avg_r
        WHERE f.flight_id = v_serviceId;
    ELSEIF v_serviceType = 'Train' THEN
        UPDATE trains t
        JOIN (
            SELECT b.service_id AS sid, AVG(sr.rating_value) AS avg_r
            FROM service_ratings sr JOIN bookings b ON sr.booking_id = b.booking_id
            WHERE b.service_type = 'Train' AND b.service_id = v_serviceId
            GROUP BY b.service_id
        ) x ON t.train_id = x.sid
        SET t.rating = x.avg_r
        WHERE t.train_id = v_serviceId;
    ELSEIF v_serviceType = 'Bus' THEN
        UPDATE buses bs
        JOIN (
            SELECT b.service_id AS sid, AVG(sr.rating_value) AS avg_r
            FROM service_ratings sr JOIN bookings b ON sr.booking_id = b.booking_id
            WHERE b.service_type = 'Bus' AND b.service_id = v_serviceId
            GROUP BY b.service_id
        ) y ON bs.bus_id = y.sid
        SET bs.rating = y.avg_r
        WHERE bs.bus_id = v_serviceId;
    ELSEIF v_serviceType = 'Hotel' THEN
        UPDATE hotels h
        JOIN (
            SELECT b.service_id AS sid, AVG(sr.rating_value) AS avg_r
            FROM service_ratings sr JOIN bookings b ON sr.booking_id = b.booking_id
            WHERE b.service_type = 'Hotel' AND b.service_id = v_serviceId
            GROUP BY b.service_id
        ) z ON h.hotel_id = z.sid
        SET h.rating = z.avg_r
        WHERE h.hotel_id = v_serviceId;
    ELSEIF v_serviceType = 'Activity' THEN
        UPDATE activities a
        JOIN (
            SELECT b.service_id AS sid, AVG(sr.rating_value) AS avg_r
            FROM service_ratings sr JOIN bookings b ON sr.booking_id = b.booking_id
            WHERE b.service_type = 'Activity' AND b.service_id = v_serviceId
            GROUP BY b.service_id
        ) w ON a.activity_id = w.sid
        SET a.rating = w.avg_r
        WHERE a.activity_id = v_serviceId;
    ELSEIF v_serviceType = 'Package' THEN
        UPDATE packages p
        JOIN (
            SELECT b.service_id AS sid, AVG(sr.rating_value) AS avg_r
            FROM service_ratings sr JOIN bookings b ON sr.booking_id = b.booking_id
            WHERE b.service_type = 'Package' AND b.service_id = v_serviceId
            GROUP BY b.service_id
        ) q ON p.package_id = q.sid
        SET p.rating = q.avg_r
        WHERE p.package_id = v_serviceId;
    END IF;

    COMMIT;
END$$

-- update_seasonal_data: update a season row after a completed booking
CREATE PROCEDURE update_seasonal_data(
    IN p_location_id INT,
    IN p_booking_date DATE,
    IN p_booking_cost DECIMAL(10,2),
    IN p_rating DECIMAL(3,2)
)
BEGIN
    DECLARE v_season ENUM('Winter','Summer','Monsoon','Spring');
    DECLARE v_exists INT;

    SET v_season = calculate_season(p_booking_date);

    -- if row exists, update aggregated fields, else insert
    SELECT COUNT(*) INTO v_exists FROM seasonal_data WHERE location_id = p_location_id AND season = v_season;
    IF v_exists = 0 THEN
        INSERT INTO seasonal_data (location_id, season, avg_booking_price, booking_count, seasonal_rating)
        VALUES (p_location_id, v_season, p_booking_cost, 1, p_rating);
    ELSE
        -- update avg booking price and rating using running average formula
        UPDATE seasonal_data
        SET avg_booking_price = ((avg_booking_price * booking_count) + p_booking_cost) / (booking_count + 1),
            seasonal_rating = ((seasonal_rating * booking_count) + p_rating) / (booking_count + 1),
            booking_count = booking_count + 1
        WHERE location_id = p_location_id AND season = v_season;
    END IF;
END$$

-- update_popularity_score: recalc popularity for all packages (simple formula)
CREATE PROCEDURE update_popularity_score()
BEGIN
    -- popularity_score = weighted combination of rating (70%) and booking_count normalized to 10 (30%)
    -- First find max booking_count for normalization
    DECLARE v_max INT DEFAULT 1;
    SELECT COALESCE(MAX(cnt),1) INTO v_max FROM (
        SELECT COUNT(b.booking_id) AS cnt FROM bookings b WHERE b.package_id IS NOT NULL GROUP BY b.package_id
    ) t;

    UPDATE packages p
    LEFT JOIN (
        SELECT package_id, COUNT(*) AS cnt, AVG(b.total_cost) AS avg_cost
        FROM bookings b
        WHERE b.package_id IS NOT NULL
        GROUP BY package_id
    ) agg ON p.package_id = agg.package_id
    SET p.popularity_score = COALESCE((0.7 * p.rating) + (0.3 * ((COALESCE(agg.cnt,0) / v_max) * 10)), p.rating);
END$$

-- recommend_packages: returns top N recommended packages for a given season/location
CREATE PROCEDURE recommend_packages(
    IN p_location_id INT,
    IN p_season ENUM('Winter','Summer','Monsoon','Spring'),
    IN p_limit INT
)
BEGIN
    SELECT p.package_id, p.name, p.base_price, p.popularity_score, p.rating
    FROM packages p
    JOIN package_details pd ON pd.package_id = p.package_id
    LEFT JOIN flights f ON (pd.service_type = 'Flight' AND pd.service_ref_id = f.flight_id)
    LEFT JOIN hotels h ON (pd.service_type = 'Hotel' AND pd.service_ref_id = h.hotel_id)
    LEFT JOIN activities a ON (pd.service_type = 'Activity' AND pd.service_ref_id = a.activity_id)
    WHERE (
        (f.origin_id = p_location_id OR f.destination_id = p_location_id)
        OR (h.location_id = p_location_id)
        OR (a.location_id = p_location_id)
    )
    ORDER BY p.popularity_score DESC, p.rating DESC
    LIMIT p_limit;
END$$

DELIMITER ;







DECLARE CONTINUE HANDLER FOR 1062
BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '23000' SET MESSAGE_TEXT = 'Duplicate key error.';
END;









DELIMITER $$

CREATE PROCEDURE search_services(
    IN p_type ENUM('Flight','Train','Bus','Hotel','Activity'),
    IN p_origin VARCHAR(100),
    IN p_destination VARCHAR(100),
    IN p_min_price DECIMAL(10,2),
    IN p_max_price DECIMAL(10,2),
    IN p_order ENUM('ASC','DESC'),
    IN p_sort_by ENUM('price','rating')
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Search query failed due to invalid parameters or system error.';
    END;

    -- Default handling for null parameters
    SET p_min_price = COALESCE(p_min_price, 0);
    SET p_max_price = COALESCE(p_max_price, 9999999);
    SET p_order = COALESCE(p_order, 'ASC');
    SET p_sort_by = COALESCE(p_sort_by, 'price');

    CASE p_type
        ------------------------------------------------------------------
        WHEN 'Flight' THEN
            SELECT 
                f.flight_id AS service_id,
                f.flight_no AS service_name,
                l1.city AS origin,
                l2.city AS destination,
                ft.tier_name AS tier,
                ft.price AS price,
                f.rating AS rating,
                ft.available_seats AS available
            FROM flights f
            JOIN flight_tiers ft ON f.flight_id = ft.flight_id
            JOIN locations l1 ON f.origin_id = l1.location_id
            JOIN locations l2 ON f.destination_id = l2.location_id
            WHERE (p_origin IS NULL OR l1.city = p_origin)
              AND (p_destination IS NULL OR l2.city = p_destination)
              AND ft.price BETWEEN p_min_price AND p_max_price
            ORDER BY 
                CASE 
                    WHEN p_sort_by = 'price' THEN ft.price
                    WHEN p_sort_by = 'rating' THEN f.rating
                END
                COLLATE utf8mb4_unicode_ci 
                ASC;

        ------------------------------------------------------------------
        WHEN 'Train' THEN
            SELECT 
                t.train_id AS service_id,
                t.train_no AS service_name,
                l1.city AS origin,
                l2.city AS destination,
                tt.tier_name AS tier,
                tt.price AS price,
                t.rating AS rating,
                tt.available_seats AS available
            FROM trains t
            JOIN train_tiers tt ON t.train_id = tt.train_id
            JOIN locations l1 ON t.origin_id = l1.location_id
            JOIN locations l2 ON t.destination_id = l2.location_id
            WHERE (p_origin IS NULL OR l1.city = p_origin)
              AND (p_destination IS NULL OR l2.city = p_destination)
              AND tt.price BETWEEN p_min_price AND p_max_price
            ORDER BY 
                CASE 
                    WHEN p_sort_by = 'price' THEN tt.price
                    WHEN p_sort_by = 'rating' THEN t.rating
                END
                COLLATE utf8mb4_unicode_ci 
                ASC;

        ------------------------------------------------------------------
        WHEN 'Bus' THEN
            SELECT 
                b.bus_id AS service_id,
                b.bus_no AS service_name,
                l1.city AS origin,
                l2.city AS destination,
                bt.category AS tier,
                bt.price AS price,
                b.rating AS rating,
                bt.available_seats AS available
            FROM buses b
            JOIN bus_tiers bt ON b.bus_id = bt.bus_id
            JOIN locations l1 ON b.origin_id = l1.location_id
            JOIN locations l2 ON b.destination_id = l2.location_id
            WHERE (p_origin IS NULL OR l1.city = p_origin)
              AND (p_destination IS NULL OR l2.city = p_destination)
              AND bt.price BETWEEN p_min_price AND p_max_price
            ORDER BY 
                CASE 
                    WHEN p_sort_by = 'price' THEN bt.price
                    WHEN p_sort_by = 'rating' THEN b.rating
                END
                COLLATE utf8mb4_unicode_ci 
                ASC;



