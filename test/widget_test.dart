import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickslot_app/data/models.dart';
import 'package:quickslot_app/widgets/premium_snackbar.dart';

void main() {
  group('QuickSlot Model Unit Tests', () {
    test('User.fromJson creates a valid User object', () {
      final json = {
        'id': 1,
        'email': 'test@example.com',
        'name': 'Test User',
      };
      final user = User.fromJson(json);
      expect(user.id, 1);
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
    });

    test('Venue.fromJson creates a valid Venue object', () {
      final json = {
        'id': 2,
        'name': 'Teal Turf Ground',
        'location': 'Sector 62, Noida',
      };
      final venue = Venue.fromJson(json);
      expect(venue.id, 2);
      expect(venue.name, 'Teal Turf Ground');
      expect(venue.location, 'Sector 62, Noida');
    });

    test('Slot.fromJson creates a valid Slot object', () {
      final json = {
        'slot_time': '10:00',
        'status': 'available',
        'booking_id': null,
        'booked_by_user_id': null,
        'booked_by_user_name': null,
      };
      final slot = Slot.fromJson(json);
      expect(slot.slotTime, '10:00');
      expect(slot.status, 'available');
      expect(slot.isBooked, false);
    });

    test('Booking.fromJson creates a valid Booking object', () {
      final json = {
        'id': 10,
        'user_id': 1,
        'venue_id': 2,
        'venue_name': 'Teal Turf Ground',
        'venue_location': 'Sector 62, Noida',
        'date': '2026-06-12',
        'slot_time': '10:00',
        'created_at': '2026-06-10T15:42:57.140468',
      };
      final booking = Booking.fromJson(json);
      expect(booking.id, 10);
      expect(booking.venueName, 'Teal Turf Ground');
      expect(booking.date, '2026-06-12');
      expect(booking.slotTime, '10:00');
    });
  });

  group('QuickSlot Widget Tests', () {
    testWidgets('PremiumSnackBar builds and contains message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    PremiumSnackBar.show(
                      context,
                      message: 'Test Success Notification',
                      type: SnackBarType.success,
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      // Tap to show SnackBar
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Verify SnackBar contents
      expect(find.text('Test Success Notification'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });
  });
}
