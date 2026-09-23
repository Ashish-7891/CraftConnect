import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';

class CustomerProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const CustomerProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock <= 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Large Image
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppTheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFF3ECE4),
                        child: const Icon(Icons.broken_image, size: 60, color: AppTheme.textMuted),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF3ECE4),
                      child: const Icon(Icons.handyman, size: 60, color: AppTheme.primaryLight),
                    ),
            ),
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Stock Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? AppTheme.error.withValues(alpha: 0.12)
                              : AppTheme.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOutOfStock ? 'Out of Stock' : 'In Stock (${product.stock} units)',
                          style: TextStyle(
                            color: isOutOfStock ? AppTheme.error : AppTheme.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Product Title
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Price
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '(Inclusive of all taxes)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Artisan Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          child: Text(
                            product.artisanName.isNotEmpty ? product.artisanName[0].toUpperCase() : 'A',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    product.artisanName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, color: AppTheme.accent, size: 16),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Verified Rural Artisan Partner',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Craft specifications 2x2
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _buildSpecRow(Icons.handyman_outlined, 'Craft Technique', product.craftType),
                        const Divider(height: 20, color: AppTheme.border),
                        _buildSpecRow(Icons.category_outlined, 'Material', product.material),
                        const Divider(height: 20, color: AppTheme.border),
                        _buildSpecRow(Icons.palette_outlined, 'Color Tones', product.color),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Story & AI Description
                  const Text(
                    'Artisan Craft Story',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search tags chips
                  if (product.tags.isNotEmpty) ...[
                    const Text(
                      'Keywords & Tags',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1E7DD),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '#$t',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Bar with Add to Cart & Buy Now
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppTheme.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Add to Cart',
                  icon: Icons.add_shopping_cart,
                  isOutlined: true,
                  onPressed: isOutOfStock
                      ? null
                      : () {
                          final cart = Provider.of<CartProvider>(context, listen: false);
                          final added = cart.addToCart(product);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(added
                                  ? 'Added to cart!'
                                  : 'Cannot add more (stock limit reached).'),
                              action: SnackBarAction(
                                label: 'VIEW CART',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const CartScreen()),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Buy Now',
                  onPressed: isOutOfStock
                      ? null
                      : () {
                          final cart = Provider.of<CartProvider>(context, listen: false);
                          cart.addToCart(product);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                          );
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryLight),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value.isNotEmpty ? value : 'Traditional',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
