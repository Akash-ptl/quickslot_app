# QuickSlot Mobile App

A premium-grade Flutter mobile application for booking sports venue slots. Designed with a custom hand-crafted Dark theme (Slate/Teal) and managed using the **BLoC (Business Logic Component)** pattern for clean separation of concerns and responsive state synchronization.

---

## 📲 Download Release Builds
* 🤖 **Android APK**: [![Download APK](https://img.shields.io/badge/Download-APK-008080?style=for-the-badge&logo=android&logoColor=white)](https://github.com/Akash-ptl/quickslot_app/releases)
* 🍎 **iOS Simulator Build**: [![iOS Simulator Build](https://img.shields.io/badge/Download-iOS%20Simulator-grey?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/Akash-ptl/quickslot_app/releases)

---

## 📂 Architecture & Folder Layout
Click on any folder or file path below to view its implementation directly:
* 📁 **Network & Core Models**: [lib/data/](lib/data/)
  * 📄 [lib/data/api_service.dart](lib/data/api_service.dart) - API requests, SharedPreferences persistence, automatic IP routing.
  * 📄 [lib/data/models.dart](lib/data/models.dart) - Data schemas (User, Venue, Slot, Booking).
* 📁 **State Management Layer**: [lib/bloc/](lib/bloc/)
  * 📁 [lib/bloc/auth/](lib/bloc/auth/) - Session status tracking.
  * 📁 [lib/bloc/venue/](lib/bloc/venue/) - Venue listings management.
  * 📁 [lib/bloc/slot/](lib/bloc/slot/) - Reservation grids and lock state transactions.
  * 📁 [lib/bloc/booking/](lib/bloc/booking/) - Booking histories and cancellations.
* 📁 **Interface Views**: [lib/screens/](lib/screens/)
  * 📄 [lib/screens/initial_screen.dart](lib/screens/initial_screen.dart) - Splash view handling auto-login routes.
  * 📄 [lib/screens/login_screen.dart](lib/screens/login_screen.dart) - Email login with hidden credentials toggling.
  * 📄 [lib/screens/register_screen.dart](lib/screens/register_screen.dart) - Account creation page.
  * 📄 [lib/screens/venue_list_screen.dart](lib/screens/venue_list_screen.dart) - Dashboard feed with shimmer skeleton loadings.
  * 📄 [lib/screens/venue_details_screen.dart](lib/screens/venue_details_screen.dart) - Venue selection calendar and availability grid.
  * 📄 [lib/screens/my_bookings_screen.dart](lib/screens/my_bookings_screen.dart) - Ticket pass view displaying booked slots.
* 📁 **Global Configs & Helpers**:
  * 📄 [lib/main.dart](lib/main.dart) - App entry configuration and Dark Theme.
  * 📄 [lib/widgets/premium_snackbar.dart](lib/widgets/premium_snackbar.dart) - Custom floating alert snackbars.
  * 📄 [lib/widgets/shimmer_loading.dart](lib/widgets/shimmer_loading.dart) - Skeleton loaders design.

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
*Note: The `ApiService` base URL is configured to connect to your computer's Wi-Fi network host address (e.g. [http://192.168.0.100:8000](http://192.168.0.100:8000)) for seamless debugging on physical mobile devices.*
