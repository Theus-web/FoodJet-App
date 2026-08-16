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
    required this.subtotal, required String restauranteId,
  });

  @override
  State<PaymentScreen> createState() =>
      _PaymentScreenState();
}

class _PaymentScreenState
    extends State<PaymentScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF5F5F5);

  String pagamentoSelecionado = 'PIX';

  // ============================================================
  // CONTINUAR
  // ============================================================

  void continuar() {
    if (widget.itens.isEmpty) {
      _mensagem(
        'Seu carrinho está vazio.',
        erro: true,
      );
      return;
    }

    debugPrint('========================================');
    debugPrint('💳 FORMA DE PAGAMENTO');
    debugPrint('Pagamento: $pagamentoSelecionado');
    debugPrint('Endereço: ${widget.endereco}');
    debugPrint('Subtotal: ${widget.subtotal}');
    debugPrint('========================================');

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
  }

  // ============================================================
  // OPÇÃO PAGAMENTO
  // ============================================================

  Widget opcaoPagamento({
    required String valor,
    required IconData icone,
    required String titulo,
    required String descricao,
  }) {
    final selecionado =
        pagamentoSelecionado == valor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selecionado
              ? laranja
              : Colors.grey.shade200,
          width: selecionado ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: RadioListTile<String>(
        value: valor,
        groupValue: pagamentoSelecionado,
        activeColor: laranja,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        secondary: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: selecionado
                ? const Color(0xFFFFE8D8)
                : Colors.grey.shade100,
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icone,
            color: laranja,
            size: 25,
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            descricao,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
        onChanged: (valorSelecionado) {
          if (valorSelecionado == null) return;

          setState(() {
            pagamentoSelecionado =
                valorSelecionado;
          });
        },
      ),
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mensagem(
    String texto, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor:
            erro ? Colors.red.shade700 : laranja,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Forma de Pagamento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
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

              const SizedBox(height: 8),

              Text(
                'Escolha uma forma de pagamento para continuar.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 22),

              opcaoPagamento(
                valor: 'PIX',
                icone: Icons.pix,
                titulo: 'PIX',
                descricao:
                    'Pagamento instantâneo',
              ),

              opcaoPagamento(
                valor: 'DINHEIRO',
                icone:
                    Icons.payments_outlined,
                titulo: 'Dinheiro',
                descricao:
                    'Pagar na entrega',
              ),

              opcaoPagamento(
                valor: 'CARTAO',
                icone:
                    Icons.credit_card_outlined,
                titulo: 'Cartão na entrega',
                descricao:
                    'Pagar com cartão ao receber',
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: laranja,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sua forma de pagamento será utilizada apenas para processar este pedido.',
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: continuar,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: const [
                      Text(
                        'CONTINUAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}