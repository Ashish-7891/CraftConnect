import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/product_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Uint8List? _imageBytes;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _craftTypeController = TextEditingController();
  final _materialController = TextEditingController();
  final _colorController = TextEditingController();
  final _tagsController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '10');

  String _selectedCategory = 'Handicrafts';
  final List<String> _categories = [
    'Pottery',
    'Textiles',
    'Woodcraft',
    'Jewellery',
    'Paintings',
    'Handicrafts',
    'Bamboo',
    'Metal Craft',
    'Other'
  ];

  bool _isAnalyzingAI = false;
  bool _isPublishing = false;
  String? _aiSuggestedPriceText;
  String? _statusMessage;
  List<String> _tags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _craftTypeController.dispose();
    _materialController.dispose();
    _colorController.dispose();
    _tagsController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file == null) {
        // User cancelled image selection - no error
        return;
      }
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _statusMessage = null;
        _aiSuggestedPriceText = null;
        // Requirements 10 & 11:
        // Clear all previous analysis and catalog state when a new image is selected
        _titleController.clear();
        _descriptionController.clear();
        _craftTypeController.clear();
        _materialController.clear();
        _colorController.clear();
        _tagsController.clear();
        _priceController.clear();
        _tags = [];
        _selectedCategory = 'Handicrafts';
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Product Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryContainer,
                  child: Icon(Icons.camera_alt, color: AppTheme.primary),
                ),
                title: const Text('Capture with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryContainer,
                  child: Icon(Icons.photo_library, color: AppTheme.primary),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeWithAI() async {
    if (_isAnalyzingAI || _isPublishing) return;

    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or capture a product image first.')),
      );
      return;
    }

    final currentBytes = _imageBytes!;
    debugPrint('AddProductScreen: Analyzing current image (${currentBytes.length} bytes)');

    setState(() {
      _isAnalyzingAI = true;
      _statusMessage = 'Gemini AI is analyzing your craft...';
    });

    try {
      final result = await GeminiService.analyzeProductImage(
        imageBytes: currentBytes,
        onStatusUpdate: (status) {
          if (mounted) {
            setState(() {
              _statusMessage = status;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _titleController.text = result.title;
        _descriptionController.text = result.description;
        _craftTypeController.text = result.craftType;
        _materialController.text = result.material;
        _colorController.text = result.color;
        _tags = result.tags;
        _tagsController.text = _tags.join(', ');

        if (_categories.contains(result.category)) {
          _selectedCategory = result.category;
        }

        _aiSuggestedPriceText =
            '₹${result.suggestedPriceMin.toStringAsFixed(0)} - ₹${result.suggestedPriceMax.toStringAsFixed(0)}';
        _priceController.text = result.suggestedPriceMid.toStringAsFixed(0);
        _statusMessage = 'AI analysis complete! Review and adjust values below.';
      });
    } catch (e) {
      debugPrint('Gemini AI analysis error: $e');
      if (!mounted) return;
      const displayMessage =
          'Gemini AI is temporarily unavailable. You can enter product details manually below.';
      setState(() {
        _statusMessage = displayMessage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(displayMessage),
          backgroundColor: AppTheme.primary,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzingAI = false;
        });
      }
    }
  }

  Future<bool> _showCloudinaryConfigDialog() async {
    final currentCloud = await CloudinaryService.getCloudName();
    final currentPreset = await CloudinaryService.getUploadPreset();
    if (!mounted) return false;

    final cloudController = TextEditingController(text: currentCloud);
    final presetController = TextEditingController(text: currentPreset);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload_outlined, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Cloudinary Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cloudinary unsigned uploads host your product images securely without any API secrets in the app.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cloudController,
                decoration: const InputDecoration(
                  labelText: 'Cloud Name',
                  hintText: 'e.g. dxyz12345',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cloud_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: presetController,
                decoration: const InputDecoration(
                  labelText: 'Unsigned Upload Preset',
                  hintText: 'e.g. craftconnect_preset',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_open_outlined),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Note: You can also pass these at build time using:\n'
                '--dart-define=CLOUDINARY_CLOUD_NAME=...\n'
                '--dart-define=CLOUDINARY_UPLOAD_PRESET=...',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cloud = cloudController.text.trim();
              final preset = presetController.text.trim();
              if (cloud.isEmpty || preset.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter both Cloud Name and Upload Preset')),
                );
                return;
              }
              await CloudinaryService.setConfig(
                cloudName: cloud,
                uploadPreset: preset,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _publishProduct() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a product image before publishing.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to publish products.')),
      );
      return;
    }

    final isCloudReady = await CloudinaryService.isConfigured();
    if (!isCloudReady) {
      final configured = await _showCloudinaryConfigDialog();
      if (!configured) return;
    }

    setState(() {
      _isPublishing = true;
      _statusMessage = 'Uploading product image to Cloudinary...';
    });

    try {
      final productId = const Uuid().v4();

      // 1. Upload image to Cloudinary using unsigned upload preset
      final downloadUrl = await CloudinaryService.uploadImage(
        bytes: _imageBytes!,
        folder: 'craftconnect/products/${currentUser.uid}',
        filename: '$productId.jpg',
      );

      setState(() {
        _statusMessage = 'Saving catalog details to Firestore...';
      });

      // 2. Fetch artisan profile for display name
      final profile = await _authService.getUserProfile(currentUser.uid);
      final artisanName = profile?.name ?? currentUser.displayName ?? 'Artisan';

      // Parse tags
      final tagList = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final newProduct = ProductModel(
        productId: productId,
        artisanId: currentUser.uid,
        artisanName: artisanName,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        craftType: _craftTypeController.text.trim(),
        material: _materialController.text.trim(),
        color: _colorController.text.trim(),
        tags: tagList,
        imageUrl: downloadUrl,
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        stock: int.tryParse(_stockController.text.trim()) ?? 10,
        createdAt: DateTime.now(),
        status: 'ACTIVE',
      );

      // 3. Save to Firestore
      await _firestoreService.createProduct(newProduct);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Handcrafted product published successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error publishing product: $e');
      if (!mounted) return;

      String displayError = e.toString().replaceFirst('Exception: ', '');
      if (e is FirebaseException) {
        displayError = 'Firestore error: ${e.message ?? e.code}';
      } else if (displayError.contains('No internet connection') ||
          displayError.contains('SocketException')) {
        displayError = 'No internet connection. Please check your network and try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayError),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 5),
          action: displayError.contains('Cloudinary')
              ? SnackBarAction(
                  label: 'Configure',
                  textColor: Colors.white,
                  onPressed: () => _showCloudinaryConfigDialog(),
                )
              : null,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _statusMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Add Handcrafted Product'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Cloudinary Image Settings',
            icon: const Icon(Icons.cloud_queue_outlined),
            onPressed: _showCloudinaryConfigDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Picker Container
                InkWell(
                  onTap: _isPublishing || _isAnalyzingAI ? null : _showImageSourceDialog,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _imageBytes != null ? AppTheme.primary : AppTheme.border,
                        width: _imageBytes != null ? 2 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageBytes != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.70),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Change Photo',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: AppTheme.primary,
                                size: 44,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Tap to take or choose photo of craft',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Supports Camera or Gallery',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // AI Analyze Action Button
                CustomButton(
                  text: 'Analyze with Gemini AI',
                  icon: Icons.auto_awesome,
                  onPressed: _imageBytes != null && !_isPublishing && !_isAnalyzingAI
                      ? _analyzeWithAI
                      : null,
                  isLoading: _isAnalyzingAI,
                  backgroundColor: AppTheme.accent,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'AI Cataloging is optional. Product details can be entered manually anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),

                if (_statusMessage != null) ...[
                  Builder(
                    builder: (context) {
                      final isUnavailable = _statusMessage!.contains('temporarily unavailable') ||
                          _statusMessage!.contains('temporarily busy') ||
                          _statusMessage!.contains('failed') ||
                          _statusMessage!.contains('error');
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isUnavailable
                              ? AppTheme.accent.withValues(alpha: 0.1)
                              : AppTheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUnavailable
                                ? AppTheme.accent.withValues(alpha: 0.4)
                                : AppTheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUnavailable ? Icons.info_outline : Icons.check_circle_outline,
                              size: 18,
                              color: isUnavailable ? AppTheme.accent : AppTheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUnavailable ? AppTheme.textPrimary : AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // AI Suggested Price Badge
                if (_aiSuggestedPriceText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, color: AppTheme.accent),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Suggested Price Range',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _aiSuggestedPriceText!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Form Fields
                const Text(
                  'Product Title',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Handcrafted Terracotta Pitcher',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please provide a title';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Category Dropdown
                const Text(
                  'Category',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border, width: 1.2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Craft Type & Material in a row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Craft Type',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _craftTypeController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Clay Throwing',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Material',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _materialController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. River Clay',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Color
                const Text(
                  'Dominant Color',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Terracotta Red & Dark Ochre',
                  ),
                ),
                const SizedBox(height: 14),

                // Description
                const Text(
                  'Product Story & Description',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe the heritage, making process, and uniqueness...',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please provide a description';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Price & Stock
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selling Price (₹ INR)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixText: '₹ ',
                              hintText: '750',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter price';
                              if (double.tryParse(val.trim()) == null) return 'Valid number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stock Quantity',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '10',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter stock';
                              if (int.tryParse(val.trim()) == null) return 'Valid integer';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tags
                const Text(
                  'Search Tags (Comma separated)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    hintText: 'handmade, terracotta, pot, kitchen, eco-friendly',
                  ),
                ),
                const SizedBox(height: 28),

                // Publish Button
                CustomButton(
                  text: 'Publish to Marketplace',
                  icon: Icons.cloud_upload_outlined,
                  onPressed: _isPublishing || _isAnalyzingAI ? null : _publishProduct,
                  isLoading: _isPublishing,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
