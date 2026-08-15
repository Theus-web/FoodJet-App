import 'package:flutter/material.dart';

import '../../services/dashboard_service.dart';

class ReportsScreen extends StatefulWidget {
  final String restauranteId;

  const ReportsScreen({
    super.key,
    required this.restauranteId,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DashboardService service = DashboardService();

  Map<String, dynamic> dados = {
    "vendasHoje": 0,
    "pedidosHoje": 0,
    "produtosMaisVendidos": <dynamic>[],
  };

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    try {
      final resultado = await service.buscarDashboard(
        widget.restauranteId,
      );

      if (!mounted) return;

      setState(() {
  dados = resultado;

  carregando = false;
});

    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      debugPrint(e.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Erro ao carregar relatório.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final produtos =
        (dados["produtosMaisVendidos"] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Relatórios"),
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: carregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _card(
                    "Vendas Hoje",
                    "R\$ ${dados["vendasHoje"]}",
                    Icons.attach_money,
                    Colors.green,
                  ),
                  _card(
                    "Pedidos Hoje",
                    dados["pedidosHoje"].toString(),
                    Icons.shopping_bag,
                    Colors.orange,
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Produtos mais vendidos 🔥",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (produtos.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text(
                          "Nenhum produto encontrado.",
                        ),
                      ),
                    ),

                  ...produtos.map(
                    (produto) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.fastfood,
                        ),
                        title: Text(
                          produto["nome"] ?? "",
                        ),
                        trailing: Text(
                          "${produto["quantidade"] ?? 0} vendas",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _card(
    String titulo,
    String valor,
    IconData icon,
    Color cor,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: cor,
          size: 35,
        ),
        title: Text(titulo),
        trailing: Text(
          valor,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}