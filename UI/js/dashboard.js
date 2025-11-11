// Dashboard functionality

document.addEventListener('DOMContentLoaded', function() {
    const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
    
    if (!user.userId) {
        window.location.href = 'index.html';
        return;
    }

    // Update user name
    const userNameElement = document.getElementById('userName');
    if (userNameElement) {
        userNameElement.textContent = `Welcome, ${user.name}!`;
    }

    // Update membership badge
    const membershipBadge = document.getElementById('membershipBadge');
    if (membershipBadge && user.membership) {
        const membershipName = user.membership.name || 'Basic';
        membershipBadge.textContent = membershipName;
        membershipBadge.className = `membership-badge ${membershipName.toLowerCase()}`;
        membershipBadge.title = `${membershipName} Membership - ${user.membership.discount || 0}% discount`;
    }

    // Dashboard is ready
    console.log('Dashboard loaded for user:', user.name);
});

