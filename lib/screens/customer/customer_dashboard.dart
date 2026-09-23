import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'marketplace_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MarketplaceScreen(),
    CartScreen(),
    CustomerOrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().totalItemCount;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavItem(
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront,
            label: l10n.translate('marketplace'),
          ),
          BottomNavItem(
            icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart,
            label: l10n.translate('cart'),
            badgeCount: cartItemCount,
          ),
          BottomNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            label: l10n.translate('my_orders'),
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
}
