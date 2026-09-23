import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/support_request_model.dart';
import '../models/refund_request_model.dart';

class ArtisanStats {
  final int totalProducts;
  final int totalOrders;
  final double totalSales;
  final double deliveredSales;
  final int pendingOrders;

  ArtisanStats({
    this.totalProducts = 0,
    this.totalOrders = 0,
    this.totalSales = 0.0,
    this.deliveredSales = 0.0,
    this.pendingOrders = 0,
  });
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== PRODUCTS ====================

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _supportRequestsRef =>
      _firestore.collection('support_requests');

  CollectionReference<Map<String, dynamic>> get _refundRequestsRef =>
      _firestore.collection('refund_requests');

  /// Create a new product in Firestore
  Future<void> createProduct(ProductModel product) async {
    try {
      await _productsRef.doc(product.productId).set(product.toFirestore());
    } catch (e) {
      debugPrint('Error creating product in Firestore: $e');
      rethrow;
    }
  }

  /// Update an existing product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _productsRef.doc(product.productId).update(product.toFirestore());
    } catch (e) {
      debugPrint('Error updating product in Firestore: $e');
      rethrow;
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsRef.doc(productId).delete();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  /// Quick stock update
  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _productsRef.doc(productId).update({
        'stock': newStock,
        if (newStock <= 0) 'status': 'OUT_OF_STOCK',
      });
    } catch (e) {
      debugPrint('Error updating stock: $e');
      rethrow;
    }
  }

  /// Get single product by ID
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _productsRef.doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching product $productId: $e');
      return null;
    }
  }

  /// Stream products created by a specific artisan (sorted in Dart to avoid composite index)
  Stream<List<ProductModel>> streamArtisanProducts(String artisanId) {
    return _productsRef
        .where('artisanId', isEqualTo: artisanId)
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return products;
        });
  }

  /// Stream all active products for the customer marketplace (sorted and filtered in Dart to eliminate composite index requirements)
  Stream<List<ProductModel>> streamMarketplaceProducts({
    String? category,
  }) {
    return _productsRef.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((p) => p.status.toUpperCase() == 'ACTIVE')
          .where((p) {
            if (category == null ||
                category.isEmpty ||
                category.toLowerCase() == 'all') {
              return true;
            }
            return p.category.toLowerCase() == category.toLowerCase();
          })
          .toList();

      // Sort newest first in memory (Dart) - completely eliminates composite index requirement
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  // ==================== ORDERS ====================

  /// Safely create customer order and decrement product inventory
  Future<void> createOrder(OrderModel order) async {
    // 1. Create the order document
    final orderDoc = _ordersRef.doc(order.orderId);
    try {
      await orderDoc.set(order.toFirestore());
      debugPrint('Order ${order.orderId} successfully placed in Firestore.');
    } catch (e) {
      debugPrint('Error placing order in Firestore: $e');
      rethrow;
    }

    // 2. Decrement stock for each item ordered
    if (order.items.isNotEmpty) {
      try {
        final batch = _firestore.batch();
        for (final item in order.items) {
          if (item.productId.isNotEmpty) {
            final productDoc = _productsRef.doc(item.productId);
            batch.update(productDoc, {
              'stock': FieldValue.increment(-item.quantity),
            });
          }
        }
        await batch.commit();
        debugPrint('Inventory stock successfully decremented for order ${order.orderId}.');
      } catch (e) {
        debugPrint('Warning: Order ${order.orderId} created, but stock decrement failed: $e');
      }
    }
  }

  /// Stream customer's personal orders (sorted in Dart to avoid composite index)
  Stream<List<OrderModel>> streamCustomerOrders(String customerId) {
    return _ordersRef
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// Stream orders relevant to an artisan (sorted in Dart to avoid composite index)
  Stream<List<OrderModel>> streamArtisanOrders(String artisanId) {
    return _ordersRef
        .where('artisanIds', arrayContains: artisanId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// Stream a single order for live tracking
  Stream<OrderModel?> streamOrder(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((doc) {
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Update order status with validation (disallow backward transitions)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final doc = await _ordersRef.doc(orderId).get();
      if (!doc.exists) {
        throw Exception('Order not found');
      }

      final currentStatus = (doc.data()?['status'] ?? 'PLACED').toString();
      if (!OrderModel.canTransition(currentStatus, newStatus)) {
        throw Exception(
            'Invalid status transition from $currentStatus to $newStatus.');
      }

      await _ordersRef.doc(orderId).update({
        'status': newStatus.toUpperCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }

  // ==================== ARTISAN STATS ====================

  /// Calculate real-time stats for artisan dashboard & earnings
  Future<ArtisanStats> getArtisanStats(String artisanId) async {
    try {
      // 1. Total products count
      final productsSnapshot = await _productsRef
          .where('artisanId', isEqualTo: artisanId)
          .get();
      final totalProducts = productsSnapshot.docs.length;

      // 2. Orders containing artisan's products
      final ordersSnapshot = await _ordersRef
          .where('artisanIds', arrayContains: artisanId)
          .get();

      int totalOrders = ordersSnapshot.docs.length;
      double totalSales = 0.0;
      double deliveredSales = 0.0;
      int pendingOrders = 0;

      for (final doc in ordersSnapshot.docs) {
        final order = OrderModel.fromFirestore(doc);
        // Calculate the portion of revenue belonging to this artisan
        double orderArtisanRevenue = 0.0;
        for (final item in order.items) {
          if (item.artisanId == artisanId) {
            orderArtisanRevenue += item.subtotal;
          }
        }

        totalSales += orderArtisanRevenue;

        if (order.status == 'DELIVERED') {
          deliveredSales += orderArtisanRevenue;
        } else {
          pendingOrders++;
        }
      }

      return ArtisanStats(
        totalProducts: totalProducts,
        totalOrders: totalOrders,
        totalSales: totalSales,
        deliveredSales: deliveredSales,
        pendingOrders: pendingOrders,
      );
    } catch (e) {
      debugPrint('Error calculating artisan stats: $e');
      return ArtisanStats();
    }
  }

  // ==================== SUPPORT & REFUND REQUESTS ====================

  /// Submit a customer support request (Issue or Refund)
  Future<void> createSupportRequest(SupportRequestModel request) async {
    try {
      await _supportRequestsRef.doc(request.id).set(request.toFirestore());
      debugPrint('Support request ${request.id} created for order ${request.orderId}');
    } catch (e) {
      debugPrint('Error creating support request: $e');
      rethrow;
    }
  }

  /// Stream support requests associated with a specific order
  Stream<List<SupportRequestModel>> streamOrderSupportRequests(String orderId) {
    return _supportRequestsRef
        .where('orderId', isEqualTo: orderId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => SupportRequestModel.fromFirestore(doc))
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  // ==================== REFUND REQUESTS ====================

  /// Stream refund requests associated with a specific order
  Stream<List<RefundRequestModel>> streamOrderRefundRequests(String orderId) {
    return _refundRequestsRef
        .where('orderId', isEqualTo: orderId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => RefundRequestModel.fromFirestore(doc))
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  /// Check whether an active PENDING refund request exists for the order
  Future<bool> hasPendingRefundRequest(String orderId) async {
    try {
      final snap = await _refundRequestsRef
          .where('orderId', isEqualTo: orderId)
          .where('status', isEqualTo: 'PENDING')
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pending refund request: $e');
      return false;
    }
  }

  /// Submit a refund request to refund_requests/{requestId}
  Future<void> createRefundRequest(RefundRequestModel request) async {
    try {
      final alreadyPending = await hasPendingRefundRequest(request.orderId);
      if (alreadyPending) {
        throw Exception(
            'A refund request is already PENDING for this order. Duplicate submissions are not allowed.');
      }
      await _refundRequestsRef.doc(request.requestId).set(request.toFirestore());
      debugPrint(
          'Refund request ${request.requestId} created for order ${request.orderId}');
    } catch (e) {
      debugPrint('Error creating refund request: $e');
      rethrow;
    }
  }
}
