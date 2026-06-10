import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import 'models.dart';

// Preconfigured Users matching our database seed data
final mockUsers = [
  User(id: 1, name: "Akash Patel"),
  User(id: 2, name: "Judge Alpha"),
  User(id: 3, name: "Judge Beta"),
  User(id: 4, name: "Test User 4"),
  User(id: 5, name: "Test User 5"),
];

// Current Logged In User
final currentUserProvider = StateProvider<User?>((ref) => null);

// ApiService Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Venues Provider
final venuesProvider = FutureProvider<List<Venue>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getVenues();
});

// Slot Param record class for slotsProvider.family
class SlotParams {
  final int venueId;
  final String date;

  SlotParams({required this.venueId, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotParams &&
          runtimeType == other.runtimeType &&
          venueId == other.venueId &&
          date == other.date;

  @override
  int get hashCode => venueId.hashCode ^ date.hashCode;
}

// Slots Provider (family)
final slotsProvider = FutureProvider.family<List<Slot>, SlotParams>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSlots(params.venueId, params.date);
});

// User Bookings Provider (family)
final userBookingsProvider = FutureProvider.family<List<Booking>, int>((ref, userId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getUserBookings(userId);
});
