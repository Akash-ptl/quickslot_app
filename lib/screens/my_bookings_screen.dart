import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/slot/slot_bloc.dart';
import '../data/models.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool _isCancelProgress = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      context.read<BookingBloc>().add(LoadUserBookingsEvent(authState.user.id));
    }
  }

  void _showLoadingSpinner() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.tealAccent),
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context, Booking booking, int userId) async {
    // Format date for output
    final DateTime parsedDate = DateTime.parse(booking.date);
    final String formattedDate = DateFormat('EEE, MMM dd').format(parsedDate);

    // Confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162D36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancel Booking?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to cancel your booking at ${booking.venueName} on $formattedDate (${booking.slotTime})?\nThis action cannot be undone.",
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

    if (context.mounted) {
      context.read<BookingBloc>().add(CancelBookingEvent(
            bookingId: booking.id,
            userId: userId,
          ));
      
      // Smart refresh slot grid if currently loaded in memory
      final slotBloc = context.read<SlotBloc>();
      if (slotBloc.state is SlotLoadedState) {
        final slotState = slotBloc.state as SlotLoadedState;
        if (slotState.venueId == booking.venueId && slotState.date == booking.date) {
          slotBloc.add(LoadSlotsEvent(venueId: booking.venueId, date: booking.date));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthenticatedState) {
          return const Scaffold(body: Center(child: Text("Unauthorized")));
        }
        final currentUser = authState.user;

        return Scaffold(
          backgroundColor: const Color(0xFF0F1E24),
          appBar: AppBar(
            backgroundColor: const Color(0xFF142930),
            title: const Text("My Bookings", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: BlocListener<BookingBloc, BookingState>(
            listener: (context, bookingState) {
              if (bookingState is BookingLoadedState) {
                // Show/hide spinner
                if (bookingState.actionStatus == 'progress' && !_isCancelProgress) {
                  _isCancelProgress = true;
                  _showLoadingSpinner();
                } else if (bookingState.actionStatus != 'progress' && _isCancelProgress) {
                  _isCancelProgress = false;
                  Navigator.of(context).pop(); // Dismiss spinner
                }

                // Show success SnackBar
                if (bookingState.actionStatus == 'success') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red.shade700,
                      content: Text(
                        bookingState.actionMessage ?? "Booking cancelled.",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  );
                  context.read<BookingBloc>().add(ResetBookingActionStatusEvent());
                }

                // Show error SnackBar
                if (bookingState.actionStatus == 'error') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.redAccent.shade700,
                      content: Text(bookingState.actionMessage ?? "Cancellation failed"),
                    ),
                  );
                  context.read<BookingBloc>().add(ResetBookingActionStatusEvent());
                }
              }
            },
            child: BlocBuilder<BookingBloc, BookingState>(
              builder: (context, state) {
                if (state is BookingLoadingState || state is BookingInitialState) {
                  return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                }

                if (state is BookingErrorState) {
                  return Center(
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
                          onPressed: () {
                            context.read<BookingBloc>().add(LoadUserBookingsEvent(currentUser.id));
                          },
                          child: const Text("Retry", style: TextStyle(color: Colors.tealAccent)),
                        ),
                      ],
                    ),
                  );
                }

                if (state is BookingLoadedState) {
                  final bookings = state.bookings;

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
                          side: BorderSide(color: Colors.white.withOpacity(0.05)),
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
                                      booking.venueName,
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
                                      "Time: ${booking.slotTime}",
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
                                  booking,
                                  currentUser.id,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        );
      },
    );
  }
}
