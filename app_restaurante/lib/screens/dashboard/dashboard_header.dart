import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String nome;
  final bool aberto;
  final VoidCallback onAlterarStatus;

  const DashboardHeader({
    super.key,
    required this.nome,
    required this.aberto,
    required this.onAlterarStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF97316),
            Color(0xFFFF8C42),
          ],
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.storefront,
              color: Color(0xFFF97316),
              size: 34,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bem-vindo 👋",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),

                Text(
                  nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: aberto
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      aberto
                          ? "Restaurante Aberto"
                          : "Restaurante Fechado",
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Switch(
            value: aberto,
            activeColor: Colors.white,
            onChanged: (_) => onAlterarStatus(),
          ),
        ],
      ),
    );
  }
}
