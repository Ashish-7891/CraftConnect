import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

class ArtisanProductDetailScreen extends StatefulWidget {
  final String productId;

  const ArtisanProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ArtisanProductDetailScreen> createState() => _ArtisanProductDetailScreenState();
}

class _ArtisanProductDetailScreenState extends State<ArtisanProductDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  ProductModel? _product;
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;
  late TextEditingController _craftTypeController;
  late TextEditingController _materialController;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final product = await _firestoreService.getProduct(widget.productId);
    if (!mounted) return;

    if (product != null) {
      _titleController = TextEditingController(text: product.title);
      _priceController = TextEditingController(text: product.price.toStringAsFixed(0));
      _stockController = TextEditingController(text: product.stock.toString());
      _descriptionController = TextEditingController(text: product.description);
      _craftTypeController = TextEditingController(text: product.craftType);
      _materialController = TextEditingController(text: product.material);

      setState(() {
        _product = product;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    if (_product != null) {
      _titleController.dispose();
      _priceController.dispose();
      _stockController.dispose();
      _descriptionController.dispose();
      _craftTypeController.dispose();
      _materialController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_product == null || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updated = _product!.copyWith(
        title: _titleController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? _product!.price,
        stock: int.tryParse(_stockController.text.trim()) ?? _product!.stock,
        description: _descriptionController.text.trim(),
        craftType: _craftTypeController.text.trim(),
        material: _materialController.text.trim(),
      );

      await _firestoreService.updateProduct(updated);

      if (!mounted) return;
      setState(() => _product = updated);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading product details...'),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Detail')),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: _product!.imageUrl.isNotEmpty
                        ? Image.network(
                            _product!.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: const Color(0xFFF3ECE4),
                              child: const Icon(Icons.broken_image, size: 48, color: AppTheme.textMuted),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF3ECE4),
                            child: const Icon(Icons.handyman, size: 48, color: AppTheme.primaryLight),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text('Title', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Price & Stock
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Price (₹)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(prefixText: '₹ '),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Stock', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Craft & Material
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Craft Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 6),
                          TextFormField(controller: _craftTypeController),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Material', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 6),
                          TextFormField(controller: _materialController),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: 'Save Changes',
                  onPressed: _isSaving ? null : _saveChanges,
                  isLoading: _isSaving,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
