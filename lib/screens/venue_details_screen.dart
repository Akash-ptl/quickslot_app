import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/slot/slot_bloc.dart';
import '../data/models.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/premium_snackbar.dart';

class VenueDetailsScreen extends StatefulWidget {
  final Venue venue;

  const VenueDetailsScreen({super.key, required this.venue});

  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1)); // Default tomorrow
  bool _isBookingProgress = false;
  String _timeFilter = 'All'; // 'All', 'Morning', 'Afternoon', 'Evening'
  final ScrollController _timelineScrollController = ScrollController();

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _displayDateStr => DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _timelineScrollController.dispose();
    super.dispose();
  }

  void _loadSlots() {
    context.read<SlotBloc>().add(LoadSlotsEvent(venueId: widget.venue.id, date: _dateStr));
  }

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
      HapticFeedback.selectionClick();
      setState(() {
        _selectedDate = picked;
      });
      _loadSlots();
      
      final difference = picked.difference(DateTime.now()).inDays;
      if (difference >= 0 && difference < 14) {
        _timelineScrollController.animateTo(
          difference * 77.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else if (difference >= 14) {
        _timelineScrollController.animateTo(
          14 * 77.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
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

  Widget _buildFilterChip(String filter) {
    final bool isSelected = _timeFilter == filter;
    return ChoiceChip(
      label: Text(
        filter,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _timeFilter = filter;
          });
        }
      },
      selectedColor: Colors.tealAccent.shade400,
      backgroundColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.tealAccent.shade400 : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildShimmerGrid() {
    return ShimmerLoading(
      isLoading: true,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF142930).withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 16,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTimeline() {
    final today = DateTime.now();
    final difference = _selectedDate.difference(today).inDays;
    final bool isCustomDateSelected = difference >= 14;
    final int itemCount = isCustomDateSelected ? 15 : 14;

    return SizedBox(
      height: 90,
      child: ListView.builder(
        controller: _timelineScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final DateTime date;
          final bool isSelected;
          if (index == 14 && isCustomDateSelected) {
            date = _selectedDate;
            isSelected = true;
          } else {
            date = today.add(Duration(days: index));
            isSelected = DateFormat('yyyy-MM-dd').format(date) == _dateStr;
          }
          final dayName = DateFormat('E').format(date);
          final dayNumber = DateFormat('dd').format(date);
          
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedDate = date;
                });
                _loadSlots();
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 65,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.tealAccent.shade400 : const Color(0xFF162D36),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.tealAccent.shade400 : Colors.white.withOpacity(0.05),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.tealAccent.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (index == 14 ? "Custom" : dayName).toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.black87 : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayNumber,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Handle Slot Tapped & Trigger Booking
  Future<void> _handleBooking(BuildContext context, Slot slot, int userId) async {
    HapticFeedback.mediumImpact();
    // Show booking confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162D36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.tealAccent.withOpacity(0.1),
            width: 1,
          ),
        ),
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

    if (context.mounted) {
      context.read<SlotBloc>().add(BookSlotEvent(
            venueId: widget.venue.id,
            date: _dateStr,
            slotTime: slot.slotTime,
            userId: userId,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthenticatedState) return const SizedBox();
        final currentUser = authState.user;

        return Scaffold(
          backgroundColor: const Color(0xFF0F1E24),
          appBar: AppBar(
            backgroundColor: const Color(0xFF142930),
            title: Text(widget.venue.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: BlocListener<SlotBloc, SlotState>(
            listener: (context, slotState) {
              if (slotState is SlotLoadedState) {
                // Handle Loader Overlay
                if (slotState.bookingStatus == 'progress' && !_isBookingProgress) {
                  _isBookingProgress = true;
                  _showLoadingSpinner();
                } else if (slotState.bookingStatus != 'progress' && _isBookingProgress) {
                  _isBookingProgress = false;
                  Navigator.of(context).pop(); // Dismiss spinner
                }

                // Handle Success
                if (slotState.bookingStatus == 'success') {
                  PremiumSnackBar.show(
                    context,
                    message: slotState.bookingMessage ?? "Successfully booked!",
                    type: SnackBarType.success,
                  );
                  // Refresh user bookings list
                  context.read<BookingBloc>().add(LoadUserBookingsEvent(currentUser.id));
                  // Reset status to idle
                  context.read<SlotBloc>().add(ResetBookingStatusEvent());
                }

                // Handle Collision Conflict
                if (slotState.bookingStatus == 'conflict') {
                  _showConflictDialog(context, slotState.conflictedSlotTime ?? '');
                  // Reset status to idle
                  context.read<SlotBloc>().add(ResetBookingStatusEvent());
                }

                // Handle Error
                if (slotState.bookingStatus == 'error') {
                  PremiumSnackBar.show(
                    context,
                    message: slotState.bookingMessage ?? "Booking failed",
                    type: SnackBarType.error,
                  );
                  // Reset status to idle
                  context.read<SlotBloc>().add(ResetBookingStatusEvent());
                }
              }
            },
            child: Column(
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Select Date",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_month_rounded, color: Colors.tealAccent),
                            tooltip: "Select Custom Date",
                            onPressed: () => _selectDate(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDateTimeline(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFilterChip('All'),
                          _buildFilterChip('Morning'),
                          _buildFilterChip('Afternoon'),
                          _buildFilterChip('Evening'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Slots Grid View
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _loadSlots();
                    },
                    color: Colors.tealAccent,
                    child: BlocBuilder<SlotBloc, SlotState>(
                      builder: (context, state) {
                        if (state is SlotLoadingState || state is SlotInitialState) {
                          return _buildShimmerGrid();
                        }

                        if (state is SlotErrorState) {
                          return Center(
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
                                  onPressed: _loadSlots,
                                  child: const Text("Retry", style: TextStyle(color: Colors.tealAccent)),
                                ),
                              ],
                            ),
                          );
                        }

                        if (state is SlotLoadedState) {
                          final filteredSlots = state.slots.where((slot) {
                            if (_timeFilter == 'All') return true;
                            final parts = slot.slotTime.split(':');
                            if (parts.isEmpty) return false;
                            final hour = int.tryParse(parts[0]) ?? 0;
                            if (_timeFilter == 'Morning') {
                              return hour >= 6 && hour < 12;
                            } else if (_timeFilter == 'Afternoon') {
                              return hour >= 12 && hour < 17;
                            } else if (_timeFilter == 'Evening') {
                              return hour >= 17 && hour <= 22;
                            }
                            return true;
                          }).toList();

                          if (filteredSlots.isEmpty) {
                            return const Center(
                              child: Text(
                                "No slots available for this time range.",
                                style: TextStyle(color: Colors.white54, fontSize: 16),
                              ),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filteredSlots.length,
                            itemBuilder: (context, index) {
                              final slot = filteredSlots[index];
                              final bool isBooked = slot.isBooked;
                              final bool isBookedByMe = isBooked && slot.bookedByUserId == currentUser.id;

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

                              return AnimatedListItem(
                                index: index,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: cardBgColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderColors, width: 1.5),
                                  ),
                                  child: InkWell(
                                    onTap: isBooked ? null : () => _handleBooking(context, slot, currentUser.id),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Center(child: slotContent),
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
                ),
              ],
            ),
          ),
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
      duration: Duration(milliseconds: 300 + (index * 60)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
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
