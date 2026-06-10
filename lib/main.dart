import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    // Wrap entire app in ProviderScope to enable Riverpod state management
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickSlot Sports Booking',
      debugShowCheckedModeBanner: false,
      // Premium Material 3 Dark Theme System
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1E24),
        colorScheme: ColorScheme.dark(
          primary: Colors.tealAccent.shade400,
          secondary: Colors.tealAccent,
          surface: const Color(0xFF142930),
          background: const Color(0xFF0F1E24),
          error: Colors.redAccent.shade200,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF142930),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF162D36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: const Color(0xFF162D36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        fontFamily: 'Outfit', // Uses default system fonts but fallbacks gracefully
      ),
      home: const LoginScreen(),
    );
  }
}
