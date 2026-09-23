import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String artisanId;
  final String artisanName;
  final String title;
  final String description;
  final String category;
  final String craftType;
  final String material;
  final String color;
  final List<String> tags;
  final String imageUrl;
  final double price;
  final int stock;
  final DateTime createdAt;
  final String status; // 'ACTIVE', 'INACTIVE'

  ProductModel({
    required this.productId,
    required this.artisanId,
    required this.artisanName,
    required this.title,
    required this.description,
    required this.category,
    required this.craftType,
    required this.material,
    required this.color,
    required this.tags,
    required this.imageUrl,
    required this.price,
    required this.stock,
    required this.createdAt,
    this.status = 'ACTIVE',
  });

  bool get isAvailable => status == 'ACTIVE' && stock > 0;

  factory ProductModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProductModel(
      productId: doc.id,
      artisanId: data['artisanId'] ?? '',
      artisanName: data['artisanName'] ?? 'Artisan',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Handicrafts',
      craftType: data['craftType'] ?? '',
      material: data['material'] ?? '',
      color: data['color'] ?? '',
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      stock: (data['stock'] is int) ? data['stock'] as int : int.tryParse(data['stock']?.toString() ?? '0') ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      status: data['status'] ?? 'ACTIVE',
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> data, String id) {
    return ProductModel(
      productId: id,
      artisanId: data['artisanId'] ?? '',
      artisanName: data['artisanName'] ?? 'Artisan',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Handicrafts',
      craftType: data['craftType'] ?? '',
      material: data['material'] ?? '',
      color: data['color'] ?? '',
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      stock: (data['stock'] is int) ? data['stock'] as int : int.tryParse(data['stock']?.toString() ?? '0') ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      status: data['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'artisanId': artisanId,
      'artisanName': artisanName,
      'title': title,
      'description': description,
      'category': category,
      'craftType': craftType,
      'material': material,
      'color': color,
      'tags': tags,
      'imageUrl': imageUrl,
      'price': price,
      'stock': stock,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  ProductModel copyWith({
    String? title,
    String? description,
    String? category,
    String? craftType,
    String? material,
    String? color,
    List<String>? tags,
    String? imageUrl,
    double? price,
    int? stock,
    String? status,
  }) {
    return ProductModel(
      productId: productId,
      artisanId: artisanId,
      artisanName: artisanName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      craftType: craftType ?? this.craftType,
      material: material ?? this.material,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
