# 🌟 STARK 2026 Event Management System

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-ffca28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

A high-performance, real-time event tracking and registration web application built to power **IIUM STARK 2026** (May 2, 2026), spearheaded by the Association of Computational and Theoretical Sciences (ACTS).

This system replaces traditional paper trails with a digitized, low-latency dashboard that handles live participant check-ins, multi-venue activity tracking, and real-time leaderboards, all optimized to handle heavy read/write traffic during a live event.

---

## ✨ Key Features

* **Real-Time Data Dashboard:** Live updates for overall attendance using interactive pie charts and a dynamic participant leaderboard.
* **Dual-Input Activity Scanner:** Supports both RFID integration and manual IC/UID entry with built-in "Anti-Duplicate" race-condition locks to prevent multi-scan database spam.
* **Main Event Check-In:** Lightning-fast attendance logging with automated cross-referencing against the pre-registered user database.
* **Comprehensive Directories:** Full CRUD (Create, Read, Update, Delete) management systems for Participants, Activities, and Committee Members.
* **Smart UI/UX:** Features dynamic role-based color coding for committee members (e.g., Gold for High Council, Orange for HODs) and fully responsive layouts that adapt seamlessly from a desktop control center to a mobile tablet on the ground.

---

## 🛠️ Architecture & Performance Optimizations

To ensure stability and protect Firebase Cloud Firestore quota limits during the massive concurrent usage of a live event, this application features several enterprise-grade optimizations:

* **State Rebuild Prevention:** Eliminated "rebuild explosions" by moving stream initializations to `initState()`, preventing recursive database reads during local UI state changes.
* **Stream Caching & Slicing:** Heavy collections (like live logs) are aggressively limited (e.g., `.limit(100)`) at the query level to prevent massive payload downloads.
* **Client-Side Pagination:** Integrated custom 5-item and 20-item pagination logic across all major list views to guarantee 60fps scrolling and blazing-fast rendering.
* **Zero-Read Local Searching:** Search bars across the directories filter cached streams locally in memory, allowing committee members to search by Name, UID, IC, or Role instantly without executing new Firestore read requests.

---

## 🚀 Tech Stack

* **Frontend:** Flutter (Web)
* **Backend:** Firebase (Cloud Firestore)
* **Hosting:** Firebase Hosting
* **Data Visualization:** `fl_chart`
* **Animations:** `flutter_animate`

---

## ⚙️ Local Setup & Deployment

### Prerequisites
* Flutter SDK installed (`>=3.0.0`)
* Firebase CLI installed and logged in

### Installation
1. Clone the repository:
   ```bash
   git clone [https://github.com/your-username/stark-2026-system.git](https://github.com/your-username/stark-2026-system.git)

2. Navigate to the project directory:
   ```bash
   cd stark-2026-system
   
4. Get Flutter dependencies:
   ```bash
   flutter pub get

6. Run locally on Chrome:
   ```bash
   flutter run -d chrome

8. Deployment to Production (To compile and deploy the highly compressed production build to Firebase Hosting:)
   ```bash
   flutter clean
   flutter build web --release
   firebase deploy --only hosting
   
