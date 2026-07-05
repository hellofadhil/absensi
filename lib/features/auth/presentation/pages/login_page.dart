import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:absensi/core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    // Listen to AuthState changes to redirect to Home on success
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is Authenticated) {
        Navigator.pushReplacementNamed(context, RouteNames.home);
      }
    });

    return AppScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & App Name Header
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: context.appColors.primarySoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.appColors.primaryBorder,
                        width: 2.5,
                      ),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      size: 44,
                      color: context.appColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Presensi Sekolah',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: context.appColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Masuk untuk mencatat kehadiran Anda hari ini',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error State Message
                      if (authState is AuthError) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: context.appColors.dangerSoft,
                            borderRadius: BorderRadius.circular(AppRadius.small),
                            border: Border.all(
                              color: context.appColors.danger.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: context.appColors.danger,
                                size: 22,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  authState.message,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                        color: context.appColors.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !isLoading,
                        style: TextStyle(color: context.appColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Email Address',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: context.appColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: context.appColors.surfaceSoft.withValues(alpha: 0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.small),
                            borderSide: BorderSide(
                              color: context.appColors.border,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.small),
                            borderSide: BorderSide(
                              color: context.appColors.primary,
                              width: 2.0,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enabled: !isLoading,
                        onFieldSubmitted: (_) => _submit(),
                        style: TextStyle(color: context.appColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(
                            Icons.lock_outlined,
                            color: context.appColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: context.appColors.surfaceSoft.withValues(alpha: 0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.small),
                            borderSide: BorderSide(
                              color: context.appColors.border,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.small),
                            borderSide: BorderSide(
                              color: context.appColors.primary,
                              width: 2.0,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: context.appColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kata sandi tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Submit Button
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: AppPrimaryButton(
                            label: 'Masuk Ke Akun',
                            onPressed: _submit,
                            icon: Icons.login_rounded,
                          ),
                        ),
                    ],
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
