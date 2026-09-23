import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _showApiKeyDialog(BuildContext context) async {
    final currentKey = await GeminiService.getApiKey();
    final controller = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gemini API Key Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Gemini API Key for product cataloging. You can also pass it via --dart-define=GEMINI_API_KEY=...',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'AIzaSy...',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await GeminiService.setApiKey(controller.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gemini API key updated successfully!')),
                );
              }
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Gemini API Key Settings',
            icon: const Icon(Icons.key, color: AppTheme.primaryLight),
            onPressed: () => _showApiKeyDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Brand Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.20),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'CraftConnect',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),

                const Text(
                  'Connecting Artisans to the World',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.20),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.handyman_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'From Handmade\nto Market Ready',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'AI-powered smart cataloging for rural & marginalized artisans. Reach customers across India with fair pricing and direct market access.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose how you want to continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Artisan Role Card
                _RoleCard(
                  icon: Icons.storefront_outlined,
                  title: "I'm an Artisan",
                  subtitle: 'Photograph crafts, auto-generate catalogs with AI, and sell directly.',
                  filled: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(initialRole: 'ARTISAN'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Customer Role Card
                _RoleCard(
                  icon: Icons.shopping_bag_outlined,
                  title: "I'm a Customer",
                  subtitle: 'Discover verified authentic handmade crafts directly from artisans.',
                  filled: false,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(initialRole: 'CUSTOMER'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: filled ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: filled ? AppTheme.primary : AppTheme.border,
              width: 1.2,
            ),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.18),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppTheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: filled ? Colors.white : AppTheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: filled ? Colors.white : AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: filled
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: filled ? Colors.white : AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
