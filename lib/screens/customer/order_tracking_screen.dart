import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../models/support_request_model.dart';
import '../../models/refund_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import 'contact_support_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  static const List<Map<String, dynamic>> _steps = [
    {
      'status': 'PLACED',
      'title': 'Order Placed',
      'description': 'Your craft order was received by the artisan.',
      'icon': Icons.receipt_long,
    },
    {
      'status': 'CONFIRMED',
      'title': 'Order Confirmed',
      'description': 'Artisan verified materials and confirmed craftsmanship.',
      'icon': Icons.check_circle_outline,
    },
    {
      'status': 'PREPARING',
      'title': 'Handcrafted with Care',
      'description': 'Artisan is packaging your traditional masterpiece.',
      'icon': Icons.handyman_outlined,
    },
    {
      'status': 'SHIPPED',
      'title': 'Dispatched for Delivery',
      'description': 'Package is en route with our verified rural courier partner.',
      'icon': Icons.local_shipping_outlined,
    },
    {
      'status': 'DELIVERED',
      'title': 'Delivered',
      'description': 'Handcrafted heritage has arrived safely at your doorstep.',
      'icon': Icons.home_work_outlined,
    },
  ];

  void _openReportIssueSheet(BuildContext context, OrderModel order) {
    final auth = AuthService();
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to report an issue.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final firestore = FirestoreService();
    final descriptionCtrl = TextEditingController();
    const issueCategories = [
      'Product not received',
      'Wrong product received',
      'Product damaged',
      'Artisan not responding',
      'Other',
    ];
    String selectedCategory = issueCategories.first;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.report_problem_outlined, color: AppTheme.error, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report an Issue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Select the reason describing the issue with your order:',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Categories
                    ...issueCategories.map((category) {
                      final isSelected = selectedCategory == category;
                      return InkWell(
                        onTap: isSubmitting
                            ? null
                            : () {
                                setSheetState(() => selectedCategory = category);
                              },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryContainer.withValues(alpha: 0.5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : AppTheme.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // Optional Description
                    TextField(
                      controller: descriptionCtrl,
                      maxLines: 3,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'Additional Description (Optional)',
                        hintText: 'Describe what happened or any specific details...',
                        labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Submit button
                    CustomButton(
                      text: 'Submit Issue',
                      isLoading: isSubmitting,
                      icon: Icons.check,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setSheetState(() => isSubmitting = true);
                              try {
                                final requestId = 'issue_${DateTime.now().millisecondsSinceEpoch}';
                                final request = SupportRequestModel(
                                  id: requestId,
                                  orderId: order.orderId,
                                  customerId: currentUser.uid,
                                  customerEmail: currentUser.email,
                                  type: 'ISSUE_REPORT',
                                  category: selectedCategory,
                                  description: descriptionCtrl.text.trim(),
                                  status: 'Issue Report Submitted',
                                  createdAt: DateTime.now(),
                                );
                                await firestore.createSupportRequest(request);
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Issue reported successfully. Our support team will investigate.'),
                                      backgroundColor: AppTheme.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => isSubmitting = false);
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to submit: $e'),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openRequestRefundSheet(BuildContext context, OrderModel order) async {
    final auth = AuthService();
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to request a refund.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final firestore = FirestoreService();
    final isAlreadyPending = await firestore.hasPendingRefundRequest(order.orderId);
    if (isAlreadyPending) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A refund request is already Under Review for this order. Duplicate submissions are not allowed.',
            ),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final descriptionCtrl = TextEditingController();
    const refundReasons = [
      'Product damaged / defective',
      'Product not received',
      'Wrong product received',
      'Artisan not responding',
      'Quality not as described',
      'Other',
    ];
    String selectedReason = refundReasons.first;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.currency_rupee, color: AppTheme.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Request Refund',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Order Amount: ₹${order.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: const Text(
                        'Refund requests are submitted to CraftConnect dispute review. Submitting does not automatically debit or refund money; our team verifies with the artisan.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF5D4037), height: 1.35),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Refund Reason:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    // Reasons
                    ...refundReasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return InkWell(
                        onTap: isSubmitting
                            ? null
                            : () {
                                setSheetState(() => selectedReason = reason);
                              },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryContainer.withValues(alpha: 0.5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : AppTheme.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // Optional Description
                    TextField(
                      controller: descriptionCtrl,
                      maxLines: 3,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'Reason Details (Optional)',
                        hintText: 'Share any extra details to help us review your refund request...',
                        labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Submit Refund Request button
                    CustomButton(
                      text: 'Submit Refund Request',
                      isLoading: isSubmitting,
                      icon: Icons.assignment_return_outlined,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setSheetState(() => isSubmitting = true);
                              try {
                                final requestId = 'REF-${DateTime.now().millisecondsSinceEpoch}';
                                final artisanId = order.artisanIds.isNotEmpty
                                    ? order.artisanIds.first
                                    : (order.items.isNotEmpty ? order.items.first.artisanId : '');

                                final refundRequest = RefundRequestModel(
                                  requestId: requestId,
                                  orderId: order.orderId,
                                  customerId: currentUser.uid,
                                  artisanId: artisanId,
                                  amount: order.totalAmount,
                                  reason: selectedReason,
                                  description: descriptionCtrl.text.trim().isNotEmpty
                                      ? descriptionCtrl.text.trim()
                                      : null,
                                  status: 'PENDING',
                                  createdAt: DateTime.now(),
                                );

                                await firestore.createRefundRequest(refundRequest);

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (dialogCtx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, color: AppTheme.success),
                                          SizedBox(width: 8),
                                          Text('Refund Request Submitted', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF8E1),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: const Color(0xFFFFD54F)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Request ID: $requestId',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                                ),
                                                const SizedBox(height: 6),
                                                const Text(
                                                  'Status: Under Review',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE65100)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          const Text(
                                            'Your refund request has been logged. Our customer support and dispute resolution team will review the order details with the artisan within 24–48 hours.\n\nNote: No money has been deducted or returned yet. This feature creates a refund request for review.',
                                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(dialogCtx),
                                          child: const Text('Understood'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => isSubmitting = false);
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to submit refund request: $e'),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openContactSupportScreen(BuildContext context, OrderModel order, {bool hasPendingRefund = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContactSupportScreen(
          order: order,
          hasPendingRefund: hasPendingRefund,
          onReportIssuePressed: () => _openReportIssueSheet(context, order),
          onRequestRefundPressed: () => _openRequestRefundSheet(context, order),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final firestore = FirestoreService();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final currentUid = auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Order Details & Tracking'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<OrderModel?>(
        stream: firestore.streamOrder(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Tracking your order...');
          }

          final order = snapshot.data;
          if (order == null) {
            return const Center(
              child: Text('Order not found.'),
            );
          }

          final currentStatus = order.status.toUpperCase();
          final currentStepIndex = OrderModel.statusFlow.indexOf(currentStatus);
          final isCustomerOwner = currentUid != null && currentUid == order.customerId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Overview Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.status,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Placed on ${dateFormat.format(order.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const Divider(height: 24, color: AppTheme.border),
                      Text(
                        'Destination: ${order.address}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Payable: ₹${order.totalAmount.toStringAsFixed(0)} (${order.paymentMethod})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Live Delivery Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Visual Tracking Timeline
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    final isPassed = index <= currentStepIndex;
                    final isCurrent = index == currentStepIndex;
                    final isLast = index == _steps.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step Indicator & Vertical Line
                          Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isPassed ? AppTheme.primary : const Color(0xFFEDE3D9),
                                  shape: BoxShape.circle,
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primary.withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  step['icon'] as IconData,
                                  size: 18,
                                  color: isPassed ? Colors.white : AppTheme.textMuted,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2.5,
                                    color: index < currentStepIndex
                                        ? AppTheme.primary
                                        : const Color(0xFFEDE3D9),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),

                          // Step description
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step['title'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isPassed ? FontWeight.w800 : FontWeight.w600,
                                      color: isPassed ? AppTheme.textPrimary : AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    step['description'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isPassed ? AppTheme.textSecondary : AppTheme.textMuted,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Order Items Accordion
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items in this Order',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.title} (x${item.quantity})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  '₹${item.subtotal.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),

                // ==================== NEED HELP? SECTION ====================
                // Appears ONLY on the Customer's Order Details screen for the order owner
                if (isCustomerOwner) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.help_outline, color: AppTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Need Help?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Have an issue with this order, need a refund, or want to contact CraftConnect support? Choose an option below:',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                        ),

                        // Real-time Refund Requests & Support Requests Stream
                        StreamBuilder<List<RefundRequestModel>>(
                          stream: firestore.streamOrderRefundRequests(order.orderId),
                          builder: (context, refundSnap) {
                            final refundList = refundSnap.data ?? [];
                            RefundRequestModel? pendingRefund;
                            for (final r in refundList) {
                              if (r.status.toUpperCase() == 'PENDING') {
                                pendingRefund = r;
                                break;
                              }
                            }
                            final hasPendingRefund = pendingRefund != null;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Active / Submitted Requests for this order
                                StreamBuilder<List<SupportRequestModel>>(
                                  stream: firestore.streamOrderSupportRequests(order.orderId),
                                  builder: (context, suppSnap) {
                                    final tickets = suppSnap.data ?? [];
                                    final hasAnyRequests = tickets.isNotEmpty || refundList.isNotEmpty;
                                    if (!hasAnyRequests) return const SizedBox.shrink();

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Submitted Requests:',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                          ),
                                          const SizedBox(height: 6),
                                          // Refund requests
                                          ...refundList.map((r) => Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFF8E1),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: const Color(0xFFFFD54F)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.currency_rupee, size: 16, color: Color(0xFFF57F17)),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              const Text(
                                                                'Refund Request Submitted',
                                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                              ),
                                                              Text(
                                                                r.status.toUpperCase() == 'PENDING'
                                                                    ? 'Status: Under Review'
                                                                    : 'Status: ${r.status}',
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 11,
                                                                  color: Color(0xFFE65100),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'Request ID: ${r.requestId} • ${r.reason} • ${dateFormat.format(r.createdAt)}',
                                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                          // Issue reports
                                          ...tickets.map((t) => Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFBE9E7),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: const Color(0xFFFFAB91)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.report_problem_outlined, size: 16, color: Color(0xFFD84315)),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            t.status,
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                          ),
                                                          Text(
                                                            '${t.category} • ${dateFormat.format(t.createdAt)}',
                                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Button 1: Report an Issue
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.textPrimary,
                                      side: const BorderSide(color: AppTheme.border, width: 1.2),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.report_problem_outlined, size: 18, color: AppTheme.warning),
                                    label: const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Report an Issue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                        Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textMuted),
                                      ],
                                    ),
                                    onPressed: () => _openReportIssueSheet(context, order),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Button 2: Request Refund (with duplicate prevention)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: hasPendingRefund ? const Color(0xFFE65100) : AppTheme.textPrimary,
                                      side: BorderSide(
                                        color: hasPendingRefund ? const Color(0xFFFFB74D) : AppTheme.border,
                                        width: 1.2,
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: Icon(
                                      hasPendingRefund ? Icons.hourglass_top : Icons.currency_rupee,
                                      size: 18,
                                      color: hasPendingRefund ? const Color(0xFFE65100) : AppTheme.primary,
                                    ),
                                    label: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          hasPendingRefund ? 'Refund Request Pending' : 'Request Refund',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: hasPendingRefund ? const Color(0xFFE65100) : AppTheme.textMuted,
                                        ),
                                      ],
                                    ),
                                    onPressed: hasPendingRefund
                                        ? () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'A refund request (ID: ${pendingRefund?.requestId ?? ''}) is already Under Review for this order. Duplicate submissions are not allowed.',
                                                ),
                                                backgroundColor: AppTheme.warning,
                                              ),
                                            );
                                          }
                                        : () => _openRequestRefundSheet(context, order),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Button 3: Contact Support
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.support_agent, size: 18, color: Colors.white),
                                    label: const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Contact Support', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                        Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white70),
                                      ],
                                    ),
                                    onPressed: () => _openContactSupportScreen(context, order, hasPendingRefund: hasPendingRefund),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
