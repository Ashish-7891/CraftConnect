import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class ArtisanOrdersScreen extends StatelessWidget {
  const ArtisanOrdersScreen({super.key});

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

  void _updateStatus(BuildContext context, OrderModel order, String newStatus, FirestoreService firestore) async {
    try {
      await firestore.updateOrderStatus(order.orderId, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as $newStatus!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final firestore = FirestoreService();
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view orders.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Customer Orders'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: firestore.streamArtisanOrders(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading orders...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading orders: ${snapshot.error}'),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Orders Yet',
              message: 'When customers purchase your handcrafted creations, their orders will appear here.',
            );
          }

          final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final order = orders[index];
              final statusColor = _getStatusColor(order.status);
              final nextStatus = order.nextStatus;

              // Filter items that belong to this artisan
              final artisanItems = order.items.where((i) => i.artisanId == uid).toList();
              final artisanTotal = artisanItems.fold(0.0, (s, i) => s + i.subtotal);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Order ID & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${order.orderId.substring(0, order.orderId.length > 8 ? 8 : order.orderId.length).toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateFormat.format(order.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppTheme.border),

                    // Customer info
                    Row(
                      children: [
                        const Icon(Icons.person_pin, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (order.phone.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.phone, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            order.phone,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                    if (order.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Deliver to: ${order.address}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Items list
                    const Text(
                      'Ordered Items:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 6),
                    ...artisanItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '• ${item.title} (x${item.quantity})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '₹${item.subtotal.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 10),

                    // Order Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Revenue Portion:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                        Text(
                          '₹${artisanTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),

                    // Next Status Action Button (Forward transition only)
                    if (nextStatus != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getStatusColor(nextStatus),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _updateStatus(context, order, nextStatus, firestore),
                          child: Text(
                            'Mark as $nextStatus',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
