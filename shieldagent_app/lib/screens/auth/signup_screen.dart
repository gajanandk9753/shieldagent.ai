import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/primary_button.dart';
import '../buyer/buyer_nav_bar.dart';
import '../vendor/vendor_nav_bar.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final String role;
  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _budgetController = TextEditingController();

  bool get _isVendor => widget.role == AgentRole.vendor;
  Color get _accent =>
      _isVendor ? AppColors.vendorAccent : AppColors.buyerAccent;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final success = await auth.register(
      role: widget.role,
      displayName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      budgetLimit: _isVendor
          ? null
          : double.tryParse(_budgetController.text.trim()),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => _isVendor ? const VendorShell() : const BuyerShell(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? "Signup failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isVendor ? "Vendor Sign Up" : "Buyer Sign Up"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create your account",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isVendor
                      ? "Register SteelWorks-style — you'll get an API key for your vendor script."
                      : "Set a budget — this is the hard ceiling ShieldAgent enforces.",
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13.5),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: _isVendor ? "Company Name" : "Agent Name",
                  controller: _nameController,
                  prefixIcon: _isVendor
                      ? Icons.storefront_outlined
                      : Icons.smart_toy_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "This field is required"
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Email",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: (v) =>
                      (v == null || !v.contains("@")) ? "Enter a valid email" : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Password",
                  controller: _passwordController,
                  obscure: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) =>
                      (v == null || v.length < 6) ? "Minimum 6 characters" : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Confirm Password",
                  controller: _confirmController,
                  obscure: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) => v != _passwordController.text
                      ? "Passwords don't match"
                      : null,
                ),
                if (!_isVendor) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: "Budget Limit (₹)",
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.account_balance_wallet_outlined,
                    validator: (v) => (v == null ||
                            double.tryParse(v.trim()) == null)
                        ? "Enter a valid amount"
                        : null,
                  ),
                ],
                const SizedBox(height: 28),
                PrimaryButton(
                  label: "Create Account",
                  isLoading: auth.isLoading,
                  color: _accent,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(role: widget.role),
                        ),
                      );
                    },
                    child: const Text(
                      "Already have an account? Log in",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
