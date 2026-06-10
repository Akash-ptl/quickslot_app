# QuickSlot — Sports Booking Application

QuickSlot is a concurrency-safe, mini-app for booking sports slots (badminton courts/turfs). This repository contains the Flutter mobile client. The corresponding backend code is in the companion `quickslot_backend` directory.

---

## 🏗️ Architecture & Data Flow

The project is structured as two independent modules:
1. **Frontend (Flutter)**: Structured using the **Riverpod** state management framework for clean separation of UI and business logic.
2. **Backend (Python FastAPI)**: Built with FastAPI, Uvicorn, and SQLAlchemy. Persists data to a local **SQLite** database.

```text
┌────────────────┐                ┌─────────────────┐                ┌──────────────┐
│  Flutter App   │  HTTP Requests │  FastAPI Server │  SQLAlchemy ORM │  SQLite DB   │
│   (Riverpod)   ├───────────────►│  (127.0.0.1)    ├───────────────►│  (WAL Mode)  │
│                │                │                 │                │  Unique Ctr  │
└────────────────┘                └─────────────────┘                └──────────────┘
```

### 🔒 Concurrency Safety (No Double-Booking)
Concurrency safety is enforced at the database layer using a **Unique Constraint** on the `bookings` table for `(venue_id, date, slot_time)`. 
* Even if multiple simultaneous requests arrive at the exact same microsecond, SQLite's transactional locks serialise writing operations. 
* Only **one** insert succeeds. The subsequent inserts violate the unique constraint and fail with an `IntegrityError`.
* FastAPI catches this error and returns an HTTP `409 Conflict` status code.
* The Flutter client catches this 409 exception, displays a graceful "Booking Collision" warning dialog to the user, and reloads the slot grid.

---

## 🚀 Setup & Execution Instructions

### 1. Run the Python Backend
Requirements: Python 3.11+

```bash
cd /Users/akashptl/StudioProjects/quickslot_backend
# Activate virtual environment
source venv/bin/activate
# Install dependencies
pip install -r requirements.txt
# Launch local server (runs on port 8000)
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```
*The database initializes automatically and seeds 3 venues, 5 mock users, and hourly slots.*

### 2. Run the Flutter App
Ensure your Flutter environment is ready (Android emulator or iOS simulator running).

```bash
cd /Users/akashptl/StudioProjects/quickslot_app
# Get packages
flutter pub get
# Run app
flutter run
```

---

## ⚙️ Concurrency Testing

To verify double-booking prevention, run the automated thread-pool test script:
```bash
cd /Users/akashptl/StudioProjects/quickslot_backend
venv/bin/python test_concurrency.py
```
This triggers **5 concurrent requests** at the exact same moment to book the same slot. Output will confirm that exactly **1 request succeeds** (`201 Created`) and the other **4 requests are rejected** with `409 Conflict`.

---

## ✂️ What We Cut & Why (Scope Choices)
* **Full Authentication (OAuth/JWT)**: We cut this to save time and prevent bloated code, using a simplified `X-User-Id` header-based authentication as allowed by the rules.
* **WebSockets for Live Synchronization**: Instead of complex WebSockets, we rely on immediate UI invalidation (refreshing lists/grids on any booking action) and manual pull-to-refresh to keep the code fast and maintainable.

---

## 🔮 With One More Day...
1. **WebSockets Integration**: Implement live push updates so slot statuses flip in real-time when another user books.
2. **Offline Mode**: Add a local database cache (using Hive or sqflite) on the Flutter client to load previously viewed bookings offline.
3. **Unit & Widget Tests**: Increase test coverage for widgets and Riverpod state notifier logic.

---

## 🤖 AI Usage Note
* **What AI was used for**: Setting up initial boilerplate for SQLAlchemy models and FastAPI endpoints, plus styling the Flutter UI screens.
* **One thing it got wrong that was caught & fixed**: The AI initially used relative imports (e.g. `from .database import get_db`) in the FastAPI backend. Running Uvicorn directly on the file threw an `ImportError: attempted relative import with no known parent package`. We caught this, converted them to absolute imports (e.g. `from database import get_db`), which resolved the startup crash.
