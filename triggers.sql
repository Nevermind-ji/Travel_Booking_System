USE travel_booking;
DELIMITER $$

/* ============================================================
   SECTION 1: DATA VALIDATION & INTEGRITY
   ============================================================ */

/* 1️⃣ Validate user details before insertion */
CREATE TRIGGER validate_user_insert
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF NEW.name IS NULL OR NEW.email IS NULL OR NEW.phone IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User name, email, and phone cannot be NULL';
    END IF;
    IF NEW.email NOT LIKE '%@%.%' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email format';
    END IF;
    IF CHAR_LENGTH(NEW.phone) < 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Phone number must be at least 10 digits';
    END IF;
END$$

/* 2️⃣ Ensure all tier/service prices are positive */
CREATE TRIGGER validate_price_positive_flights
BEFORE INSERT ON flight_tiers
FOR EACH ROW
BEGIN
    IF NEW.price <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Flight tier price must be positive';
    END IF;
END$$

CREATE TRIGGER validate_price_positive_hotels
BEFORE INSERT ON hotel_tiers
FOR EACH ROW
BEGIN
    IF NEW.price_per_night <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Hotel room price must be positive';
    END IF;
END$$

CREATE TRIGGER validate_price_positive_trains
BEFORE INSERT ON train_tiers
FOR EACH ROW
BEGIN
    IF NEW.price <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Train tier price must be positive';
    END IF;
END$$

CREATE TRIGGER validate_price_positive_buses
BEFORE INSERT ON bus_tiers
FOR EACH ROW
BEGIN
    IF NEW.price <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bus tier price must be positive';
    END IF;
END$$

CREATE TRIGGER validate_price_positive_activities
BEFORE INSERT ON activities
FOR EACH ROW
BEGIN
    IF NEW.price <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Activity price must be positive';
    END IF;
END$$

/* 3️⃣ Payments must reference at least one related entity */
CREATE TRIGGER prevent_null_foreign_keys
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    IF NEW.related_booking_id IS NULL AND NEW.related_package_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Either booking_id or package_id must be provided for a payment';
    END IF;
END$$


/* ============================================================
   SECTION 2: AVAILABILITY & OVERBOOKING PROTECTION
   ============================================================ */

/* 4️⃣ Check service availability before booking */
CREATE TRIGGER check_availability_before_booking
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    DECLARE available_count INT DEFAULT 0;

    CASE NEW.service_type
        WHEN 'Flight' THEN
            SELECT ft.available_seats INTO available_count
            FROM flight_tiers ft WHERE ft.flight_id = NEW.service_id LIMIT 1;
        WHEN 'Train' THEN
            SELECT tt.available_seats INTO available_count
            FROM train_tiers tt WHERE tt.train_id = NEW.service_id LIMIT 1;
        WHEN 'Bus' THEN
            SELECT bt.available_seats INTO available_count
            FROM bus_tiers bt WHERE bt.bus_id = NEW.service_id LIMIT 1;
        WHEN 'Hotel' THEN
            SELECT ht.available_rooms INTO available_count
            FROM hotel_tiers ht WHERE ht.hotel_id = NEW.service_id LIMIT 1;
        WHEN 'Activity' THEN
            SELECT a.available_slots INTO available_count
            FROM activities a WHERE a.activity_id = NEW.service_id LIMIT 1;
    END CASE;

    IF available_count <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Service unavailable — no seats/rooms/slots left';
    END IF;
END$$


/* 5️⃣ Decrease availability after booking */
CREATE TRIGGER update_availability_after_booking
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
    CASE NEW.service_type
        WHEN 'Flight' THEN
            UPDATE flight_tiers SET available_seats = available_seats - 1 WHERE flight_id = NEW.service_id;
        WHEN 'Train' THEN
            UPDATE train_tiers SET available_seats = available_seats - 1 WHERE train_id = NEW.service_id;
        WHEN 'Bus' THEN
            UPDATE bus_tiers SET available_seats = available_seats - 1 WHERE bus_id = NEW.service_id;
        WHEN 'Hotel' THEN
            UPDATE hotel_tiers SET available_rooms = available_rooms - 1 WHERE hotel_id = NEW.service_id;
        WHEN 'Activity' THEN
            UPDATE activities SET available_slots = available_slots - 1 WHERE activity_id = NEW.service_id;
    END CASE;
END$$


/* 6️⃣ Restore availability on cancellation */
CREATE TRIGGER restore_availability_on_cancel
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    IF NEW.status = 'Cancelled' AND OLD.status <> 'Cancelled' THEN
        CASE NEW.service_type
            WHEN 'Flight' THEN
                UPDATE flight_tiers SET available_seats = available_seats + 1 WHERE flight_id = NEW.service_id;
            WHEN 'Train' THEN
                UPDATE train_tiers SET available_seats = available_seats + 1 WHERE train_id = NEW.service_id;
            WHEN 'Bus' THEN
                UPDATE bus_tiers SET available_seats = available_seats + 1 WHERE bus_id = NEW.service_id;
            WHEN 'Hotel' THEN
                UPDATE hotel_tiers SET available_rooms = available_rooms + 1 WHERE hotel_id = NEW.service_id;
            WHEN 'Activity' THEN
                UPDATE activities SET available_slots = available_slots + 1 WHERE activity_id = NEW.service_id;
        END CASE;
    END IF;
END$$


/* ============================================================
   SECTION 3: RATINGS & INSIGHTS AUTOMATION
   ============================================================ */

/* 7️⃣ Update average rating after a new service rating */
CREATE TRIGGER update_service_avg_rating
AFTER INSERT ON service_ratings
FOR EACH ROW
BEGIN
    DECLARE avg_rating DECIMAL(3,2);

    SELECT AVG(rating_value) INTO avg_rating
    FROM service_ratings
    WHERE service_type = NEW.service_type AND service_id = NEW.service_id;

    CASE NEW.service_type
        WHEN 'Flight' THEN UPDATE flights SET rating = avg_rating WHERE flight_id = NEW.service_id;
        WHEN 'Train' THEN UPDATE trains SET rating = avg_rating WHERE train_id = NEW.service_id;
        WHEN 'Bus' THEN UPDATE buses SET rating = avg_rating WHERE bus_id = NEW.service_id;
        WHEN 'Hotel' THEN UPDATE hotels SET rating = avg_rating WHERE hotel_id = NEW.service_id;
        WHEN 'Activity' THEN UPDATE activities SET rating = avg_rating WHERE activity_id = NEW.service_id;
        WHEN 'Package' THEN UPDATE packages SET rating = avg_rating WHERE package_id = NEW.service_id;
    END CASE;
END$$


/* 8️⃣ Update seasonal averages after booking */
CREATE TRIGGER update_seasonal_avg_after_booking
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
    DECLARE loc_id INT;
    DECLARE current_season VARCHAR(20);

    SET current_season = calculate_season(CURDATE());

    -- Find related location based on service type
    CASE NEW.service_type
        WHEN 'Flight' THEN SELECT destination_id INTO loc_id FROM flights WHERE flight_id = NEW.service_id;
        WHEN 'Train' THEN SELECT destination_id INTO loc_id FROM trains WHERE train_id = NEW.service_id;
        WHEN 'Bus' THEN SELECT destination_id INTO loc_id FROM buses WHERE bus_id = NEW.service_id;
        WHEN 'Hotel' THEN SELECT location_id INTO loc_id FROM hotels WHERE hotel_id = NEW.service_id;
        WHEN 'Activity' THEN SELECT location_id INTO loc_id FROM activities WHERE activity_id = NEW.service_id;
    END CASE;

    UPDATE seasonal_data
    SET booking_count = booking_count + 1,
        avg_booking_price = (avg_booking_price * (booking_count - 1) + NEW.price) / booking_count
    WHERE location_id = loc_id AND season = current_season;
END$$


/* 9️⃣ Auto-update package popularity */
CREATE TRIGGER update_package_popularity
AFTER INSERT ON service_ratings
FOR EACH ROW
BEGIN
    IF NEW.service_type = 'Package' THEN
        UPDATE packages
        SET popularity_score = (0.7 * rating) + (0.3 * booking_count)
        WHERE package_id = NEW.service_id;
    END IF;
END$$


/* ============================================================
   SECTION 4: PAYMENT & TRANSACTION SAFETY
   ============================================================ */

/* 🔟 Prevent unpaid bookings */
CREATE TRIGGER prevent_booking_without_payment
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM payments
        WHERE (related_booking_id = NEW.booking_id OR related_package_id = NEW.package_id)
          AND status = 'Paid'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Booking cannot be made without a successful payment';
    END IF;
END$$


/* 11️⃣ Validate payment logic */
CREATE TRIGGER validate_payment_status
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    IF NEW.amount < 0 AND NEW.status <> 'Refunded' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Negative amount allowed only for refunds';
    END IF;
    IF NEW.status NOT IN ('Paid', 'Pending', 'Failed', 'Refunded') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid payment status';
    END IF;
END$$


/* ============================================================
   SECTION 5: AUDIT & MAINTENANCE
   ============================================================ */

/* 12️⃣ Log booking activities for auditing */
CREATE TRIGGER log_booking_activity
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
    INSERT INTO booking_log (booking_id, user_id, service_type, action, log_time)
    VALUES (NEW.booking_id, NEW.user_id, NEW.service_type, 'Created', NOW());
END$$

CREATE TRIGGER log_booking_update
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    INSERT INTO booking_log (booking_id, user_id, service_type, action, log_time)
    VALUES (NEW.booking_id, NEW.user_id, NEW.service_type, CONCAT('Updated to ', NEW.status), NOW());
END$$


/* 13️⃣ Clean up expired temp packages */
CREATE TRIGGER cleanup_expired_temp_packages
AFTER INSERT ON temp_package
FOR EACH ROW
BEGIN
    DELETE FROM temp_package WHERE created_at < NOW() - INTERVAL 1 DAY;
END$$

DELIMITER ;
