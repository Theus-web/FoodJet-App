import 'package:flutter/material.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  final double total;
  final String pagamento;
  final Future<void> Function() finalizarPagamento;

  const PaymentCheckoutScreen({
    super.key,
    required this.total,
    required this.pagamento,
    required this.finalizarPagamento,
  });

  @override
  State<PaymentCheckoutScreen> createState() =>
      _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState
    extends State<PaymentCheckoutScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF5F5F5);

  String metodo = 'MERCADO_PAGO';
  bool processando = false;

  String formatarPreco(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> pagar() async {
    if (processando) return;

    setState(() {
      processando = true;
    });

    try {
      /*
       * AQUI ENTRARÁ A INTEGRAÇÃO REAL DO GATEWAY.
       *
       * Mercado Pago:
       * - criar preferência no backend
       * - abrir checkout
       * - aguardar resultado
       *
       * Nubank:
       * - pagamento via PIX
       * - gerar cobrança PIX
       * - apresentar QR Code
       * - confirmar pagamento pelo backend
       */

      await widget.finalizarPagamento();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Não foi possível processar o pagamento.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          processando = false;
        });
      }
    }
  }

  Widget metodoPagamento({
    required String valor,
    required Widget logo,
    required String titulo,
    required String descricao,
  }) {
    final selecionado = metodo == valor;

    return GestureDetector(
      onTap: () {
        setState(() {
          metodo = valor;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selecionado
                ? laranja
                : Colors.grey.shade200,
            width: selecionado ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selecionado
                    ? const Color(0xFFFFE8D8)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: logo,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    descricao,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              selecionado
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selecionado
                  ? laranja
                  : Colors.grey,
            ),
          ],
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
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'Pagamento seguro',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Escolha como deseja pagar seu pedido.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 24),

              // TOTAL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF97316),
                      Color(0xFFEA580C),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total do pedido',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      formatarPreco(widget.total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Escolha o método',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // MERCADO PAGO
              metodoPagamento(
                valor: 'MERCADO_PAGO',
                titulo: 'Mercado Pago',
                descricao:
                    'Pix, cartão de crédito ou débito',
                logo: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF009EE3),
                  size: 29,
                ),
              ),

              // NUBANK
              metodoPagamento(
                valor: 'NUBANK_PIX',
                titulo: 'Pix via Nubank',
                descricao:
                    'Pague rapidamente pelo aplicativo Nubank',
                logo: const Text(
                  'Nu',
                  style: TextStyle(
                    color: Color(0xFF820AD1),
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // PIX FOODJET
              metodoPagamento(
                valor: 'PIX',
                titulo: 'Pix',
                descricao:
                    'QR Code ou código Copia e Cola',
                logo: const Icon(
                  Icons.pix,
                  color: Color(0xFF32BCAD),
                  size: 30,
                ),
              ),

              // DINHEIRO
              if (widget.pagamento == 'DINHEIRO')
                metodoPagamento(
                  valor: 'DINHEIRO',
                  titulo: 'Dinheiro',
                  descricao:
                      'Pagamento realizado na entrega',
                  logo: const Icon(
                    Icons.payments_outlined,
                    color: Colors.green,
                    size: 29,
                  ),
                ),

              const SizedBox(height: 20),

              // SEGURANÇA
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.green
                            .withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Pagamento protegido. Seus dados financeiros não ficam armazenados no FoodJet.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed:
                      processando ? null : pagar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.grey.shade400,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: processando
                      ? const SizedBox(
                          width: 25,
                          height: 25,
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
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
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

              const SizedBox(height: 15),

              Center(
                child: Text(
                  'Compra segura • FoodJet',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}