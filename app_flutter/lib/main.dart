import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'config/app_theme.dart';
import 'config/theme_controller.dart';
import 'screens/login/login_screen.dart';

void main() {
  runApp(const FoodJetApp());
}

class FoodJetApp extends StatefulWidget {
  const FoodJetApp({super.key});

  @override
  State<FoodJetApp> createState() => _FoodJetAppState();
}

class _FoodJetAppState extends State<FoodJetApp> {
  @override
  void initState() {
    super.initState();

    themeController.addListener(_atualizarTema);
  }

  void _atualizarTema() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    themeController.removeListener(_atualizarTema);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodJet',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      darkTheme: AppTheme.darkTheme,

      themeMode: themeController.themeMode,

      home: const SplashScreen(),
    );
  }
}

// ============================================================
// SPLASH SCREEN FOODJET
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _abrirLogin();
  }

  Future<void> _abrirLogin() async {
    // Tempo mínimo da Splash
    await Future.delayed(
      const Duration(
        milliseconds: 3000,
      ),
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF97316),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ==================================================
            // ANIMAÇÃO LOTTIE
            // ==================================================

            SizedBox(
              width: 250,
              height: 250,
              child: Lottie.asset(
                'assets/animations/foodjet_splash.json',
                fit: BoxFit.contain,
                repeat: false,
                animate: true,
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // NOME FOODJET
            // ==================================================

            const Text(
              'FoodJet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Delivery rápido',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 35),

            // ==================================================
            // CARREGAMENTO
            // ==================================================

            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}