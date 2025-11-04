-- =====================================================
-- INSERT DATA FOR TRAVEL_BOOKING SYSTEM
-- =====================================================


INSERT INTO memberships (tier_name, discount_percent) VALUES
('Basic', 0.00),
('Silver', 5.00),
('Gold', 10.00),
('Platinum', 15.00);


INSERT INTO users (name, email, phone, membership_id) VALUES
('Aarav Mehta','aarav01@gmail.com','9876543210',1),
('Isha Kapoor','isha.kapoor@gmail.com','9812345678',2),
('Rohan Sharma','rohan_sharma@gmail.com','9821112233',1),
('Priya Singh','priya.singh@gmail.com','9800001111',3),
('Aditya Rao','aditya.rao@gmail.com','9001112222',1),
('Meera Joshi','meera.j@gmail.com','9011223344',4),
('Tanvi Bansal','tanvi.b@gmail.com','9087654321',3),
('Kunal Arora','kunal.a@gmail.com','9223344556',2),
('Ritika Malhotra','ritika.m@gmail.com','9322233344',3),
('Arnav Gupta','arnav.gupta@gmail.com','9411122233',4),
('Simran Kaur','simran.kaur@gmail.com','9512233445',2),
('Dev Patel','dev.p@gmail.com','9611344556',1),
('Ananya Verma','ananya.v@gmail.com','9712455667',3),
('Ritesh Iyer','ritesh.i@gmail.com','9813566778',2),
('Aisha Khan','aisha.k@gmail.com','9914677889',4),
('Vikram Das','vikram.das@gmail.com','9812789988',1),
('Sanya Kapoor','sanya.k@gmail.com','9876501234',2),
('Harsh Agarwal','harsh.a@gmail.com','9823456789',1),
('Maya Dey','maya.d@gmail.com','9834567890',3),
('Nikhil Taneja','nikhil.t@gmail.com','9845678901',1),
('Diya Bhatt','diya.b@gmail.com','9856789012',4),
('Arjit Singh','arjit.s@gmail.com','9867890123',2),
('Neha Reddy','neha.r@gmail.com','9878901234',3),
('Kiran Das','kiran.d@gmail.com','9889012345',4),
('Rahul Nair','rahul.n@gmail.com','9890123456',2),
('Manish Kumar','manish.k@gmail.com','9891234567',1),
('Sneha Ghosh','sneha.g@gmail.com','9892345678',3),
('Ravi Chauhan','ravi.c@gmail.com','9893456789',4),
('Esha Sharma','esha.s@gmail.com','9894567890',2),
('Aman Malik','aman.m@gmail.com','9895678901',3),
('Tanya Sethi','tanya.s@gmail.com','9896789012',1),
('Rohit Jain','rohit.j@gmail.com','9897890123',2),
('Alisha Paul','alisha.p@gmail.com','9898901234',3),
('Yash Gupta','yash.g@gmail.com','9899012345',4),
('Ira Mehta','ira.m@gmail.com','9900123456',2),
('Kabir Singh','kabir.s@gmail.com','9901234567',1),
('Rhea Kapoor','rhea.k@gmail.com','9902345678',3),
('Vivan Bhatt','vivan.b@gmail.com','9903456789',2),
('Rehan Malik','rehan.m@gmail.com','9904567890',3),
('Anvi Joshi','anvi.j@gmail.com','9905678901',1),
('Karthik Iyer','karthik.i@gmail.com','9906789012',2),
('Sara Thomas','sara.t@gmail.com','9907890123',4),
('Krishna Rao','krishna.r@gmail.com','9908901234',3),
('Dia Kapoor','dia.k@gmail.com','9909012345',1),
('Tushar Bansal','tushar.b@gmail.com','9910123456',2),
('Aditi Sharma','aditi.s@gmail.com','9911234567',4),
('Raghav Menon','raghav.m@gmail.com','9912345678',3),
('Pari Yadav','pari.y@gmail.com','9913456789',2),
('Veer Chawla','veer.c@gmail.com','9914567890',1),
('Naina Kohli','naina.k@gmail.com','9915678901',3);


INSERT INTO locations (city, country, avg_rating, seasonal_rating, seasonal_demand) VALUES
('Delhi','India',4.2,4.0,75),
('Mumbai','India',4.1,3.9,68),
('Goa','India',4.7,4.6,90),
('Manali','India',4.6,4.8,85),
('Jaipur','India',4.4,4.3,72),
('Paris','France',4.9,4.7,95),
('London','UK',4.8,4.6,92),
('Dubai','UAE',4.5,4.4,88),
('Singapore','Singapore',4.7,4.5,90),
('Tokyo','Japan',4.8,4.7,93);


INSERT INTO flights (flight_no, origin_id, destination_id, departure_time, arrival_time, total_seats) VALUES
('AI101',1,6,'2025-11-20 08:00:00','2025-11-20 18:00:00',180),
('AI102',1,7,'2025-12-05 09:00:00','2025-12-05 17:00:00',150),
('AI103',2,3,'2025-12-10 06:00:00','2025-12-10 09:00:00',200),
('AI104',3,8,'2025-12-12 07:30:00','2025-12-12 11:30:00',220),
('AI105',1,4,'2025-12-15 09:45:00','2025-12-15 12:45:00',180),
('AI106',2,9,'2025-12-20 08:30:00','2025-12-20 13:00:00',160);


INSERT INTO flight_tiers (flight_id, tier_name, price, available_seats) VALUES
(1,'Economy',18000,150),
(1,'Business',42000,30),
(2,'Economy',22000,140),
(2,'First',60000,10),
(3,'Economy',9000,190),
(3,'Business',25000,10),
(4,'Economy',15000,200),
(5,'Economy',7000,160),
(5,'Business',18000,20),
(6,'Economy',20000,140),
(6,'First',52000,20);


INSERT INTO trains (train_no, origin_id, destination_id, departure_time, arrival_time, total_seats) VALUES
('TR1001',1,3,'2025-11-15 06:00:00','2025-11-15 12:00:00',600),
('TR1002',2,5,'2025-11-20 07:00:00','2025-11-20 11:00:00',500),
('TR1003',1,5,'2025-12-01 08:00:00','2025-12-01 14:00:00',700);


INSERT INTO train_tiers (train_id, coach_type, price, available_seats) VALUES
(1,'Sleeper',600,400),
(1,'AC 3-tier',900,150),
(1,'AC 2-tier',1300,50),
(2,'Sleeper',700,300),
(2,'AC 3-tier',1000,150),
(3,'AC 2-tier',1400,100),
(3,'Chair',800,300);


INSERT INTO buses (bus_no, origin_id, destination_id, departure_time, arrival_time, total_seats) VALUES
('BUS101',1,5,'2025-12-05 07:00:00','2025-12-05 14:00:00',50),
('BUS102',2,3,'2025-12-06 08:00:00','2025-12-06 15:00:00',45),
('BUS103',4,1,'2025-12-07 09:00:00','2025-12-07 18:00:00',40);


INSERT INTO bus_tiers (bus_id, category, price, available_seats) VALUES
(1,'AC',1200,40),
(1,'Non-AC',800,10),
(2,'Volvo',1600,35),
(3,'Luxury',2000,30);


INSERT INTO hotels (location_id, name, total_rooms) VALUES
(3,'Goa Paradise Resort',80),
(4,'Snow Valley Inn',60),
(5,'Royal Heritage Jaipur',100),
(6,'Eiffel Stay Paris',120),
(7,'London Central Hotel',90),
(9,'Marina Bay View',110);


INSERT INTO hotel_tiers (hotel_id, room_type, price_per_night, available_rooms) VALUES
(1,'Standard',3000,40),
(1,'Deluxe',5000,30),
(2,'Standard',2500,30),
(2,'Suite',6000,10),
(3,'Standard',3500,60),
(4,'Deluxe',9000,70),
(4,'Suite',15000,30),
(5,'Deluxe',10000,60),
(6,'Standard',7000,80);


INSERT INTO activities (location_id, name, category, price, capacity, available_slots, duration_hrs) VALUES
(3,'Beach Jet Ski','Adventure',1200,50,30,2),
(3,'Parasailing','Adventure',1500,40,25,2),
(4,'Trekking Solang','Nature',800,60,50,4),
(5,'Amber Fort Tour','Cultural',600,100,80,3),
(6,'Eiffel Tower Visit','Leisure',2000,200,150,2),
(7,'London Eye Ride','Leisure',1800,180,120,2),
(9,'Night Safari','Adventure',2500,80,50,3);


INSERT INTO packages (name, description, base_price, duration_days, popularity_score, rating) VALUES
('Goa Beach Escape','3 nights stay in Goa with water activities',15000,4,8.9,4.6),
('Paris Dream Trip','5 days in Paris including Eiffel Tower visit',75000,5,9.5,4.8),
('Manali Snow Trek','Adventure trip to Solang Valley',12000,3,8.0,4.5),
('Jaipur Heritage Tour','Cultural tour across royal forts',10000,3,7.5,4.3);


INSERT INTO package_details (package_id, service_type, service_ref_id) VALUES
(1,'Flight',3),
(1,'Hotel',1),
(1,'Activity',1),
(2,'Flight',1),
(2,'Hotel',4),
(2,'Activity',5),
(3,'Train',1),
(3,'Hotel',2),
(3,'Activity',3),
(4,'Train',3),
(4,'Hotel',3),
(4,'Activity',4);


INSERT INTO seasonal_data (location_id, season, avg_booking_price, booking_count, seasonal_rating) VALUES
(3,'Summer',14500,320,4.7),
(3,'Winter',12000,280,4.5),
(4,'Winter',12500,300,4.8),
(5,'Spring',10000,180,4.4),
(6,'Summer',70000,500,4.9),
(7,'Winter',68000,450,4.8),
(9,'Monsoon',20000,250,4.6);
