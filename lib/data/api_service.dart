import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
  // Production Render API URL
  static const String baseUrl = 'https://quickslot-backend-jdhl.onrender.com';

  // GET /users
  Future<List<User>> getUsers() async {
    final url = Uri.parse('$baseUrl/users');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => User.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, "Failed to load users");
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
        'X-User-Id': userId.toString(),
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

  // GET /users/{id}/bookings
  Future<List<Booking>> getUserBookings(int userId) async {
    final url = Uri.parse('$baseUrl/users/$userId/bookings');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Booking.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, "Failed to load user bookings");
    }
  }

  // DELETE /bookings/{id}
  Future<void> cancelBooking(int bookingId) async {
    final url = Uri.parse('$baseUrl/bookings/$bookingId');
    final response = await http.delete(url);

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
