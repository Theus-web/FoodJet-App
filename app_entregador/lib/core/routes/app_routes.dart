import 'package:flutter/material.dart';

import '../../models/pedido.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/delivery/new_delivery_screen.dart';
import '../../screens/earnings/earnings_screen.dart';
import '../../screens/profile/profile_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String delivery = '/delivery';
  static const String earnings = '/earnings';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case delivery:
        final arguments = settings.arguments;

        if (arguments is Pedido) {
          return MaterialPageRoute(
            builder: (_) => NewDeliveryScreen(
              pedido: arguments,
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case earnings:
        return MaterialPageRoute(
          builder: (_) => const EarningsScreen(),
          settings: settings,
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
    }
  }
}