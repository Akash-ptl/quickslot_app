import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class SlotAlreadyBookedException implements Exception {
  final String message;
  SlotAlreadyBookedException(this.message);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => "Error $statusCode: $message";
}

class ApiService {
  // SET THIS TO TRUE to test with a local uvicorn backend on your physical phone / emulator.
  // When false, the app connects to the live production Render backend.
  static const bool _useLocalBackend = true;

  // Dynamic Base URL selection
  static String get baseUrl {
    if (_useLocalBackend) {
      // Connect to your local computer's Wi-Fi IP address
      return 'http://192.168.0.100:8000';
    }
    return 'https://quickslot-backend-jdhl.onrender.com';
  }

  // Session keys
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  String? _token;

  String? get token => _token;

  Future<User> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    print('[ApiService] Logging in user: $email');
    print('[ApiService] POST URL: $url');
    print('[ApiService] Request payload: {"email": "$email", "password": "${"*" * password.length}"}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('[ApiService] Login Response Status Code: ${response.statusCode}');
      print('[ApiService] Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'] as String;
        final user = User.fromJson(data['user']);

        // Persist session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, _token!);
        await prefs.setInt(_keyUserId, user.id);
        await prefs.setString(_keyUserEmail, user.email);
        await prefs.setString(_keyUserName, user.name);

        return user;
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        throw ApiException(response.statusCode, errorMsg);
      }
    } catch (e, stack) {
      print('[ApiService] Login error: $e');
      print(stack);
      rethrow;
    }
  }

  Future<User> register(String email, String name, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    print('[ApiService] Registering user: $email, Name: $name');
    print('[ApiService] POST URL: $url');
    print('[ApiService] Request payload: {"email": "$email", "name": "$name", "password": "${"*" * password.length}"}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'password': password,
        }),
      );

      print('[ApiService] Register Response Status Code: ${response.statusCode}');
      print('[ApiService] Register Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        final errorMsg = _parseErrorMessage(response.body);
        throw ApiException(response.statusCode, errorMsg);
      }
    } catch (e, stack) {
      print('[ApiService] Register error: $e');
      print(stack);
      rethrow;
    }
  }

  Future<User?> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final userId = prefs.getInt(_keyUserId);
      final userEmail = prefs.getString(_keyUserEmail);
      final userName = prefs.getString(_keyUserName);

      if (token != null && userId != null && userEmail != null && userName != null) {
        _token = token;
        return User(id: userId, email: userEmail, name: userName);
      }
    } catch (e) {
      print('[ApiService] Error during auto-login check: $e');
    }
    return null;
  }

  Future<void> logout() async {
    _token = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserName);
    } catch (e) {
      print('[ApiService] Error during logout clearing: $e');
    }
  }

  // GET /venues
  Future<List<Venue>> getVenues() async {
    final url = Uri.parse('$baseUrl/venues');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Venue.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, "Failed to load venues");
    }
  }

  // GET /venues/{id}/slots?date=YYYY-MM-DD
  Future<List<Slot>> getSlots(int venueId, String date) async {
    final url = Uri.parse('$baseUrl/venues/$venueId/slots?date=$date');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Slot.fromJson(json)).toList();
    } else {
      final errorMsg = _parseErrorMessage(response.body);
      throw ApiException(response.statusCode, errorMsg);
    }
  }

  // POST /bookings
  Future<Booking> createBooking(int venueId, String date, String slotTime, int userId) async {
    final url = Uri.parse('$baseUrl/bookings');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'venue_id': venueId,
        'date': date,
        'slot_time': slotTime,
      }),
    );

    if (response.statusCode == 201) {
      return Booking.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 409) {
      throw SlotAlreadyBookedException("This slot was just booked by another user!");
    } else {
      final errorMsg = _parseErrorMessage(response.body);
      throw ApiException(response.statusCode, errorMsg);
    }
  }

  static const String _keyMyBookingsCache = 'my_bookings_cache_';

  // GET /users/{id}/bookings
  Future<List<Booking>> getUserBookings(int userId) async {
    final url = Uri.parse('$baseUrl/users/$userId/bookings');
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Cache the raw JSON response for offline read support
        await prefs.setString('$_keyMyBookingsCache$userId', response.body);
        
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw ApiException(response.statusCode, "Failed to load user bookings");
      }
    } catch (e) {
      // Offline fallback
      final cachedData = prefs.getString('$_keyMyBookingsCache$userId');
      if (cachedData != null) {
        print('[ApiService] Offline cache hit for user bookings: $userId');
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((json) => Booking.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  // DELETE /bookings/{id}
  Future<void> cancelBooking(int bookingId) async {
    final url = Uri.parse('$baseUrl/bookings/$bookingId');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      final errorMsg = _parseErrorMessage(response.body);
      throw ApiException(response.statusCode, errorMsg);
    }
  }

  // Parse error message helper
  String _parseErrorMessage(String body) {
    try {
      final Map<String, dynamic> json = jsonDecode(body);
      if (json.containsKey('detail')) {
        return json['detail'] is String ? json['detail'] : json['detail'].toString();
      }
    } catch (_) {}
    return "Something went wrong";
  }
}
