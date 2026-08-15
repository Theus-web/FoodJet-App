import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    verificarSessao();
  }

  Future<void> verificarSessao() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    final auth = AuthService();

    final logado = await auth.estaLogado();

    if (!mounted) return;

    if (logado) {
      final usuario = await auth.buscarRestaurante();

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        "/home",
        arguments: usuario ?? {},
      );
    } else {
      Navigator.pushReplacementNamed(
        context,
        "/login",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF97316),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              "FoodJet Restaurante",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}