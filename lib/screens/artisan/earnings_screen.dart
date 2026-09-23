import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widget.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  late Future<ArtisanStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final uid = _authService.currentUser?.uid ?? '';
    _statsFuture = _firestoreService.getArtisanStats(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Artisan Earnings & Revenue'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<ArtisanStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Calculating earnings from orders...');
          }

          final stats = snapshot.data ?? ArtisanStats();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadStats();
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Earnings Hero Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Sales Revenue',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${stats.totalSales.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'From ${stats.totalOrders} total orders received',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Order Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Metrics 2x2 Grid
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle_outline,
                          iconColor: AppTheme.success,
                          title: 'Delivered Sales',
                          value: '₹${stats.deliveredSales.toStringAsFixed(0)}',
                          subtitle: 'Realized Revenue',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.hourglass_top_outlined,
                          iconColor: AppTheme.warning,
                          title: 'Pending Orders',
                          value: '${stats.pendingOrders}',
                          subtitle: 'In Progress / Transit',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.shopping_bag_outlined,
                          iconColor: AppTheme.primary,
                          title: 'Total Orders',
                          value: '${stats.totalOrders}',
                          subtitle: 'All customer orders',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.inventory_2_outlined,
                          iconColor: AppTheme.accent,
                          title: 'Active Products',
                          value: '${stats.totalProducts}',
                          subtitle: 'In your catalog',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Payout info note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: AppTheme.primary, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Direct Artisan Bank Settlement',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Earnings are calculated from verified Firestore orders and settled directly to your registered bank account without middlemen commissions.',
                                style: TextStyle(
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
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
