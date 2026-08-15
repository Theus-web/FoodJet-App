import 'package:flutter/material.dart';
import 'cart_screen.dart';
import 'order_review_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, String> endereco;
  final List<CartItem> itens;
  final double subtotal;

  const PaymentScreen({
    super.key,
    required this.endereco,
    required this.itens,
    required this.subtotal,
  });

  @override
  State<PaymentScreen> createState() =>
      _PaymentScreenState();
}

class _PaymentScreenState
    extends State<PaymentScreen> {
  String pagamentoSelecionado = 'PIX';

  @override
  Widget build(BuildContext context) {
    const laranja = Color(0xFFF97316);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        title: const Text(
          'Forma de Pagamento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Como você deseja pagar?',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: RadioListTile<String>(
                value: 'PIX',
                groupValue: pagamentoSelecionado,
                activeColor: laranja,
                title: const Text('PIX'),
                subtitle: const Text(
                  'Pagamento instantâneo',
                ),
                onChanged: (valor) {
                  setState(() {
                    pagamentoSelecionado = valor!;
                  });
                },
              ),
            ),

            Card(
              child: RadioListTile<String>(
                value: 'DINHEIRO',
                groupValue: pagamentoSelecionado,
                activeColor: laranja,
                title: const Text('Dinheiro'),
                subtitle: const Text(
                  'Pagar na entrega',
                ),
                onChanged: (valor) {
                  setState(() {
                    pagamentoSelecionado = valor!;
                  });
                },
              ),
            ),

            Card(
              child: RadioListTile<String>(
                value: 'CARTAO',
                groupValue: pagamentoSelecionado,
                activeColor: laranja,
                title: const Text(
                  'Cartão na entrega',
                ),
                subtitle: const Text(
                  'Pagar com cartão ao receber',
                ),
                onChanged: (valor) {
                  setState(() {
                    pagamentoSelecionado = valor!;
                  });
                },
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
  print(
    '💳 PAGAMENTO: '
    '$pagamentoSelecionado',
  );

  print(
    '📍 ENDEREÇO: '
    '${widget.endereco}',
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OrderReviewScreen(
        itens: widget.itens,
        subtotal: widget.subtotal,
        endereco: widget.endereco,
        pagamento: pagamentoSelecionado,
      ),
    ),
  );
},

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: laranja,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),

                child: const Text(
                  'CONTINUAR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}