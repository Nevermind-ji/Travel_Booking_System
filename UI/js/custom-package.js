// Custom package builder functionality

let packageItems = JSON.parse(localStorage.getItem('tempPackage') || '[]');

// Load package items on page load
document.addEventListener('DOMContentLoaded', function() {
    renderPackageItems();
});

// Switch tabs
function switchTab(tabName, buttonElement) {
    // Hide all tabs
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });

    // Show selected tab
    document.getElementById(tabName + 'Tab').classList.add('active');
    if (buttonElement) {
        buttonElement.classList.add('active');
    }
}

// Add to package
function addToPackage(event, serviceType) {
    event.preventDefault();
    const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
    
    if (!user.userId) {
        alert('Please login first');
        window.location.href = 'index.html';
        return;
    }

    // Mock data - in real app, this would search actual services
    let serviceData = {};
    let price = 0;
    let tier = 'Standard';
    let description = '';

    switch(serviceType) {
        case 'Flight':
            const origin = document.getElementById('customFlightOrigin').value;
            const dest = document.getElementById('customFlightDestination').value;
            price = 5000;
            tier = 'Economy';
            description = `Flight: ${origin} to ${dest}`;
            break;
        case 'Train':
            const trainOrigin = document.getElementById('customTrainOrigin').value;
            const trainDest = document.getElementById('customTrainDestination').value;
            price = 1000;
            tier = 'AC 3-tier';
            description = `Train: ${trainOrigin} to ${trainDest}`;
            break;
        case 'Bus':
            const busOrigin = document.getElementById('customBusOrigin').value;
            const busDest = document.getElementById('customBusDestination').value;
            price = 500;
            tier = 'AC';
            description = `Bus: ${busOrigin} to ${busDest}`;
            break;
        case 'Hotel':
            const hotelLoc = document.getElementById('customHotelLocation').value;
            price = 2000;
            tier = 'Standard';
            description = `Hotel in ${hotelLoc}`;
            break;
        case 'Activity':
            const activityLoc = document.getElementById('customActivityLocation').value;
            price = 1000;
            tier = 'Standard';
            description = `Activity in ${activityLoc}`;
            break;
    }

    const item = {
        id: Date.now(),
        serviceType: serviceType,
        serviceId: Math.floor(Math.random() * 100),
        tierId: 1,
        tier: tier,
        price: price,
        description: description,
        qty: 1
    };

    packageItems.push(item);
    localStorage.setItem('tempPackage', JSON.stringify(packageItems));
    
    renderPackageItems();
    
    // Reset form
    event.target.reset();
    
    alert(`${serviceType} added to package!`);
}

// Render package items
function renderPackageItems() {
    const packageItemsDiv = document.getElementById('packageItems');
    const bookBtn = document.getElementById('bookPackageBtn');
    
    if (packageItems.length === 0) {
        packageItemsDiv.innerHTML = '<p class="empty-message">No items added yet. Start building your package!</p>';
        bookBtn.disabled = true;
        document.getElementById('packageTotal').textContent = '₹0';
        return;
    }

    const total = packageItems.reduce((sum, item) => sum + (item.price * item.qty), 0);

    packageItemsDiv.innerHTML = packageItems.map((item, index) => `
        <div class="package-item">
            <div class="package-item-info">
                <strong>${item.serviceType}</strong> - ${item.description}
                <br>
                <small>${item.tier} - ₹${item.price} x ${item.qty}</small>
            </div>
            <div style="display: flex; align-items: center; gap: 10px;">
                <div class="package-item-price">₹${(item.price * item.qty).toLocaleString()}</div>
                <button class="package-item-remove" onclick="removePackageItem(${index})">Remove</button>
            </div>
        </div>
    `).join('');

    document.getElementById('packageTotal').textContent = `₹${total.toLocaleString()}`;
    bookBtn.disabled = false;
}

// Remove package item
function removePackageItem(index) {
    packageItems.splice(index, 1);
    localStorage.setItem('tempPackage', JSON.stringify(packageItems));
    renderPackageItems();
}

// Book custom package
function bookCustomPackage() {
    const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
    
    if (!user.userId) {
        alert('Please login first');
        window.location.href = 'index.html';
        return;
    }

    if (packageItems.length === 0) {
        alert('Please add items to your package first');
        return;
    }

    const baseTotal = packageItems.reduce((sum, item) => sum + (item.price * item.qty), 0);
    
    // Calculate discount
    let discount = 0;
    if (user.membership) {
        discount = user.membership.discount || 0;
    }
    const discountAmount = (baseTotal * discount) / 100;
    const finalTotal = baseTotal - discountAmount;

    const bookingData = {
        bookingId: Date.now(),
        userId: user.userId,
        serviceType: 'Package',
        packageItems: packageItems,
        price: baseTotal,
        basePrice: baseTotal,
        discount: discount,
        discountAmount: discountAmount,
        total: finalTotal,
        isCustomPackage: true
    };

    // Show payment modal
    showPaymentModal(bookingData, function(payment, bookingData) {
        // Create bookings for each item
        const bookings = JSON.parse(localStorage.getItem('bookings') || '[]');
        
        bookingData.packageItems.forEach(item => {
            const booking = {
                bookingId: Date.now() + Math.random(),
                userId: user.userId,
                serviceType: item.serviceType,
                serviceId: item.serviceId,
                tier: item.tier,
                price: item.price * item.qty,
                basePrice: item.price * item.qty,
                discount: discount,
                discountAmount: (item.price * item.qty * discount) / 100,
                totalCost: (item.price * item.qty) - ((item.price * item.qty * discount) / 100),
                bookingDate: new Date().toISOString(),
                status: 'Confirmed',
                ticketNumber: 'CUST' + Date.now() + Math.random(),
                isCustomPackage: true,
                paymentId: payment.paymentId
            };
            bookings.push(booking);
        });

        localStorage.setItem('bookings', JSON.stringify(bookings));
        
        // Clear temp package
        packageItems = [];
        localStorage.removeItem('tempPackage');
        
        alert(`Custom package booked successfully! Total: ₹${finalTotal.toLocaleString()}`);
        window.location.href = 'my-bookings.html';
    });
}

