// Groups management functionality

let groups = JSON.parse(localStorage.getItem('groups') || '[]');

// Load groups on page load
document.addEventListener('DOMContentLoaded', function() {
    renderGroups();
});

// Show create group modal
function showCreateGroupModal() {
    document.getElementById('createGroupModal').style.display = 'block';
}

// Handle create group
function handleCreateGroup(event) {
    event.preventDefault();
    const groupName = document.getElementById('groupName').value;
    const user = JSON.parse(localStorage.getItem('currentUser') || '{}');

    const newGroup = {
        groupId: Date.now(),
        name: groupName,
        createdByUserID: user.userId,
        travellers: []
    };

    groups.push(newGroup);
    localStorage.setItem('groups', JSON.stringify(groups));
    
    closeModal('createGroupModal');
    document.getElementById('createGroupForm').reset();
    renderGroups();
}

// Render groups
function renderGroups() {
    const groupsList = document.getElementById('groupsList');
    const user = JSON.parse(localStorage.getItem('currentUser') || '{}');
    
    // Filter groups created by current user
    const userGroups = groups.filter(g => g.createdByUserID === user.userId);

    if (userGroups.length === 0) {
        groupsList.innerHTML = '<p class="empty-message">No groups created yet. Create your first group!</p>';
        return;
    }

    groupsList.innerHTML = userGroups.map(group => `
        <div class="group-card">
            <div class="group-header">
                <div class="group-title">${group.name}</div>
                <button class="btn btn-primary" onclick="showAddTravellerModal(${group.groupId})">Add Traveller</button>
            </div>
            <div class="travellers-list">
                ${group.travellers.length === 0 
                    ? '<p style="color: #999;">No travellers added yet</p>' 
                    : group.travellers.map(t => `
                        <div class="traveller-badge">
                            ${t.name} (${t.age}${t.gender ? ', ' + t.gender : ''})
                        </div>
                    `).join('')
                }
            </div>
        </div>
    `).join('');
}

// Show add traveller modal
function showAddTravellerModal(groupId) {
    document.getElementById('travellerGroupId').value = groupId;
    document.getElementById('addTravellerModal').style.display = 'block';
}

// Handle add traveller
function handleAddTraveller(event) {
    event.preventDefault();
    const groupId = parseInt(document.getElementById('travellerGroupId').value);
    const name = document.getElementById('travellerName').value;
    const age = parseInt(document.getElementById('travellerAge').value);
    const gender = document.getElementById('travellerGender').value;
    const idProof = document.getElementById('travellerIdProof').value;

    const group = groups.find(g => g.groupId === groupId);
    if (group) {
        const traveller = {
            name: name,
            age: age,
            gender: gender,
            idProof: idProof
        };
        group.travellers.push(traveller);
        localStorage.setItem('groups', JSON.stringify(groups));
        renderGroups();
        closeModal('addTravellerModal');
        document.getElementById('addTravellerForm').reset();
    }
}

