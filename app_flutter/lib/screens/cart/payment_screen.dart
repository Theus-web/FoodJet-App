
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'order_tracking_screen.dart';

import '../../config/api.dart';
import 'cart_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, String> endereco;
  final List<CartItem> itens;
  final double subtotal;
  final String restauranteId;

  final double taxaEntrega;
  final double taxaServico;

  final String formaPagamento;

  // ID DO PEDIDO JÁ CRIADO PELO OrderReviewScreen
  final String pedidoId;

  const PaymentScreen({
    super.key,
    required this.endereco,
    required this.pedidoId,
    required this.itens,
    required this.subtotal,
    required this.restauranteId,
    this.taxaEntrega = 6.50,
    this.taxaServico = 0.0,
    this.formaPagamento = 'PIX',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const Color laranja = Color(0xFFF97316);

  double get total =>
      widget.subtotal +
      widget.taxaServico +
      widget.taxaEntrega;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _iniciarPagamento();
    });
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
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
        backgroundColor: erro ? Colors.red.shade700 : laranja,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // INICIAR PAGAMENTO
  // ============================================================

  void _iniciarPagamento() {
    if (!mounted) return;

    if (widget.itens.isEmpty) {
      _mensagem(
        'Seu carrinho está vazio.',
        erro: true,
      );

      Navigator.pop(context);
      return;
    }

    if (widget.restauranteId.trim().isEmpty) {
      _mensagem(
        'Restaurante não identificado.',
        erro: true,
      );

      Navigator.pop(context);
      return;
    }

    if (widget.pedidoId.trim().isEmpty) {
      _mensagem(
        'Pedido não identificado.',
        erro: true,
      );

      Navigator.pop(context);
      return;
    }

    if (total <= 0) {
      _mensagem(
        'O valor do pedido é inválido.',
        erro: true,
      );

      Navigator.pop(context);
      return;
    }

    final forma = widget.formaPagamento.trim().toUpperCase();

    debugPrint('========================================');
    debugPrint('💳 FOODJET - INICIAR PAGAMENTO');
    debugPrint('🆔 PEDIDO ID: ${widget.pedidoId}');
    debugPrint('🏪 RESTAURANTE: ${widget.restauranteId}');
    debugPrint('💰 TOTAL: $total');
    debugPrint('💳 FORMA: $forma');
    debugPrint('========================================');

    // ==========================================================
    // PIX
    // ==========================================================

    if (forma == 'PIX') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PixCheckoutPage(
            pedidoId: widget.pedidoId,
            total: total,
            subtotal: widget.subtotal,
            taxaEntrega: widget.taxaEntrega,
            taxaServico: widget.taxaServico,
            restauranteId: widget.restauranteId,
            endereco: widget.endereco,
            itens: widget.itens,
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // CRÉDITO
    // ==========================================================

    if (forma == 'CREDITO' ||
        forma == 'CRÉDITO' ||
        forma == 'CREDIT_CARD') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CardPaymentPage(
            pedidoId: widget.pedidoId,
            formaPagamento: 'CREDITO',
            total: total,
            subtotal: widget.subtotal,
            taxaEntrega: widget.taxaEntrega,
            taxaServico: widget.taxaServico,
            restauranteId: widget.restauranteId,
            endereco: widget.endereco,
            itens: widget.itens,
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // DÉBITO
    // ==========================================================

    if (forma == 'DEBITO' ||
        forma == 'DÉBITO' ||
        forma == 'DEBIT_CARD') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CardPaymentPage(
            pedidoId: widget.pedidoId,
            formaPagamento: 'DEBITO',
            total: total,
            subtotal: widget.subtotal,
            taxaEntrega: widget.taxaEntrega,
            taxaServico: widget.taxaServico,
            restauranteId: widget.restauranteId,
            endereco: widget.endereco,
            itens: widget.itens,
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // DINHEIRO
    // ==========================================================

    if (forma == 'DINHEIRO') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CashPaymentPage(
            pedidoId: widget.pedidoId,
            total: total,
            subtotal: widget.subtotal,
            taxaEntrega: widget.taxaEntrega,
            taxaServico: widget.taxaServico,
            restauranteId: widget.restauranteId,
            endereco: widget.endereco,
            itens: widget.itens,
          ),
        ),
      );

      return;
    }

    _mensagem(
      'Forma de pagamento inválida: $forma',
      erro: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF97316),
        ),
      ),
    );
  }
}

// ============================================================================
// PAGAMENTO COM CARTÃO
// ============================================================================

class CardPaymentPage extends StatefulWidget {
  final String pedidoId;
  final String formaPagamento;
  final double total;
  final double subtotal;
  final double taxaEntrega;
  final double taxaServico;
  final String restauranteId;
  final Map<String, String> endereco;
  final List<CartItem> itens;

  const CardPaymentPage({
    super.key,
    required this.pedidoId,
    required this.formaPagamento,
    required this.total,
    required this.subtotal,
    required this.taxaEntrega,
    required this.taxaServico,
    required this.restauranteId,
    required this.endereco,
    required this.itens,
  });

  @override
  State<CardPaymentPage> createState() => _CardPaymentPageState();
}

class _CardPaymentPageState extends State<CardPaymentPage> {
  static const Color laranja = Color(0xFFF97316);

  final _formKey = GlobalKey<FormState>();

  final numeroController = TextEditingController();
  final nomeController = TextEditingController();
  final validadeController = TextEditingController();
  final cvvController = TextEditingController();

  bool carregando = false;

  @override
  void dispose() {
    numeroController.dispose();
    nomeController.dispose();
    validadeController.dispose();
    cvvController.dispose();

    super.dispose();
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get titulo {
    if (widget.formaPagamento == 'CREDITO') {
      return 'Cartão de crédito';
    }

    return 'Cartão de débito';
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> _obterToken() async {
    final prefs = await SharedPreferences.getInstance();

    const chaves = [
      'token',
      'jwt',
      'access_token',
      'auth_token',
    ];

    for (final chave in chaves) {
      final valor = prefs.getString(chave);

      if (valor == null) {
        continue;
      }

      var token = valor.trim();

      if (token.isEmpty) {
        continue;
      }

      if (token.toLowerCase().startsWith('bearer ')) {
        token = token.substring(7).trim();
      }

      if (token.isNotEmpty) {
        debugPrint(
          '🔐 TOKEN ENCONTRADO PARA PAGAMENTO: $chave',
        );

        return token;
      }
    }

    debugPrint(
      '❌ NENHUM TOKEN ENCONTRADO NO STORAGE',
    );

    return null;
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
        backgroundColor: erro ? Colors.red.shade700 : laranja,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // PAGAR CARTÃO
  // ============================================================

  Future<void> _pagar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final token = await _obterToken();

    if (token == null) {
      _mensagem(
        'Sessão expirada. Faça login novamente.',
        erro: true,
      );
      return;
    }

    if (widget.pedidoId.trim().isEmpty) {
      _mensagem(
        'Pedido não identificado.',
        erro: true,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      carregando = true;
    });

    try {
      final String endpoint;

      if (widget.formaPagamento == 'DEBITO') {
        endpoint = '/pagamentos/debito';
      } else {
        endpoint = '/pagamentos/cartao';
      }

      final url = Uri.parse(
        '${Api.baseUrl}$endpoint',
      );

      debugPrint('========================================');
      debugPrint('💳 FOODJET PAGAMENTO');
      debugPrint('🆔 PEDIDO ID: ${widget.pedidoId}');
      debugPrint('💳 FORMA: ${widget.formaPagamento}');
      debugPrint('📍 ENDPOINT: $endpoint');
      debugPrint('========================================');

      final itens = widget.itens.map((item) {
        return {
          'produtoId': item.nome,
          'nome': item.nome,
          'quantidade': item.quantidade,
          'preco': item.preco,
          'valor': item.preco * item.quantidade,
        };
      }).toList();

      final body = {
        // ======================================================
        // PEDIDO JÁ EXISTENTE
        // ======================================================

        'pedidoId': widget.pedidoId,

        'valor': double.parse(
          widget.total.toStringAsFixed(2),
        ),

        'total': double.parse(
          widget.total.toStringAsFixed(2),
        ),

        'subtotal': double.parse(
          widget.subtotal.toStringAsFixed(2),
        ),

        'taxaEntrega': double.parse(
          widget.taxaEntrega.toStringAsFixed(2),
        ),

        'taxaServico': double.parse(
          widget.taxaServico.toStringAsFixed(2),
        ),

        'restauranteId': widget.restauranteId,

        'formaPagamento': widget.formaPagamento,

        'endereco': widget.endereco,

        'itens': itens,

        'cartao': {
          'numero': numeroController.text.replaceAll(
            ' ',
            '',
          ),
          'nome': nomeController.text.trim(),
          'validade': validadeController.text.trim(),
          'cvv': cvvController.text.trim(),
        },
      };

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 60),
          );

      debugPrint(
        '💳 HTTP: ${response.statusCode}',
      );

      debugPrint(
        '💳 BODY: ${response.body}',
      );

      dynamic dados;

      try {
        dados = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Resposta inválida do servidor.',
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String mensagem =
            'Não foi possível processar o pagamento.';

        if (dados is Map) {
          mensagem =
              dados['erro']?.toString() ??
              dados['message']?.toString() ??
              dados['error']?.toString() ??
              mensagem;
        }

        throw Exception(mensagem);
      }

      if (dados is Map &&
          dados['sucesso'] == false) {
        throw Exception(
          dados['erro']?.toString() ??
              dados['message']?.toString() ??
              'Pagamento não aprovado.',
        );
      }

      // ========================================================
      // DÉBITO
      // ========================================================

      if (widget.formaPagamento == 'DEBITO') {
        final invoiceUrl = dados is Map
            ? dados['invoiceUrl']?.toString()
            : null;

        if (invoiceUrl != null &&
            invoiceUrl.isNotEmpty) {
          _mensagem(
            'Cobrança criada. Continue o pagamento pela fatura do Asaas.',
          );

          await Future.delayed(
            const Duration(milliseconds: 700),
          );

          if (!mounted) return;

          await showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: const Text(
                  'Pagamento com débito',
                ),
                content: SelectableText(
                  invoiceUrl,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: invoiceUrl,
                        ),
                      );

                      Navigator.pop(context);

                      _mensagem(
                        'Link da fatura copiado.',
                      );
                    },
                    child: const Text(
                      'COPIAR LINK',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'FECHAR',
                    ),
                  ),
                ],
              );
            },
          );

          return;
        }
      }

      // ========================================================
      // SUCESSO
      // ========================================================

      if (!mounted) return;

      _mensagem(
        widget.formaPagamento == 'CREDITO'
            ? 'Pagamento com cartão de crédito enviado para processamento.'
            : 'Pagamento enviado para processamento.',
      );

      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        '❌ ERRO CARTÃO/DÉBITO: $e',
      );

      if (!mounted) return;

      _mensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  InputDecoration _decoracao(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        color: laranja,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pedido #${widget.pedidoId}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Total: ${dinheiro(widget.total)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: numeroController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  decoration: _decoracao(
                    'Número do cartão',
                    Icons.credit_card,
                  ),
                  validator: (value) {
                    final numero =
                        value?.replaceAll(' ', '') ?? '';

                    if (numero.length < 13) {
                      return 'Digite o número do cartão';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: nomeController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: _decoracao(
                    'Nome no cartão',
                    Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Digite o nome do cartão';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: validadeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: _decoracao(
                          'Validade',
                          Icons.date_range,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.length != 4) {
                            return 'MM/AA';
                          }

                          return null;
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: TextFormField(
                        controller: cvvController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: _decoracao(
                          'CVV',
                          Icons.lock_outline,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.length < 3) {
                            return 'CVV inválido';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFAF4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Colors.green,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Pagamento processado com segurança.',
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        carregando ? null : _pagar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: laranja,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    child: carregando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'PAGAR ${dinheiro(widget.total)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PAGAMENTO EM DINHEIRO
// ============================================================================

class CashPaymentPage extends StatefulWidget {
  final String pedidoId;
  final double total;
  final double subtotal;
  final double taxaEntrega;
  final double taxaServico;
  final String restauranteId;
  final Map<String, String> endereco;
  final List<CartItem> itens;

  const CashPaymentPage({
    super.key,
    required this.pedidoId,
    required this.total,
    required this.subtotal,
    required this.taxaEntrega,
    required this.taxaServico,
    required this.restauranteId,
    required this.endereco,
    required this.itens,
  });

  @override
  State<CashPaymentPage> createState() =>
      _CashPaymentPageState();
}

class _CashPaymentPageState
    extends State<CashPaymentPage> {
  static const Color laranja =
      Color(0xFFF97316);

  bool carregando = false;

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<String?> _obterToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    const chaves = [
      'token',
      'jwt',
      'access_token',
      'auth_token',
    ];

    for (final chave in chaves) {
      final valor =
          prefs.getString(chave);

      if (valor == null) {
        continue;
      }

      var token =
          valor.trim();

      if (token.isEmpty) {
        continue;
      }

      if (token.toLowerCase().startsWith('bearer ')) {
        token =
            token.substring(7).trim();
      }

      if (token.isNotEmpty) {
        return token;
      }
    }

    return null;
  }

  void _mensagem(
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
        backgroundColor:
            erro
                ? Colors.red.shade700
                : laranja,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // CONFIRMAR PEDIDO EM DINHEIRO
  //
  // O pedido já foi criado pelo OrderReviewScreen.
  // Portanto NÃO criamos outro POST /orders aqui.
  // ============================================================

  Future<void> _confirmarPedido() async {
    final token =
        await _obterToken();

    if (token == null) {
      _mensagem(
        'Sessão expirada. Faça login novamente.',
        erro: true,
      );
      return;
    }

    if (widget.pedidoId.trim().isEmpty) {
      _mensagem(
        'Pedido não identificado.',
        erro: true,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      carregando = true;
    });

    try {
      /*
       * O pedido já foi criado anteriormente.
       *
       * Não fazemos POST /orders novamente aqui,
       * pois isso criaria pedido duplicado.
       *
       * O pedido já está registrado como DINHEIRO
       * pelo fluxo anterior.
       */

      debugPrint('========================================');
      debugPrint('💵 FOODJET - PAGAMENTO EM DINHEIRO');
      debugPrint('🆔 PEDIDO ID: ${widget.pedidoId}');
      debugPrint('💰 TOTAL: ${widget.total}');
      debugPrint('========================================');

      if (!mounted) return;

      _mensagem(
        'Pedido confirmado! Pagamento em dinheiro na entrega.',
      );

      await Future.delayed(
        const Duration(
          milliseconds: 900,
        ),
      );

      if (!mounted) return;

      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    } catch (e) {
      debugPrint(
        '❌ ERRO DINHEIRO: $e',
      );

      if (!mounted) return;

      _mensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black87,
        elevation: 0,
        title:
            const Text(
          'Pagamento em dinheiro',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(
            18,
          ),

          child: Column(
            children: [
              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  20,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),

                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration:
                          const BoxDecoration(
                        color:
                            Color(0xFFFFE8D8),
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          const Icon(
                        Icons.payments_outlined,
                        color:
                            laranja,
                        size: 38,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    const Text(
                      'Pagamento em dinheiro',
                      style:
                          TextStyle(
                        fontSize:
                            19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'Você pagará ao entregador quando receber seu pedido.',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize:
                            13,
                        height:
                            1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Text(
                      'Pedido #${widget.pedidoId}',
                      style:
                          TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize:
                            12,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      'Total: ${dinheiro(widget.total)}',
                      style:
                          const TextStyle(
                        color:
                            laranja,
                        fontSize:
                            22,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width:
                    double.infinity,

                height: 56,

                child:
                    ElevatedButton(
                  onPressed:
                      carregando
                          ? null
                          : _confirmarPedido,

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

                  child:
                      carregando
                          ? const SizedBox(
                              width:
                                  24,
                              height:
                                  24,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    2.5,
                              ),
                            )
                          : const Text(
                              'CONFIRMAR PEDIDO',
                              style:
                                  TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight.w800,
                              ),
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

// ============================================================================
// PIX CHECKOUT ASAAS
// ============================================================================

class PixCheckoutPage extends StatefulWidget {
  // ============================================================
  // PEDIDO JÁ CRIADO
  // ============================================================

  final String pedidoId;

  final double total;
  final double subtotal;
  final double taxaEntrega;
  final double taxaServico;
  final String restauranteId;
  final Map<String, String> endereco;
  final List<CartItem> itens;

  const PixCheckoutPage({
    super.key,
    required this.pedidoId,
    required this.total,
    required this.subtotal,
    required this.taxaEntrega,
    required this.taxaServico,
    required this.restauranteId,
    required this.endereco,
    required this.itens,
  });

  @override
  State<PixCheckoutPage> createState() =>
      _PixCheckoutPageState();
}

class _PixCheckoutPageState
    extends State<PixCheckoutPage> {
  static const Color laranja =
      Color(0xFFF97316);

  static const Color verdePix =
      Color(0xFF00A884);

  bool carregando = true;
  bool erro = false;

  String mensagemErro = '';

  // ID DO PEDIDO FOODJET
  late String pedidoId;

  // ID DO PAGAMENTO ASAAS
  String? pagamentoId;

  String? pixPayload;
  String? encodedImage;
  String? expirationDate;

  // ============================================================
  // MONITORAMENTO DO PAGAMENTO
  // ============================================================

  Timer? _timerPagamento;

  bool _pagamentoConfirmado = false;

  bool _navegando = false;

  @override
  void initState() {
    super.initState();

    pedidoId =
        widget.pedidoId;

    _iniciarFluxoPix();
  }

  @override
  void dispose() {
    _timerPagamento?.cancel();

    super.dispose();
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> _obterToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    const chaves = [
      'token',
      'jwt',
      'access_token',
      'auth_token',
    ];

    for (final chave in chaves) {
      final valor =
          prefs.getString(chave);

      if (valor == null) {
        continue;
      }

      var token =
          valor.trim();

      if (token.isEmpty) {
        continue;
      }

      if (token
          .toLowerCase()
          .startsWith('bearer ')) {
        token =
            token.substring(7).trim();
      }

      if (token.isNotEmpty) {
        debugPrint(
          '🔐 TOKEN ENCONTRADO PARA PIX: $chave',
        );

        return token;
      }
    }

    debugPrint(
      '❌ NENHUM TOKEN ENCONTRADO NO STORAGE',
    );

    return null;
  }

  // ============================================================
  // DECODIFICAR RESPOSTA
  // ============================================================

  dynamic _decodificarResposta(
    http.Response response,
    String origem,
  ) {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('🌐 RESPOSTA DO SERVIDOR');
    debugPrint('📍 ORIGEM: $origem');
    debugPrint(
      '📊 STATUS HTTP: ${response.statusCode}',
    );
    debugPrint(
      '📄 CONTENT-TYPE: ${response.headers['content-type'] ?? 'não informado'}',
    );
    debugPrint('📦 BODY:');
    debugPrint(response.body);
    debugPrint('========================================');
    debugPrint('');

    final body =
        response.body.trim();

    if (body.isEmpty) {
      throw Exception(
        '$origem: o servidor retornou uma resposta vazia. HTTP ${response.statusCode}.',
      );
    }

    try {
      return jsonDecode(body);
    } catch (e) {
      debugPrint(
        '❌ ERRO AO DECODIFICAR JSON',
      );

      debugPrint(
        '📍 ORIGEM: $origem',
      );

      debugPrint(
        '❌ ERRO: $e',
      );

      debugPrint(
        '📦 RESPOSTA RECEBIDA: $body',
      );

      throw Exception(
        '$origem: o servidor não retornou JSON válido. HTTP ${response.statusCode}.',
      );
    }
  }

  // ============================================================
  // INICIAR PIX
  // ============================================================

  Future<void> _iniciarFluxoPix() async {
    debugPrint(
      '🚀 ========================================',
    );

    debugPrint(
      '🚀 INICIANDO FLUXO PIX ASAAS',
    );

    debugPrint(
      '🚀 ========================================',
    );

    debugPrint(
      '🆔 pedidoId: ${widget.pedidoId}',
    );

    debugPrint(
      '🏪 restauranteId: ${widget.restauranteId}',
    );

    debugPrint(
      '💰 subtotal: ${widget.subtotal}',
    );

    debugPrint(
      '🚚 taxaEntrega: ${widget.taxaEntrega}',
    );

    debugPrint(
      '⚙️ taxaServico: ${widget.taxaServico}',
    );

    debugPrint(
      '💰 TOTAL: ${widget.total}',
    );

    debugPrint(
      '🛒 ITENS: ${widget.itens.length}',
    );

    debugPrint(
      '🌐 API BASE: ${Api.baseUrl}',
    );

    if (!mounted) return;

    setState(() {
      carregando = true;
      erro = false;
      mensagemErro = '';
    });

    try {
      // ========================================================
      // VALIDAÇÕES
      // ========================================================

      if (widget.itens.isEmpty) {
        throw Exception(
          'Seu carrinho está vazio.',
        );
      }

      if (widget.restauranteId.trim().isEmpty) {
        throw Exception(
          'Restaurante não identificado.',
        );
      }

      if (widget.pedidoId.trim().isEmpty) {
        throw Exception(
          'Pedido não identificado.',
        );
      }

      if (widget.total <= 0) {
        throw Exception(
          'O valor do pedido é inválido.',
        );
      }

      debugPrint(
        '✅ Validações iniciais OK',
      );

      // ========================================================
      // TOKEN
      // ========================================================

      final token =
          await _obterToken();

      debugPrint(
        '🔐 Token retornado: ${token != null ? "SIM" : "NÃO"}',
      );

      if (token == null) {
        throw Exception(
          'Sessão expirada. Faça login novamente.',
        );
      }

      // ========================================================
      // PEDIDO JÁ EXISTE
      // ========================================================

      debugPrint(
        '✅ Pedido já existe.',
      );

      debugPrint(
        '🆔 USANDO PEDIDO EXISTENTE: ${widget.pedidoId}',
      );

      // ========================================================
      // GERAR PIX
      // ========================================================

      debugPrint(
        '➡️ Chamando _gerarPix()',
      );

      await _gerarPix(token);

      debugPrint(
        '✅ _gerarPix() terminou com sucesso',
      );

      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = false;
      });

      // ========================================================
      // INICIAR MONITORAMENTO
      // ========================================================

      await _iniciarMonitoramentoPagamento();

      debugPrint(
        '🎉 ========================================',
      );

      debugPrint(
        '🎉 PIX PREPARADO COM SUCESSO',
      );

      debugPrint(
        '🎉 ========================================',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ ========================================',
      );

      debugPrint(
        '❌ ERRO NO FLUXO PIX',
      );

      debugPrint(
        '❌ ERRO: $e',
      );

      debugPrint(
        '❌ STACKTRACE: $stackTrace',
      );

      debugPrint(
        '❌ ========================================',
      );

      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = true;

        mensagemErro = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // GERAR PIX ASAAS
  // ============================================================

  Future<void> _gerarPix(
    String token,
  ) async {
    if (pedidoId.trim().isEmpty) {
      throw Exception(
        'Pedido não identificado para gerar o Pix.',
      );
    }

    final url = Uri.parse(
      '${Api.baseUrl}/pagamentos/pix',
    );

    final itens =
        widget.itens.map((item) {
      return {
        'produtoId': item.nome,
        'nome': item.nome,
        'quantidade': item.quantidade,
        'preco': item.preco,
        'valor':
            item.preco *
                item.quantidade,
      };
    }).toList();

    // ==========================================================
    // BODY PIX
    // ==========================================================

    final body = {
      'valor': double.parse(
        widget.total.toStringAsFixed(2),
      ),

      'total': double.parse(
        widget.total.toStringAsFixed(2),
      ),

      'subtotal': double.parse(
        widget.subtotal.toStringAsFixed(2),
      ),

      'taxaEntrega': double.parse(
        widget.taxaEntrega.toStringAsFixed(2),
      ),

      'taxaServico': double.parse(
        widget.taxaServico.toStringAsFixed(2),
      ),

      'restauranteId':
          widget.restauranteId,

      'pedidoId':
          pedidoId,

      'formaPagamento':
          'PIX',

      'endereco':
          widget.endereco,

      'itens':
          itens,
    };

    debugPrint(
      '========================================',
    );

    debugPrint(
      '💠 FOODJET - GERANDO PIX ASAAS',
    );

    debugPrint(
      '🆔 PEDIDO FOODJET: $pedidoId',
    );

    debugPrint(
      '💰 VALOR: ${widget.total}',
    );

    debugPrint(
      '🏪 RESTAURANTE: ${widget.restauranteId}',
    );

    debugPrint(
      '📦 BODY: ${jsonEncode(body)}',
    );

    debugPrint(
      '========================================',
    );

    final response =
        await http
            .post(
              url,
              headers: {
                'Content-Type':
                    'application/json',
                'Accept':
                    'application/json',
                'Authorization':
                    'Bearer $token',
              },
              body:
                  jsonEncode(body),
            )
            .timeout(
              const Duration(
                seconds: 30,
              ),
            );

    debugPrint(
      '💠 PIX HTTP: ${response.statusCode}',
    );

    debugPrint(
      '💠 PIX BODY: ${response.body}',
    );

    final dynamic dados =
        _decodificarResposta(
      response,
      'GERAR PIX',
    );

    // ==========================================================
    // ERRO HTTP
    // ==========================================================

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String detalhe =
          'Não foi possível gerar o Pix.';

      if (dados is Map) {
        detalhe =
            dados['erro']?.toString() ??
            dados['message']?.toString() ??
            dados['error']?.toString() ??
            detalhe;
      }

      throw Exception(
        detalhe,
      );
    }

    // ==========================================================
    // VALIDAR MAP
    // ==========================================================

    if (dados is! Map) {
      throw Exception(
        'Resposta inválida do servidor.',
      );
    }

    // ==========================================================
    // ERRO DE NEGÓCIO
    // ==========================================================

    if (dados['sucesso'] == false) {
      throw Exception(
        dados['erro']?.toString() ??
            dados['message']?.toString() ??
            'Não foi possível gerar o Pix.',
      );
    }

    // ==========================================================
    // PAGAMENTO ASAAS
    // ==========================================================

    pagamentoId =
        _stringValue(
      dados['pagamentoId'],
    );

    pagamentoId ??=
        _stringValue(
      dados['paymentId'],
    );

    pagamentoId ??=
        _stringValue(
      dados['id'],
    );

    // ==========================================================
    // DADOS PIX
    // ==========================================================

    final pix =
        dados['pix'] is Map
            ? dados['pix']
            : <dynamic, dynamic>{};

    pixPayload =
        _stringValue(
      pix['qrCode'],
    );

    encodedImage =
        _stringValue(
      pix['qrCodeBase64'],
    );

    expirationDate =
        _stringValue(
      pix['expiracao'],
    );

    pixPayload ??=
        _stringValue(
      pix['payload'],
    );

    encodedImage ??=
        _stringValue(
      pix['encodedImage'],
    );

    expirationDate ??=
        _stringValue(
      pix['expirationDate'],
    );

    // ==========================================================
    // ALGUNS BACKENDS RETORNAM PIX DIRETAMENTE
    // ==========================================================

    pixPayload ??=
        _stringValue(
      dados['qrCode'],
    );

    encodedImage ??=
        _stringValue(
      dados['qrCodeBase64'],
    );

    pixPayload ??=
        _stringValue(
      dados['payload'],
    );

    encodedImage ??=
        _stringValue(
      dados['encodedImage'],
    );

    // ==========================================================
    // VALIDAR PIX
    // ==========================================================

    if ((pixPayload == null ||
            pixPayload!.isEmpty) &&
        (encodedImage == null ||
            encodedImage!.isEmpty)) {
      throw Exception(
        'O servidor criou o pagamento, mas não retornou os dados do Pix.',
      );
    }

    debugPrint(
      '========================================',
    );

    debugPrint(
      '✅ PIX ASAAS GERADO',
    );

    debugPrint(
      '🆔 PEDIDO FOODJET: $pedidoId',
    );

    debugPrint(
      '💳 PAGAMENTO ASAAS: $pagamentoId',
    );

    debugPrint(
      '📊 PIX PAYLOAD: ${pixPayload != null ? "SIM" : "NÃO"}',
    );

    debugPrint(
      '📷 QR CODE: ${encodedImage != null ? "SIM" : "NÃO"}',
    );

    debugPrint(
      '========================================',
    );
  }

  // ============================================================
  // INICIAR MONITORAMENTO DO PAGAMENTO
  // ============================================================

  Future<void> _iniciarMonitoramentoPagamento() async {
    if (pagamentoId == null ||
        pagamentoId!.trim().isEmpty) {
      debugPrint(
        '⚠️ Não foi possível iniciar monitoramento: pagamentoId vazio.',
      );

      return;
    }

    debugPrint(
      '========================================',
    );

    debugPrint(
      '🔎 INICIANDO MONITORAMENTO PIX',
    );

    debugPrint(
      '💳 PAGAMENTO ASAAS: $pagamentoId',
    );

    debugPrint(
      '🆔 PEDIDO FOODJET: $pedidoId',
    );

    debugPrint(
      '⏱️ INTERVALO: 2 SEGUNDOS',
    );

    debugPrint(
      '========================================',
    );

    _timerPagamento?.cancel();

    // ==========================================================
    // PRIMEIRA VERIFICAÇÃO IMEDIATA
    // ==========================================================

    await _verificarPagamento();

    if (_pagamentoConfirmado) {
      return;
    }

    // ==========================================================
    // VERIFICA A CADA 2 SEGUNDOS
    // ==========================================================

    _timerPagamento = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        _verificarPagamento();
      },
    );
  }

  // ============================================================
  // VERIFICAR PAGAMENTO NO BACKEND
  // ============================================================

  Future<void> _verificarPagamento() async {
    if (_pagamentoConfirmado ||
        _navegando) {
      return;
    }

    if (pagamentoId == null ||
        pagamentoId!.trim().isEmpty) {
      return;
    }

    try {
      final token =
          await _obterToken();

      if (token == null) {
        debugPrint(
          '⚠️ Não foi possível verificar pagamento: token ausente.',
        );

        return;
      }

      final url = Uri.parse(
        '${Api.baseUrl}/pagamentos/$pagamentoId',
      );

      final response =
          await http
              .get(
                url,
                headers: {
                  'Accept':
                      'application/json',
                  'Authorization':
                      'Bearer $token',
                },
              )
              .timeout(
                const Duration(
                  seconds: 10,
                ),
              );

      debugPrint(
        '🔎 VERIFICANDO PAGAMENTO $pagamentoId',
      );

      debugPrint(
        '📡 HTTP: ${response.statusCode}',
      );

      debugPrint(
        '📦 BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        return;
      }

      final dynamic dados =
          _decodificarResposta(
        response,
        'VERIFICAR PAGAMENTO',
      );

      final String? status =
          _extrairStatusPagamento(
        dados,
      );

      debugPrint(
        '💳 STATUS PAGAMENTO: ${status ?? "DESCONHECIDO"}',
      );

      if (_statusPagamentoAprovado(
        status,
      )) {
        debugPrint(
          '========================================',
        );

        debugPrint(
          '🎉 PIX CONFIRMADO!',
        );

        debugPrint(
          '💳 PAGAMENTO: $pagamentoId',
        );

        debugPrint(
          '🆔 PEDIDO: $pedidoId',
        );

        debugPrint(
          '📊 STATUS: $status',
        );

        debugPrint(
          '========================================',
        );

        await _pagamentoFoiConfirmado();
      }
    } catch (e) {
      // ========================================================
      // IMPORTANTE:
      //
      // Se uma consulta falhar, não mostramos erro para o
      // cliente. O próximo ciclo tentará novamente.
      // ========================================================

      debugPrint(
        '⚠️ Erro ao consultar status do pagamento: $e',
      );
    }
  }

  // ============================================================
  // EXTRAIR STATUS
  // ============================================================

  String? _extrairStatusPagamento(
    dynamic dados,
  ) {
    if (dados is! Map) {
      return null;
    }

    // ==========================================================
    // RESPOSTAS POSSÍVEIS
    // ==========================================================

    final candidatos = [
      dados['status'],
      dados['statusPagamento'],
      dados['status_pagamento'],
      dados['statusAsaas'],
      dados['status_asaas'],
      dados['paymentStatus'],
      dados['payment_status'],
    ];

    for (final candidato in candidatos) {
      final valor =
          _stringValue(candidato);

      if (valor != null) {
        return valor;
      }
    }

    // ==========================================================
    // OBJETO PAGAMENTO
    // ==========================================================

    final pagamento =
        dados['pagamento'];

    if (pagamento is Map) {
      final candidatosPagamento = [
        pagamento['status'],
        pagamento['statusPagamento'],
        pagamento['status_pagamento'],
        pagamento['statusAsaas'],
        pagamento['status_asaas'],
      ];

      for (final candidato
          in candidatosPagamento) {
        final valor =
            _stringValue(candidato);

        if (valor != null) {
          return valor;
        }
      }
    }

    // ==========================================================
    // OBJETO DADOS
    // ==========================================================

    final dadosInternos =
        dados['dados'];

    if (dadosInternos is Map) {
      final candidatosDados = [
        dadosInternos['status'],
        dadosInternos['statusPagamento'],
        dadosInternos['status_pagamento'],
        dadosInternos['statusAsaas'],
        dadosInternos['status_asaas'],
      ];

      for (final candidato
          in candidatosDados) {
        final valor =
            _stringValue(candidato);

        if (valor != null) {
          return valor;
        }
      }
    }

    return null;
  }

  // ============================================================
  // STATUS APROVADO
  // ============================================================

  bool _statusPagamentoAprovado(
    String? status,
  ) {
    if (status == null) {
      return false;
    }

    final normalizado =
        status
            .trim()
            .toUpperCase();

    const aprovados = {
      'RECEIVED',
      'CONFIRMED',
      'RECEIVED_IN_CASH',
      'APPROVED',
      'APROVADO',
      'PAGO',
      'PAID',
      'PAYMENT_RECEIVED',
      'CONFIRMADO',
    };

    return aprovados.contains(
      normalizado,
    );
  }

  // ============================================================
  // PAGAMENTO CONFIRMADO
  // ============================================================

  Future<void> _pagamentoFoiConfirmado() async {
    if (_pagamentoConfirmado ||
        _navegando ||
        !mounted) {
      return;
    }

    _pagamentoConfirmado = true;

    _timerPagamento?.cancel();
    _timerPagamento = null;

    if (!mounted) {
      return;
    }

    setState(() {
      carregando = true;
      erro = false;
    });

    // ==========================================================
    // PEQUENA PAUSA PARA MOSTRAR CONFIRMAÇÃO
    // ==========================================================

    await Future.delayed(
      const Duration(
        milliseconds: 700,
      ),
    );

    if (!mounted ||
        _navegando) {
      return;
    }

    _navegando = true;

    debugPrint(
      '➡️ NAVEGANDO PARA OrderTrackingScreen',
    );

    debugPrint(
      '🆔 PEDIDO: $pedidoId',
    );

    // ==========================================================
    // ABRIR ACOMPANHAMENTO DO PEDIDO
    // ==========================================================

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OrderTrackingScreen(
          pedidoId:
              int.parse(pedidoId),
        ),
      ),
    );
  }

  // ============================================================
  // STRING SEGURA
  // ============================================================

  String? _stringValue(
    dynamic valor,
  ) {
    if (valor == null) {
      return null;
    }

    final texto =
        valor.toString().trim();

    if (texto.isEmpty) {
      return null;
    }

    return texto;
  }

  // ============================================================
  // COPIAR PIX
  // ============================================================

  Future<void> _copiarPix() async {
    if (pixPayload == null ||
        pixPayload!.isEmpty) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: pixPayload!,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Código Pix copiado!',
        ),
        backgroundColor:
            verdePix,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // QR CODE
  // ============================================================

  Widget _qrCode() {
    if (encodedImage == null ||
        encodedImage!.isEmpty) {
      return Container(
        width: 240,
        height: 240,
        alignment:
            Alignment.center,
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
        child:
            const Icon(
          Icons.qr_code_2,
          size: 110,
          color: Colors.grey,
        ),
      );
    }

    try {
      String base64String =
          encodedImage!.trim();

      if (base64String.contains(',')) {
        base64String =
            base64String.split(',').last;
      }

      final bytes =
          base64Decode(
        base64String,
      );

      return Container(
        width: 240,
        height: 240,
        padding:
            const EdgeInsets.all(
          16,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
        child:
            Image.memory(
          bytes,
          fit:
              BoxFit.contain,
        ),
      );
    } catch (_) {
      return Container(
        width: 240,
        height: 240,
        alignment:
            Alignment.center,
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
        child:
            const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 42,
        ),
      );
    }
  }

  // ============================================================
  // LINHA
  // ============================================================

  Widget _linha(
    String titulo,
    String valor, {
    bool destaque = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: destaque
                ? Colors.black87
                : Colors.grey.shade700,
            fontSize:
                destaque ? 15 : 12,
            fontWeight:
                destaque
                    ? FontWeight.w800
                    : FontWeight.w500,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            color: destaque
                ? laranja
                : Colors.black87,
            fontSize:
                destaque ? 18 : 12,
            fontWeight:
                destaque
                    ? FontWeight.w900
                    : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARREGANDO
  // ============================================================

  Widget _carregando() {
    return const Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: verdePix,
          ),
          SizedBox(height: 20),
          Text(
            'Preparando seu pagamento...',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gerando seu Pix com segurança.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _erro() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 55,
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'Não foi possível preparar o Pix',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              mensagemErro,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed:
                  _iniciarFluxoPix,
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    laranja,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'TENTAR NOVAMENTE',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTEÚDO
  // ============================================================

  Widget _conteudo() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFE4F7EF),
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child:
                const Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color:
                      verdePix,
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                      Text(
                    'Pagamento seguro processado pelo Asaas.',
                    style:
                        TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(12),
            margin:
                const EdgeInsets.only(
              bottom: 18,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color:
                      laranja,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                      Text(
                    'Pedido #$pedidoId',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Text(
            'Escaneie o QR Code',
            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Center(
            child:
                _qrCode(),
          ),

          const SizedBox(
            height: 20,
          ),

          const Text(
            'Ou copie o código Pix',
            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Container(
            padding:
                const EdgeInsets.all(13),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child:
                Row(
              children: [
                Expanded(
                  child:
                      Text(
                    pixPayload ??
                        'Código indisponível',
                    maxLines: 3,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      _copiarPix,
                  icon:
                      const Icon(
                    Icons.copy_outlined,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Container(
            padding:
                const EdgeInsets.all(15),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child:
                Column(
              children: [
                _linha(
                  'Subtotal',
                  dinheiro(
                    widget.subtotal,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                _linha(
                  'Taxa de serviço',
                  dinheiro(
                    widget.taxaServico,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                _linha(
                  'Taxa de entrega',
                  dinheiro(
                    widget.taxaEntrega,
                  ),
                ),

                const Divider(
                  height: 20,
                ),

                _linha(
                  'Total',
                  dinheiro(
                    widget.total,
                  ),
                  destaque:
                      true,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // ======================================================
          // MONITORAMENTO
          // ======================================================

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFE4F7EF),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              border:
                  Border.all(
                color:
                    const Color(0xFFB7E4D1),
              ),
            ),
            child:
                const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color:
                        verdePix,
                  ),
                ),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aguardando confirmação do pagamento',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.black87,
                        ),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Assim que o Asaas confirmar o Pix, esta tela será atualizada automaticamente.',
                        style:
                            TextStyle(
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          SizedBox(
            width:
                double.infinity,
            height: 54,
            child:
                ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
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
                    15,
                  ),
                ),
              ),
              child:
                  const Text(
                'VOLTAR AO PEDIDO',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Center(
            child:
                Text(
              expirationDate !=
                          null &&
                      expirationDate!
                          .isNotEmpty
                  ? 'QR Code válido até $expirationDate'
                  : 'Pix gerado com segurança pelo Asaas',
              style:
                  TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ),

          const SizedBox(
            height: 20,
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
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black87,
        elevation: 0,
        title:
            const Text(
          'PIX',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child:
            carregando
                ? _carregando()
                : erro
                    ? _erro()
                    : _conteudo(),
      ),
    );
  }
}

