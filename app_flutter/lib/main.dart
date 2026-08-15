import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'config/theme_controller.dart';
import 'screens/login/login_screen.dart';

void main() {
  runApp(const FoodJetApp());
}

class FoodJetApp extends StatefulWidget {
  const FoodJetApp({super.key});

  @override
  State<FoodJetApp> createState() =>
      _FoodJetAppState();
}

class _FoodJetAppState extends State<FoodJetApp> {
  @override
  void initState() {
    super.initState();

    themeController.addListener(
      _atualizarTema,
    );
  }

  void _atualizarTema() {
    setState(() {});
  }

  @override
  void dispose() {
    themeController.removeListener(
      _atualizarTema,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodJet',

      debugShowCheckedModeBanner: false,

      // ==============================
      // TEMA CLARO
      // ==============================
      theme: AppTheme.lightTheme,

      // ==============================
      // TEMA ESCURO
      // ==============================
      darkTheme: AppTheme.darkTheme,

      // ==============================
      // TEMA ATUAL
      // ==============================
      themeMode:
          themeController.themeMode,

      home: const LoginScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.delivery_dining,
              color: Color(0xFFFF6B00),
              size: 100,
            ),

            SizedBox(height: 20),

            Text(
              "FoodJet",
              style: TextStyle(
                fontSize: 34,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Delivery rápido e inteligente",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 40),

            CircularProgressIndicator(
              color: Color(0xFFFF6B00),
            ),
          ],
        ),
      ),
    );
  }
}