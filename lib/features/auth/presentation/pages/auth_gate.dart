import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:absensi/core/theme/app_colors.dart';
import 'package:absensi/core/theme/app_spacing.dart';
import 'package:absensi/features/home/presentation/pages/home_page.dart';
import 'package:absensi/features/auth/presentation/providers/auth_provider.dart';
import 'login_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is AuthInitial || authState is AuthLoading) {
      return Scaffold(
        backgroundColor: context.appColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Beautiful pulsing or static loader icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.appColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 36,
                  color: context.appColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CircularProgressIndicator(
                strokeWidth: 3,
                color: context.appColors.primary,
              ),
            ],
          ),
        ),
      );
    }

    if (authState is Authenticated) {
      return const HomePage();
    }

    return const LoginPage();
  }
}
