import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import 'venue_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Dynamically load users from backend API
    context.read<AuthBloc>().add(LoadUsersEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const VenueListScreen(),
              ),
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF2C5364),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Header Area
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.sports_tennis_rounded,
                        size: 64,
                        color: Colors.tealAccent.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "QuickSlot",
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Select a profile to continue",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // User selection container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1.0,
                        ),
                      ),
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthUsersLoadingState || state is AuthInitialState) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(color: Colors.tealAccent),
                              ),
                            );
                          }

                          if (state is AuthUsersErrorState) {
                            return Column(
                              children: [
                                const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 48),
                                const SizedBox(height: 12),
                                const Text(
                                  "Failed to load profiles.",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state.message.contains("SocketException") 
                                      ? "Check network connection or backend state."
                                      : state.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF142930),
                                    foregroundColor: Colors.tealAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    context.read<AuthBloc>().add(LoadUsersEvent());
                                  },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text("Retry"),
                                ),
                              ],
                            );
                          }

                          if (state is AuthUsersLoadedState) {
                            final users = state.users;
                            if (users.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No users found in database.",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "LIVE PROFILES",
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.tealAccent.shade400,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: users.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final user = users[index];
                                    return InkWell(
                                      onTap: () {
                                        context.read<AuthBloc>().add(LoginEvent(user));
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.08),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Colors.tealAccent.shade700.withOpacity(0.2),
                                              child: Text(
                                                user.name.substring(0, 1).toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.tealAccent.shade400,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "ID: ${user.id} • Registered User",
                                                    style: const TextStyle(
                                                      color: Colors.white38,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 16,
                                              color: Colors.white.withOpacity(0.3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          }

                          return const SizedBox();
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "TODO(security): Mock authorization used for testing.\nIn production, implement a secure authentication workflow.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
