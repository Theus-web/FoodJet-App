import 'package:flutter/material.dart';

import 'cart_screen.dart';
import 'checkout_payment_screen.dart';

class OrderReviewScreen extends StatefulWidget {
  final List<CartItem> itens;
  final double subtotal;
  final Map<String, String> endereco;
  final String pagamento;
  final String restauranteId;

  const OrderReviewScreen({
    super.key,
    required this.itens,
    required this.subtotal,
    required this.endereco,
    required this.pagamento,
    required this.restauranteId,
  });

  @override
  State<OrderReviewScreen> createState() =>
      _OrderReviewScreenState();
}

class _OrderReviewScreenState
    extends State<OrderReviewScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF5F5F5);

  final double taxaEntrega = 6.50;
  final double percentualTaxaServico = 0.10;

  double get taxaServico {
    return widget.subtotal * percentualTaxaServico;
  }

  double get totalPedido {
    return widget.subtotal +
        taxaServico +
        taxaEntrega;
  }

  String formatarPreco(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String enderecoCompleto() {
    final rua = widget.endereco['rua'] ?? '';
    final numero = widget.endereco['numero'] ?? '';
    final complemento =
        widget.endereco['complemento'] ?? '';
    final bairro = widget.endereco['bairro'] ?? '';
    final cidade = widget.endereco['cidade'] ?? '';
    final estado = widget.endereco['estado'] ?? '';

    String resultado = '$rua, $numero';

    if (complemento.isNotEmpty) {
      resultado += ' - $complemento';
    }

    if (bairro.isNotEmpty) {
      resultado += '\n$bairro';
    }

    if (cidade.isNotEmpty || estado.isNotEmpty) {
      resultado += '\n$cidade - $estado';
    }

    return resultado;
  }

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _linhaValor(
    String titulo,
    double valor,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
          ),
        ),
        Text(
          formatarPreco(valor),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // IR PARA CHECKOUT
  // ============================================================

  void abrirCheckout() {
    if (widget.itens.isEmpty) {
      _mensagem(
        'Seu carrinho está vazio.',
        erro: true,
      );
      return;
    }

    if (widget.restauranteId.isEmpty) {
      _mensagem(
        'Restaurante não identificado.',
        erro: true,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPaymentScreen(
          total: totalPedido,
          pagamento: widget.pagamento,
          restauranteId: widget.restauranteId,

          itens: widget.itens,

          endereco: widget.endereco,

          subtotal: widget.subtotal,

          taxaServico: taxaServico,

          taxaEntrega: taxaEntrega,
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Revisar Pedido',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Confira seu pedido',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Itens do pedido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _card(
              child: Column(
                children: List.generate(
                  widget.itens.length,
                  (index) {
                    final item = widget.itens[index];

                    final subtotalItem =
                        item.preco * item.quantidade;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            index ==
                                    widget.itens.length - 1
                                ? 0
                                : 14,
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nome,
                                  style:
                                      const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  '${item.quantidade}x ${formatarPreco(item.preco)}',
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatarPreco(
                              subtotalItem,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Endereço de entrega',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _card(
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFFE8D8),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: laranja,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      enderecoCompleto(),
                      style:
                          const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Forma de pagamento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _card(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFFE8D8),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: laranja,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      widget.pagamento,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Resumo dos valores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _card(
              child: Column(
                children: [
                  _linhaValor(
                    'Subtotal',
                    widget.subtotal,
                  ),

                  const SizedBox(height: 10),

                  _linhaValor(
                    'Taxa de serviço',
                    taxaServico,
                  ),

                  const SizedBox(height: 10),

                  _linhaValor(
                    'Taxa de entrega',
                    taxaEntrega,
                  ),

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: Divider(),
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      Text(
                        formatarPreco(
                          totalPedido,
                        ),
                        style:
                            const TextStyle(
                          color: laranja,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: abrirCheckout,
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
                child: const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'IR PARA PAGAMENTO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}