import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'role_selection_screen.dart';
import 'artisan/artisan_dashboard.dart';
import 'customer/customer_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Artificial minimum delay for brand display
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      // Not logged in -> Role Selection / Login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
      return;
    }

    try {
      // User is logged in -> fetch role from Firestore
      final profile = await _authService.getUserProfile(currentUser.uid);
      if (!mounted) return;

      if (profile != null && profile.isArtisan) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ArtisanDashboard()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerDashboard()),
        );
      }
    } catch (e) {
      debugPrint('Error resolving user profile on splash: $e');
      if (!mounted) return;
      // Fallback if network issue or profile missing
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'CraftConnect',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'Connecting Artisans to the World',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
