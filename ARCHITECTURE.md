# Real‑World Battle Royale Game (FreeFire‑in‑Real‑Life)

## Overview
A GPS‑based multiplayer battle‑royale where players move **in the real world** using their smartphones. The app runs on **Android, iOS and Desktop** (via Flutter) and communicates with a **Node.js backend** for real‑time matchmaking, location updates and game state.

## Architecture
```
+----------------------+      +-----------------------+      +-------------------+
|   Flutter Frontend   | <--->|   Node.js Backend      |<--->|   MongoDB Atlas   |
| (iOS/Android/Web)   |      |  (Express + Socket.io) |      | (Player data,    |
+----------------------+      +-----------------------+      |   match history) |
          ^                               ^                +-------------------+
          |                               |
          |      Real‑time location      |
          |      updates via WebSocket   |
          +-------------------------------+
```

* **Frontend (Flutter)** – Handles UI, GPS, camera, AR overlays, and communicates over **WebSocket** to the backend.
* **Backend (Node.js)** – Manages rooms, matchmaking, safety‑zone logic, and stores persistent data in **MongoDB**.
* **Database** – Stores player profiles, inventory, match history, and analytics.
* **Optional services** – Push notifications (Firebase Cloud Messaging), map tiles (Mapbox), and cheat‑prevention (server‑side validation).

## Technologies
- **Flutter 3.x** – Cross‑platform UI, GPS (`geolocator`), maps (`flutter_map`), real‑time sockets (`socket_io_client`).
- **Node.js 20** – Express, Socket.io, JWT auth.
- **MongoDB Atlas** – Cloud‑hosted document store.
- **Docker** – Containerised backend for easy deployment.
- **Firebase** – Optional push notifications & analytics.

## Getting Started
1. **Clone repo**
   ```bash
   git clone https://github.com/yourorg/real‑world‑battle‑royale.git
   cd real‑world‑battle‑royale
   ```
2. **Backend**
   ```bash
   cd backend
   npm install
   cp .env.example .env   # fill DB_URI and JWT secret
   npm run dev   # starts Express & Socket.io on port 4000
   ```
3. **Flutter Frontend**
   ```bash
   cd ../flutter_app
   flutter pub get
   flutter run   # on device/emulator
   ```

## Development Roadmap
| Phase | Features |
|------|----------|
| **MVP** | GPS login, live location broadcast, simple death‑match area, 10‑player lobby |
| **Beta** | Weapon inventory, health system, safe‑zone shrinking, map UI |
| **Launch** | Ranking, clans, in‑app purchases, AR effects |

---
*Feel free to customise the design, add more game modes, or integrate AR.*
