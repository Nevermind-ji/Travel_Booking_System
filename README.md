# Travel Booking System - Frontend

A comprehensive HTML/CSS/JavaScript frontend for a travel booking management system.

## Project Structure

```
Travel_Booking_System/
├── UI/
│   ├── html/
│   │   ├── index.html              # Landing page with login/signup
│   │   ├── dashboard.html          # Main dashboard after login
│   │   ├── groups.html             # Manage co-traveller groups
│   │   ├── book-flight.html        # Book flights
│   │   ├── book-train.html         # Book trains
│   │   ├── book-bus.html           # Book buses
│   │   ├── book-hotel.html         # Book hotels
│   │   ├── book-activity.html      # Book activities
│   │   ├── packages.html           # Browse and book travel packages
│   │   ├── custom-package.html     # Build custom travel packages
│   │   └── my-bookings.html        # View and manage bookings
│   ├── css/
│   │   └── styles.css             # Main stylesheet
│   └── js/
│       ├── auth.js                # Authentication handling
│       ├── dashboard.js           # Dashboard functionality
│       ├── groups.js              # Group management
│       ├── bookings.js            # Booking functionality (flights, trains, buses, hotels, activities)
│       ├── packages.js            # Package booking
│       ├── custom-package.js      # Custom package builder
│       └── my-bookings.js         # Bookings management
├── Create_Table.sql               # Database schema
└── README.md                      # This file
```

## Features

- **User Authentication**: Login and Sign Up functionality
- **Dashboard**: Central hub for all travel booking options
- **Group Management**: Create and manage co-traveller groups
- **Transportation Booking**: 
  - Flights (Economy, Business, First class)
  - Trains (Sleeper, AC 3-tier, AC 2-tier, Chair)
  - Buses (AC, Non-AC, Volvo, Luxury)
- **Accommodation**: Hotel booking with different room types
- **Activities**: Book adventure, cultural, nature, and leisure activities
- **Travel Packages**: Browse pre-made packages
- **Custom Packages**: Build your own package by selecting services
- **Booking Management**: View, filter, and cancel bookings

## Usage

1. Open `UI/html/index.html` in a web browser
2. Create an account or login
3. Navigate through the dashboard to book services
4. All data is stored in browser's localStorage (for demo purposes)

**Note:** All HTML files are in `UI/html/`, CSS in `UI/css/`, and JavaScript in `UI/js/`. The paths are configured to work from this structure.

## Note

This is a frontend-only implementation. In a production environment, you would need to:
- Connect to a backend API
- Implement proper authentication
- Connect to a database
- Add payment processing
- Implement actual search functionality

## Technologies Used

- HTML5
- CSS3 (with modern features like Flexbox and Grid)
- JavaScript (ES6+)
- LocalStorage for data persistence (demo purposes)

