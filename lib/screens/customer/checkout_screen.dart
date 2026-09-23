import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  String _paymentMethod = 'Cash on Delivery (COD)';
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  void _prefillUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      final profile = await _authService.getUserProfile(user.uid);
      if (profile != null) {
        if (_nameController.text.isEmpty) _nameController.text = profile.name;
        if (profile.phone != null) _phoneController.text = profile.phone!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.itemList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty.')),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to complete checkout.')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final orderId = const Uuid().v4();

      final fullAddress =
          '${_addressController.text.trim()}, ${_cityController.text.trim()}, ${_stateController.text.trim()} - ${_pincodeController.text.trim()}';

      // Build Order Items
      final orderItems = cart.itemList.map((ci) {
        return OrderItemModel(
          productId: ci.product.productId,
          title: ci.product.title,
          imageUrl: ci.product.imageUrl,
          price: ci.product.price,
          quantity: ci.quantity,
          artisanId: ci.product.artisanId,
          artisanName: ci.product.artisanName,
        );
      }).toList();

      // Collect all artisan IDs participating in this order
      final artisanIds = orderItems.map((i) => i.artisanId).toSet().toList();

      final newOrder = OrderModel(
        orderId: orderId,
        customerId: user.uid,
        customerName: _nameController.text.trim(),
        items: orderItems,
        artisanIds: artisanIds,
        totalAmount: cart.totalAmount,
        address: fullAddress,
        phone: _phoneController.text.trim(),
        status: 'PLACED',
        paymentMethod: _paymentMethod,
        createdAt: DateTime.now(),
      );

      // Create order atomically in Firestore and decrement product stock
      await _firestoreService.createOrder(newOrder);

      // Clear the local cart
      cart.clear();

      if (!mounted) return;

      // Celebrate and navigate to Tracking Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
        ),
      );
    } catch (e) {
      debugPrint('Error placing order: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Checkout & Delivery'),
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
                // Delivery Address Section
                const Text(
                  'Shipping Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Full Name',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Street Address / Colony / House No.',
                          prefixIcon: Icon(Icons.home_outlined, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(labelText: 'City / District'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(labelText: 'State'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter state' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Postal PIN Code'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter PIN code' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Method
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _paymentMethod = 'Cash on Delivery (COD)'),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                _paymentMethod == 'Cash on Delivery (COD)'
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cash on Delivery (COD)',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    Text(
                                      'Pay when authentic craft arrives at your doorstep',
                                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.border),
                      InkWell(
                        onTap: () => setState(() => _paymentMethod = 'Demo UPI / Online Payment'),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                _paymentMethod == 'Demo UPI / Online Payment'
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Demo UPI on Delivery',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    Text(
                                      'Scan QR via GPay / PhonePe upon delivery',
                                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Order Summary Card
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      ...cart.itemList.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.product.title} (x${item.quantity})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  '₹${item.subtotal.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 20, color: AppTheme.border),
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
                          const Text('Delivery', style: TextStyle(color: AppTheme.textSecondary)),
                          Text(
                            cart.deliveryFee == 0.0 ? 'FREE' : '₹${cart.deliveryFee.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cart.deliveryFee == 0.0 ? AppTheme.success : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: AppTheme.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '₹${cart.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Place Order Button
                CustomButton(
                  text: 'Confirm & Place Order',
                  icon: Icons.check_circle_outline,
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  isLoading: _isPlacingOrder,
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
