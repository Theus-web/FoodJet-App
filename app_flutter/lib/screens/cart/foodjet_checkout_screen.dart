import 'package:flutter/material.dart';

import 'cart_screen.dart';


class FoodJetCheckoutScreen extends StatefulWidget {
  final List<CartItem> itens;
  final double subtotal;
  final Map<String, String> endereco;
  final String pagamento;
  final String restauranteId;

  const FoodJetCheckoutScreen({
    super.key,
    required this.itens,
    required this.subtotal,
    required this.endereco,
    required this.pagamento,
    required this.restauranteId,
  });

  @override
  State<FoodJetCheckoutScreen> createState() =>
      _FoodJetCheckoutScreenState();
}

class _FoodJetCheckoutScreenState
    extends State<FoodJetCheckoutScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF5F5F5);

  late String metodoSelecionado;

  final double taxaEntrega = 6.50;
  final double percentualTaxaServico = 0.10;

  bool processando = false;

  @override
  void initState() {
    super.initState();

    metodoSelecionado = _normalizarPagamento(
      widget.pagamento,
    );
  }

  String _normalizarPagamento(String pagamento) {
    final valor = pagamento.toUpperCase();

    if (valor.contains('NUBANK')) {
      return 'NUBANK';
    }

    if (valor.contains('MERCADO')) {
      return 'MERCADO_PAGO';
    }

    if (valor.contains('CARTAO')) {
      return 'CARTAO';
    }

    if (valor.contains('DINHEIRO')) {
      return 'DINHEIRO';
    }

    return 'PIX';
  }

  double get taxaServico =>
      widget.subtotal * percentualTaxaServico;

  double get total =>
      widget.subtotal + taxaServico + taxaEntrega;

  String preco(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  void selecionar(String metodo) {
    setState(() {
      metodoSelecionado = metodo;
    });
  }

  Future<void> continuarPagamento() async {
    if (processando) return;

    if (widget.itens.isEmpty) {
      mensagem(
        'Seu carrinho está vazio.',
        erro: true,
      );
      return;
    }

    setState(() {
      processando = true;
    });

    /*
     * IMPORTANTE:
     *
     * Nesta primeira etapa estamos preparando o checkout.
     *
     * PIX/Nubank/Mercado Pago deverão receber posteriormente
     * a integração real com o backend/PSP.
     *
     * Dinheiro e cartão na entrega podem continuar diretamente.
     */

    if (metodoSelecionado == 'PIX' ||
        metodoSelecionado == 'NUBANK' ||
        metodoSelecionado == 'MERCADO_PAGO' ||
        metodoSelecionado == 'CARTAO') {
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      setState(() {
        processando = false;
      });

      _mostrarPagamentoPendente();

      return;
    }

    // Dinheiro/cartão na entrega
    await _finalizarPedido();
  }

  Future<void> _finalizarPedido() async {
    if (!mounted) return;

    /*
     * Por enquanto o pedido segue para a tela de revisão/
     * confirmação. A criação definitiva permanece no fluxo
     * que você já possui.
     */

    setState(() {
      processando = false;
    });

    Navigator.pop(context, metodoSelecionado);
  }

  void _mostrarPagamentoPendente() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            22,
            12,
            22,
            30,
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
                    color: _corMetodo().withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconeMetodo(),
                    color: _corMetodo(),
                    size: 36,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  _tituloMetodo(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _descricaoMetodo(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: fundo,
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        preco(total),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: laranja,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                if (metodoSelecionado == 'NUBANK')
                  _botaoNubank(),

                if (metodoSelecionado == 'PIX')
                  _botaoPix(),

                if (metodoSelecionado ==
                    'MERCADO_PAGO')
                  _botaoMercadoPago(),

                if (metodoSelecionado == 'CARTAO')
                  _botaoCartao(),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Voltar',
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _botaoNubank() {
    return _botaoPrincipal(
      texto: 'Pagar com Nubank',
      icone: Icons.account_balance_wallet_outlined,
      cor: const Color(0xFF820AD1),
      onPressed: () {
        Navigator.pop(context);
        _mostrarPixSimulado('Nubank');
      },
    );
  }

  Widget _botaoPix() {
    return _botaoPrincipal(
      texto: 'Gerar PIX',
      icone: Icons.pix,
      cor: laranja,
      onPressed: () {
        Navigator.pop(context);
        _mostrarPixSimulado('PIX');
      },
    );
  }

  Widget _botaoMercadoPago() {
    return _botaoPrincipal(
      texto: 'Continuar com Mercado Pago',
      icone: Icons.payment,
      cor: const Color(0xFF009EE3),
      onPressed: () {
        Navigator.pop(context);
        _mostrarPixSimulado('Mercado Pago');
      },
    );
  }

  Widget _botaoCartao() {
    return _botaoPrincipal(
      texto: 'Continuar com cartão',
      icone: Icons.credit_card,
      cor: laranja,
      onPressed: () {
        Navigator.pop(context);
        _mostrarCartao();
      },
    );
  }

  Widget _botaoPrincipal({
    required String texto,
    required IconData icone,
    required Color cor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icone),
        label: Text(
          texto,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  void _mostrarPixSimulado(String origem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Icon(
                origem == 'Nubank'
                    ? Icons.account_balance_wallet
                    : Icons.pix,
                color: origem == 'Nubank'
                    ? const Color(0xFF820AD1)
                    : laranja,
              ),
              const SizedBox(width: 10),
              Text('PIX • $origem'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_2,
                    size: 145,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Pagamento de ${preco(total)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'O QR Code real será gerado pelo servidor do FoodJet através do gateway de pagamento.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _pagamentoAprovado();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'JÁ PAGUEI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarCartao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            20,
            22,
            MediaQuery.of(context).viewInsets.bottom + 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pagamento com cartão',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Número do cartão',
                  prefixIcon:
                      const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Validade',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _pagamentoAprovado();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'PAGAR ${preco(total)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pagamentoAprovado() {
    mensagem(
      'Pagamento confirmado. Finalizando pedido...',
    );

    /*
     * Aqui vamos conectar a confirmação real do gateway
     * ao POST /orders.
     *
     * Por enquanto retornamos o método para o
     * OrderReviewScreen.
     */

    Future.delayed(
      const Duration(milliseconds: 700),
      () {
        if (!mounted) return;

        Navigator.pop(
          context,
          metodoSelecionado,
        );
      },
    );
  }

  Color _corMetodo() {
    switch (metodoSelecionado) {
      case 'NUBANK':
        return const Color(0xFF820AD1);

      case 'MERCADO_PAGO':
        return const Color(0xFF009EE3);

      case 'CARTAO':
        return laranja;

      default:
        return laranja;
    }
  }

  IconData _iconeMetodo() {
    switch (metodoSelecionado) {
      case 'NUBANK':
        return Icons.account_balance_wallet_outlined;

      case 'MERCADO_PAGO':
        return Icons.payment;

      case 'CARTAO':
        return Icons.credit_card;

      default:
        return Icons.pix;
    }
  }

  String _tituloMetodo() {
    switch (metodoSelecionado) {
      case 'NUBANK':
        return 'Pagamento Nubank';

      case 'MERCADO_PAGO':
        return 'Mercado Pago';

      case 'CARTAO':
        return 'Pagamento com cartão';

      default:
        return 'Pagamento PIX';
    }
  }

  String _descricaoMetodo() {
    switch (metodoSelecionado) {
      case 'NUBANK':
        return 'Pague rapidamente pelo aplicativo Nubank usando PIX.';

      case 'MERCADO_PAGO':
        return 'Continue para realizar o pagamento com segurança.';

      case 'CARTAO':
        return 'Informe os dados do seu cartão para continuar.';

      default:
        return 'Escaneie o QR Code ou copie o código PIX.';
    }
  }

  void mensagem(
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

  Widget _opcaoPagamento({
    required String id,
    required String titulo,
    required String descricao,
    required IconData icone,
    required Color cor,
  }) {
    final selecionado =
        metodoSelecionado == id;

    return GestureDetector(
      onTap: () => selecionar(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: selecionado
                ? cor
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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: cor.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Icon(
                icone,
                color: cor,
                size: 27,
              ),
            ),

            const SizedBox(width: 13),

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
                  const SizedBox(height: 3),
                  Text(
                    descricao,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selecionado
                    ? cor
                    : Colors.transparent,
                border: Border.all(
                  color: selecionado
                      ? cor
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selecionado
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 15,
                    )
                  : null,
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
          'Checkout FoodJet',
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
                'Como você quer pagar?',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Escolha uma opção segura para finalizar seu pedido.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              _opcaoPagamento(
                id: 'PIX',
                titulo: 'PIX',
                descricao:
                    'Pagamento instantâneo',
                icone: Icons.pix,
                cor: laranja,
              ),

              _opcaoPagamento(
                id: 'NUBANK',
                titulo: 'Nubank',
                descricao:
                    'Pague com PIX pelo Nubank',
                icone:
                    Icons.account_balance_wallet_outlined,
                cor: const Color(0xFF820AD1),
              ),

              _opcaoPagamento(
                id: 'MERCADO_PAGO',
                titulo: 'Mercado Pago',
                descricao:
                    'PIX ou cartão pelo Mercado Pago',
                icone: Icons.payment,
                cor: const Color(0xFF009EE3),
              ),

              _opcaoPagamento(
                id: 'CARTAO',
                titulo: 'Cartão',
                descricao:
                    'Crédito ou débito',
                icone:
                    Icons.credit_card_outlined,
                cor: laranja,
              ),

              _opcaoPagamento(
                id: 'DINHEIRO',
                titulo: 'Dinheiro',
                descricao:
                    'Pagar na entrega',
                icone:
                    Icons.payments_outlined,
                cor: Colors.green,
              ),

              _opcaoPagamento(
                id: 'CARTAO_ENTREGA',
                titulo: 'Cartão na entrega',
                descricao:
                    'Pague com cartão ao receber',
                icone:
                    Icons.point_of_sale_outlined,
                cor: Colors.blueGrey,
              ),

              const SizedBox(height: 8),

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
                        'Pagamento protegido pelo checkout FoodJet.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      preco(total),
                      style: const TextStyle(
                        color: laranja,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 57,
                child: ElevatedButton(
                  onPressed: processando
                      ? null
                      : continuarPagamento,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.grey.shade400,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
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
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PAGAR ${preco(total)}',
                              style: const TextStyle(
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
      ),
    );
  }
}