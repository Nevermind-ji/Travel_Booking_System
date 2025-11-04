// Authentication handling

// Check if user is logged in
function checkAuth() {
    const user = localStorage.getItem('currentUser');
    const currentPath = window.location.pathname;
    if (!user && !currentPath.includes('index.html')) {
        window.location.href = 'index.html';
    }
    return user ? JSON.parse(user) : null;
}

// Show login modal
function showLogin() {
    document.getElementById('loginModal').style.display = 'block';
    document.getElementById('signupModal').style.display = 'none';
}

// Show signup modal
function showSignup() {
    document.getElementById('signupModal').style.display = 'block';
    document.getElementById('loginModal').style.display = 'none';
}

// Close modal
function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
}

// Switch to signup from login
function switchToSignup() {
    closeModal('loginModal');
    showSignup();
}

// Switch to login from signup
function switchToLogin() {
    closeModal('signupModal');
    showLogin();
}

// Handle login
function handleLogin(event) {
    event.preventDefault();
    const email = document.getElementById('loginEmail').value;
    const password = document.getElementById('loginPassword').value;

    // Simulate login - in real app, this would be an API call
    const users = JSON.parse(localStorage.getItem('users') || '[]');
    const user = users.find(u => u.email === email && u.password === password);

    if (user) {
        const currentUser = {
            userId: user.userId,
            name: user.name,
            email: user.email,
            phone: user.phone
        };
        localStorage.setItem('currentUser', JSON.stringify(currentUser));
        closeModal('loginModal');
        window.location.href = 'dashboard.html';
    } else {
        alert('Invalid email or password');
    }
}

// Handle signup
function handleSignup(event) {
    event.preventDefault();
    const name = document.getElementById('signupName').value;
    const email = document.getElementById('signupEmail').value;
    const phone = document.getElementById('signupPhone').value;
    const password = document.getElementById('signupPassword').value;

    // Simulate signup - in real app, this would be an API call
    const users = JSON.parse(localStorage.getItem('users') || '[]');
    
    // Check if email already exists
    if (users.find(u => u.email === email)) {
        alert('Email already registered');
        return;
    }

    const newUser = {
        userId: Date.now(),
        name: name,
        email: email,
        phone: phone,
        password: password
    };

    users.push(newUser);
    localStorage.setItem('users', JSON.stringify(users));

    const currentUser = {
        userId: newUser.userId,
        name: newUser.name,
        email: newUser.email,
        phone: newUser.phone
    };
    localStorage.setItem('currentUser', JSON.stringify(currentUser));
    
    closeModal('signupModal');
    window.location.href = 'dashboard.html';
}

// Logout
function logout() {
    localStorage.removeItem('currentUser');
    window.location.href = 'index.html';
}

// Close modal when clicking outside
window.onclick = function(event) {
    const modals = document.getElementsByClassName('modal');
    for (let modal of modals) {
        if (event.target === modal) {
            modal.style.display = 'none';
        }
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    const user = checkAuth();
    if (user) {
        const userNameElement = document.getElementById('userName');
        if (userNameElement) {
            userNameElement.textContent = `Welcome, ${user.name}!`;
        }
    }
});

