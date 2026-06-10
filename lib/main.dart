import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/api_service.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/venue/venue_bloc.dart';
import 'bloc/slot/slot_bloc.dart';
import 'bloc/booking/booking_bloc.dart';
import 'screens/login_screen.dart';

void main() {
  final apiService = ApiService();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiService>.value(value: apiService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(),
          ),
          BlocProvider<VenueBloc>(
            create: (context) => VenueBloc(apiService: apiService),
          ),
          BlocProvider<SlotBloc>(
            create: (context) => SlotBloc(apiService: apiService),
          ),
          BlocProvider<BookingBloc>(
            create: (context) => BookingBloc(apiService: apiService),
          ),
        ],
        child: const MyApp(),
      ),
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
