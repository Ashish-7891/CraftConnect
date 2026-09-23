import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class FirebaseSetupScreen extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const FirebaseSetupScreen({
    super.key,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('CraftConnect Setup'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: AppTheme.warning,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Firebase Configuration Needed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'CraftConnect is a real, production-connected app. Please link your Firebase project to enable Authentication and Firestore (images are hosted on Cloudinary).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              if (errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text(
                'Setup Instructions (4 Steps):',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              _buildStepCard(
                step: '1',
                title: 'Register Android App in Firebase Console',
                description: 'Package Name:\ncom.sih.craftconnect.craftconnect',
              ),
              const SizedBox(height: 10),
              _buildStepCard(
                step: '2',
                title: 'Download google-services.json',
                description: 'Place the downloaded file into:\nmobile/android/app/google-services.json',
              ),
              const SizedBox(height: 10),
              _buildStepCard(
                step: '3',
                title: 'Enable Firebase Services',
                description: 'In Firebase Console, enable:\n• Authentication (Email/Password)\n• Cloud Firestore Database\n(Images are hosted via Cloudinary)',
              ),
              const SizedBox(height: 10),
              _buildStepCard(
                step: '4',
                title: 'Apply Security Rules',
                description: 'Deploy firestore.rules provided in this repository.',
              ),

              const SizedBox(height: 32),
              CustomButton(
                text: 'Retry Firebase Connection',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
