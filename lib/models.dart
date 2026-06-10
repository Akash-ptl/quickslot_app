class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class Venue {
  final int id;
  final String name;
  final String location;

  Venue({
    required this.id,
    required this.name,
    required this.location,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String,
    );
  }
}

class Slot {
  final String slotTime;
  final String status; // "available" or "booked"
  final int? bookingId;
  final int? bookedByUserId;
  final String? bookedByUserName;

  Slot({
    required this.slotTime,
    required this.status,
    this.bookingId,
    this.bookedByUserId,
    this.bookedByUserName,
  });

  bool get isBooked => status == 'booked';

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      slotTime: json['slot_time'] as String,
      status: json['status'] as String,
      bookingId: json['booking_id'] as int?,
      bookedByUserId: json['booked_by_user_id'] as int?,
      bookedByUserName: json['booked_by_user_name'] as String?,
    );
  }
}

class Booking {
  final int id;
  final int userId;
  final int venueId;
  final String venueName;
  final String venueLocation;
  final String date;
  final String slotTime;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.venueName,
    required this.venueLocation,
    required this.date,
    required this.slotTime,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      venueId: json['venue_id'] as int,
      venueName: json['venue_name'] as String,
      venueLocation: json['venue_location'] as String,
      date: json['date'] as String,
      slotTime: json['slot_time'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
