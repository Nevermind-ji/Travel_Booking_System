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
LEFT JOIN package_details pd 
    ON pd.service_type = 'Activity' AND pd.service_ref_id = l.location_id
LEFT JOIN packages p 
    ON pd.package_id = p.package_id;



CREATE OR REPLACE VIEW available_services_view AS
SELECT 'Flight' AS service_type, f.flight_id AS service_id, f.flight_no AS service_name,
       l1.city AS origin, l2.city AS destination, ft.price, ft.available_seats AS available, f.rating
FROM flights f
JOIN flight_tiers ft ON f.flight_id = ft.flight_id
JOIN locations l1 ON f.origin_id = l1.location_id
JOIN locations l2 ON f.destination_id = l2.location_id
UNION
SELECT 'Train', t.train_id, t.train_no, l1.city, l2.city, tt.price, tt.available_seats, t.rating
FROM trains t
JOIN train_tiers tt ON t.train_id = tt.train_id
JOIN locations l1 ON t.origin_id = l1.location_id
JOIN locations l2 ON t.destination_id = l2.location_id
UNION
SELECT 'Bus', b.bus_id, b.bus_no, l1.city, l2.city, bt.price, bt.available_seats, b.rating
FROM buses b
JOIN bus_tiers bt ON b.bus_id = bt.bus_id
JOIN locations l1 ON b.origin_id = l1.location_id
JOIN locations l2 ON b.destination_id = l2.location_id
UNION
SELECT 'Hotel', h.hotel_id, h.name, l.city, NULL, ht.price_per_night, ht.available_rooms, h.rating
FROM hotels h
JOIN hotel_tiers ht ON h.hotel_id = ht.hotel_id
JOIN locations l ON h.location_id = l.location_id
UNION
SELECT 'Activity', a.activity_id, a.name, l.city, NULL, a.price, a.available_slots, a.rating
FROM activities a
JOIN locations l ON a.location_id = l.location_id;





CREATE OR REPLACE VIEW user_bookings_view AS
SELECT 
    b.booking_id,
    b.user_id,
    u.name AS user_name,
    b.service_type,
    b.service_id,
    b.status,
    b.total_cost AS price,  -- ✅ use total_cost here
    p.payment_id,
    p.amount,
    p.status AS payment_status,
    p.method AS payment_method,
    p.payment_date,
    CASE 
        WHEN b.service_type = 'Flight' THEN f.flight_no
        WHEN b.service_type = 'Train' THEN t.train_no
        WHEN b.service_type = 'Bus' THEN b2.bus_no
        WHEN b.service_type = 'Hotel' THEN h.name
        WHEN b.service_type = 'Activity' THEN a.name
    END AS service_name
FROM bookings b
JOIN users u ON b.user_id = u.user_id
LEFT JOIN payments p ON (p.related_booking_id = b.booking_id)
LEFT JOIN flights f ON b.service_id = f.flight_id
LEFT JOIN trains t ON b.service_id = t.train_id
LEFT JOIN buses b2 ON b.service_id = b2.bus_id
LEFT JOIN hotels h ON b.service_id = h.hotel_id
LEFT JOIN activities a ON b.service_id = a.activity_id;









CREATE OR REPLACE VIEW package_services_view AS
SELECT 
    p.package_id,
    p.name AS package_name,
    pd.service_type,
    pd.service_ref_id AS service_id,
    CASE 
        WHEN pd.service_type = 'Flight' THEN f.flight_no
        WHEN pd.service_type = 'Hotel' THEN h.name
        WHEN pd.service_type = 'Bus' THEN b.bus_no
        WHEN pd.service_type = 'Train' THEN t.train_no
        WHEN pd.service_type = 'Activity' THEN a.name
    END AS service_name,
    CASE
        WHEN pd.service_type = 'Flight' THEN ft.price
        WHEN pd.service_type = 'Train' THEN tt.price
        WHEN pd.service_type = 'Bus' THEN bt.price
        WHEN pd.service_type = 'Hotel' THEN ht.price_per_night
        WHEN pd.service_type = 'Activity' THEN a.price
    END AS service_price
FROM packages p
JOIN package_details pd ON p.package_id = pd.package_id
LEFT JOIN flights f ON pd.service_ref_id = f.flight_id
LEFT JOIN flight_tiers ft ON f.flight_id = ft.flight_id
LEFT JOIN trains t ON pd.service_ref_id = t.train_id
LEFT JOIN train_tiers tt ON t.train_id = tt.train_id
LEFT JOIN buses b ON pd.service_ref_id = b.bus_id
LEFT JOIN bus_tiers bt ON b.bus_id = bt.bus_id
LEFT JOIN hotels h ON pd.service_ref_id = h.hotel_id
LEFT JOIN hotel_tiers ht ON h.hotel_id = ht.hotel_id
LEFT JOIN activities a ON pd.service_ref_id = a.activity_id;







CREATE OR REPLACE VIEW active_users_view AS
SELECT 
    u.user_id,
    u.name,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_cost) AS total_spent
FROM users u
LEFT JOIN bookings b ON u.user_id = b.user_id
GROUP BY u.user_id
ORDER BY total_bookings DESC;

