import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/loading_widget.dart';
import 'add_product_screen.dart';
import 'my_products_screen.dart';
import 'artisan_orders_screen.dart';
import 'earnings_screen.dart';
import '../customer/profile_screen.dart';

class ArtisanDashboard extends StatefulWidget {
  const ArtisanDashboard({super.key});

  @override
  State<ArtisanDashboard> createState() => _ArtisanDashboardState();
}

class _ArtisanDashboardState extends State<ArtisanDashboard> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  late Future<ArtisanStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  void _refreshStats() {
    final uid = _authService.currentUser?.uid ?? '';
    setState(() {
      _statsFuture = _firestoreService.getArtisanStats(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final List<Widget> pages = [
      _buildHomeView(),
      const MyProductsScreen(),
      const ArtisanOrdersScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 0) _refreshStats();
          });
        },
        items: [
          BottomNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: l10n.translate('dashboard'),
          ),
          BottomNavItem(
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2,
            label: l10n.translate('my_products'),
          ),
          BottomNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            label: l10n.translate('orders'),
          ),
          BottomNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: l10n.translate('profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    final user = _authService.currentUser;
    final displayName = user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Artisan Partner';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refreshStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $displayName 🙏',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'CraftConnect Artisan Studio',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hero AI Cataloging Callout Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Gemini Vision AI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ready to add a new handmade creation?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Just take a photo. Gemini will identify materials, craft technique, write the story, and suggest pricing.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        minimumSize: const Size(160, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AddProductScreen()),
                        ).then((_) => _refreshStats());
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Add Product Now',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Real-time Firestore Dashboard Statistics
              const Text(
                'Studio Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              FutureBuilder<ArtisanStats>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget(message: 'Loading live statistics...');
                  }

                  final stats = snapshot.data ?? ArtisanStats();

                  return Row(
                    children: [
                      Expanded(
                        child: _StatMetricCard(
                          title: 'Total Sales',
                          value: '₹${stats.totalSales.toStringAsFixed(0)}',
                          icon: Icons.currency_rupee,
                          iconColor: AppTheme.success,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const EarningsScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatMetricCard(
                          title: 'Total Orders',
                          value: '${stats.totalOrders}',
                          icon: Icons.shopping_bag_outlined,
                          iconColor: AppTheme.primary,
                          onTap: () => setState(() => _currentIndex = 2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatMetricCard(
                          title: 'Products',
                          value: '${stats.totalProducts}',
                          icon: Icons.inventory_2_outlined,
                          iconColor: AppTheme.accent,
                          onTap: () => setState(() => _currentIndex = 1),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Quick Actions Grid
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _ActionCard(
                    title: 'Add Product',
                    subtitle: 'AI Auto-Catalog',
                    icon: Icons.add_photo_alternate_outlined,
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddProductScreen()),
                      ).then((_) => _refreshStats());
                    },
                  ),
                  _ActionCard(
                    title: 'My Products',
                    subtitle: 'Manage inventory',
                    icon: Icons.list_alt_rounded,
                    color: AppTheme.accent,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _ActionCard(
                    title: 'Customer Orders',
                    subtitle: 'Process deliveries',
                    icon: Icons.local_shipping_outlined,
                    color: const Color(0xFF1976D2),
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                  _ActionCard(
                    title: 'Earnings',
                    subtitle: 'Sales & payouts',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppTheme.success,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EarningsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _StatMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
