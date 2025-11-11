// Payment processing functionality

// Show payment modal
function showPaymentModal(bookingData, callback) {
    const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
    const basePrice = bookingData.price || bookingData.total || 0;
    
    // Calculate discount based on membership
    let discount = 0;
    let discountAmount = 0;
    if (user.membership) {
        discount = user.membership.discount || 0;
        discountAmount = (basePrice * discount) / 100;
    }
    
    const finalPrice = basePrice - discountAmount;
    
    // Create payment modal HTML
    const modalHTML = `
        <div id="paymentModal" class="modal" style="display: block;">
            <div class="modal-content" style="max-width: 600px;">
                <span class="close" onclick="closePaymentModal()">&times;</span>
                <h2>Complete Payment</h2>
                
                <div class="payment-summary">
                    <div class="summary-row">
                        <span>Base Price:</span>
                        <span>₹${basePrice.toLocaleString()}</span>
                    </div>
                    ${discount > 0 ? `
                        <div class="summary-row">
                            <span>
                                Membership Discount (${discount}%)
                                <span class="discount-badge">${user.membership.name}</span>
                            </span>
                            <span style="color: #28a745;">-₹${discountAmount.toLocaleString()}</span>
                        </div>
                    ` : ''}
                    <div class="summary-row">
                        <span><strong>Total Amount:</strong></span>
                        <span><strong>₹${finalPrice.toLocaleString()}</strong></span>
                    </div>
                </div>
                
                <form id="paymentForm" onsubmit="processPayment(event, ${finalPrice})">
                    <div class="form-group">
                        <label>Select Payment Method</label>
                        <div class="payment-methods">
                            <div class="payment-method" onclick="selectPaymentMethod('Card', this)">
                                <div class="payment-method-icon">💳</div>
                                <div>Card</div>
                            </div>
                            <div class="payment-method" onclick="selectPaymentMethod('UPI', this)">
                                <div class="payment-method-icon">📱</div>
                                <div>UPI</div>
                            </div>
                            <div class="payment-method" onclick="selectPaymentMethod('NetBanking', this)">
                                <div class="payment-method-icon">🏦</div>
                                <div>Net Banking</div>
                            </div>
                            <div class="payment-method" onclick="selectPaymentMethod('Wallet', this)">
                                <div class="payment-method-icon">👛</div>
                                <div>Wallet</div>
                            </div>
                            <div class="payment-method" onclick="selectPaymentMethod('Cash', this)">
                                <div class="payment-method-icon">💵</div>
                                <div>Cash</div>
                            </div>
                        </div>
                        <input type="hidden" id="selectedPaymentMethod" required>
                    </div>
                    
                    <div id="paymentDetails" style="display: none;">
                        <div class="form-group">
                            <label id="paymentMethodLabel">Payment Details</label>
                            <input type="text" id="paymentDetailsInput" placeholder="Enter details" required>
                        </div>
                    </div>
                    
                    <button type="submit" class="btn btn-primary btn-block">Pay ₹${finalPrice.toLocaleString()}</button>
                </form>
            </div>
        </div>
    `;
    
    // Remove existing payment modal if any
    const existingModal = document.getElementById('paymentModal');
    if (existingModal) {
        existingModal.remove();
    }
    
    // Add modal to body
    document.body.insertAdjacentHTML('beforeend', modalHTML);
    
    // Store callback and booking data
    window.paymentCallback = callback;
    window.currentBookingData = bookingData;
}

// Select payment method
function selectPaymentMethod(method, element) {
    // Remove selected class from all methods
    document.querySelectorAll('.payment-method').forEach(el => {
        el.classList.remove('selected');
    });
    
    // Add selected class to clicked method
    element.classList.add('selected');
    document.getElementById('selectedPaymentMethod').value = method;
    
    // Show payment details input
    const detailsDiv = document.getElementById('paymentDetails');
    const detailsInput = document.getElementById('paymentDetailsInput');
    const label = document.getElementById('paymentMethodLabel');
    
    detailsDiv.style.display = 'block';
    
    switch(method) {
        case 'Card':
            label.textContent = 'Card Number';
            detailsInput.placeholder = 'Enter 16-digit card number';
            detailsInput.type = 'text';
            detailsInput.pattern = '[0-9]{16}';
            break;
        case 'UPI':
            label.textContent = 'UPI ID';
            detailsInput.placeholder = 'Enter UPI ID (e.g., user@paytm)';
            detailsInput.type = 'text';
            break;
        case 'NetBanking':
            label.textContent = 'Account Number';
            detailsInput.placeholder = 'Enter account number';
            detailsInput.type = 'text';
            break;
        case 'Wallet':
            label.textContent = 'Wallet Number';
            detailsInput.placeholder = 'Enter wallet number';
            detailsInput.type = 'text';
            break;
        case 'Cash':
            label.textContent = 'Cash Payment Confirmation';
            detailsInput.placeholder = 'Enter confirmation code';
            detailsInput.type = 'text';
            break;
    }
}

// Process payment
function processPayment(event, finalPrice) {
    event.preventDefault();
    
    const paymentMethod = document.getElementById('selectedPaymentMethod').value;
    const paymentDetails = document.getElementById('paymentDetailsInput').value;
    const bookingData = window.currentBookingData;
    
    if (!paymentMethod) {
        alert('Please select a payment method');
        return;
    }
    
    if (!paymentDetails) {
        alert('Please enter payment details');
        return;
    }
    
    const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
    
    // Create payment record
    const payment = {
        paymentId: Date.now(),
        payerUserId: user.userId,
        amount: finalPrice,
        method: paymentMethod,
        paymentDate: new Date().toISOString(),
        status: 'Paid',
        paymentDetails: paymentDetails
    };
    
    // Store payment
    const payments = JSON.parse(localStorage.getItem('payments') || '[]');
    payments.push(payment);
    localStorage.setItem('payments', JSON.stringify(payments));
    
    // Update booking with payment
    if (bookingData && bookingData.bookingId) {
        const bookings = JSON.parse(localStorage.getItem('bookings') || '[]');
        const booking = bookings.find(b => b.bookingId === bookingData.bookingId);
        if (booking) {
            booking.paymentId = payment.paymentId;
            booking.totalCost = finalPrice;
            localStorage.setItem('bookings', JSON.stringify(bookings));
        }
    }
    
    // Close modal
    closePaymentModal();
    
    // Show success message
    alert(`Payment successful! Payment ID: ${payment.paymentId}`);
    
    // Call callback if provided
    if (window.paymentCallback && typeof window.paymentCallback === 'function') {
        window.paymentCallback(payment, bookingData);
    }
}

// Close payment modal
function closePaymentModal() {
    const modal = document.getElementById('paymentModal');
    if (modal) {
        modal.remove();
    }
    window.paymentCallback = null;
    window.currentBookingData = null;
}

// Close modal when clicking outside
document.addEventListener('click', function(event) {
    const modal = document.getElementById('paymentModal');
    if (modal && event.target === modal) {
        closePaymentModal();
    }
});

