import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final bool showArtisan;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.showArtisan = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock <= 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with category and stock badges
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.1,
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFF3ECE4),
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppTheme.textMuted,
                                size: 36,
                              ),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: const Color(0xFFF7F2EC),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryLight,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFFF3ECE4),
                            child: const Center(
                              child: Icon(
                                Icons.handyman_outlined,
                                color: AppTheme.primaryLight,
                                size: 40,
                              ),
                            ),
                          ),
                  ),

                  // Category pill
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Stock warning if low or out
                  if (isOutOfStock)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else if (product.stock < 5)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Only ${product.stock} left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Product Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showArtisan && product.artisanName.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.verified, size: 13, color: AppTheme.accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.artisanName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (showArtisan && product.artisanName.isNotEmpty)
                      const SizedBox(height: 4),

                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                        if (onAddToCart != null && !isOutOfStock)
                          Material(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: onAddToCart,
                              borderRadius: BorderRadius.circular(10),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.add_shopping_cart,
                                  size: 18,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
