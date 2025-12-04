/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/presentation/widgets/buttons/primary_button.dart';
import 'package:eco_check/presentation/widgets/inputs/custom_text_field.dart';
import 'package:eco_check/presentation/widgets/dialogs/dialogs.dart';
import 'package:eco_check/presentation/blocs/auth/auth_bloc.dart';
import 'package:eco_check/presentation/blocs/auth/auth_event.dart';
import 'package:eco_check/presentation/blocs/auth/auth_state.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    print('📱 [LOGIN] Dispatching login event...');
    // Dispatch login event to AuthBloc
    context.read<AuthBloc>().add(
      LoginRequested(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        print('📱 [LOGIN] State changed to: ${state.runtimeType}');

        if (state is AuthError) {
          print('📱 [LOGIN] Error: ${state.message}');
          showErrorDialog(context, message: state.message);
        } else if (state is Authenticated) {
          print('📱 [LOGIN] User authenticated: ${state.user.fullName}');
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.recycling,
                        size: 60,
                        color: AppColors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      AppStrings.appTagline,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

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

                    const SizedBox(height: 8),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                        },
                        child: Text(
                          AppStrings.forgotPassword,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    PrimaryButton(
                      text: AppStrings.login,
                      onPressed: isLoading ? null : _login,
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.dontHaveAccount,
                          style: AppTextStyles.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            AppStrings.register,
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
      },
    );
  }
}
