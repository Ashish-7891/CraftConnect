import 'package:cloud_firestore/cloud_firestore.dart';

class RefundRequestModel {
  final String requestId;
  final String orderId;
  final String customerId;
  final String artisanId;
  final double amount;
  final String reason;
  final String? description;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED'
  final DateTime createdAt;

  RefundRequestModel({
    required this.requestId,
    required this.orderId,
    required this.customerId,
    required this.artisanId,
    required this.amount,
    required this.reason,
    this.description,
    this.status = 'PENDING',
    required this.createdAt,
  });

  factory RefundRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return RefundRequestModel.fromMap(data, doc.id);
  }

  factory RefundRequestModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        parsedDate = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        parsedDate = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    }

    return RefundRequestModel(
      requestId: id,
      orderId: data['orderId'] ?? '',
      customerId: data['customerId'] ?? '',
      artisanId: data['artisanId'] ?? '',
      amount: (data['amount'] is num) ? (data['amount'] as num).toDouble() : 0.0,
      reason: data['reason'] ?? '',
      description: data['description'],
      status: data['status'] ?? 'PENDING',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'orderId': orderId,
      'customerId': customerId,
      'artisanId': artisanId,
      'amount': amount,
      'reason': reason,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'orderId': orderId,
      'customerId': customerId,
      'artisanId': artisanId,
      'amount': amount,
      'reason': reason,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
