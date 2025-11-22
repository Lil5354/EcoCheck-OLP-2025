import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/presentation/widgets/buttons/primary_button.dart';
import 'package:eco_check/presentation/widgets/inputs/custom_text_field.dart';
import 'package:eco_check/presentation/widgets/dialogs/dialogs.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (!mounted) return;

    // Show success
    showSuccessDialog(
      context,
      'Đăng ký thành công!',
      'Vui lòng đăng nhập để tiếp tục.',
      onConfirm: () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Back to login
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full Name
                CustomTextField(
                  controller: _fullNameController,
                  labelText: AppStrings.fullName,
                  prefixIcon: const Icon(Icons.person, color: AppColors.grey),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.fieldRequired;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Phone Input
                PhoneInput(
                  controller: _phoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.fieldRequired;
                    }
                    if (value.length != 10) {
                      return AppStrings.invalidPhone;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  controller: _emailController,
                  labelText: '${AppStrings.email} (Tùy chọn)',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email, color: AppColors.grey),
                ),

                const SizedBox(height: 16),

                // Password Input
                PasswordInput(
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.fieldRequired;
                    }
                    if (value.length < 6) {
                      return AppStrings.passwordTooShort;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password
                PasswordInput(
                  controller: _confirmPasswordController,
                  labelText: AppStrings.confirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.fieldRequired;
                    }
                    if (value != _passwordController.text) {
                      return AppStrings.passwordNotMatch;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Register Button
                PrimaryButton(
                  text: AppStrings.register,
                  onPressed: _register,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.alreadyHaveAccount,
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        AppStrings.login,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
