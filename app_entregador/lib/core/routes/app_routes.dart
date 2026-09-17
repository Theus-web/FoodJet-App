import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/earnings/earnings_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/support/support_screen.dart';
import '../../screens/delivery/new_delivery_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const earnings = '/earnings';
  static const profile = '/profile';
  static const support = '/support';
  static const newDelivery = '/new-delivery';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginScreen(),
        home: (_) => const HomeScreen(),
        earnings: (_) => const EarningsScreen(),
        profile: (_) => const ProfileScreen(),
        support: (_) => const SupportScreen(),
        newDelivery: (_) => const NewDeliveryScreen(),
      };
}
