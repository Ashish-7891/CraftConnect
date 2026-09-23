import 'package:flutter_test/flutter_test.dart';
import 'package:craftconnect/models/refund_request_model.dart';

void main() {
  group('RefundRequestModel Specification & Firestore Rules Compatibility', () {
    test('RefundRequestModel.toFirestore() contains all required fields with status PENDING', () {
      final now = DateTime(2026, 9, 23, 10, 30);
      final refund = RefundRequestModel(
        requestId: 'REF-1727065000000',
        orderId: 'order_12345',
        customerId: 'cust_abc123',
        artisanId: 'artisan_xyz789',
        amount: 950.0,
        reason: 'Product damaged / defective',
        description: 'Pottery handle was cracked on arrival.',
        status: 'PENDING',
        createdAt: now,
      );

      final firestoreMap = refund.toFirestore();
      expect(firestoreMap['requestId'], 'REF-1727065000000');
      expect(firestoreMap['orderId'], 'order_12345');
      expect(firestoreMap['customerId'], 'cust_abc123');
      expect(firestoreMap['artisanId'], 'artisan_xyz789');
      expect(firestoreMap['amount'], 950.0);
      expect(firestoreMap['reason'], 'Product damaged / defective');
      expect(firestoreMap['description'], 'Pottery handle was cracked on arrival.');
      expect(firestoreMap['status'], 'PENDING');
      expect(firestoreMap.containsKey('createdAt'), true);

      // Verify status is strictly PENDING and does not claim processed refund
      expect(firestoreMap['status'], isNot('REFUNDED'));
      expect(firestoreMap['status'], isNot('APPROVED'));
    });

    test('RefundRequestModel deserialization parses from Firestore map correctly', () {
      final data = {
        'orderId': 'order_999',
        'customerId': 'cust_001',
        'artisanId': 'artisan_002',
        'amount': 1450.50,
        'reason': 'Wrong product received',
        'description': 'Received brass bell instead of diya.',
        'status': 'PENDING',
        'createdAt': '2026-09-23T10:30:00.000',
      };

      final parsed = RefundRequestModel.fromMap(data, 'REF-999000');
      expect(parsed.requestId, 'REF-999000');
      expect(parsed.orderId, 'order_999');
      expect(parsed.customerId, 'cust_001');
      expect(parsed.artisanId, 'artisan_002');
      expect(parsed.amount, 1450.50);
      expect(parsed.reason, 'Wrong product received');
      expect(parsed.description, 'Received brass bell instead of diya.');
      expect(parsed.status, 'PENDING');
    });

    test('RefundRequestModel handles null and whitespace descriptions safely', () {
      final refundNoDesc = RefundRequestModel(
        requestId: 'REF-111',
        orderId: 'order_111',
        customerId: 'cust_111',
        artisanId: 'artisan_111',
        amount: 300.0,
        reason: 'Other',
        description: '   ',
        status: 'PENDING',
        createdAt: DateTime.now(),
      );

      final map = refundNoDesc.toFirestore();
      expect(map.containsKey('description'), false);
    });
  });
}
