import 'package:flutter/material.dart';

import 'dashboard_card.dart';

class DashboardSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> resumo;

  const DashboardSummaryWidget({
    super.key,
    required this.resumo,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        DashboardCard(
          titulo: "Pedidos Hoje",
          valor: resumo["pedidosHoje"].toString(),
          icon: Icons.shopping_bag_rounded,
          cor: Colors.orange,
        ),
        DashboardCard(
          titulo: "Vendas",
          valor: "R\$ ${resumo["vendasHoje"]}",
          icon: Icons.attach_money_rounded,
          cor: Colors.green,
        ),
        DashboardCard(
          titulo: "Produtos",
          valor: resumo["produtos"].toString(),
          icon: Icons.fastfood_rounded,
          cor: Colors.blue,
        ),
        DashboardCard(
          titulo: "Avaliação",
          valor: "${resumo["avaliacao"]} ⭐",
          icon: Icons.star_rounded,
          cor: Colors.amber,
        ),
      ],
    );
  }
}