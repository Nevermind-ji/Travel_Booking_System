// Booking functionality for flights, trains, buses, hotels, activities

// Mock data for services
const mockFlights = [
    { id: 1, flightNo: 'AI101', origin: 'Mumbai', destination: 'Delhi', departure: '2024-12-15 10:00', arrival: '2024-12-15 12:00', economy: 5000, business: 15000, first: 25000, rating: 4.5 },
    { id: 2, flightNo: 'SG202', origin: 'Bangalore', destination: 'Mumbai', departure: '2024-12-15 14:00', arrival: '2024-12-15 15:30', economy: 4000, business: 12000, first: 20000, rating: 4.2 }
];

const mockTrains = [
    { id: 1, trainNo: '12345', origin: 'Mumbai', destination: 'Delhi', departure: '2024-12-15 20:00', arrival: '2024-12-16 10:00', sleeper: 800, ac3: 1500, ac2: 2500, chair: 600, rating: 4.3 },
    { id: 2, trainNo: '67890', origin: 'Bangalore', destination: 'Chennai', departure: '2024-12-15 18:00', arrival: '2024-12-16 06:00', sleeper: 600, ac3: 1200, ac2: 2000, chair: 500, rating: 4.0 }
];

const mockBuses = [
    { id: 1, busNo: 'B101', origin: 'Mumbai', destination: 'Pune', departure: '2024-12-15 08:00', arrival: '2024-12-15 12:00', ac: 500, nonac: 300, volvo: 800, luxury: 1200, rating: 4.1 },
    { id: 2, busNo: 'B202', origin: 'Delhi', destination: 'Jaipur', departure: '2024-12-15 09:00', arrival: '2024-12-15 14:00', ac: 600, nonac: 350, volvo: 900, luxury: 1400, rating: 4.4 }
];

const mockHotels = [
    { id: 1, name: 'Grand Hotel', location: 'Mumbai', standard: 2000, deluxe: 3500, suite: 6000, rating: 4.5 },
    { id: 2, name: 'Luxury Resort', location: 'Goa', standard: 3000, deluxe: 5000, suite: 9000, rating: 4.7 }
];

const mockActivities = [
    { id: 1, name: 'Water Sports', location: 'Goa', category: 'Adventure', price: 1500, duration: 3, rating: 4.6 },
    { id: 2, name: 'Heritage Walk', location: 'Delhi', category: 'Cultural', price: 800, duration: 2, rating: 4.3 },
    { id: 3, name: 'Trekking', location: 'Mumbai', category: 'Nature', price: 2000, duration: 5, rating: 4.8 }
];

// Search flights
function searchFlights(event) {
    event.preventDefault();
    const origin = document.getElementById('flightOrigin').value;
    const destination = document.getElementById('flightDestination').value;
    
    const results = mockFlights.filter(f => 
        f.origin.toLowerCase().includes(origin.toLowerCase()) &&
        f.destination.toLowerCase().includes(destination.toLowerCase())
    );
    
    displayFlightResults(results);
}

function displayFlightResults(flights) {
    const resultsDiv = document.getElementById('flightResults');
    if (flights.length === 0) {
        resultsDiv.innerHTML = '<p class="empty-message">No flights found. Try different search criteria.</p>';
        return;
    }

    resultsDiv.innerHTML = flights.map(flight => `
        <div class="result-card">
            <div class="result-header">
                <div class="result-title">${flight.flightNo}</div>
                <div class="rating">⭐ ${flight.rating}</div>
            </div>
            <div class="result-details">
                <div class="result-detail-item">
                    <strong>From:</strong> ${flight.origin}
                </div>
                <div class="result-detail-item">
                    <strong>To:</strong> ${flight.destination}
                </div>
                <div class="result-detail-item">
                    <strong>Departure:</strong> ${flight.departure}
                </div>
                <div class="result-detail-item">
                    <strong>Arrival:</strong> ${flight.arrival}
                </div>
            </div>
            <div style="margin-top: 15px;">
                <h4>Select Tier:</h4>
                <div style="display: flex; gap: 10px; margin-top: 10px;">
                    <button class="btn btn-primary" onclick="bookService(${flight.id}, 'Flight', 'Economy', ${flight.economy})">
                        Economy - ₹${flight.economy}
                    </button>
                    <button class="btn btn-primary" onclick="bookService(${flight.id}, 'Flight', 'Business', ${flight.business})">
                        Business - ₹${flight.business}
                    </button>
                    <button class="btn btn-primary" onclick="bookService(${flight.id}, 'Flight', 'First', ${flight.first})">
                        First - ₹${flight.first}
                    </button>
                </div>
            </div>
        </div>
    `).join('');
}

// Search trains
function searchTrains(event) {
    event.preventDefault();
    const origin = document.getElementById('trainOrigin').value;
    const destination = document.getElementById('trainDestination').value;
    
    const results = mockTrains.filter(t => 
        t.origin.toLowerCase().includes(origin.toLowerCase()) &&
        t.destination.toLowerCase().includes(destination.toLowerCase())
    );
    
    displayTrainResults(results);
}

function displayTrainResults(trains) {
    const resultsDiv = document.getElementById('trainResults');
    if (trains.length === 0) {
        resultsDiv.innerHTML = '<p class="empty-message">No trains found. Try different search criteria.</p>';
        return;
    }

    resultsDiv.innerHTML = trains.map(train => `
        <div class="result-card">
            <div class="result-header">
                <div class="result-title">${train.trainNo}</div>
                <div class="rating">⭐ ${train.rating}</div>
            </div>
            <div class="result-details">
                <div class="result-detail-item">
                    <strong>From:</strong> ${train.origin}
                </div>
                <div class="result-detail-item">
                    <strong>To:</strong> ${train.destination}
                </div>
                <div class="result-detail-item">
                    <strong>Departure:</strong> ${train.departure}
                </div>
                <div class="result-detail-item">
                    <strong>Arrival:</strong> ${train.arrival}
                </div>
            </div>
            <div style="margin-top: 15px;">
                <h4>Select Coach Type:</h4>
                <div style="display: flex; gap: 10px; margin-top: 10px; flex-wrap: wrap;">
                    <button class="btn btn-primary" onclick="bookService(${train.id}, 'Train', 'Sleeper', ${train.sleeper})">
                        Sleeper - ₹${train.sleeper}
                    </button>
                    <button class="btn btn-primary" onclick="bookService(${train.id}, 'Train', 'AC 3-tier', ${train.ac3})">
                        AC 3-tier - ₹${train.ac3}
                    </button>
                    <button class="btn btn-primary" onclick="bookService(${train.id}, 'Train', 'AC 2-tier', ${train.ac2})">
                        AC 2-tier - ₹${train.ac2}
                    </button>
                    <button class="btn btn-primary" onclick="bookService(${train.id}, 'Train', 'Chair', ${train.chair})">
                        Chair - ₹${train.chair}
                    </button>
                </div>
            </div>
        </div>
    `).join('');
}

// Search buses
function searchBuses(event) {
    event.preventDefault();
    const origin = document.getElementById('busOrigin').value;
    const destination = document.getElementById('busDestination').value;
    
    const results = mockBuses.filter(b => 
        b.origin.toLowerCase().includes(origin.toLowerCase()) &&
        b.destination.toLowerCase().includes(destination.toLowerCase())
    );
    
    displayBusResults(results);
}

function displayBusResults(buses) {
    const resultsDiv = document.getElementById('busResults');
    if (buses.length === 0) {
        resultsDiv.innerHTML = '<p class="empty-message">No buses found. Try different search criteria.</p>';
        return;
    }

    resultsDiv.innerHTML = buses.map(bus => `
        <div class="result-card">
            <div class="result-header">
                <div class="result-title">${bus.busNo}</div>
                <div class="rating">⭐ ${bus.rating}</div>
            </div>
            <div class="result-details">
                <div class="result-detail-item">
                    <strong>From:</strong> ${bus.origin}
                </div>
                <div class="result-detail-item">
                    <strong>To:</strong> ${bus.destination}
                </div>
                <div class="result-detail-item">
                    <strong>Departure:</strong> ${bus.departure}
                </div>
                <div class="result-detail-item">
                    <strong>Arrival:</strong> ${bus.arrival}
                </div>
            </div>
            <div style="margin-top: 15px;">
                <h4>Select Category:</h4>
                <div style="display: flex; gap: 10px; margin-top: 10px; flex-wrap: wrap;">
                    <button class="btn btn-primary" onclick="bookService(${bus.id}, 'Bus', 'AC', ${bus.ac})">
                        AC - ₹${bus.ac}
                    </button>
                    <button class="btn btn-primary" onclick="bookService(${bus.id}, 'Bus', 'Non-AC', ${bus.nonac})">
                        Non-AC - ₹${bus.nonac}
                    </button>
                    <button class="btn btn-primary" onclick="bookService(${bus.id}, 'Bus', 'Volvo', ${bus.volvo})">
                        Volvo - ₹${bus.volvo}
                    </button>
                    <button class="btn btn-primary" onclick="bookService(${bus.id}, 'Bus', 'Luxury', ${bus.luxury})">
                        Luxury - ₹${bus.luxury}
                    </button>
                </div>
            </div>
        </div>
    `).join('');
}

// Search hotels
function searchHotels(event) {
    event.preventDefault();
    const location = document.getElementById('hotelLocation').value;
    
    const results = mockHotels.filter(h => 
        h.location.toLowerCase().includes(location.toLowerCase())
    );
    
    displayHotelResults(results);
}

function displayHotelResults(hotels) {
    const resultsDiv = document.getElementById('hotelResults');
    if (hotels.length === 0) {
        resultsDiv.innerHTML = '<p class="empty-message">No hotels found. Try different search criteria.</p>';
        return;
    }

    resultsDiv.innerHTML = hotels.map(hotel => `
        <div class="result-card">
            <div class="result-header">
                <div class="result-title">${hotel.name}</div>
                <div class="rating">⭐ ${hotel.rating}</div>
            </div>
            <div class="result-details">
                <div class="result-detail-item">
                    <strong>Location:</strong> ${hotel.location}
                </div>
            </div>
            <div style="margin-top: 15px;">
                <h4>Select Room Type:</h4>
                <div style="display: flex; gap: 10px; margin-top: 10px; flex-wrap: wrap;">
                    <button class="btn btn-primary" onclick="bookService(${hotel.id}, 'Hotel', 'Standard', ${hotel.standard})">
                        Standard - ₹${hotel.standard}/night
                    </button>
                    <button class="btn btn-primary" onclick="bookService(${hotel.id}, 'Hotel', 'Deluxe', ${hotel.deluxe})">
                        Deluxe - ₹${hotel.deluxe}/night
                    </button>
                    <button class="btn btn-primary" onclick="bookService(${hotel.id}, 'Hotel', 'Suite', ${hotel.suite})">
                        Suite - ₹${hotel.suite}/night
                    </button>
                </div>
            </div>
        </div>
    `).join('');
}

// Search activities
function searchActivities(event) {
    event.preventDefault();
    const location = document.getElementById('activityLocation').value;
    const category = document.getElementById('activityCategory').value;
    
    let results = mockActivities.filter(a => 
        a.location.toLowerCase().includes(location.toLowerCase())
    );
    
    if (category) {
        results = results.filter(a => a.category === category);
    }
    
    displayActivityResults(results);
}

function displayActivityResults(activities) {
    const resultsDiv = document.getElementById('activityResults');
    if (activities.length === 0) {
        resultsDiv.innerHTML = '<p class="empty-message">No activities found. Try different search criteria.</p>';
        return;
    }

    resultsDiv.innerHTML = activities.map(activity => `
        <div class="result-card">
            <div class="result-header">
                <div class="result-title">${activity.name}</div>
                <div class="rating">⭐ ${activity.rating}</div>
            </div>
            <div class="result-details">
                <div class="result-detail-item">
                    <strong>Location:</strong> ${activity.location}
                </div>
                <div class="result-detail-item">
                    <strong>Category:</strong> ${activity.category}
                </div>
                <div class="result-detail-item">
                    <strong>Duration:</strong> ${activity.duration} hours
                </div>
                <div class="result-detail-item">
                    <strong>Price:</strong> ₹${activity.price}
                </div>
            </div>
            <div style="margin-top: 15px;">
                <button class="btn btn-primary" onclick="bookService(${activity.id}, 'Activity', 'Standard', ${activity.price})">
                    Book Activity - ₹${activity.price}
                </button>
            </div>
        </div>
    `).join('');
}

// Book service
function bookService(serviceId, serviceType, tier, price) {
    const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
    if (!user.userId) {
        alert('Please login first');
        window.location.href = 'index.html';
        return;
    }

    const booking = {
        bookingId: Date.now(),
        userId: user.userId,
        serviceType: serviceType,
        serviceId: serviceId,
        tier: tier,
        price: price,
        bookingDate: new Date().toISOString(),
        status: 'Confirmed',
        ticketNumber: 'TKT' + Date.now()
    };

    const bookings = JSON.parse(localStorage.getItem('bookings') || '[]');
    bookings.push(booking);
    localStorage.setItem('bookings', JSON.stringify(bookings));

    alert(`Booking confirmed! Ticket Number: ${booking.ticketNumber}`);
    window.location.href = 'my-bookings.html';
}

