import 'package:flutter/material.dart';

class CheckoutPaymentScreen extends StatefulWidget {
  final double total;
  final String pagamento;
  final String restauranteId;
  final VoidCallback? onPagamentoConfirmado;

  const CheckoutPaymentScreen({
    super.key,
    required this.total,
    required this.pagamento,
    required this.restauranteId,
    this.onPagamentoConfirmado,
  });

  @override
  State<CheckoutPaymentScreen> createState() =>
      _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState
    extends State<CheckoutPaymentScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF5F5F5);

  String metodoSelecionado = '';

  bool processando = false;

  @override
  void initState() {
    super.initState();

    metodoSelecionado = widget.pagamento;
  }

  String formatarPreco(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // PAGAR
  // ============================================================

  Future<void> processarPagamento() async {
    if (processando) return;

    if (metodoSelecionado.isEmpty) {
      mensagem(
        'Selecione uma forma de pagamento.',
        erro: true,
      );
      return;
    }

    setState(() {
      processando = true;
    });

    try {
      /*
       * IMPORTANTE:
       *
       * Aqui será conectado o Mercado Pago.
       *
       * O backend deverá criar a preferência
       * / pagamento e retornar os dados do checkout.
       *
       * Neste momento estamos deixando a interface
       * pronta sem processar pagamento real.
       */

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (!mounted) return;

      mensagem(
        'Pagamento preparado com sucesso.',
      );

      widget.onPagamentoConfirmado?.call();

    } catch (e) {
      if (!mounted) return;

      mensagem(
        'Não foi possível iniciar o pagamento.',
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          processando = false;
        });
      }
    }
  }

  // ============================================================
  // OPÇÃO
  // ============================================================

  Widget opcao({
    required String id,
    required IconData icone,
    required String titulo,
    required String descricao,
    Widget? logo,
  }) {
    final selecionado =
        metodoSelecionado == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          metodoSelecionado = id;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        margin:
            const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: selecionado
                ? laranja
                : Colors.grey.shade200,
            width:
                selecionado ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.035),
              blurRadius: 8,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selecionado
                    ? const Color(0xFFFFE8D8)
                    : Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: logo ??
                  Icon(
                    icone,
                    color: laranja,
                    size: 27,
                  ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    descricao,
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 200,
              ),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selecionado
                      ? laranja
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: selecionado
                    ? laranja
                    : Colors.transparent,
              ),
              child: selecionado
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void mensagem(
    String texto, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro
            ? Colors.red.shade700
            : laranja,
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
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
          'Pagamento',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // TOTAL
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(20),
                      decoration:
                          BoxDecoration(
                        gradient:
                            const LinearGradient(
                          begin:
                              Alignment.topLeft,
                          end:
                              Alignment.bottomRight,
                          colors: [
                            Color(0xFFF97316),
                            Color(0xFFEA580C),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          22,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total do pedido',
                            style: TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            formatarPreco(
                              widget.total,
                            ),
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 30,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          const Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color:
                                    Colors.white70,
                                size: 16,
                              ),
                              SizedBox(
                                width: 6,
                              ),
                              Text(
                                'Pagamento seguro',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    const Text(
                      'Escolha como pagar',
                      style:
                          TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      'Selecione uma opção para finalizar seu pedido.',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ==================================================
                    // PIX
                    // ==================================================

                    opcao(
                      id: 'PIX',
                      icone: Icons.pix,
                      titulo: 'PIX',
                      descricao:
                          'Pague instantaneamente pelo PIX',
                    ),

                    // ==================================================
                    // MERCADO PAGO
                    // ==================================================

                    opcao(
                      id: 'MERCADO_PAGO',
                      icone:
                          Icons.account_balance_wallet_outlined,
                      titulo:
                          'Mercado Pago',
                      descricao:
                          'Cartão, PIX ou saldo Mercado Pago',
                    ),

                    // ==================================================
                    // NUBANK
                    // ==================================================

                    opcao(
                      id: 'NUBANK',
                      icone:
                          Icons.account_balance,
                      titulo:
                          'Nubank',
                      descricao:
                          'Pague usando sua conta Nubank',
                      logo: Container(
                        alignment:
                            Alignment.center,
                        child: const Text(
                          'Nu',
                          style: TextStyle(
                            color:
                                Color(0xFF820AD1),
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // CARTÃO
                    // ==================================================

                    opcao(
                      id: 'CARTAO',
                      icone:
                          Icons.credit_card,
                      titulo:
                          'Cartão',
                      descricao:
                          'Cartão de crédito ou débito',
                    ),

                    // ==================================================
                    // DINHEIRO
                    // ==================================================

                    opcao(
                      id: 'DINHEIRO',
                      icone:
                          Icons.payments_outlined,
                      titulo:
                          'Dinheiro',
                      descricao:
                          'Pagar na entrega',
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // SEGURANÇA
                    // ==================================================

                    Container(
                      padding:
                          const EdgeInsets.all(15),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFFFE8D8,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: const Icon(
                              Icons.verified_user_outlined,
                              color:
                                  laranja,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Text(
                              'Seus dados de pagamento são protegidos e utilizados somente para processar esta compra.',
                              style:
                                  TextStyle(
                                color: Colors
                                    .grey
                                    .shade700,
                                fontSize: 12,
                                height: 1.4,
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

            // ==========================================================
            // BOTÃO
            // ==========================================================

            Container(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20,
              ),
              decoration:
                  const BoxDecoration(
                color: Colors.white,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: processando
                      ? null
                      : processarPagamento,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        laranja,
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        Colors.grey.shade400,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                  ),
                  child: processando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 19,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              'PAGAR ${formatarPreco(widget.total)}',
                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
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