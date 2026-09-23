import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'Newest'; // 'Newest', 'Price: Low to High', 'Price: High to Low'
  double _maxPriceFilter = 25000;

  final List<String> _categories = [
    'All',
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sort & Filter',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _sortBy = 'Newest';
                          _maxPriceFilter = 25000;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'Sort By',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Newest', 'Price: Low to High', 'Price: High to Low'].map((sort) {
                    final isSelected = _sortBy == sort;
                    return ChoiceChip(
                      label: Text(sort),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() => _sortBy = sort);
                          setState(() => _sortBy = sort);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Max Price',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '₹${_maxPriceFilter.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ],
                ),
                Slider(
                  value: _maxPriceFilter,
                  min: 100,
                  max: 25000,
                  divisions: 50,
                  activeColor: AppTheme.primary,
                  onChanged: (val) {
                    setModalState(() => _maxPriceFilter = val);
                    setState(() => _maxPriceFilter = val);
                  },
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primary, size: 22),
            SizedBox(width: 8),
            Text('CraftConnect Marketplace'),
          ],
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter Products',
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search craft, pottery, silk, brass, tags...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                ),
              ),
            ),

            // Horizontal Categories Pills
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;

                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                      width: 1.2,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Products Stream Grid
            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: _firestoreService.streamMarketplaceProducts(
                  category: _selectedCategory,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget(message: 'Exploring artisan crafts...');
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Error loading products: ${snapshot.error}'),
                      ),
                    );
                  }

                  var products = snapshot.data ?? [];

                  // Apply client-side search query across title, category, craftType, tags, and materials
                  if (_searchQuery.isNotEmpty) {
                    products = products.where((p) {
                      final matchTitle = p.title.toLowerCase().contains(_searchQuery);
                      final matchCategory = p.category.toLowerCase().contains(_searchQuery);
                      final matchCraft = p.craftType.toLowerCase().contains(_searchQuery);
                      final matchMaterial = p.material.toLowerCase().contains(_searchQuery);
                      final matchTags = p.tags.any((t) => t.toLowerCase().contains(_searchQuery));
                      return matchTitle || matchCategory || matchCraft || matchMaterial || matchTags;
                    }).toList();
                  }

                  // Max price filter
                  products = products.where((p) => p.price <= _maxPriceFilter).toList();

                  // Sort
                  if (_sortBy == 'Price: Low to High') {
                    products.sort((a, b) => a.price.compareTo(b.price));
                  } else if (_sortBy == 'Price: High to Low') {
                    products.sort((a, b) => b.price.compareTo(a.price));
                  } else {
                    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  }

                  if (products.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off_outlined,
                      title: 'No Crafts Found',
                      message: _searchQuery.isNotEmpty
                          ? 'No products matched "$_searchQuery". Try different search terms or categories.'
                          : 'No handcrafted products currently in this category. Check back soon!',
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];

                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CustomerProductDetailScreen(product: product),
                            ),
                          );
                        },
                        onAddToCart: () {
                          final cart = Provider.of<CartProvider>(context, listen: false);
                          final added = cart.addToCart(product);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(added
                                  ? 'Added "${product.title}" to Cart!'
                                  : 'Cannot add more (stock limit reached).'),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'VIEW CART',
                                onPressed: () {},
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
