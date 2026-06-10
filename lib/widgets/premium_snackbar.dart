import 'package:flutter/material.dart';

enum SnackBarType { success, error, info }

class PremiumSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
  }) {
    // Clear any active snackbar immediately for responsiveness
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    IconData icon;
    Color iconColor;
    Color borderLeftColor;

    switch (type) {
      case SnackBarType.success:
        icon = Icons.check_circle_outline_rounded;
        iconColor = Colors.tealAccent.shade400;
        borderLeftColor = Colors.tealAccent.shade400;
        break;
      case SnackBarType.error:
        icon = Icons.error_outline_rounded;
        iconColor = Colors.redAccent;
        borderLeftColor = Colors.redAccent;
        break;
      case SnackBarType.info:
        icon = Icons.info_outline_rounded;
        iconColor = Colors.blueAccent;
        borderLeftColor = Colors.blueAccent;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF162D36),
        elevation: 6.0,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1.0,
          ),
        ),
        duration: const Duration(seconds: 3),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  color: borderLeftColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: iconColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
