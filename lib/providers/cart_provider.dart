import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => {..._items};

  List<CartItemModel> get itemList => _items.values.toList();

  int get totalItemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.values.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Delivery calculation: Free delivery over ₹999, otherwise ₹50
  double get deliveryFee {
    if (_items.isEmpty) return 0.0;
    return subtotal >= 999.0 ? 0.0 : 50.0;
  }

  double get totalAmount => subtotal + deliveryFee;

  bool containsProduct(String productId) => _items.containsKey(productId);

  int getQuantity(String productId) => _items[productId]?.quantity ?? 0;

  /// Add product to cart, validating against available stock
  bool addToCart(ProductModel product, {int quantity = 1}) {
    if (product.stock <= 0) return false;

    if (_items.containsKey(product.productId)) {
      final currentQty = _items[product.productId]!.quantity;
      final newQty = currentQty + quantity;
      if (newQty > product.stock) {
        // Cap at available stock
        _items[product.productId]!.quantity = product.stock;
        notifyListeners();
        return false;
      }
      _items[product.productId]!.quantity = newQty;
    } else {
      final initialQty = quantity > product.stock ? product.stock : quantity;
      _items[product.productId] = CartItemModel(
        product: product,
        quantity: initialQty,
      );
    }
    notifyListeners();
    return true;
  }

  /// Increment quantity by 1, respecting stock limit
  bool incrementQuantity(String productId) {
    if (!_items.containsKey(productId)) return false;
    final item = _items[productId]!;
    if (item.quantity < item.product.stock) {
      item.quantity++;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Decrement quantity by 1; if it reaches 0, removes from cart
  void decrementQuantity(String productId) {
    if (!_items.containsKey(productId)) return;
    final item = _items[productId]!;
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  /// Remove item completely from cart
  void removeFromCart(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  /// Clear the entire cart (after successful order placement)
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
