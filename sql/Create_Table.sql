CREATE TABLE memberships (
    membership_id INT AUTO_INCREMENT PRIMARY KEY,
    tier_name VARCHAR(50) NOT NULL,
    discount_percent DECIMAL(5,2) DEFAULT 0.00 CHECK (discount_percent >= 0)
);

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    membership_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_membership FOREIGN KEY (membership_id) REFERENCES memberships(membership_id)
);

CREATE TABLE user_groups (
    group_id INT AUTO_INCREMENT PRIMARY KEY,
    createdByUserID INT NOT NULL,
    CONSTRAINT fk_group_user FOREIGN KEY (createdByUserID) REFERENCES users(user_id)
);

CREATE TABLE locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    avg_rating DECIMAL(3,2) DEFAULT 0.0,
    seasonal_rating DECIMAL(3,2) DEFAULT 0.0,
    seasonal_demand INT DEFAULT 0 CHECK (seasonal_demand >= 0)
);

CREATE TABLE flights (
    flight_id INT AUTO_INCREMENT PRIMARY KEY,
    flight_no VARCHAR(20) UNIQUE NOT NULL,
    origin_id INT NOT NULL,
    destination_id INT NOT NULL,
    departure_time DATETIME NOT NULL,
    arrival_time DATETIME NOT NULL,
    total_seats INT NOT NULL CHECK (total_seats > 0),
    rating DECIMAL(3,2) DEFAULT 0.0,
    CONSTRAINT fk_flight_origin FOREIGN KEY (origin_id) REFERENCES locations(location_id),
    CONSTRAINT fk_flight_destination FOREIGN KEY (destination_id) REFERENCES locations(location_id)
);

CREATE TABLE flight_tiers (
    flight_tier_id INT AUTO_INCREMENT PRIMARY KEY,
    flight_id INT NOT NULL,
    tier_name ENUM('Economy','Business','First') NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    available_seats INT DEFAULT 0 CHECK (available_seats >= 0),
    CONSTRAINT fk_flighttier_flight FOREIGN KEY (flight_id) REFERENCES flights(flight_id)
);


CREATE TABLE train_tiers (
    train_tier_id INT AUTO_INCREMENT PRIMARY KEY,
    train_id INT NOT NULL,
    coach_type ENUM('Sleeper','AC 3-tier','AC 2-tier','Chair') NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    available_seats INT DEFAULT 0 CHECK (available_seats >= 0),
    CONSTRAINT fk_train_tier FOREIGN KEY (train_id) REFERENCES trains(train_id)
);

CREATE TABLE buses (
    bus_id INT AUTO_INCREMENT PRIMARY KEY,
    bus_no VARCHAR(20) UNIQUE NOT NULL,
    origin_id INT NOT NULL,
    destination_id INT NOT NULL,
    departure_time DATETIME NOT NULL,
    arrival_time DATETIME NOT NULL,
    total_seats INT NOT NULL CHECK (total_seats > 0),
    rating DECIMAL(3,2) DEFAULT 0.0,
    CONSTRAINT fk_bus_origin FOREIGN KEY (origin_id) REFERENCES locations(location_id),
    CONSTRAINT fk_bus_destination FOREIGN KEY (destination_id) REFERENCES locations(location_id)
);

CREATE TABLE bus_tiers (
    bus_tier_id INT AUTO_INCREMENT PRIMARY KEY,
    bus_id INT NOT NULL,
    category ENUM('AC','Non-AC','Volvo','Luxury') NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    available_seats INT DEFAULT 0 CHECK (available_seats >= 0),
    CONSTRAINT fk_bustier_bus FOREIGN KEY (bus_id) REFERENCES buses(bus_id)
);

CREATE TABLE hotels (
    hotel_id INT AUTO_INCREMENT PRIMARY KEY,
    location_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    rating DECIMAL(3,2) DEFAULT 0.0,
    total_rooms INT NOT NULL CHECK (total_rooms > 0),
    CONSTRAINT fk_hotel_location FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

CREATE TABLE hotel_tiers (
    room_type_id INT AUTO_INCREMENT PRIMARY KEY,
    hotel_id INT NOT NULL,
    room_type ENUM('Standard','Deluxe','Suite') NOT NULL,
    price_per_night DECIMAL(10,2) NOT NULL CHECK (price_per_night >= 0),
    available_rooms INT DEFAULT 0 CHECK (available_rooms >= 0),
    CONSTRAINT fk_roomtype_hotel FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
);

CREATE TABLE activities (
    activity_id INT AUTO_INCREMENT PRIMARY KEY,
    location_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    category ENUM('Adventure','Cultural','Nature','Leisure') NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    capacity INT DEFAULT 0 CHECK (capacity >= 0),
    available_slots INT DEFAULT 0 CHECK (available_slots >= 0),
    rating DECIMAL(3,2) DEFAULT 0.0,
    duration_hrs INT,
    CONSTRAINT fk_activity_location FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

CREATE TABLE packages (
    package_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    base_price DECIMAL(10,2) DEFAULT 0.0 CHECK (base_price >= 0),
    duration_days INT,
    popularity_score DECIMAL(5,2) DEFAULT 0.0 CHECK (popularity_score >= 0),
    rating DECIMAL(3,2) DEFAULT 0.0
);

CREATE TABLE package_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    package_id INT NOT NULL,
    service_type ENUM('Flight','Train','Bus','Hotel','Activity') NOT NULL,
    service_ref_id INT NOT NULL CHECK (service_ref_id > 0),
    CONSTRAINT fk_packagedetails_package FOREIGN KEY (package_id) REFERENCES packages(package_id)
);

CREATE TABLE bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    package_id INT,
    service_type ENUM('Flight','Train','Bus','Hotel','Activity','Package') NOT NULL,
    service_id INT NOT NULL,
    tier_id INT,
    booking_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Confirmed','Cancelled','Completed') NOT NULL,
    ticket_number VARCHAR(20) UNIQUE,
    total_cost DECIMAL(10,2) DEFAULT 0.0 CHECK (total_cost >= 0),
    CONSTRAINT fk_booking_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_booking_package FOREIGN KEY (package_id) REFERENCES packages(package_id)
);

CREATE TABLE co_travelers (
    traveler_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    groupID INT,
    name VARCHAR(100) NOT NULL,
    age INT CHECK (age >= 0),
    gender ENUM('M','F','Other'),
    id_proof VARCHAR(50),
    CONSTRAINT fk_cotraveler_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    CONSTRAINT fk_cotraveler_group FOREIGN KEY (groupID) REFERENCES user_groups(group_id)
);

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    payer_user_id INT NOT NULL,
    related_package_id INT,
    related_booking_id INT,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    method ENUM('Card','UPI','NetBanking','Wallet','Cash') NOT NULL,
    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Paid','Refunded','Pending','Failed') NOT NULL,
    CONSTRAINT fk_payment_user FOREIGN KEY (payer_user_id) REFERENCES users(user_id),
    CONSTRAINT fk_payment_package FOREIGN KEY (related_package_id) REFERENCES packages(package_id),
    CONSTRAINT fk_payment_booking FOREIGN KEY (related_booking_id) REFERENCES bookings(booking_id),
    CONSTRAINT chk_one_reference CHECK (
        (related_package_id IS NOT NULL AND related_booking_id IS NULL)
        OR
        (related_package_id IS NULL AND related_booking_id IS NOT NULL)
    )
);

CREATE TABLE service_ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    user_id INT NOT NULL,
    service_type ENUM('Flight','Train','Bus','Hotel','Activity','Package') NOT NULL,
    service_id INT NOT NULL,
    rating_value DECIMAL(2,1) NOT NULL CHECK (rating_value BETWEEN 0 AND 5),
    review TEXT,
    rating_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rating_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    CONSTRAINT fk_rating_user FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE seasonal_data (
    season_id INT AUTO_INCREMENT PRIMARY KEY,
    location_id INT NOT NULL,
    season ENUM('Winter','Summer','Monsoon','Spring') NOT NULL,
    avg_booking_price DECIMAL(10,2) DEFAULT 0.0 CHECK (avg_booking_price >= 0),
    booking_count INT DEFAULT 0 CHECK (booking_count >= 0),
    seasonal_rating DECIMAL(3,2) DEFAULT 0.0,
    CONSTRAINT fk_season_location FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

CREATE TABLE temp_package (
    tempID INT AUTO_INCREMENT PRIMARY KEY,
    userID INT NOT NULL,
    serviceType ENUM('Flight','Train','Bus','Hotel','Activity') NOT NULL,
    serviceId INT NOT NULL,
    TierID INT NOT NULL,
    qty INT DEFAULT 1 CHECK (qty > 0),
    price DECIMAL(10,2) DEFAULT 0.0 CHECK (price >= 0),
    added_on_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_temp_user FOREIGN KEY (userID) REFERENCES users(user_id)
);

-- ============================================================
-- VIEWS SECTION
-- ============================================================

CREATE OR REPLACE VIEW insights_view AS
SELECT
    l.location_id,
    l.city,
    s.season,
    s.avg_booking_price,
    s.booking_count,
    s.seasonal_rating,
    p.package_id,
    p.name AS package_name,
    p.base_price,
    p.popularity_score,
    p.rating AS package_rating
FROM locations l
JOIN seasonal_data s ON l.location_id = s.location_id
LEFT JOIN package_details pd ON pd.service_ref_id = l.location_id AND pd.service_type = 'Activity'
LEFT JOIN packages p ON pd.package_id = p.package_id;

