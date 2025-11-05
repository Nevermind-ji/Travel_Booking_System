-- ===========================================================
-- =============== Helper Functions ==========================
-- ===========================================================

DELIMITER $$

-- function: calculate_season(date) -> 'Winter'/'Summer'/'Monsoon'/'Spring'
CREATE FUNCTION calculate_season(p_dt DATE)
RETURNS ENUM('Winter','Summer','Monsoon','Spring')
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

-- function: validate_email
CREATE FUNCTION validate_email(p_email VARCHAR(255))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    IF p_email IS NULL OR p_email = '' THEN
        RETURN FALSE;
    END IF;
    IF LOCATE('@', p_email) = 0 OR LOCATE('.', p_email, LOCATE('@', p_email)) = 0 THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
END$$

-- function: validate_price
CREATE FUNCTION validate_price(p_price DECIMAL(10,2))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    IF p_price IS NULL OR p_price < 0 THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
END$$

-- function: check_availability(service_type, service_id, tier_id)
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


-- ===========================================================
-- =============== User & Admin Procedures ===================
-- ===========================================================

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

-- create_predefined_package: admin helper
CREATE PROCEDURE create_predefined_package(
    IN p_name VARCHAR(100),
    IN p_desc TEXT,
    IN p_base_price DECIMAL(10,2),
    IN p_duration_days INT
)
BEGIN
    IF NOT validate_price(p_base_price) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid base price.';
    END IF;

    START TRANSACTION;
        INSERT INTO packages (name, description, base_price, duration_days)
        VALUES (p_name, p_desc, p_base_price, p_duration_days);
    COMMIT;
END$$

DELIMITER ;


-- ===========================================================
-- =============== Booking & Payment Procedures ==============
-- ===========================================================

DELIMITER $$

-- process_payment_single: for single service
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

    IF p_qty <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be >= 1.';
    END IF;

    START TRANSACTION;

    SET v_avail = check_availability(p_service_type, p_service_id, p_tier_id);
    IF v_avail < p_qty THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough availability.';
    END IF;

    INSERT INTO payments (payer_user_id, amount, method, status)
    VALUES (p_user_id, p_total_amount, p_method, 'Paid');
    SET @payment_id = LAST_INSERT_ID();

    INSERT INTO bookings (user_id, service_type, service_id, tier_id, booking_date, status, total_cost)
    VALUES (p_user_id, p_service_type, p_service_id, p_tier_id, NOW(), 'Confirmed', p_total_amount);
    SET v_booking_id = LAST_INSERT_ID();

    CASE p_service_type
        WHEN 'Flight' THEN
            UPDATE flight_tiers SET available_seats = available_seats - p_qty WHERE flight_tier_id = p_tier_id;
        WHEN 'Train' THEN
            UPDATE train_tiers SET available_seats = available_seats - p_qty WHERE train_tier_id = p_tier_id;
        WHEN 'Bus' THEN
            UPDATE bus_tiers SET available_seats = available_seats - p_qty WHERE bus_tier_id = p_tier_id;
        WHEN 'Hotel' THEN
            UPDATE hotel_tiers SET available_rooms = available_rooms - p_qty WHERE room_type_id = p_tier_id;
        WHEN 'Activity' THEN
            UPDATE activities SET available_slots = available_slots - p_qty WHERE activity_id = p_service_id;
    END CASE;

    UPDATE payments SET related_booking_id = v_booking_id WHERE payment_id = @payment_id;

    COMMIT;
END$$

-- process_payment_custom_package: for user-created package
CREATE PROCEDURE process_payment_custom_package(
    IN p_user_id INT,
    IN p_package_name VARCHAR(150),
    IN p_package_description TEXT,
    IN p_method ENUM('Card','UPI','NetBanking','Wallet','Cash')
)
BEGIN
    DECLARE v_total DECIMAL(12,2) DEFAULT 0.0;
    DECLARE v_package_id INT;
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

    SELECT COALESCE(SUM(price),0) INTO v_total FROM temp_package WHERE userID = p_user_id;
    IF v_total = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cart empty.';
    END IF;

    START TRANSACTION;

    INSERT INTO packages (name, description, base_price)
    VALUES (p_package_name, p_package_description, v_total);
    SET v_package_id = LAST_INSERT_ID();

    INSERT INTO package_details (package_id, service_type, service_ref_id)
    SELECT v_package_id, serviceType, serviceId FROM temp_package WHERE userID = p_user_id;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_temp_id, v_serviceType, v_serviceId, v_tierId, v_price;
        IF v_temp_id = -1 THEN LEAVE read_loop; END IF;

        IF check_availability(v_serviceType, v_serviceId, v_tierId) <= 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Service unavailable.';
        END IF;

        INSERT INTO bookings (user_id, package_id, service_type, service_id, tier_id, booking_date, status, total_cost)
        VALUES (p_user_id, v_package_id, v_serviceType, v_serviceId, v_tierId, NOW(), 'Confirmed', v_price);

        CASE v_serviceType
            WHEN 'Flight' THEN UPDATE flight_tiers SET available_seats = available_seats - 1 WHERE flight_tier_id = v_tierId;
            WHEN 'Train' THEN UPDATE train_tiers SET available_seats = available_seats - 1 WHERE train_tier_id = v_tierId;
            WHEN 'Bus' THEN UPDATE bus_tiers SET available_seats = available_seats - 1 WHERE bus_tier_id = v_tierId;
            WHEN 'Hotel' THEN UPDATE hotel_tiers SET available_rooms = available_rooms - 1 WHERE room_type_id = v_tierId;
            WHEN 'Activity' THEN UPDATE activities SET available_slots = available_slots - 1 WHERE activity_id = v_serviceId;
        END CASE;
    END LOOP;
    CLOSE cur;

    INSERT INTO payments (payer_user_id, related_package_id, amount, method, status)
    VALUES (p_user_id, v_package_id, v_total, p_method, 'Paid');

    DELETE FROM temp_package WHERE userID = p_user_id;

    COMMIT;
END$$

-- cancel_booking: safely cancel booking and restore availability
CREATE PROCEDURE cancel_booking(
    IN p_booking_id INT,
    IN p_requesting_user INT,
    IN p_issue_refund BOOLEAN
)
BEGIN
    DECLARE v_serviceType ENUM('Flight','Train','Bus','Hotel','Activity','Package');
    DECLARE v_serviceId INT;
    DECLARE v_tierId INT;
    DECLARE v_total DECIMAL(10,2);

    START TRANSACTION;

    SELECT service_type, service_id, tier_id, total_cost INTO v_serviceType, v_serviceId, v_tierId, v_total
    FROM bookings WHERE booking_id = p_booking_id FOR UPDATE;

    UPDATE bookings SET status = 'Cancelled' WHERE booking_id = p_booking_id;

    CASE v_serviceType
        WHEN 'Flight' THEN UPDATE flight_tiers SET available_seats = available_seats + 1 WHERE flight_tier_id = v_tierId;
        WHEN 'Train' THEN UPDATE train_tiers SET available_seats = available_seats + 1 WHERE train_tier_id = v_tierId;
        WHEN 'Bus' THEN UPDATE bus_tiers SET available_seats = available_seats + 1 WHERE bus_tier_id = v_tierId;
        WHEN 'Hotel' THEN UPDATE hotel_tiers SET available_rooms = available_rooms + 1 WHERE room_type_id = v_tierId;
        WHEN 'Activity' THEN UPDATE activities SET available_slots = available_slots + 1 WHERE activity_id = v_serviceId;
    END CASE;

    IF p_issue_refund THEN
        INSERT INTO payments (payer_user_id, related_booking_id, amount, method, status)
        VALUES (p_requesting_user, p_booking_id, v_total * -1, 'Refund', 'Refunded');
    END IF;

    COMMIT;
END$$

DELIMITER ;


-- ===========================================================
-- =============== Rating & Insights Procedures ==============
-- ===========================================================

DELIMITER $$

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

    IF p_rating_value < 0 OR p_rating_value > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid rating.';
    END IF;

    START TRANSACTION;

    SELECT status, service_type, service_id INTO v_status, v_serviceType, v_serviceId
    FROM bookings WHERE booking_id = p_booking_id;

    IF v_status <> 'Completed' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot rate before completion.';
    END IF;

    INSERT INTO service_ratings (booking_id, user_id, service_type, service_id, rating_value, review)
    VALUES (p_booking_id, p_user_id, v_serviceType, v_serviceId, p_rating_value, p_review);

    COMMIT;
END$$


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
    SELECT COUNT(*) INTO v_exists FROM seasonal_data WHERE location_id = p_location_id AND season = v_season;

    IF v_exists = 0 THEN
        INSERT INTO seasonal_data (location_id, season, avg_booking_price, booking_count, seasonal_rating)
        VALUES (p_location_id, v_season, p_booking_cost, 1, p_rating);
    ELSE
        UPDATE seasonal_data
        SET avg_booking_price = ((avg_booking_price * booking_count) + p_booking_cost) / (booking_count + 1),
            seasonal_rating = ((seasonal_rating * booking_count) + p_rating) / (booking_count + 1),
            booking_count = booking_count + 1
        WHERE location_id = p_location_id AND season = v_season;
    END IF;
END$$


CREATE PROCEDURE update_popularity_score()
BEGIN
    DECLARE v_max INT DEFAULT 1;
    SELECT COALESCE(MAX(cnt),1) INTO v_max FROM (
        SELECT COUNT(b.booking_id) AS cnt FROM bookings b WHERE b.package_id IS NOT NULL GROUP BY b.package_id
    ) t;

    UPDATE packages p
    LEFT JOIN (
        SELECT package_id, COUNT(*) AS cnt
        FROM bookings
        WHERE package_id IS NOT NULL
        GROUP BY package_id
    ) agg ON p.package_id = agg.package_id
    SET p.popularity_score = COALESCE((0.7 * p.rating) + (0.3 * ((COALESCE(agg.cnt,0) / v_max) * 10)), p.rating);
END$$


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


-- ===========================================================
-- =============== Search Procedure ==========================
-- ===========================================================

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
    SET p_min_price = COALESCE(p_min_price, 0);
    SET p_max_price = COALESCE(p_max_price, 9999999);

    CASE p_type
        WHEN 'Flight' THEN
            SELECT f.flight_id, f.flight_no, l1.city AS origin, l2.city AS destination,
                   ft.tier_name, ft.price, f.rating, ft.available_seats
            FROM flights f
            JOIN flight_tiers ft ON f.flight_id = ft.flight_id
            JOIN locations l1 ON f.origin_id = l1.location_id
            JOIN locations l2 ON f.destination_id = l2.location_id
            WHERE (p_origin IS NULL OR l1.city = p_origin)
              AND (p_destination IS NULL OR l2.city = p_destination)
              AND ft.price BETWEEN p_min_price AND p_max_price
            ORDER BY 
                CASE WHEN p_sort_by = 'price' THEN ft.price WHEN p_sort_by = 'rating' THEN f.rating END;

        WHEN 'Train' THEN
            SELECT t.train_id, t.train_no, l1.city AS origin, l2.city AS destination,
                   tt.tier_name, tt.price, t.rating, tt.available_seats
            FROM trains t
            JOIN train_tiers tt ON t.train_id = tt.train_id
