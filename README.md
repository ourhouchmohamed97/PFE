# 🚗 HayMobility — Smart Car Tracking App

> Your all-in-one solution for managing, and tracking vehicles in real-time using Flutter & Firebase.

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
| ![home](https://i.postimg.cc/PqMgHnM6/welcome.png) | ![map](https://i.postimg.cc/nrjpb3gN/Screen-Shot-2025-07-06-at-6-52-13-PM.png) | ![setting](https://i.postimg.cc/6qvJ1yGX/Screen-Shot-2025-07-06-at-6-53-37-PM.png) |

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
- **Figma** — UI/UX Design

---

## 🏗️ Architecture

- **Modular Structure**
  - `/admin/screens/` → Admin-specific screens (e.g., Login, Home, Profile)
  - `/core/` → Core logic and services (e.g., Authentication, Utilities)
  - `/driver/` → Driver-specific screens (e.g., Vehicle Info, Driver Home)
  - `/routes/` → Centralized routing for pages (e.g., /login, /home, /profile)
  - `/shared/pages/` → Shared screens used by both Admin and Driver modules
  - `/main` → App entry point and main configuration
- **Clean Code & Separation of Concerns**

---

## 🚀 Getting Started

1. **Clone the repo**
   ```bash
   git clone https://github.com/ourhouchmohamed97/PFE.git HayMobility
   cd HayMobility
   flutter run
