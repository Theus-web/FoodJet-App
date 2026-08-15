import 'package:flutter/material.dart';

class RecentOrdersWidget extends StatelessWidget {
  final List<dynamic> pedidos;
  final Function(Map<String, dynamic>) onPedidoTap;

  const RecentOrdersWidget({
    super.key,
    required this.pedidos,
    required this.onPedidoTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pedidos.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 60,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                "Nenhum pedido recebido",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Os novos pedidos aparecerão aqui.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: pedidos.take(5).map((pedido) {
        final status = pedido["status"] ?? "AGUARDANDO";

        Color corStatus;

        switch (status) {
          case "PREPARANDO":
            corStatus = Colors.blue;
            break;

          case "PRONTO":
            corStatus = Colors.green;
            break;

          case "ENTREGUE":
            corStatus = Colors.grey;
            break;

          default:
            corStatus = Colors.orange;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: corStatus.withOpacity(.15),
              child: Icon(
                Icons.shopping_bag,
                color: corStatus,
              ),
            ),
            title: Text(
              "Pedido #${pedido["id"]}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "R\$ ${pedido["total"]}",
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: corStatus.withOpacity(.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: corStatus,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => onPedidoTap(pedido),
          ),
        );
      }).toList(),
    );
  }
}