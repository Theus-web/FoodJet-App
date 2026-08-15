import 'package:flutter/material.dart';

import 'quick_action_card.dart';

class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onPedidos;
  final VoidCallback onProdutos;
  final VoidCallback onCardapio;
  final VoidCallback onRelatorios;
  final VoidCallback onGanhos;
  final VoidCallback onConfiguracoes;

  const QuickActionsGrid({
    super.key,
    required this.onPedidos,
    required this.onProdutos,
    required this.onCardapio,
    required this.onRelatorios,
    required this.onGanhos,
    required this.onConfiguracoes,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: .95,
      children: [
        QuickActionCard(
          titulo: "Pedidos",
          icon: Icons.receipt_long,
          color: Colors.orange,
          onTap: onPedidos,
        ),

        QuickActionCard(
          titulo: "Produtos",
          icon: Icons.fastfood,
          color: Colors.blue,
          onTap: onProdutos,
        ),

        QuickActionCard(
          titulo: "Cardápio",
          icon: Icons.restaurant_menu,
          color: Colors.green,
          onTap: onCardapio,
        ),

        QuickActionCard(
          titulo: "Relatórios",
          icon: Icons.bar_chart,
          color: Colors.purple,
          onTap: onRelatorios,
        ),

        QuickActionCard(
          titulo: "Ganhos",
          icon: Icons.attach_money,
          color: Colors.teal,
          onTap: onGanhos,
        ),

        QuickActionCard(
          titulo: "Config.",
          icon: Icons.settings,
          color: Colors.grey,
          onTap: onConfiguracoes,
        ),
      ],
    );
  }
}