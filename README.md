# QuickSlot App

A mobile Flutter application for booking sports venue slots. Designed with a custom Material 3 Dark theme and managed using the **BLoC (Business Logic Component)** pattern for clean separation of concerns.

---

## 📂 Project Architecture & Folder Structure

This application is built using a layer-first structure inside the `lib/` directory:

```text
lib/
├── data/
│   ├── api_service.dart      # REST API client with local emulator IP routing
│   └── models.dart           # Immutable models (User, Venue, Slot, Booking)
├── bloc/
│   ├── auth/                 # User login session state
│   ├── venue/                # Venue dashboard state
│   ├── slot/                 # Grid slots loading & booking transaction states
│   └── booking/              # User bookings list & cancellation state
├── screens/
│   ├── login_screen.dart     # Select profile to login
│   ├── venue_list_screen.dart# Main dashboard listing venues
│   ├── venue_details_screen.dart # Calendar date selector & interactive slot grid
│   └── my_bookings_screen.dart # List bookings with cancellation buttons
└── main.dart                 # Initialises Theme and global MultiRepository/MultiBloc providers
```

---

## 🔄 App User Flow

```text
  [LoginScreen] ────► [VenueListScreen] ────► [VenueDetailsScreen] ◄────► [MyBookingsScreen]
  (Pick profile)       (Browse venues)        (Pick date & book)          (View & cancel bookings)
```

1. **Profile Selection**: On start, users pick one of the five seeded test accounts to set the `AuthBloc` state. This provides the `X-User-Id` header for API request authentication.
2. **Venue Dashboard**: Displays sports venues with custom styling. Displays loading shimmers and provides pull-to-refresh to fetch updated listings.
3. **Slot Booking Grid**: Displays hourly slots (6:00 AM to 10:00 PM). Booked slots show details on who holds the booking. Tapping an available slot prompts confirmation.
4. **Active Bookings Manager**: Accessible via the bookmark icon. Lists all active reservations with option to cancel them.

---

## ⚡ Concurrency Conflict Handling (UX Flow)

Double-booking collisions are handled cleanly using BLoC's state-listener flow:

```text
  [Slot Grid] ──(Tap Book)──► [SlotBloc] ──(POST /bookings)──► [FastAPI Backend]
                                                                        │
  [Grid Refreshed] ◄──(Reset)─── [SlotBloc] ◄──(Conflict State)◄─── [409 Conflict]
          │
  [Collision Dialog shown]
```

1. When a user requests a booking, the app shows a progress overlay.
2. If another user books the slot milliseconds earlier, the backend returns a `409 Conflict`.
3. The `SlotBloc` intercepts the 409 exception, fetches the updated slot grid status, and emits a `SlotLoadedState` with `bookingStatus: 'conflict'`.
4. The screen's `BlocListener` intercepts this conflict state:
   - Dismisses the progress spinner.
   - Triggers an alert dialog: *"Booking Collision! Another user booked this slot at the exact same instant."*
   - Refreshes the grid automatically to reflect the newly updated slot status.

---

## 🚀 Running the App locally

### 1. Requirements
Ensure you have the Flutter SDK installed and a running emulator/simulator.

### 2. Configure Dependencies
Fetch packages:
```bash
flutter pub get
```

### 3. Execution
Ensure the local backend is running, then start the Flutter app:
```bash
flutter run
```
*Note: The `ApiService` automatically detects if it is running on an Android Emulator and translates the base URL host to `http://10.0.2.2:8000` (instead of `localhost:8000`) so network requests succeed without proxy config.*
