// My Bookings functionality

let currentFilter = 'all';

// Load bookings on page load
document.addEventListener('DOMContentLoaded', function() {
    loadBookings();
});

// Load bookings
function loadBookings() {
    const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
    if (!user.userId) {
        window.location.href = 'index.html';
        return;
    }

    const bookings = JSON.parse(localStorage.getItem('bookings') || '[]');
    const userBookings = bookings.filter(b => b.userId === user.userId);
    
    renderBookings(userBookings);
}

// Filter bookings
function filterBookings(filter) {
    currentFilter = filter;
    
    // Update filter buttons
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');

    const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
    const bookings = JSON.parse(localStorage.getItem('bookings') || '[]');
    let userBookings = bookings.filter(b => b.userId === user.userId);

    if (filter !== 'all') {
        userBookings = userBookings.filter(b => 
            b.status.toLowerCase() === filter.toLowerCase()
        );
    }

    renderBookings(userBookings);
}

// Render bookings
function renderBookings(bookings) {
    const bookingsList = document.getElementById('bookingsList');

    if (bookings.length === 0) {
        bookingsList.innerHTML = '<p class="empty-message">No bookings found.</p>';
        return;
    }

    // Sort by booking date (newest first)
    bookings.sort((a, b) => new Date(b.bookingDate) - new Date(a.bookingDate));

    bookingsList.innerHTML = bookings.map(booking => {
        const bookingDate = new Date(booking.bookingDate).toLocaleDateString();
        const statusClass = booking.status.toLowerCase();

        return `
            <div class="booking-card">
                <div class="booking-header">
                    <div>
                        <div class="booking-id">Ticket #${booking.ticketNumber}</div>
                        <div style="color: #666; font-size: 0.9rem; margin-top: 5px;">
                            Booked on: ${bookingDate}
                        </div>
                    </div>
                    <div class="booking-status ${statusClass}">${booking.status}</div>
                </div>
                <div class="result-details">
                    <div class="result-detail-item">
                        <strong>Service Type:</strong> ${booking.serviceType}
                    </div>
                    ${booking.packageName ? `
                        <div class="result-detail-item">
                            <strong>Package:</strong> ${booking.packageName}
                        </div>
                    ` : ''}
                    ${booking.tier ? `
                        <div class="result-detail-item">
                            <strong>Tier/Category:</strong> ${booking.tier}
                        </div>
                    ` : ''}
                    <div class="result-detail-item">
                        <strong>Total Cost:</strong> ₹${(booking.totalCost || booking.price).toLocaleString()}
                        ${booking.discount && booking.discount > 0 ? `
                            <span style="color: #28a745; font-size: 0.85rem; margin-left: 10px;">
                                (${booking.discount}% discount applied)
                            </span>
                        ` : ''}
                    </div>
                    ${booking.isCustomPackage ? `
                        <div class="result-detail-item">
                            <strong>Type:</strong> Custom Package
                        </div>
                    ` : ''}
                </div>
                <div style="margin-top: 15px; display: flex; gap: 10px;">
                    ${booking.status === 'Confirmed' ? `
                        <button class="btn btn-secondary" onclick="cancelBooking('${booking.ticketNumber}')">
                            Cancel Booking
                        </button>
                    ` : ''}
                    <button class="btn btn-primary" onclick="viewBookingDetails('${booking.ticketNumber}')">
                        View Details
                    </button>
                </div>
            </div>
        `;
    }).join('');
}

// Cancel booking
function cancelBooking(ticketNumber) {
    if (!confirm('Are you sure you want to cancel this booking?')) {
        return;
    }

    const bookings = JSON.parse(localStorage.getItem('bookings') || '[]');
    const booking = bookings.find(b => b.ticketNumber === ticketNumber);
    
    if (booking) {
        booking.status = 'Cancelled';
        localStorage.setItem('bookings', JSON.stringify(bookings));
        loadBookings();
        alert('Booking cancelled successfully');
    }
}

// View booking details
function viewBookingDetails(ticketNumber) {
    const bookings = JSON.parse(localStorage.getItem('bookings') || '[]');
    const booking = bookings.find(b => b.ticketNumber === ticketNumber);
    
    if (booking) {
        const details = `
Ticket Number: ${booking.ticketNumber}
Service Type: ${booking.serviceType}
Status: ${booking.status}
Total Cost: ₹${booking.price.toLocaleString()}
Booking Date: ${new Date(booking.bookingDate).toLocaleString()}
${booking.tier ? `Tier/Category: ${booking.tier}` : ''}
${booking.packageName ? `Package: ${booking.packageName}` : ''}
        `;
        alert(details);
    }
}

