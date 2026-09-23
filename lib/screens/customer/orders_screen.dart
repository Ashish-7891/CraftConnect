import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import 'order_tracking_screen.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return const Color(0xFFE65100);
      case 'CONFIRMED':
        return const Color(0xFF1976D2);
      case 'PREPARING':
        return const Color(0xFF8E24AA);
      case 'SHIPPED':
        return const Color(0xFF00796B);
      case 'DELIVERED':
        return AppTheme.success;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final firestore = FirestoreService();
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your orders.')),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: firestore.streamCustomerOrders(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Retrieving your orders...');
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading orders: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Orders Yet',
              message: 'When you purchase artisanal crafts, you can track their status here in real time.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final statusColor = _getStatusColor(order.status);

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(orderId: order.orderId),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.orderId.substring(0, order.orderId.length > 8 ? 8 : order.orderId.length).toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      const Divider(height: 18, color: AppTheme.border),
                      Text(
                        '${order.items.length} item(s): ${order.items.map((e) => e.title).join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: ₹${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                          const Row(
                            children: [
                              Text(
                                'Track Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.primary),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
