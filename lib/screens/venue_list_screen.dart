import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/venue/venue_bloc.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';
import 'venue_details_screen.dart';

class VenueListScreen extends StatefulWidget {
  const VenueListScreen({super.key});

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  @override
  void initState() {
    super.initState();
    // Load venues on entry
    context.read<VenueBloc>().add(LoadVenuesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthenticatedState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutEvent());
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<VenueBloc>().add(LoadVenuesEvent());
            },
            color: Colors.tealAccent.shade400,
            backgroundColor: const Color(0xFF142930),
            child: BlocBuilder<VenueBloc, VenueState>(
              builder: (context, state) {
                if (state is VenueLoadingState || state is VenueInitialState) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                    ),
                  );
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
                  final venues = state.venues;
                  if (venues.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          const Text(
                            "No venues available right now",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: venues.length,
                    itemBuilder: (context, index) {
                      final venue = venues[index];

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

                      return Card(
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
                                // Venue Icon container with specific background
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.schedule_rounded,
                                              size: 12,
                                              color: accentColor,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              "6:00 AM - 10:00 PM Daily",
                                              style: TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
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
