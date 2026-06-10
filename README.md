# QuickSlot App 📲

A premium-grade Flutter mobile application for booking sports venue slots, styled with a custom Material 3 Dark theme (Slate/Teal) and managed using the BLoC pattern.

---

## 🚀 Download & Live API
* 🤖 [Download Android APK](https://github.com/Akash-ptl/quickslot_app/releases)
* 🌐 [Production API Swagger Docs](https://quickslot-backend-jdhl.onrender.com/docs)

## 🏆 Completed Requirements Checklist (100% Coverage)

### Core Features
- [x] **Concurrency Collision Safety**: Enforced via a composite unique database index (`UNIQUE(venue_id, date, slot_time)`). In a double-booking scenario, exactly one write succeeds (`201`) and the other is rejected (`409 Conflict`), triggering a collision alert dialog and automatic grid updates.
- [x] **Lightweight Secure Auth**: Implemented standard email/password registration (`POST /auth/register`) and login (`POST /auth/login`) with `bcrypt` encryption and OAuth2 JWT Bearer Tokens.
- [x] **Startup & Session Persistence**: Local token cache integration (`shared_preferences`) allows auto-login on startup via a dedicated splash screen (`InitialScreen`).
- [x] **Dashboards**: Displays seeded sports grounds in a clean category chips layout with a glassmorphic search bar and sliding entry animations.
- [x] **Interactive Scheduling**: Scrollable custom date timeline picker capsules alongside an available/booked hourly slot availability grid.
- [x] **My Bookings Manager**: Custom clipper stadium passes notched layout cards depicting time, date, venue details, check-in QR codes, and booking cancellation buttons.

### API Specifications (FastAPI Backend)
- [x] `GET /venues` (Browse seeded venues)
- [x] `GET /venues/{id}/slots` (Check slots availability by date)
- [x] `POST /bookings` (Concurrency-safe booking creation)
- [x] `GET /users/{id}/bookings` (User active bookings history)
- [x] `DELETE /bookings/{id}` (Cancel active bookings)

### Standardized State Management & Polish
- [x] **BLoC state isolation**: Decouples business logic completely from view layout components.
- [x] **State Handlers Everywhere**:
  - *Loading states*: Custom animated gradient shimmer overlays (`ShimmerLoading`) on dashboards and booking grids.
  - *Empty states*: User-friendly empty graphics for booked out dates or empty schedules.
  - *Error states*: Custom floating notification banners (`PremiumSnackBar`) with status accent borders and icons.
- [x] **Haptic feedback triggers**: Tactile triggers on timeline navigation, category chip updates, and slot selection.
- [x] **Clean release permission**: Main manifest is configured to request `<uses-permission android:name="android.permission.INTERNET"/>` so release builds work seamlessly.

### Completed Hackathon Bonus Features
- [x] **Bonus 1 (Filter slots by time of day)**: Client-side choice chips sorting slots into Morning, Afternoon, Evening, or All.
- [x] **Bonus 2 (Slot status updates via polling)**: Background execution timer (`Timer.periodic`) triggering background slot refreshes silently every 4 seconds.
- [x] **Bonus 3 (Unit and widget testing)**: Unit tests verifying JSON serialization models and widget tests auditing the snackbar alert rendering engine.

---

## 📸 App Screenshots

<table border="1" cellpadding="5">
  <tr>
    <td align="center" width="33%"><b>Login & Profile Selection</b></td>
    <td align="center" width="33%"><b>Account Registration</b></td>
    <td align="center" width="33%"><b>Venues Feed Dashboard</b></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/login_screen.png" width="100%" alt="Login Screen" style="border-radius: 16px; border: 6px solid #1c1c1e;"/></td>
    <td align="center"><img src="screenshots/signup_screen.png" width="100%" alt="Sign Up Screen" style="border-radius: 16px; border: 6px solid #1c1c1e;"/></td>
    <td align="center"><img src="screenshots/venue_list_screen.png" width="100%" alt="Venue List" style="border-radius: 16px; border: 6px solid #1c1c1e;"/></td>
  </tr>
  <tr>
    <td align="center"><b>Venue Booking Details</b></td>
    <td align="center"><b>Timeline Date Picker</b></td>
    <td align="center"><b>Confirm Booking Alert</b></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/venue_details_screen.png" width="100%" alt="Venue Details" style="border-radius: 16px; border: 6px solid #1c1c1e;"/></td>
    <td align="center"><img src="screenshots/date_picker.png" width="100%" alt="Date Picker" style="border-radius: 16px; border: 6px solid #1c1c1e;"/></td>
    <td align="center"><img src="screenshots/booking_dialog.png" width="100%" alt="Confirm Dialog" style="border-radius: 16px; border: 6px solid #1c1c1e;"/></td>
  </tr>
  <tr>
    <td align="center"><b>Stadium Ticket Passes</b></td>
    <td align="center"><b>Logout Session Confirmation</b></td>
    <td align="center"><b>QuickSlot App</b></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/my_bookings_screen.png" width="100%" alt="My Bookings" style="border-radius: 16px; border: 6px solid #1c1c1e;"/></td>
    <td align="center"><img src="screenshots/logout_dialog.png" width="100%" alt="Logout Dialog" style="border-radius: 16px; border: 6px solid #1c1c1e;"/></td>
    <td align="center" valign="middle">
      <br/><br/>
      <img src="https://img.shields.io/badge/QuickSlot-Sports%20Booking-008080?style=for-the-badge&logo=sports_tennis" alt="QuickSlot Logo"/>
      <br/><br/>
    </td>
  </tr>
</table>

---

## 📐 Architecture Note & Folder Layout
The app is built using a layer-first structure inside the `lib/` directory:
* `data/`: REST client ([api_service.dart](lib/data/api_service.dart)) and data schemas ([models.dart](lib/data/models.dart)).
* `bloc/`: BLoC managers for decoupled state management (`auth`, `venue`, `slot`, `booking`).
* `screens/`: Layout screens ([initial_screen.dart](lib/screens/initial_screen.dart), [login_screen.dart](lib/screens/login_screen.dart), [register_screen.dart](lib/screens/register_screen.dart), [venue_list_screen.dart](lib/screens/venue_list_screen.dart), [venue_details_screen.dart](lib/screens/venue_details_screen.dart), [my_bookings_screen.dart](lib/screens/my_bookings_screen.dart)).
* `widgets/`: Premium notification alert helper ([premium_snackbar.dart](lib/widgets/premium_snackbar.dart)) and custom shimmer skeleton overlays ([shimmer_loading.dart](lib/widgets/shimmer_loading.dart)).

---

## 🔄 App User Flow

```text
  [LoginScreen] ────► [VenueListScreen] ────► [VenueDetailsScreen] ◄────► [MyBookingsScreen]
  (Auto-Login Check)   (Shimmer Loaders)      (Timeline Picker)           (Stadium Passes Layout)
```

1. **Auto-Login / Splash Screen**: App starts at `InitialScreen`, checks if session token exists in local storage (`shared_preferences`), and dynamically routes to `VenueListScreen` or `LoginScreen`.
2. **Venue Listing Feed**: Displays active sports grounds with search capability, categorization chips, shimmer placeholders, and cascading entry animations.
3. **Availability Grid & Booking**: Displays dates in a scrollable timeline capsule list and slots as a status grid. Tapping a slot opens a booking confirmation modal.
4. **My Bookings Manager**: Displays active bookings styled as stadium ticket passes. Users can view passes or cancel a booking.

---

## ⚡ Concurrency Conflict UX Flow

Double-booking collisions are handled cleanly using BLoC's state-listener flow:

```text
  [Slot Grid] ──(Tap Book)──► [SlotBloc] ──(POST /bookings)──► [FastAPI Backend]
                                                                        │
  [Grid Refreshed] ◄──(Reset)─── [SlotBloc] ◄──(Conflict State)◄─── [409 Conflict]
          │
  [Collision Dialog shown]
```

1. If another user books the slot milliseconds earlier, the backend database composite unique constraint rejects the second write and yields a `409 Conflict`.
2. The `SlotBloc` intercepts the conflict, pulls updated slot states, and emits `bookingStatus: 'conflict'`.
3. The UI listener detects the status, dismisses the progress spinner, triggers a custom warning dialog, and refreshes the slot grid.

---

## 🛠️ Setup & Running Locally
1. Fetch packages:
   ```bash
   flutter pub get
   ```
2. Start the Flutter app:
   ```bash
   flutter run
   ```
*Note: The app is configured to connect to uvicorn running on your local computer's Wi-Fi network gateway (`192.168.0.100:8000`) for seamless debugging on physical devices.*


