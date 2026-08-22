import 'package:flutter/material.dart';

import 'cart_screen.dart';
import 'order_review_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, String> endereco;
  final List<CartItem> itens;
  final double subtotal;
  final String restauranteId;

  const PaymentScreen({
    super.key,
    required this.endereco,
    required this.itens,
    required this.subtotal,
    required this.restauranteId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF6F7F9);

  String pagamentoSelecionado = 'PIX';

  void continuar() {
    if (widget.itens.isEmpty) {
      _mensagem('Seu carrinho está vazio.', erro: true);
      return;
    }

    if (pagamentoSelecionado == 'PIX') {
      _abrirCheckoutPix();
      return;
    }

    if (pagamentoSelecionado == 'MERCADO_PAGO') {
      _abrirCheckoutMercadoPago();
      return;
    }

    if (pagamentoSelecionado == 'NUBANK') {
      _abrirCheckoutNubank();
      return;
    }

    _irParaRevisao();
  }

  void _irParaRevisao() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderReviewScreen(
          itens: widget.itens,
          subtotal: widget.subtotal,
          endereco: widget.endereco,
          pagamento: pagamentoSelecionado,
          restauranteId: widget.restauranteId,
        ),
      ),
    );
  }

  void _abrirCheckoutPix() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CheckoutModal(
          titulo: 'Pagamento via PIX',
          subtitulo: 'Rápido, seguro e instantâneo',
          icone: Icons.pix,
          iconeCor: const Color(0xFF00A884),
          total: widget.subtotal,
          tipo: 'PIX',
          onContinuar: () {
            Navigator.pop(context);
            _irParaRevisao();
          },
        );
      },
    );
  }

  void _abrirCheckoutMercadoPago() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CheckoutModal(
          titulo: 'Mercado Pago',
          subtitulo: 'Pague com sua conta Mercado Pago',
          icone: Icons.account_balance_wallet,
          iconeCor: const Color(0xFF009EE3),
          total: widget.subtotal,
          tipo: 'MERCADO_PAGO',
          onContinuar: () {
            Navigator.pop(context);
            _irParaRevisao();
          },
        );
      },
    );
  }

  void _abrirCheckoutNubank() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CheckoutModal(
          titulo: 'Nubank',
          subtitulo: 'Pague usando seu cartão ou conta Nubank',
          icone: Icons.credit_card,
          iconeCor: const Color(0xFF820AD1),
          total: widget.subtotal,
          tipo: 'NUBANK',
          onContinuar: () {
            Navigator.pop(context);
            _irParaRevisao();
          },
        );
      },
    );
  }

  Widget _metodo({
    required String valor,
    required String titulo,
    required String descricao,
    required IconData icone,
    required Color cor,
  }) {
    final selecionado = pagamentoSelecionado == valor;

    return GestureDetector(
      onTap: () {
        setState(() {
          pagamentoSelecionado = valor;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selecionado ? cor : Colors.grey.shade200,
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
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icone,
                color: cor,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selecionado
                      ? cor
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: selecionado
                    ? cor
                    : Colors.transparent,
              ),
              child: selecionado
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _mensagem(
    String texto, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor:
            erro ? Colors.red.shade700 : laranja,
        behavior: SnackBarBehavior.floating,
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
          'Pagamento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  22,
                  20,
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Escolha como pagar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tenha uma experiência rápida e segura.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _tituloSecao('Pagamento instantâneo'),

                    _metodo(
                      valor: 'PIX',
                      titulo: 'PIX',
                      descricao:
                          'Pagamento instantâneo',
                      icone: Icons.pix,
                      cor: const Color(0xFF00A884),
                    ),

                    _metodo(
                      valor: 'MERCADO_PAGO',
                      titulo: 'Mercado Pago',
                      descricao:
                          'Pague com Mercado Pago',
                      icone:
                          Icons.account_balance_wallet,
                      cor: const Color(0xFF009EE3),
                    ),

                    _metodo(
                      valor: 'NUBANK',
                      titulo: 'Nubank',
                      descricao:
                          'Cartão ou conta Nubank',
                      icone: Icons.credit_card,
                      cor: const Color(0xFF820AD1),
                    ),

                    const SizedBox(height: 8),

                    _tituloSecao('Pagamento na entrega'),

                    _metodo(
                      valor: 'CARTAO',
                      titulo: 'Cartão na entrega',
                      descricao:
                          'Pague ao receber seu pedido',
                      icone:
                          Icons.credit_card_outlined,
                      cor: laranja,
                    ),

                    _metodo(
                      valor: 'DINHEIRO',
                      titulo: 'Dinheiro',
                      descricao:
                          'Pague em dinheiro ao receber',
                      icone:
                          Icons.payments_outlined,
                      cor: Colors.green,
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: laranja,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Seus dados de pagamento são protegidos e utilizados somente para este pedido.',
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
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                18,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: continuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: const [
                      Text(
                        'CONTINUAR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
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

  Widget _tituloSecao(String texto) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
        top: 4,
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================
// CHECKOUT MODAL
// ============================================================

class _CheckoutModal extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Color iconeCor;
  final double total;
  final String tipo;
  final VoidCallback onContinuar;

  const _CheckoutModal({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.iconeCor,
    required this.total,
    required this.tipo,
    required this.onContinuar,
  });

  String preco(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        25,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: iconeCor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icone,
                color: iconeCor,
                size: 35,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Valor do pedido',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    preco(total),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (tipo == 'PIX')
              _informacao(
                Icons.flash_on,
                'PIX será utilizado para pagamento instantâneo.',
              ),

            if (tipo == 'MERCADO_PAGO')
              _informacao(
                Icons.security,
                'Pagamento protegido pelo Mercado Pago.',
              ),

            if (tipo == 'NUBANK')
              _informacao(
                Icons.lock_outline,
                'Pagamento protegido e processado com segurança.',
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: onContinuar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconeCor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'CONTINUAR PARA REVISÃO',
                  style: TextStyle(
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

  Widget _informacao(
    IconData icon,
    String texto,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconeCor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}