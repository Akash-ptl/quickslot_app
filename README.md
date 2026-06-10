# QuickSlot Mobile App

A premium-grade Flutter mobile application for booking sports venue slots. Designed with a custom hand-crafted Dark theme (Slate/Teal) and managed using the **BLoC (Business Logic Component)** pattern for clean separation of concerns and responsive state synchronization.

---

## 📲 Download Release Builds
[![Download APK](https://img.shields.io/badge/Download-APK-008080?style=for-the-badge&logo=android&logoColor=white)](https://github.com/akashptl/quickslot_app/releases)
[![iOS Simulator Build](https://img.shields.io/badge/Download-iOS%20Simulator-grey?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/akashptl/quickslot_app/releases)

---

## 📂 Architecture & Folder Layout
This application is built using a layer-first structure inside the `lib/` directory:
```text
lib/
├── data/
│   ├── api_service.dart      # REST Client, session persistence, automatic Wi-Fi IP routing
│   └── models.dart           # Immutable models (User, Venue, Slot, Booking)
├── bloc/
│   ├── auth/                 # User login session state
│   ├── venue/                # Venue dashboard state
│   ├── slot/                 # Grid slots loading & booking transaction states
│   └── booking/              # User bookings list & cancellation state
├── screens/
│   ├── initial_screen.dart   # Startup splash page which check for local session auto-login
│   ├── login_screen.dart     # User login form with email and password (toggleable visibility)
│   ├── register_screen.dart  # Sign-up page for new accounts
│   ├── venue_list_screen.dart# Main dashboard listing venues with skeleton shimmers
│   ├── venue_details_screen.dart # Scrollable custom date timeline picker & interactive slot grid
│   └── my_bookings_screen.dart # Ticket Notch pass dashboard with cancellation handlers
├── widgets/
│   ├── premium_snackbar.dart # Custom floating notification with solid left border strips
│   └── shimmer_loading.dart  # Custom skeleton loader placeholders
└── main.dart                 # App initialization and theme definitions
```

---

## 🔄 Startup & Auto-Login Flow

```text
  [App Startup] ──► [InitialScreen] ──► Checks SharedPreferences
                          │
         ┌────────────────┴──────────────┐
         ▼                               ▼
  [Session Found]                [No Session Found]
  Sets auth token                Routes to [LoginScreen]
  Routes to [VenueListScreen]
```

1. **Auto-Login Check**: On start, `InitialScreen` is loaded showing a premium tennis icon animation while triggering `CheckAuthEvent`.
2. **Session Persistence**: If user tokens exist in local storage (`shared_preferences`), the `ApiService` is pre-populated and the user is seamlessly routed to `VenueListScreen`.
3. **Purged Stack Navigation**: During log-out, the app clears all credentials, destroys the navigation history stack (`Navigator.pushAndRemoveUntil`), and returns the user securely to `LoginScreen` to prevent backwards navigation.

---

## ✨ Premium UI & UX Overhaul Details

* **Custom Horizontal Calendar Timeline**: Replaces basic dates dropdown. Rendered as animated capsules highlighting the selected day number and text. Tapping a day automatically scrolls it into focus and loads slots instantly.
* **Shimmer Skeleton Loaders**: Replaces generic progress spinners. Custom gradient layout placeholders match the card designs, offering a responsive native feel.
* **Stadium Ticket Pass Layout**: Booking cards inside `MyBookingsScreen` are clipped using a custom Clipper path to render stadium ticket notches. Includes perforated divider styling, QR checks, and details layout.
* **Tactile Haptic Feedback**: Tactile triggers (`HapticFeedback`) on booking taps, category chip selections, and slot grid updates.
* **Premium Snackbars (`PremiumSnackBar`)**: Fully custom notifications that float cleanly on the screen. Contains left solid indicator borders and status symbols reflecting success, failure, or info.
* **Glowing Dialog Borders**: Custom confirmation modals designed with rounded corners (`20dp`) and a subtle glowing edge border (`Colors.tealAccent.withOpacity(0.1)`).

---

## 🚀 Running the App Locally

### 1. Requirements
Ensure Flutter SDK is installed and an emulator or physical testing device is configured.

### 2. Configure Packages
Fetch dependencies:
```bash
flutter pub get
```

### 3. Execution
Ensure the local API server is running on your network, then start the Flutter app:
```bash
flutter run
```
*Note: The `ApiService` base URL is configured to connect to your computer's Wi-Fi network host address (e.g. `http://192.168.0.100:8000`) for seamless debugging on physical mobile devices.*
