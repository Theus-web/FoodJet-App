import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const FoodJetEntregadorApp(),
  );
}

class FoodJetEntregadorApp
    extends StatelessWidget {
  const FoodJetEntregadorApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false,

      title:
          'FoodJet Entregador',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              const Color(
            0xFFF97316,
          ),
        ),

        scaffoldBackgroundColor:
            const Color(
          0xFFF6F6F6,
        ),

        fontFamily:
            'Roboto',
      ),

      home:
          const InitialScreen(),
    );
  }
}

class InitialScreen
    extends StatefulWidget {
  const InitialScreen({
    super.key,
  });

  @override
  State<InitialScreen> createState() =>
      _InitialScreenState();
}

class _InitialScreenState
    extends State<InitialScreen> {

  @override
  void initState() {
    super.initState();

    verificarLogin();
  }

  Future<void> verificarLogin() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    final token =
        prefs.getString('token');

    if (!mounted) return;

    if (token != null &&
        token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const HomeScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor:
          Color(0xFFF97316),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 80,
            ),
            SizedBox(height: 20),
            Text(
              'FoodJet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Text(
              'ENTREGADOR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}