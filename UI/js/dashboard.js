// Dashboard functionality

document.addEventListener('DOMContentLoaded', function() {
    const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
    
    if (!user.userId) {
        window.location.href = 'index.html';
        return;
    }

    // Dashboard is ready
    console.log('Dashboard loaded for user:', user.name);
});

