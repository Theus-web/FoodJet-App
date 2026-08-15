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
  static const Color laranja =
      Color(0xFFF97316);

  static const Color fundo =
      Color(0xFFF7F7F8);

  String pagamentoSelecionado = 'PIX';

  // ============================================================
  // PREÇO
  // ============================================================

  String formatarPreco(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // QUANTIDADE
  // ============================================================

  int get quantidadeItens {
    return widget.itens.fold(
      0,
      (total, item) => total + item.quantidade,
    );
  }

  // ============================================================
  // PAGAMENTO
  // ============================================================

  void selecionarPagamento(String valor) {
    setState(() {
      pagamentoSelecionado = valor;
    });
  }

  // ============================================================
  // CONTINUAR
  // ============================================================

  void continuar() {
    debugPrint(
      '💳 PAGAMENTO: $pagamentoSelecionado',
    );

    debugPrint(
      '📍 ENDEREÇO: ${widget.endereco}',
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
  }

  // ============================================================
  // MÉTODO PAGAMENTO
  // ============================================================

  Widget metodoPagamento({
    required String valor,
    required IconData icone,
    required String titulo,
    required String descricao,
    required String detalhe,
  }) {
    final selecionado =
        pagamentoSelecionado == valor;

    return GestureDetector(
      onTap: () {
        selecionarPagamento(valor);
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        margin:
            const EdgeInsets.only(bottom: 13),
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: selecionado
                ? laranja
                : const Color(0xFFE7E7E7),
            width: selecionado ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: selecionado
                    ? 0.07
                    : 0.025,
              ),
              blurRadius:
                  selecionado ? 10 : 5,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ÍCONE
            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 200,
              ),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selecionado
                    ? laranja
                    : laranja.withValues(
                        alpha: 0.10,
                      ),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Icon(
                icone,
                color: selecionado
                    ? Colors.white
                    : laranja,
                size: 27,
              ),
            ),

            const SizedBox(width: 14),

            // TEXTOS
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Colors.black87,
                          ),
                        ),
                      ),

                      if (selecionado)
                        Container(
                          width: 25,
                          height: 25,
                          decoration:
                              const BoxDecoration(
                            color: laranja,
                            shape:
                                BoxShape.circle,
                          ),
                          child:
                              const Icon(
                            Icons.check,
                            color:
                                Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    descricao,
                    style:
                        const TextStyle(
                      color:
                          Colors.black54,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    detalhe,
                    style:
                        TextStyle(
                      color: selecionado
                          ? laranja
                          : Colors.grey.shade600,
                      fontSize: 11.5,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESUMO ENDEREÇO
  // ============================================================

  Widget resumoEndereco() {
    final endereco =
        widget.endereco;

    final rua =
        endereco['rua'] ?? '';

    final numero =
        endereco['numero'] ?? '';

    final bairro =
        endereco['bairro'] ?? '';

    final cidade =
        endereco['cidade'] ?? '';

    final estado =
        endereco['estado'] ?? '';

    final complemento =
        endereco['complemento'] ?? '';

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE7E7E7),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color:
                  laranja.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: laranja,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entregar em',
                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        Colors.black54,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '$rua, $numero',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  [
                    if (bairro.isNotEmpty)
                      bairro,
                    if (cidade.isNotEmpty)
                      '$cidade - $estado',
                    if (complemento.isNotEmpty)
                      complemento,
                  ].join(' • '),
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESUMO PEDIDO
  // ============================================================

  Widget resumoPedido() {
    return Container(
      padding:
          const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_bag_rounded,
                color: laranja,
                size: 21,
              ),

              const SizedBox(width: 9),

              const Expanded(
                child: Text(
                  'Resumo do pedido',
                  style:
                      TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              Text(
                '$quantidadeItens ${quantidadeItens == 1 ? 'item' : 'itens'}',
                style:
                    const TextStyle(
                  color:
                      Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          const Divider(
            height: 1,
          ),

          const SizedBox(height: 13),

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style:
                    TextStyle(
                  color:
                      Colors.black54,
                  fontSize: 14,
                ),
              ),

              Text(
                formatarPreco(
                  widget.subtotal,
                ),
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: fundo,

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor:
            Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 18,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Pagamento',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Escolha como pagar seu pedido',
              style: TextStyle(
                fontSize: 12,
                color:
                    Colors.white70,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  20,
                  18,
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // TÍTULO
                    // ==================================================

                    const Text(
                      'Como você deseja pagar?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Selecione uma forma de pagamento para continuar.',
                      style: TextStyle(
                        color:
                            Colors.black54,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // ENDEREÇO
                    // ==================================================

                    resumoEndereco(),

                    const SizedBox(height: 15),

                    // ==================================================
                    // RESUMO
                    // ==================================================

                    resumoPedido(),

                    const SizedBox(height: 25),

                    const Text(
                      'Forma de pagamento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 13),

                    // ==================================================
                    // PIX
                    // ==================================================

                    metodoPagamento(
                      valor: 'PIX',
                      icone:
                          Icons.qr_code_rounded,
                      titulo: 'PIX',
                      descricao:
                          'Pagamento instantâneo',
                      detalhe:
                          'Rápido, seguro e prático',
                    ),

                    // ==================================================
                    // DINHEIRO
                    // ==================================================

                    metodoPagamento(
                      valor:
                          'DINHEIRO',
                      icone:
                          Icons.payments_rounded,
                      titulo: 'Dinheiro',
                      descricao:
                          'Pagar na entrega',
                      detalhe:
                          'Tenha o valor em mãos',
                    ),

                    // ==================================================
                    // CARTÃO
                    // ==================================================

                    metodoPagamento(
                      valor:
                          'CARTAO',
                      icone:
                          Icons.credit_card_rounded,
                      titulo:
                          'Cartão na entrega',
                      descricao:
                          'Pagar com cartão ao receber',
                      detalhe:
                          'Débito ou crédito',
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // SEGURANÇA
                    // ==================================================

                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets.all(
                        14,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.green.withValues(
                          alpha: 0.07,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .verified_user_outlined,
                            color:
                                Colors.green,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 9,
                          ),
                          Expanded(
                            child: Text(
                              'Seus dados de pagamento são tratados com segurança.',
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey.shade700,
                                fontSize:
                                    11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ========================================================
            // RODAPÉ
            // ========================================================

            Container(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                13,
                18,
                15,
              ),
              decoration:
                  const BoxDecoration(
                color:
                    Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black12,
                    blurRadius: 10,
                    offset:
                        Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'Total do pedido',
                          style:
                              TextStyle(
                            fontSize: 14,
                            color:
                                Colors.black54,
                          ),
                        ),
                        Text(
                          formatarPreco(
                            widget.subtotal,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                laranja,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 11),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 54,
                      child:
                          ElevatedButton(
                        onPressed:
                            continuar,
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              laranja,
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            const Text(
                              'CONTINUAR',
                              style:
                                  TextStyle(
                                fontSize:
                                    15,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              width: 9,
                            ),
                            Container(
                              width: 29,
                              height: 29,
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white.withValues(
                                  alpha: 0.18,
                                ),
                                shape:
                                    BoxShape.circle,
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .arrow_forward_rounded,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}