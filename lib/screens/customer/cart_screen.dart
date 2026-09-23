import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.itemList.isEmpty) {
            return EmptyState(
              icon: Icons.remove_shopping_cart_outlined,
              title: 'Your Cart is Empty',
              message: 'Discover unique handmade crafts made with love by Indian rural artisans.',
              buttonText: 'Explore Marketplace',
              onButtonPressed: () {
                Navigator.of(context).pop();
              },
            );
          }

          return Column(
            children: [
              // Free delivery banner notice
              if (cart.subtotal < 999)
                Container(
                  width: double.infinity,
                  color: AppTheme.primaryContainer.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Add ₹${(999 - cart.subtotal).toStringAsFixed(0)} more for FREE Nationwide Delivery!',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Item List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.itemList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cart.itemList[index];
                    final product = item.product;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        color: const Color(0xFFF0E6DC),
                                        child: const Icon(Icons.image, color: AppTheme.textMuted),
                                      ),
                                    )
                                  : Container(
                                      color: const Color(0xFFF0E6DC),
                                      child: const Icon(Icons.handyman, color: AppTheme.primaryLight),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Title and price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'By ${product.artisanName}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₹${item.subtotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Quantity controls
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => cart.decrementQuantity(product.productId),
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Icon(Icons.remove, size: 16, color: AppTheme.textPrimary),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    final incremented = cart.incrementQuantity(product.productId);
                                    if (!incremented) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Cannot exceed available artisan stock limit.'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Icon(Icons.add, size: 16, color: AppTheme.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                            onPressed: () => cart.removeFromCart(product.productId),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Checkout Bottom Summary Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(top: BorderSide(color: AppTheme.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(color: AppTheme.textSecondary)),
                          Text('₹${cart.subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery Fee', style: TextStyle(color: AppTheme.textSecondary)),
                          Text(
                            cart.deliveryFee == 0.0 ? 'FREE' : '₹${cart.deliveryFee.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cart.deliveryFee == 0.0 ? AppTheme.success : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18, color: AppTheme.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '₹${cart.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Proceed to Checkout',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
