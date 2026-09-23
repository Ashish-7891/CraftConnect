import 'package:flutter_test/flutter_test.dart';
import 'package:craftconnect/models/support_request_model.dart';

void main() {
  group('SupportRequestModel Serialization & Firestore Compatibility', () {
    test('Issue Report toFirestore and toMap contain all expected fields', () {
      final now = DateTime(2026, 9, 23, 10, 30);
      final issueRequest = SupportRequestModel(
        id: 'issue_123456789',
        orderId: 'order_test_999',
        customerId: 'customer_uid_123',
        customerEmail: 'customer@example.com',
        type: 'ISSUE_REPORT',
        category: 'Product damaged',
        description: 'The ceramic pot had a crack near the handle.',
        status: 'Issue Report Submitted',
        createdAt: now,
      );

      final map = issueRequest.toMap();
      expect(map['id'], 'issue_123456789');
      expect(map['orderId'], 'order_test_999');
      expect(map['customerId'], 'customer_uid_123');
      expect(map['customerEmail'], 'customer@example.com');
      expect(map['type'], 'ISSUE_REPORT');
      expect(map['category'], 'Product damaged');
      expect(map['description'], 'The ceramic pot had a crack near the handle.');
      expect(map['status'], 'Issue Report Submitted');
      expect(map['createdAt'], now.toIso8601String());

      final firestoreMap = issueRequest.toFirestore();
      expect(firestoreMap['id'], 'issue_123456789');
      expect(firestoreMap['orderId'], 'order_test_999');
      expect(firestoreMap['customerId'], 'customer_uid_123');
      expect(firestoreMap['type'], 'ISSUE_REPORT');
      expect(firestoreMap['category'], 'Product damaged');
      expect(firestoreMap['description'], 'The ceramic pot had a crack near the handle.');
      expect(firestoreMap['status'], 'Issue Report Submitted');
      expect(firestoreMap.containsKey('createdAt'), true);
    });

    test('Refund Request does not claim processed refund and maintains request status', () {
      final now = DateTime.now();
      final refundRequest = SupportRequestModel(
        id: 'refund_987654321',
        orderId: 'order_test_555',
        customerId: 'cust_777',
        customerEmail: 'artisanbuyer@example.com',
        type: 'REFUND_REQUEST',
        category: 'Wrong product received',
        description: 'Received blue scarf instead of red embroidered shawl.',
        status: 'Refund Request Submitted',
        createdAt: now,
      );

      expect(refundRequest.status, 'Refund Request Submitted');
      expect(refundRequest.status, isNot(contains('Refunded')));
      expect(refundRequest.type, 'REFUND_REQUEST');

      final parsed = SupportRequestModel.fromMap(refundRequest.toMap(), refundRequest.id);
      expect(parsed.id, 'refund_987654321');
      expect(parsed.orderId, 'order_test_555');
      expect(parsed.category, 'Wrong product received');
      expect(parsed.status, 'Refund Request Submitted');
    });

    test('SupportRequestModel handles optional description gracefully', () {
      final request = SupportRequestModel(
        id: 'issue_no_desc',
        orderId: 'order_123',
        customerId: 'cust_456',
        type: 'ISSUE_REPORT',
        category: 'Artisan not responding',
        description: null,
        status: 'Issue Report Submitted',
        createdAt: DateTime.now(),
      );

      final firestoreMap = request.toFirestore();
      expect(firestoreMap.containsKey('description'), false);

      final parsed = SupportRequestModel.fromMap(firestoreMap, 'issue_no_desc');
      expect(parsed.description, isNull);
    });
  });
}
