import 'package:cloud_firestore/cloud_firestore.dart';

class SupportRequestModel {
  final String id;
  final String orderId;
  final String customerId;
  final String? customerEmail;
  final String type; // 'ISSUE_REPORT' or 'REFUND_REQUEST'
  final String category; // Issue category or refund reason
  final String? description;
  final String status; // e.g. 'Issue Report Submitted' or 'Refund Request Submitted'
  final DateTime createdAt;

  SupportRequestModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    this.customerEmail,
    required this.type,
    required this.category,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory SupportRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return SupportRequestModel.fromMap(data, doc.id);
  }

  factory SupportRequestModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        parsedDate = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        parsedDate = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    }

    return SupportRequestModel(
      id: id,
      orderId: data['orderId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerEmail: data['customerEmail'],
      type: data['type'] ?? 'ISSUE_REPORT',
      category: data['category'] ?? '',
      description: data['description'],
      status: data['status'] ?? 'Submitted',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'orderId': orderId,
      'customerId': customerId,
      if (customerEmail != null && customerEmail!.isNotEmpty)
        'customerEmail': customerEmail,
      'type': type,
      'category': category,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'customerId': customerId,
      if (customerEmail != null && customerEmail!.isNotEmpty)
        'customerEmail': customerEmail,
      'type': type,
      'category': category,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
