# 🚗 CarTrack — Smart Car Rental & Tracking App

> Your all-in-one solution for managing, renting, and tracking vehicles in real-time using Flutter & Firebase.

---

## 📱 Features

- 🔐 **User Authentication** (Email & Phone login)
- 🛻 **Vehicle Listing & Management**
- 📍 **Real-Time Vehicle Tracking (Google Maps)**
- 🧾 **Car Rental Booking System**
- 📤 **Admin Panel for Adding/Updating Cars**
- 💳 **Planned Online Payment Integration**
- 📲 **Modern, Responsive UI with Flutter**

---

## 📸 Screenshots

| Home Page | Active Vehicles | setting Page |
|-----------|-----------------|--------------|
| ![home](https://i.postimg.cc/PqMgHnM6/welcome.png) | ![map](https://i.postimg.cc/Xq61B2xZ/Map.png) | ![setting](https://i.postimg.cc/rsSpjJCz/settings.png) |

---

## ⚙️ Technologies Used

- **Flutter** — Frontend UI framework
- **Firebase** — Backend-as-a-Service  
  - Firestore (Database)  
  - Firebase Auth  
  - Firebase Storage  
- **Google Maps API** — Real-time location tracking
- **Geolocator** — GPS & permissions
- **Provider / Riverpod** — State Management
- **Figma / Visily** — UI/UX Design

---

## 🏗️ Architecture

- **Modular Structure**
  - `/screens/` — Pages like login, home, profile, etc.
  - `/models/` — Dart classes for Vehicles & Users
  - `/services/` — Firebase logic (auth, db, location)
  - `/widgets/` — Reusable UI components
- **Clean Code & Separation of Concerns**

---

## 🚀 Getting Started

1. **Clone the repo**
   ```bash
   git clone https://github.com/yourusername/CarTrack.git
   cd CarTrack
   flutter run
