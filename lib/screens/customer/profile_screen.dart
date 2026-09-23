import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../role_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  void _showEditProfileDialog(BuildContext context, UserModel user) {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('edit_profile')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: l10n.translate('full_name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: InputDecoration(labelText: l10n.translate('phone_number')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = user.copyWith(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              await _authService.updateProfile(updated);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('profile_updated'))),
                );
              }
            },
            child: Text(l10n.translate('save')),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final currentCode = localeProvider.currentLanguageCode;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.language, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              l10n.translate('select_language'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppLocalizations.supportedLanguages.map((lang) {
              final code = lang['code']!;
              final isSelected = code == currentCode;

              return ListTile(
                leading: Icon(
                  Icons.translate,
                  color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                  size: 20,
                ),
                title: Text(
                  lang['nativeName']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
                subtitle: code != 'en'
                    ? Text(
                        lang['name']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                        ),
                      )
                    : null,
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 22)
                    : null,
                onTap: () async {
                  await localeProvider.setLocale(Locale(code));
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) async {
    final currentKey = await GeminiService.getApiKey();
    final controller = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Gemini API Key for product catalog generation:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
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
                  const SnackBar(content: Text('Gemini API key saved!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCloudinaryDialog(BuildContext context) async {
    final currentCloud = await CloudinaryService.getCloudName();
    final currentPreset = await CloudinaryService.getUploadPreset();
    final cloudController = TextEditingController(text: currentCloud);
    final presetController = TextEditingController(text: currentPreset);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload_outlined, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Cloudinary Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure Cloudinary image storage for your artisan product uploads:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cloudController,
                decoration: const InputDecoration(
                  labelText: 'Cloud Name',
                  hintText: 'e.g. dxyz12345',
                  prefixIcon: Icon(Icons.cloud_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: presetController,
                decoration: const InputDecoration(
                  labelText: 'Unsigned Upload Preset',
                  hintText: 'e.g. craftconnect_preset',
                  prefixIcon: Icon(Icons.lock_open_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cloud = cloudController.text.trim();
              final preset = presetController.text.trim();
              if (cloud.isEmpty || preset.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter both Cloud Name and Upload Preset')),
                );
                return;
              }
              await CloudinaryService.setConfig(
                cloudName: cloud,
                uploadPreset: preset,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cloudinary settings saved successfully!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('sign_out_title')),
        content: Text(l10n.translate('sign_out_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(l10n.translate('sign_out_title')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();

    if (uid == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Not logged in'),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Go to Login',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.translate('account_profile')),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<UserModel?>(
        stream: _authService.streamUserProfile(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading profile...');
          }

          final user = snapshot.data ??
              UserModel(
                uid: uid,
                name: _authService.currentUser?.displayName ?? 'User',
                email: _authService.currentUser?.email ?? '',
                role: 'CUSTOMER',
              );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar & Name Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          user.isArtisan
                              ? l10n.translate('artisan_partner')
                              : l10n.translate('verified_customer'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Account Details & Settings Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone_outlined, color: AppTheme.primary),
                        title: Text(l10n.translate('phone_number')),
                        subtitle: Text(user.phone?.isNotEmpty == true
                            ? user.phone!
                            : l10n.translate('not_specified')),
                        trailing: const Icon(Icons.edit, size: 16, color: AppTheme.textMuted),
                        onTap: () => _showEditProfileDialog(context, user),
                      ),
                      const Divider(height: 1, color: AppTheme.border),
                      // Language Selection Option - Visible for both Customer and Artisan
                      ListTile(
                        leading: const Icon(Icons.language, color: AppTheme.primary),
                        title: Text(
                          l10n.translate('language'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${localeProvider.currentLanguageNativeName} (${localeProvider.currentLanguageName})',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                        onTap: () => _showLanguageSelectionDialog(context),
                      ),
                      if (user.isArtisan) ...[
                        const Divider(height: 1, color: AppTheme.border),
                        ListTile(
                          leading: const Icon(Icons.cloud_queue_outlined, color: AppTheme.primary),
                          title: Text(l10n.translate('cloudinary_settings')),
                          subtitle: Text(l10n.translate('cloudinary_subtitle')),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                          onTap: () => _showCloudinaryDialog(context),
                        ),
                      ],
                      const Divider(height: 1, color: AppTheme.border),
                      ListTile(
                        leading: const Icon(Icons.key_outlined, color: AppTheme.accent),
                        title: Text(l10n.translate('gemini_vision_api_key')),
                        subtitle: Text(l10n.translate('gemini_subtitle')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                        onTap: () => _showApiKeyDialog(context),
                      ),
                      const Divider(height: 1, color: AppTheme.border),
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
                        title: Text(l10n.translate('about_craftconnect')),
                        subtitle: const Text('Empowering Artisans, Connecting Markets'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Edit Profile Button
                CustomButton(
                  text: l10n.translate('edit_profile_info'),
                  isOutlined: true,
                  icon: Icons.edit_outlined,
                  onPressed: () => _showEditProfileDialog(context, user),
                ),
                const SizedBox(height: 14),

                // Logout Button
                CustomButton(
                  text: l10n.translate('sign_out'),
                  icon: Icons.logout,
                  backgroundColor: AppTheme.error,
                  textColor: Colors.white,
                  onPressed: () => _confirmLogout(context),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
