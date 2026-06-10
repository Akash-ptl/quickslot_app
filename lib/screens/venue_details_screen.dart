import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';
import '../api_service.dart';

class VenueDetailsScreen extends ConsumerStatefulWidget {
  final Venue venue;

  const VenueDetailsScreen({super.key, required this.venue});

  @override
  ConsumerState<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends ConsumerState<VenueDetailsScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1)); // Default to tomorrow to avoid past slots

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _displayDateStr => DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.tealAccent.shade400,
              onPrimary: Colors.black,
              surface: const Color(0xFF142930),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0F1E24),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Double Booking Concurrency Handler Dialog
  void _showConflictDialog(BuildContext context, String slotTime) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B2C33),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.amber.shade400.withOpacity(0.5), width: 1.5),
          ),
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber.shade400,
            size: 48,
          ),
          title: const Text(
            "Booking Collision!",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Oops! Another user just booked the $slotTime slot at ${widget.venue.name} at the exact same instant.\n\nWe have automatically refreshed the grid so you can select another time.",
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.amber.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK, Refresh Grid", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Handle Slot Tapped & Trigger Booking
  Future<void> _handleBooking(BuildContext context, WidgetRef ref, Slot slot) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Show booking confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162D36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Booking", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Do you want to book the ${slot.slotTime} slot at ${widget.venue.name} for $_displayDateStr?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.tealAccent.shade400,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Book Now", style: TextStyle(fontWeight: FontWeight.bold)),
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
    final params = SlotParams(venueId: widget.venue.id, date: _dateStr);

    try {
      // Call createBooking
      await apiService.createBooking(widget.venue.id, _dateStr, slot.slotTime, currentUser.id);

      // Pop loading spinner
      if (context.mounted) Navigator.of(context).pop();

      // Show success
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal.shade700,
            content: Text(
              "Successfully booked ${widget.venue.name} at ${slot.slotTime}!",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      // Refresh slots grid
      ref.invalidate(slotsProvider(params));
      // Refresh user bookings list
      ref.invalidate(userBookingsProvider(currentUser.id));

    } on SlotAlreadyBookedException catch (_) {
      // Pop loading spinner
      if (context.mounted) Navigator.of(context).pop();

      // Show collision warning dialog
      if (context.mounted) {
        _showConflictDialog(context, slot.slotTime);
      }

      // Refresh slots grid
      ref.invalidate(slotsProvider(params));

    } catch (e) {
      // Pop loading spinner
      if (context.mounted) Navigator.of(context).pop();

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent.shade700,
            content: Text("Booking failed: ${e.toString()}"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = SlotParams(venueId: widget.venue.id, date: _dateStr);
    final slotsAsync = ref.watch(slotsProvider(params));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1E24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142930),
        title: Text(widget.venue.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Header info & Date Picker Selector
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF142930),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.tealAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.venue.location,
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Date picker trigger button
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.tealAccent, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              _displayDateStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: Colors.tealAccent, size: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Slots Grid View
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(slotsProvider(params));
              },
              color: Colors.tealAccent,
              child: slotsAsync.when(
                data: (slots) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      final bool isBooked = slot.isBooked;
                      final bool isBookedByMe = isBooked && slot.bookedByUserId == currentUser?.id;

                      Color cardBgColor;
                      Color borderColors;
                      Widget slotContent;

                      if (isBookedByMe) {
                        cardBgColor = Colors.teal.shade900.withOpacity(0.4);
                        borderColors = Colors.tealAccent;
                        slotContent = Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slot.slotTime,
                              style: const TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, color: Colors.tealAccent, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  "Booked by You",
                                  style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else if (isBooked) {
                        cardBgColor = Colors.grey.shade900.withOpacity(0.6);
                        borderColors = Colors.white.withOpacity(0.05);
                        slotContent = Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slot.slotTime,
                              style: const TextStyle(color: Colors.white30, fontSize: 16, decoration: TextDecoration.lineThrough),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slot.bookedByUserName ?? "Booked",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white24, fontSize: 11),
                            ),
                          ],
                        );
                      } else {
                        // Available slot
                        cardBgColor = const Color(0xFF142930).withOpacity(0.6);
                        borderColors = Colors.tealAccent.withOpacity(0.2);
                        slotContent = Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slot.slotTime,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Available",
                              style: TextStyle(color: Colors.tealAccent.shade400, fontSize: 11),
                            ),
                          ],
                        );
                      }

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColors, width: 1.5),
                        ),
                        child: InkWell(
                          onTap: isBooked ? null : () => _handleBooking(context, ref, slot),
                          borderRadius: BorderRadius.circular(16),
                          child: Center(child: slotContent),
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
                        "Failed to load slots for this date",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF142930)),
                        onPressed: () => ref.invalidate(slotsProvider(params)),
                        child: const Text("Retry", style: TextStyle(color: Colors.tealAccent)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
