import 'package:flutter/material.dart';

import '../../features/attendance/presentation/pages/attendance_history_page.dart';
import '../../features/auth/presentation/pages/auth_gate.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import 'route_names.dart';

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      RouteNames.home => const AuthGate(),
      RouteNames.login => const LoginPage(),
      RouteNames.history => const AttendanceHistoryPage(),
      _ => const AuthGate(),
    };

    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
