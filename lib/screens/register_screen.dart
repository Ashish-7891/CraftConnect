import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import 'artisan/artisan_dashboard.dart';
import 'customer/customer_dashboard.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String initialRole;

  const RegisterScreen({
    super.key,
    this.initialRole = 'CUSTOMER',
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  late String _selectedRole;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        role: _selectedRole,
      );

      if (!mounted) return;

      // Navigate directly to the corresponding role dashboard
      if (user.isArtisan) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ArtisanDashboard()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerDashboard()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join CraftConnect',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign up to link handmade crafts to fair nationwide markets',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Role Selector Pills
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE3D9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedRole = 'ARTISAN'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'ARTISAN' ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.storefront_outlined,
                                  size: 18,
                                  color: _selectedRole == 'ARTISAN' ? Colors.white : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Artisan Seller',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedRole == 'ARTISAN' ? Colors.white : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedRole = 'CUSTOMER'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'CUSTOMER' ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 18,
                                  color: _selectedRole == 'CUSTOMER' ? Colors.white : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Customer Buyer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedRole == 'CUSTOMER' ? Colors.white : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Full Name
                const Text(
                  'Full Name',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Ramesh Kumar or Meera Bai',
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                const Text(
                  'Email Address',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your email';
                    if (!val.contains('@') || !val.contains('.')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                const Text(
                  'Phone Number (Optional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+91 98765 43210',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                const Text(
                  'Password',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter a password';
                    if (val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                const Text(
                  'Confirm Password',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppTheme.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please confirm your password';
                    if (val != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'Register Account',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
