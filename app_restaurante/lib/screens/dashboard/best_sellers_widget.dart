import 'package:flutter/material.dart';

class BestSellersWidget extends StatelessWidget {
  final List<dynamic> produtos;

  const BestSellersWidget({
    super.key,
    required this.produtos,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: produtos.isEmpty
            ? const Column(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 48,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Nenhuma venda ainda",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Os produtos mais vendidos aparecerão aqui.",
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Mais vendidos",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  ...List.generate(
                    produtos.length > 5 ? 5 : produtos.length,
                    (index) {
                      final produto = produtos[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              Colors.orange.withOpacity(.15),
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          produto["nome"] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "${produto["quantidade"]} vendas",
                        ),
                        trailing: const Icon(
                          Icons.trending_up,
                          color: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}