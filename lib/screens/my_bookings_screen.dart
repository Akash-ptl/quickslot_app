import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/slot/slot_bloc.dart';
import '../data/models.dart';
import '../widgets/shimmer_loading.dart';

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

  Widget _buildShimmerBookings() {
    return ShimmerLoading(
      isLoading: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return ClipPath(
            clipper: TicketClipper(),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 160,
              color: const Color(0xFF162D36),
            ),
          );
        },
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
                  return _buildShimmerBookings();
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

                      return AnimatedListItem(
                        index: index,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipPath(
                            clipper: TicketClipper(),
                            child: Container(
                              color: const Color(0xFF162D36),
                              child: Column(
                                children: [
                                  // Top section of the ticket
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Left: Sports Category Icon
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.tealAccent.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.tealAccent.withOpacity(0.2)),
                                          ),
                                          child: const Icon(
                                            Icons.confirmation_num_outlined,
                                            color: Colors.tealAccent,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Middle: Booking Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                booking.venueName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Row(
                                                children: [
                                                  Icon(Icons.location_on_rounded, size: 12, color: Colors.white38),
                                                  SizedBox(width: 4),
                                                  Text("Main Court", style: TextStyle(color: Colors.white38, fontSize: 11)),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text("DATE", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          DateFormat('MMM dd, yyyy').format(parsedDate),
                                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text("TIME", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          booking.slotTime,
                                                          style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Dashed Line Divider
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                                    child: DashedDivider(height: 1, color: Colors.white12),
                                  ),
                                  
                                  // Bottom section of the ticket
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.qr_code_2_rounded, color: Colors.tealAccent.shade400, size: 24),
                                            const SizedBox(width: 8),
                                            Text(
                                              "PASS #${booking.id} - Tap to scan",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.5),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Cancel Button
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          onPressed: () => _handleCancel(
                                            context,
                                            booking,
                                            currentUser.id,
                                          ),
                                          icon: const Icon(Icons.cancel_outlined, size: 16),
                                          label: const Text(
                                            "Cancel",
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double punchRadius = 10.0;
    final double punchPosition = size.height * 0.62;

    // Start at top-left
    path.moveTo(0.0, 0.0);
    
    // Draw top line to top-right
    path.lineTo(size.width, 0.0);
    
    // Draw right side down to right punch
    path.lineTo(size.width, punchPosition - punchRadius);
    // Draw right punch circle cutout (arc)
    path.arcToPoint(
      Offset(size.width, punchPosition + punchRadius),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );
    // Draw down to bottom-right
    path.lineTo(size.width, size.height);
    
    // Draw bottom line to bottom-left
    path.lineTo(0.0, size.height);
    
    // Draw left side up to left punch
    path.lineTo(0.0, punchPosition + punchRadius);
    // Draw left punch circle cutout (arc)
    path.arcToPoint(
      Offset(0.0, punchPosition - punchRadius),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );
    
    // Draw up to top-left
    path.lineTo(0.0, 0.0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;

  const DashedDivider({super.key, this.height = 1.0, this.color = Colors.white24});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

class AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;

  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
