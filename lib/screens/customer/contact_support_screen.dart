import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';

class ContactSupportScreen extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onReportIssuePressed;
  final VoidCallback? onRequestRefundPressed;
  final bool hasPendingRefund;

  const ContactSupportScreen({
    super.key,
    required this.order,
    this.onReportIssuePressed,
    this.onRequestRefundPressed,
    this.hasPendingRefund = false,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortOrderId = order.orderId.length > 8
        ? order.orderId.substring(0, 8).toUpperCase()
        : order.orderId.toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Contact Support'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Reference Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_outlined, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Regarding Order #$shortOrderId',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Current Status: ${order.status} • ₹${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Header Message
            const Text(
              'How can we assist you?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Our dedicated artisan support team is here to assist you with order delivery, craftsmanship questions, or artisan communication.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Official Support Channels Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  // Email Support
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.email_outlined, color: AppTheme.primary, size: 20),
                    ),
                    title: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('support@craftconnect.in', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: AppTheme.primary),
                      tooltip: 'Copy Email',
                      onPressed: () => _copyToClipboard(context, 'support@craftconnect.in', 'Support Email'),
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.border),

                  // Phone Helpline
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.phone_in_talk_outlined, color: AppTheme.primary, size: 20),
                    ),
                    title: const Text('Toll-Free Helpline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('1800-202-CRAFT (Mon - Sat, 9 AM - 6 PM)', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: AppTheme.primary),
                      tooltip: 'Copy Number',
                      onPressed: () => _copyToClipboard(context, '18002022723', 'Helpline Number'),
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.border),

                  // Response SLA
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.access_time, color: AppTheme.primary, size: 20),
                    ),
                    title: const Text('Turnaround Time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Support inquiries are addressed within 24 to 48 hours.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Resolution Options Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F5F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppTheme.accent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Direct Order Actions',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Need faster resolution? You can log an issue or initiate a refund request directly on this order for prioritized review.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (onReportIssuePressed != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.report_problem_outlined, size: 16, color: AppTheme.primary),
                            label: const Text('Report Issue', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(context);
                              onReportIssuePressed!();
                            },
                          ),
                        ),
                      if (onReportIssuePressed != null && onRequestRefundPressed != null)
                        const SizedBox(width: 10),
                      if (onRequestRefundPressed != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: hasPendingRefund ? AppTheme.accent : AppTheme.primary,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: Icon(
                              hasPendingRefund ? Icons.hourglass_top : Icons.currency_rupee,
                              size: 16,
                              color: hasPendingRefund ? AppTheme.accent : AppTheme.primary,
                            ),
                            label: Text(
                              hasPendingRefund ? 'Refund Pending' : 'Request Refund',
                              style: TextStyle(
                                fontSize: 12,
                                color: hasPendingRefund ? AppTheme.accent : AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              if (hasPendingRefund) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('A refund request is already Under Review for this order.'),
                                    backgroundColor: AppTheme.warning,
                                  ),
                                );
                              } else {
                                Navigator.pop(context);
                                onRequestRefundPressed!();
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            CustomButton(
              text: 'Back to Order Details',
              isOutlined: true,
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
