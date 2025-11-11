// Packages functionality

const mockPackages = [
    {
        id: 1,
        name: 'Mumbai - Goa Adventure',
        description: 'Complete package with flight, hotel, and water sports activities',
        basePrice: 25000,
        duration: 5,
        popularity: 4.8,
        rating: 4.6,
        includes: ['Flight', 'Hotel', 'Activities']
    },
    {
        id: 2,
        name: 'Delhi Heritage Tour',
        description: 'Explore the rich heritage of Delhi with guided tours and luxury stay',
        basePrice: 18000,
        duration: 3,
        popularity: 4.5,
        rating: 4.4,
        includes: ['Train', 'Hotel', 'Activities']
    },
    {
        id: 3,
        name: 'Bangalore Nature Escape',
        description: 'Relaxing nature retreat with trekking and eco-friendly accommodation',
        basePrice: 15000,
        duration: 4,
        popularity: 4.3,
        rating: 4.5,
        includes: ['Bus', 'Hotel', 'Activities']
    },
    {
        id: 4,
        name: 'Kerala Backwaters',
        description: 'Experience the serene backwaters with houseboat stay and cultural activities',
        basePrice: 22000,
        duration: 6,
        popularity: 4.9,
        rating: 4.7,
        includes: ['Train', 'Hotel', 'Activities']
    }
];

// Load packages on page load
document.addEventListener('DOMContentLoaded', function() {
    displayPackages(mockPackages);
});

// Search packages
function searchPackages(event) {
    event.preventDefault();
    const budget = parseFloat(document.getElementById('packageBudget').value) || Infinity;
    const duration = parseInt(document.getElementById('packageDuration').value) || 0;
    const sortBy = document.getElementById('packageSort').value;

    let filtered = mockPackages.filter(p => {
        if (p.basePrice > budget) return false;
        if (duration > 0 && p.duration !== duration) return false;
        return true;
    });

    // Sort packages
    switch(sortBy) {
        case 'popularity':
            filtered.sort((a, b) => b.popularity - a.popularity);
            break;
        case 'rating':
            filtered.sort((a, b) => b.rating - a.rating);
            break;
        case 'price_low':
            filtered.sort((a, b) => a.basePrice - b.basePrice);
            break;
        case 'price_high':
            filtered.sort((a, b) => b.basePrice - a.basePrice);
            break;
    }

    displayPackages(filtered);
}

// Display packages
function displayPackages(packages) {
    const packagesList = document.getElementById('packagesList');
    
    if (packages.length === 0) {
        packagesList.innerHTML = '<p class="empty-message">No packages found matching your criteria.</p>';
        return;
    }

    packagesList.innerHTML = packages.map(pkg => `
        <div class="package-card">
            <div class="package-image">📦</div>
            <div class="package-content">
                <div class="package-name">${pkg.name}</div>
                <div class="package-description">${pkg.description}</div>
                <div class="result-details">
                    <div class="result-detail-item">
                        <strong>Duration:</strong> ${pkg.duration} days
                    </div>
                    <div class="result-detail-item">
                        <strong>Rating:</strong> ⭐ ${pkg.rating}
                    </div>
                    <div class="result-detail-item">
                        <strong>Includes:</strong> ${pkg.includes.join(', ')}
                    </div>
                </div>
                <div class="package-footer">
                    <div class="result-price">₹${pkg.basePrice.toLocaleString()}</div>
                    <button class="btn btn-primary" onclick="bookPackage(${pkg.id}, ${pkg.basePrice})">
                        Book Now
                    </button>
                </div>
            </div>
        </div>
    `).join('');
}

// Book package
function bookPackage(packageId, price) {
    const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
    if (!user.userId) {
        alert('Please login first');
        window.location.href = 'index.html';
        return;
    }

    const pkg = mockPackages.find(p => p.id === packageId);
    if (!pkg) {
        alert('Package not found');
        return;
    }

    // Calculate discount
    let discount = 0;
    if (user.membership) {
        discount = user.membership.discount || 0;
    }
    const discountAmount = (price * discount) / 100;
    const finalPrice = price - discountAmount;

    const booking = {
        bookingId: Date.now(),
        userId: user.userId,
        packageId: packageId,
        serviceType: 'Package',
        serviceId: packageId,
        price: price,
        basePrice: price,
        discount: discount,
        discountAmount: discountAmount,
        totalCost: finalPrice,
        bookingDate: new Date().toISOString(),
        status: 'Pending Payment',
        ticketNumber: 'PKG' + Date.now(),
        packageName: pkg.name
    };

    // Show payment modal
    showPaymentModal(booking, function(payment, bookingData) {
        // Update booking status after payment
        booking.status = 'Confirmed';
        booking.paymentId = payment.paymentId;
        
        const bookings = JSON.parse(localStorage.getItem('bookings') || '[]');
        bookings.push(booking);
        localStorage.setItem('bookings', JSON.stringify(bookings));

        alert(`Package booked successfully! Ticket Number: ${booking.ticketNumber}`);
        window.location.href = 'my-bookings.html';
    });
}

