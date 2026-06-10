import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/venue/venue_bloc.dart';
import '../data/models.dart';
import '../widgets/shimmer_loading.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';
import 'venue_details_screen.dart';

class VenueListScreen extends StatefulWidget {
  const VenueListScreen({super.key});

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    context.read<VenueBloc>().add(LoadVenuesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildCategoryChip(String category) {
    final bool isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(
        category,
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
            _selectedCategory = category;
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

  Widget _buildShimmerList() {
    return ShimmerLoading(
      isLoading: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: const Color(0xFF162D36).withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.03)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Venue> _filterVenues(List<Venue> venues) {
    final query = _searchController.text.toLowerCase();
    return venues.where((v) {
      final nameMatches = v.name.toLowerCase().contains(query) || v.location.toLowerCase().contains(query);
      if (!nameMatches) return false;
      
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Badminton') return v.name.toLowerCase().contains('badminton');
      if (_selectedCategory == 'Football') return v.name.toLowerCase().contains('football') || v.name.toLowerCase().contains('turf');
      if (_selectedCategory == 'Cricket') return v.name.toLowerCase().contains('cricket');
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthenticatedState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          });
          return const SizedBox();
        }

        final currentUser = authState.user;

        return Scaffold(
          backgroundColor: const Color(0xFF0F1E24),
          appBar: AppBar(
            backgroundColor: const Color(0xFF142930),
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "QuickSlot Venues",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  "Logged in as: ${currentUser.name}",
                  style: TextStyle(
                    color: Colors.tealAccent.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: "My Bookings",
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.bookmark_added_rounded, size: 28),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.tealAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyBookingsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: "Logout",
                icon: const Icon(Icons.logout_rounded),
                onPressed: () async {
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
                      title: const Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      content: const Text(
                        "Are you sure you want to log out of your session?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.redAccent.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            "Logout",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    context.read<AuthBloc>().add(LogoutEvent());
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                color: const Color(0xFF142930),
                child: Column(
                  children: [
                    // Glassmorphic Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Search arenas, locations...",
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                          border: InputBorder.none,
                          icon: Icon(Icons.search_rounded, color: Colors.tealAccent.shade400),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Categories Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCategoryChip('All'),
                        _buildCategoryChip('Badminton'),
                        _buildCategoryChip('Football'),
                        _buildCategoryChip('Cricket'),
                      ],
                    ),
                  ],
                ),
              ),

              // Venues List with Refresh Indicator
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<VenueBloc>().add(LoadVenuesEvent());
                  },
                  color: Colors.tealAccent.shade400,
                  backgroundColor: const Color(0xFF142930),
                  child: BlocBuilder<VenueBloc, VenueState>(
                    builder: (context, state) {
                      if (state is VenueLoadingState || state is VenueInitialState) {
                        return _buildShimmerList();
                      }

                      if (state is VenueErrorState) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                                const SizedBox(height: 16),
                                Text(
                                  "Network error: Unable to connect to backend",
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Ensure your FastAPI server is running.",
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white38),
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
                                    context.read<VenueBloc>().add(LoadVenuesEvent());
                                  },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text("Retry Connection"),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state is VenueLoadedState) {
                        final filtered = _filterVenues(state.venues);

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sports_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                const Text(
                                  "No matching venues found",
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final venue = filtered[index];

                            // Dynamically assign icons based on name
                            IconData venueIcon = Icons.sports_tennis_rounded;
                            Color accentColor = Colors.tealAccent;
                            if (venue.name.toLowerCase().contains("turf") || venue.name.toLowerCase().contains("football")) {
                              venueIcon = Icons.sports_soccer_rounded;
                              accentColor = Colors.lightGreenAccent.shade400;
                            } else if (venue.name.toLowerCase().contains("badminton")) {
                              venueIcon = Icons.sports_cricket_rounded;
                              accentColor = Colors.orangeAccent;
                            }

                            // Dynamic ratings & amenities for premium feel
                            final rating = (4.5 + (index % 5) * 0.1).toStringAsFixed(1);
                            final amenities = index % 3 == 0 
                                ? ["AC Available", "Locker Room"] 
                                : (index % 3 == 1 ? ["Parking", "Lounge"] : ["Cafeteria", "AC Available"]);

                            return AnimatedListItem(
                              index: index,
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                color: const Color(0xFF162D36),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.05),
                                    width: 1.0,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VenueDetailsScreen(venue: venue),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        // Venue Icon container
                                        Container(
                                          height: 64,
                                          width: 64,
                                          decoration: BoxDecoration(
                                            color: accentColor.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: accentColor.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            venueIcon,
                                            size: 32,
                                            color: accentColor,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // Venue details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                venue.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on_rounded,
                                                    size: 14,
                                                    color: Colors.white38,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      venue.location,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.star_rounded, color: Colors.amber.shade400, size: 16),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "$rating Rating",
                                                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  ...amenities.map((amenity) => Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.tealAccent.withOpacity(0.08),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      amenity,
                                                      style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.w500),
                                                    ),
                                                  )),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white.withOpacity(0.3),
                                          size: 28,
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
              ),
            ],
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
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 35 * (1 - value)),
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
