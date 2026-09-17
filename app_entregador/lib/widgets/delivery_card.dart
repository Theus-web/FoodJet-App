import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/pedido.dart';

class DeliveryCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const DeliveryCard({
    super.key,
    required this.pedido,
    required this.onAccept,
    required this.onReject,
  });

  String money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: FoodJetColors.orange.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: FoodJetColors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NOVA ENTREGA',
                      style: TextStyle(
                        color: FoodJetColors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pedido.restaurante,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                money(pedido.valorEntrega),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _info(Icons.person_outline, pedido.cliente),
          const SizedBox(height: 9),
          _info(
            Icons.route_outlined,
            pedido.distanciaKm > 0
                ? '${pedido.distanciaKm.toStringAsFixed(1)} km'
                : 'Distância a calcular',
          ),
          const SizedBox(height: 9),
          _info(Icons.payments_outlined, pedido.pagamento),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    side: const BorderSide(
                      color: Color(0xFFE5E5E5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'RECUSAR',
                    style: TextStyle(
                      color: FoodJetColors.dark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                  ),
                  child: const Text(
                    'ACEITAR ENTREGA',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: FoodJetColors.gray,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text.isEmpty ? 'Não informado' : text,
            style: const TextStyle(
              color: FoodJetColors.dark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
