import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  void _showStockDialog(BuildContext context, ProductModel product, FirestoreService service) {
    final controller = TextEditingController(text: product.stock.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Stock: ${product.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter new inventory stock count:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Available Quantity',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(controller.text.trim());
              if (newStock != null && newStock >= 0) {
                await service.updateStock(product.productId, newStock);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stock updated successfully!')),
                  );
                }
              }
            },
            child: const Text('Save Stock'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel product, FirestoreService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await service.deleteProduct(product.productId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted successfully.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final firestore = FirestoreService();
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your catalog.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Products Catalog'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Add Product'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: firestore.streamArtisanProducts(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading your products...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading catalog: ${snapshot.error}'),
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No Products Yet',
              message: 'Take a photo of your craft and let Gemini AI automatically create your catalog!',
              buttonText: 'Add First Product',
              onButtonPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
              },
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ArtisanProductDetailScreen(productId: product.productId),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      // Product thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 80,
                          height: 80,
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

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.category,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '₹${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => _showStockDialog(context, product, firestore),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: product.stock > 0
                                          ? AppTheme.success.withValues(alpha: 0.12)
                                          : AppTheme.error.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Stock: ${product.stock}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: product.stock > 0
                                                ? AppTheme.success
                                                : AppTheme.error,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.edit, size: 11, color: AppTheme.textMuted),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Actions popup
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
                        onSelected: (val) {
                          if (val == 'stock') {
                            _showStockDialog(context, product, firestore);
                          } else if (val == 'delete') {
                            _confirmDelete(context, product, firestore);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'stock',
                            child: Row(
                              children: [
                                Icon(Icons.inventory, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Stock'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: AppTheme.error, size: 18),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: AppTheme.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
