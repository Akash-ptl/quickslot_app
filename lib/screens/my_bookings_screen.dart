import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  Future<void> _handleCancel(BuildContext context, WidgetRef ref, int bookingId, String venueName, String slotTime, String date) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Format date for output
    final DateTime parsedDate = DateTime.parse(date);
    final String formattedDate = DateFormat('EEE, MMM dd').format(parsedDate);

    // Confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162D36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancel Booking?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to cancel your booking at $venueName on $formattedDate ($slotTime)?\nThis action cannot be undone.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Keep Booking", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes, Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.tealAccent),
      ),
    );

    final apiService = ref.read(apiServiceProvider);

    try {
      await apiService.cancelBooking(bookingId);

      // Pop loading spinner
      if (context.mounted) Navigator.of(context).pop();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: const Text(
              "Booking cancelled successfully.",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        );
      }

      // Refresh lists
      ref.invalidate(userBookingsProvider(currentUser.id));
      
      // Invalidate slots cache globally (so grid reflects the cancellation)
      // Since we don't know the exact slotParams combinations currently in cache,
      // invalidating slotsProvider.family entirely works or we can let users refresh it.
      // In Riverpod, ref.invalidate(slotsProvider) invalidates all families!
      ref.invalidate(slotsProvider);

    } catch (e) {
      // Pop loading spinner
      if (context.mounted) Navigator.of(context).pop();

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent.shade700,
            content: Text("Failed to cancel booking: ${e.toString()}"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Unauthorized")));
    }

    final bookingsAsync = ref.watch(userBookingsProvider(currentUser.id));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1E24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142930),
        title: const Text("My Bookings", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_online_outlined,
                      size: 72,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No Active Bookings",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Browse venues, pick a date, and reserve your first slots today!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Back to Venue list
                      },
                      icon: const Icon(Icons.search_rounded),
                      label: const Text("Browse Venues", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              // Parse and format date
              final DateTime parsedDate = DateTime.parse(booking.date);
              final String dateDisplay = DateFormat('EEEE, MMM dd, yyyy').format(parsedDate);

              return Card(
                color: const Color(0xFF162D36),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Active Booking Accent Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.shade400.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Colors.tealAccent.shade400,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Booking details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.venue_name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateDisplay,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Time: ${booking.slot_time}",
                              style: TextStyle(
                                color: Colors.tealAccent.shade400,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Cancel Button
                      IconButton(
                        tooltip: "Cancel Booking",
                        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                        onPressed: () => _handleCancel(
                          context,
                          ref,
                          booking.id,
                          booking.venue_name,
                          booking.slot_time,
                          booking.date,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text(
                "Failed to load bookings",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF142930)),
                onPressed: () => ref.invalidate(userBookingsProvider(currentUser.id)),
                child: const Text("Retry", style: TextStyle(color: Colors.tealAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
