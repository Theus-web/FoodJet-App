import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pedido.dart';
import '../../services/delivery_service.dart';

class NewDeliveryScreen extends StatefulWidget {
  const NewDeliveryScreen({super.key});

  @override
  State<NewDeliveryScreen> createState() => _NewDeliveryScreenState();
}

class _NewDeliveryScreenState extends State<NewDeliveryScreen> {
  Pedido? pedido;
  bool loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Pedido) {
      pedido ??= args;
    }
  }

  Future<void> update(String status) async {
    if (pedido == null) return;

    setState(() => loading = true);

    try {
      await DeliveryService.updateStatus(pedido!.id, status);

      if (!mounted) return;

      if (status == 'ENTREGUE' ||
          status == 'FINALIZADO') {
        Navigator.pop(context);
        return;
      }

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status atualizado: $status'),
          backgroundColor: FoodJetColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: FoodJetColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pedido == null) {
      return const Scaffold(
        body: Center(
          child: Text('Entrega não encontrada.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Entrega',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: FoodJetColors.dark,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENTREGA EM ANDAMENTO',
                  style: TextStyle(
                    color: FoodJetColors.orange,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  pedido!.restaurante,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pedido!.cliente,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _address(
            'RETIRADA',
            pedido!.enderecoRetirada,
            Icons.restaurant_rounded,
          ),
          const SizedBox(height: 12),
          _address(
            'ENTREGA',
            pedido!.enderecoEntrega,
            Icons.location_on_rounded,
          ),
          const SizedBox(height: 25),
          _button(
            'CHEGUEI AO RESTAURANTE',
            Icons.storefront_rounded,
            'CHEGUEI_RESTAURANTE',
          ),
          const SizedBox(height: 10),
          _button(
            'INICIAR ENTREGA',
            Icons.navigation_rounded,
            'EM_ENTREGA',
          ),
          const SizedBox(height: 10),
          _button(
            'FINALIZAR ENTREGA',
            Icons.check_circle_rounded,
            'ENTREGUE',
            primary: true,
          ),
        ],
      ),
    );
  }

  Widget _address(
    String label,
    String address,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                FoodJetColors.orange.withValues(alpha: .12)
            child: Icon(
              icon,
              color: FoodJetColors.orange,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: FoodJetColors.gray,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  address.isEmpty
                      ? 'Endereço não informado'
                      : address,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(
    String text,
    IconData icon,
    String status, {
    bool primary = false,
  }) {
    return ElevatedButton(
      onPressed: loading ? null : () => update(status),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            primary ? FoodJetColors.orange : Colors.white,
        foregroundColor:
            primary ? Colors.white : FoodJetColors.dark,
        side: primary
            ? BorderSide.none
            : BorderSide(
                Colors.black.withValues(alpha: .08)
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
