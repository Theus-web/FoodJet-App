
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  const PaymentScreen({
    super.key,
    required this.endereco,
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
        backgroundColor:
            erro ? Colors.red.shade700 : laranja,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // TOKEN PADRONIZADO
  // ============================================================


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

    if (total <= 0) {
      _mensagem(
        'O valor do pedido é inválido.',
        erro: true,
      );

      Navigator.pop(context);
      return;
    }

    final forma = widget.formaPagamento
        .trim()
        .toUpperCase();

    debugPrint(
      '💳 FORMA DE PAGAMENTO RECEBIDA: $forma',
    );

    // ==========================================================
    // PIX
    // ==========================================================

    if (forma == 'PIX') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PixCheckoutPage(
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
  State<CardPaymentPage> createState() =>
      _CardPaymentPageState();
}

class _CardPaymentPageState
    extends State<CardPaymentPage> {
  static const Color laranja = Color(0xFFF97316);

  final _formKey = GlobalKey<FormState>();

  final numeroController =
      TextEditingController();

  final nomeController =
      TextEditingController();

  final validadeController =
      TextEditingController();

  final cvvController =
      TextEditingController();

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
  // MESMO TOKEN DO PIX
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
  // PAGAR CARTÃO
  // ============================================================

  Future<void> _pagar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final token =
        await _obterToken();

    if (token == null) {
      _mensagem(
        'Sessão expirada. Faça login novamente.',
        erro: true,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      carregando = true;
    });

    try {
      // ========================================================
      // ENDPOINT CORRETO
      // ========================================================

      final String endpoint;

      if (widget.formaPagamento == 'DEBITO') {
        endpoint =
            '/pagamentos/debito';
      } else {
        endpoint =
            '/pagamentos/cartao';
      }

      final url = Uri.parse(
        '${Api.baseUrl}$endpoint',
      );

      debugPrint(
        '========================================',
      );

      debugPrint(
        '💳 FOODJET PAGAMENTO',
      );

      debugPrint(
        'FORMA: ${widget.formaPagamento}',
      );

      debugPrint(
        'ENDPOINT: $endpoint',
      );

      debugPrint(
        'TOKEN: ${token.isNotEmpty ? "SIM" : "NÃO"}',
      );

      debugPrint(
        '========================================',
      );

      // ========================================================
      // ITENS
      // ========================================================

      final itens =
          widget.itens.map((item) {
        return {
          'produtoId':
              item.nome,
          'nome':
              item.nome,
          'quantidade':
              item.quantidade,
          'preco':
              item.preco,
          'valor':
              item.preco *
                  item.quantidade,
        };
      }).toList();

      // ========================================================
      // BODY
      // ========================================================

      final body = {
        'valor':
            double.parse(
          widget.total
              .toStringAsFixed(2),
        ),

        'total':
            double.parse(
          widget.total
              .toStringAsFixed(2),
        ),

        'subtotal':
            double.parse(
          widget.subtotal
              .toStringAsFixed(2),
        ),

        'taxaEntrega':
            double.parse(
          widget.taxaEntrega
              .toStringAsFixed(2),
        ),

        'taxaServico':
            double.parse(
          widget.taxaServico
              .toStringAsFixed(2),
        ),

        'restauranteId':
            widget.restauranteId,

        'formaPagamento':
            widget.formaPagamento,

        'endereco':
            widget.endereco,

        'itens':
            itens,

        // Para o débito o Asaas não processa
        // os dados diretamente pela API.
        //
        // Para crédito, o backend pode usar
        // os dados conforme sua implementação.
        'cartao': {
          'numero':
              numeroController.text
                  .replaceAll(
                    ' ',
                    '',
                  ),

          'nome':
              nomeController.text
                  .trim(),

          'validade':
              validadeController.text
                  .trim(),

          'cvv':
              cvvController.text
                  .trim(),
        },
      };

      // ========================================================
      // POST COM BEARER
      // ========================================================

      final response =
          await http.post(
        url,

        headers: {
          'Content-Type':
              'application/json',

          // MESMO PADRÃO DO PIX
          'Authorization':
              'Bearer $token',
        },

        body:
            jsonEncode(body),
      ).timeout(
        const Duration(
          seconds: 60,
        ),
      );

      debugPrint(
        '💳 HTTP: ${response.statusCode}',
      );

      debugPrint(
        '💳 BODY: ${response.body}',
      );

      dynamic dados;

      try {
        dados =
            jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Resposta inválida do servidor.',
        );
      }

      // ========================================================
      // ERRO HTTP
      // ========================================================

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String mensagem =
            'Não foi possível processar o pagamento.';

        if (dados is Map) {
          mensagem =
              dados['erro']
                      ?.toString() ??
                  dados['message']
                      ?.toString() ??
                  dados['error']
                      ?.toString() ??
                  mensagem;
        }

        throw Exception(
          mensagem,
        );
      }

      // ========================================================
      // ERRO DE NEGÓCIO
      // ========================================================

      if (dados is Map &&
          dados['sucesso'] == false) {
        throw Exception(
          dados['erro']
                  ?.toString() ??
              'Pagamento não aprovado.',
        );
      }

      // ========================================================
      // DÉBITO
      // ========================================================

      if (widget.formaPagamento ==
          'DEBITO') {
        final invoiceUrl =
            dados is Map
                ? dados['invoiceUrl']
                    ?.toString()
                : null;

        if (invoiceUrl != null &&
            invoiceUrl.isNotEmpty) {
          _mensagem(
            'Cobrança criada. Continue o pagamento pela fatura do Asaas.',
          );

          await Future.delayed(
            const Duration(
              milliseconds: 700,
            ),
          );

          if (!mounted) return;

          // Não abrimos URL automaticamente
          // para evitar depender de pacote externo.
          //
          // Exibe a URL para o usuário copiar.
          await showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title:
                    const Text(
                  'Pagamento com débito',
                ),
                content:
                    SelectableText(
                  invoiceUrl,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              invoiceUrl,
                        ),
                      );

                      Navigator.pop(
                        context,
                      );

                      _mensagem(
                        'Link da fatura copiado.',
                      );
                    },
                    child:
                        const Text(
                      'COPIAR LINK',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    child:
                        const Text(
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
        widget.formaPagamento ==
                'CREDITO'
            ? 'Pagamento com cartão de crédito enviado para processamento.'
            : 'Pagamento enviado para processamento.',
      );

      await Future.delayed(
        const Duration(
          milliseconds: 800,
        ),
      );

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {
      debugPrint(
        '❌ ERRO CARTÃO/DÉBITO: $e',
      );

      if (!mounted) return;

      _mensagem(
        e.toString()
            .replaceFirst(
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
      prefixIcon:
          Icon(icon),
      filled: true,
      fillColor:
          Colors.white,
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            BorderSide.none,
      ),
    );
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
        title: Text(
          titulo,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child:
              SingleChildScrollView(
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
                    16,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  child: Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        color:
                            laranja,
                        size: 30,
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            Text(
                              titulo,
                              style:
                                  const TextStyle(
                                fontSize:
                                    17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              'Total: ${dinheiro(widget.total)}',
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                TextFormField(
                  controller:
                      numeroController,

                  keyboardType:
                      TextInputType.number,

                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly,

                    LengthLimitingTextInputFormatter(
                      16,
                    ),
                  ],

                  decoration:
                      _decoracao(
                    'Número do cartão',
                    Icons.credit_card,
                  ),

                  validator: (
                    value,
                  ) {
                    final numero =
                        value
                                ?.replaceAll(
                              ' ',
                              '',
                            ) ??
                            '';

                    if (numero.length <
                        13) {
                      return 'Digite o número do cartão';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 14,
                ),

                TextFormField(
                  controller:
                      nomeController,

                  textCapitalization:
                      TextCapitalization
                          .words,

                  decoration:
                      _decoracao(
                    'Nome no cartão',
                    Icons.person_outline,
                  ),

                  validator: (
                    value,
                  ) {
                    if (value ==
                            null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Digite o nome do cartão';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 14,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          TextFormField(
                        controller:
                            validadeController,

                        keyboardType:
                            TextInputType
                                .number,

                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,

                           LengthLimitingTextInputFormatter(
                            4,
                          ),
                        ],

                        decoration:
                            _decoracao(
                          'Validade',
                          Icons.date_range,
                        ),

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value.length !=
                                  4) {
                            return 'MM/AA';
                          }

                          return null;
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                          TextFormField(
                        controller:
                            cvvController,

                        keyboardType:
                            TextInputType
                                .number,

                        obscureText:
                            true,

                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,

                           LengthLimitingTextInputFormatter(
                            4,
                          ),
                        ],

                        decoration:
                            _decoracao(
                          'CVV',
                          Icons.lock_outline,
                        ),

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value.length <
                                  3) {
                            return 'CVV inválido';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 22,
                ),

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
                        const Color(
                      0xFFEFFAF4,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),

                  child: const Row(
                    children: [
                      Icon(
                        Icons
                            .verified_user_outlined,
                        color:
                            Colors.green,
                      ),

                      SizedBox(
                        width: 9,
                      ),

                      Expanded(
                        child:
                            Text(
                          'Pagamento processado com segurança.',
                          style:
                              TextStyle(
                            fontSize:
                                12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                SizedBox(
                  width:
                      double.infinity,

                  height: 56,

                  child:
                      ElevatedButton(
                    onPressed:
                        carregando
                            ? null
                            : _pagar,

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
                            : Text(
                                'PAGAR ${dinheiro(widget.total)}',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w800,
                                  fontSize:
                                      15,
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
  final double total;
  final double subtotal;
  final double taxaEntrega;
  final double taxaServico;
  final String restauranteId;
  final Map<String, String> endereco;
  final List<CartItem> itens;

  const CashPaymentPage({
    super.key,
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

  // ============================================================
  // MESMO TOKEN
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

    if (!mounted) return;

    setState(() {
      carregando = true;
    });

    try {
      final url = Uri.parse(
        '${Api.baseUrl}/orders',
      );

      final itens =
          widget.itens.map((item) {
        return {
          'produtoId':
              item.nome,
          'nome':
              item.nome,
          'quantidade':
              item.quantidade,
          'preco':
              item.preco,
          'valor':
              item.preco *
                  item.quantidade,
        };
      }).toList();

      final body = {
        'restauranteId':
            widget.restauranteId,

        'formaPagamento':
            'DINHEIRO',

        'pagamento':
            'DINHEIRO',

        'statusPagamento':
            'PENDING',

        'subtotal':
            widget.subtotal,

        'taxaEntrega':
            widget.taxaEntrega,

        'taxaServico':
            widget.taxaServico,

        'total':
            widget.total,

        'endereco':
            widget.endereco,

        'itens':
            itens,
      };

      final response =
          await http.post(
        url,

        headers: {
          'Content-Type':
              'application/json',

          'Authorization':
              'Bearer $token',
        },

        body:
            jsonEncode(body),
      ).timeout(
        const Duration(
          seconds: 30,
        ),
      );

      debugPrint(
        '💵 HTTP: ${response.statusCode}',
      );

      debugPrint(
        '💵 BODY: ${response.body}',
      );

      final dados =
          jsonDecode(
        response.body,
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          dados is Map
              ? dados['erro']
                      ?.toString() ??
                  dados['message']
                      ?.toString() ??
                  'Não foi possível criar o pedido.'
              : 'Não foi possível criar o pedido.',
        );
      }

      if (dados is Map &&
          dados['sucesso'] == false) {
        throw Exception(
          dados['erro']
                  ?.toString() ??
              'Não foi possível criar o pedido.',
        );
      }

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
        e.toString()
            .replaceFirst(
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
                        Icons
                            .payments_outlined,
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
                      height: 18,
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

// ============================================================================
// PIX CHECKOUT ASAAS
// ============================================================================

class PixCheckoutPage extends StatefulWidget {
  final double total;
  final double subtotal;
  final double taxaEntrega;
  final double taxaServico;
  final String restauranteId;
  final Map<String, String> endereco;
  final List<CartItem> itens;

  const PixCheckoutPage({
    super.key,
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

class _PixCheckoutPageState extends State<PixCheckoutPage> {
  static const Color laranja = Color(0xFFF97316);
  static const Color verdePix = Color(0xFF00A884);

  bool carregando = true;
  bool erro = false;

  String mensagemErro = '';

  // ID DO PEDIDO FOODJET
  String? pedidoId;

  // ID DO PAGAMENTO ASAAS
  String? pagamentoId;

  String? pixPayload;
  String? encodedImage;
  String? expirationDate;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _iniciarFluxoPix();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
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
  // DECODIFICAR RESPOSTA DO BACKEND COM DIAGNÓSTICO COMPLETO
  // ============================================================

  dynamic _decodificarResposta(
    http.Response response,
    String origem,
  ) {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('🌐 RESPOSTA DO SERVIDOR');
    debugPrint('📍 ORIGEM: $origem');
    debugPrint('📊 STATUS HTTP: ${response.statusCode}');
    debugPrint(
      '📄 CONTENT-TYPE: ${response.headers['content-type'] ?? 'não informado'}',
    );
    debugPrint('📦 BODY:');
    debugPrint(response.body);
    debugPrint('========================================');
    debugPrint('');

    final body = response.body.trim();

    if (body.isEmpty) {
      throw Exception(
        '$origem: o servidor retornou uma resposta vazia. HTTP ${response.statusCode}.',
      );
    }

    try {
      return jsonDecode(body);
    } catch (e) {
      debugPrint('❌ ERRO AO DECODIFICAR JSON');
      debugPrint('📍 ORIGEM: $origem');
      debugPrint('❌ ERRO: $e');
      debugPrint('📦 RESPOSTA RECEBIDA: $body');

      throw Exception(
        '$origem: o servidor não retornou JSON válido. HTTP ${response.statusCode}.',
      );
    }
  }

  // ============================================================
  // INICIAR FLUXO COMPLETO
  //
  // 1. CRIA PEDIDO
  // 2. RECEBE pedidoId
  // 3. CRIA PIX NO ASAAS
  // ============================================================

  Future<void> _iniciarFluxoPix() async {
  debugPrint('🚀 ========================================');
  debugPrint('🚀 INICIANDO FLUXO PIX');
  debugPrint('🚀 ========================================');

  debugPrint('🏪 restauranteId: ${widget.restauranteId}');
  debugPrint('💰 subtotal: ${widget.subtotal}');
  debugPrint('🚚 taxaEntrega: ${widget.taxaEntrega}');
  debugPrint('⚙️ taxaServico: ${widget.taxaServico}');
  debugPrint('💰 TOTAL: ${widget.total}');
  debugPrint('🛒 ITENS: ${widget.itens.length}');
  debugPrint('🌐 API BASE: ${Api.baseUrl}');

  if (!mounted) return;

  setState(() {
    carregando = true;
    erro = false;
    mensagemErro = '';
  });

  try {
    debugPrint('✅ Entrou no try do PIX');

    if (widget.itens.isEmpty) {
      debugPrint('❌ ERRO: carrinho vazio');

      throw Exception(
        'Seu carrinho está vazio.',
      );
    }

    if (widget.restauranteId.trim().isEmpty) {
      debugPrint('❌ ERRO: restauranteId vazio');

      throw Exception(
        'Restaurante não identificado.',
      );
    }

    if (widget.total <= 0) {
      debugPrint(
        '❌ ERRO: total inválido: ${widget.total}',
      );

      throw Exception(
        'O valor do pedido é inválido.',
      );
    }

    debugPrint('✅ Validações iniciais OK');

    final token = await _obterToken();

    debugPrint(
      '🔐 Token retornado: ${token != null ? "SIM" : "NÃO"}',
    );

    if (token == null) {
      throw Exception(
        'Sessão expirada. Faça login novamente.',
      );
    }

    debugPrint('➡️ Chamando _criarPedido()');

    final id = await _criarPedido(token);

    debugPrint(
      '✅ _criarPedido() terminou: $id',
    );

    pedidoId = id;

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
  // CRIAR PEDIDO
  // ============================================================

  Future<String> _criarPedido(String token) async {
    final url = Uri.parse(
      '${Api.baseUrl}/orders',
    );

    // ----------------------------------------------------------
    // ITENS
    // ----------------------------------------------------------

    final itens = widget.itens.map((item) {
      return {
        'produtoId': item.nome,
        'nome': item.nome,
        'quantidade': item.quantidade,
        'preco': item.preco,
        'valor': item.preco * item.quantidade,
      };
    }).toList();

    // ----------------------------------------------------------
    // BODY DO PEDIDO
    // ----------------------------------------------------------

    final body = {
      'restauranteId': widget.restauranteId,

      'formaPagamento': 'PIX',

      'pagamento': 'PIX',

      // O pedido fica pendente até o webhook
      // confirmar o pagamento no Asaas.
      'statusPagamento': 'PENDING',

      'subtotal': double.parse(
        widget.subtotal.toStringAsFixed(2),
      ),

      'taxaEntrega': double.parse(
        widget.taxaEntrega.toStringAsFixed(2),
      ),

      'taxaServico': double.parse(
        widget.taxaServico.toStringAsFixed(2),
      ),

      'total': double.parse(
        widget.total.toStringAsFixed(2),
      ),

      'endereco': widget.endereco,

      'itens': itens,
    };

    debugPrint(
      '========================================',
    );

    debugPrint(
      '🛒 FOODJET - CRIANDO PEDIDO',
    );

    debugPrint(
      'RESTAURANTE: ${widget.restauranteId}',
    );

    debugPrint(
      'FORMA: PIX',
    );

    debugPrint(
      'TOTAL: ${widget.total}',
    );

    debugPrint(
      '========================================',
    );

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
          const Duration(
            seconds: 30,
          ),
        );

    debugPrint(
      '🛒 CRIAR PEDIDO HTTP: ${response.statusCode}',
    );

    debugPrint(
      '🛒 CRIAR PEDIDO BODY: ${response.body}',
    );

    final dynamic dados = _decodificarResposta(
      response,
      'CRIAR PEDIDO',
    );

    // ----------------------------------------------------------
    // ERRO HTTP
    // ----------------------------------------------------------

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String mensagem =
          'Não foi possível criar o pedido.';

      if (dados is Map) {
        mensagem =
            dados['erro']?.toString() ??
            dados['message']?.toString() ??
            dados['error']?.toString() ??
            mensagem;
      }

      throw Exception(mensagem);
    }

    // ----------------------------------------------------------
    // ERRO DE NEGÓCIO
    // ----------------------------------------------------------

    if (dados is Map &&
        dados['sucesso'] == false) {
      throw Exception(
        dados['erro']?.toString() ??
            dados['message']?.toString() ??
            'Não foi possível criar o pedido.',
      );
    }

    // ----------------------------------------------------------
    // LOCALIZAR PEDIDO ID
    //
    // Aceitamos os formatos mais comuns para não depender
    // de uma única estrutura da resposta.
    // ----------------------------------------------------------

    String? id;

    if (dados is Map) {
      // Exemplo:
      // { "pedidoId": "123" }
      id = _stringValue(
        dados['pedidoId'],
      );

      // Exemplo:
      // { "id": "123" }
      id ??= _stringValue(
        dados['id'],
      );

      // Exemplo:
      // { "pedido": { "id": "123" } }
      if (id == null &&
          dados['pedido'] is Map) {
        final pedido = dados['pedido'];

        id = _stringValue(
          pedido['pedidoId'],
        );

        id ??= _stringValue(
          pedido['id'],
        );
      }

      // Exemplo:
      // { "data": { "id": "123" } }
      if (id == null &&
          dados['data'] is Map) {
        final data = dados['data'];

        id = _stringValue(
          data['pedidoId'],
        );

        id ??= _stringValue(
          data['id'],
        );
      }
    }

    if (id == null || id.isEmpty) {
      debugPrint(
        '❌ SERVIDOR NÃO RETORNOU pedidoId',
      );

      throw Exception(
        'O pedido foi criado, mas o servidor não retornou o ID do pedido.',
      );
    }

    debugPrint(
      '✅ pedidoId RECEBIDO: $id',
    );

    return id;
  }

  // ============================================================
  // GERAR PIX ASAAS
  // ============================================================

  Future<void> _gerarPix(String token) async {
    if (pedidoId == null ||
        pedidoId!.trim().isEmpty) {
      throw Exception(
        'Pedido não identificado para gerar o Pix.',
      );
    }

    final url = Uri.parse(
      '${Api.baseUrl}/pagamentos/pix',
    );

    // ----------------------------------------------------------
    // ITENS
    // ----------------------------------------------------------

    final itens = widget.itens.map((item) {
      return {
        'produtoId': item.nome,
        'nome': item.nome,
        'quantidade': item.quantidade,
        'preco': item.preco,
        'valor': item.preco * item.quantidade,
      };
    }).toList();

    // ----------------------------------------------------------
    // BODY PIX
    // ----------------------------------------------------------

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

      // ========================================================
      // AQUI ESTÁ A CORREÇÃO PRINCIPAL
      // ========================================================

      'pedidoId': pedidoId,

      'formaPagamento': 'PIX',

      'endereco': widget.endereco,

      'itens': itens,
    };

    debugPrint(
      '========================================',
    );

    debugPrint(
      '💠 FOODJET - GERANDO PIX ASAAS',
    );

    debugPrint(
      '🆔 PEDIDO ID: $pedidoId',
    );

    debugPrint(
      '💰 VALOR: ${widget.total}',
    );

    debugPrint(
      '🏪 RESTAURANTE: ${widget.restauranteId}',
    );

    debugPrint(
      '========================================',
    );

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

    // ----------------------------------------------------------
    // DECODIFICAR RESPOSTA
    // ----------------------------------------------------------

    final dynamic dados = _decodificarResposta(
      response,
      'GERAR PIX',
    );

    // ----------------------------------------------------------
    // ERRO HTTP
    // ----------------------------------------------------------

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

      throw Exception(detalhe);
    }

    // ----------------------------------------------------------
    // VALIDAR SUCESSO
    // ----------------------------------------------------------

    if (dados is! Map) {
      throw Exception(
        'Resposta inválida do servidor.',
      );
    }

    if (dados['sucesso'] == false) {
      throw Exception(
        dados['erro']?.toString() ??
            dados['message']?.toString() ??
            'Não foi possível gerar o Pix.',
      );
    }

    // ----------------------------------------------------------
    // PAGAMENTO ID
    // ----------------------------------------------------------

    pagamentoId = _stringValue(
      dados['pagamentoId'],
    );

    pagamentoId ??= _stringValue(
      dados['paymentId'],
    );

    pagamentoId ??= _stringValue(
      dados['id'],
    );

    // ----------------------------------------------------------
    // DADOS PIX
    // ----------------------------------------------------------

    final pix = dados['pix'] is Map
        ? dados['pix']
        : <dynamic, dynamic>{};

    pixPayload = _stringValue(
      pix['qrCode'],
    );

    encodedImage = _stringValue(
      pix['qrCodeBase64'],
    );

    expirationDate = _stringValue(
      pix['expiracao'],
    );

    // Algumas respostas podem usar
    // nomes alternativos.

    pixPayload ??= _stringValue(
      pix['payload'],
    );

    encodedImage ??= _stringValue(
      pix['encodedImage'],
    );

    expirationDate ??= _stringValue(
      pix['expirationDate'],
    );

    // ----------------------------------------------------------
    // VALIDAR DADOS PIX
    // ----------------------------------------------------------

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
  // STRING SEGURA
  // ============================================================

  String? _stringValue(dynamic valor) {
    if (valor == null) {
      return null;
    }

    final texto = valor.toString().trim();

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
        backgroundColor: verdePix,
        behavior: SnackBarBehavior.floating,
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
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Icon(
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

      final bytes = base64Decode(
        base64String,
      );

      return Container(
        width: 240,
        height: 240,
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
        ),
      );
    } catch (_) {
      return Container(
        width: 240,
        height: 240,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Icon(
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
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Criando pedido e gerando seu Pix.',
            textAlign: TextAlign.center,
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
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              mensagemErro,
              textAlign: TextAlign.center,
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed: _iniciarFluxoPix,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: laranja,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
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
          // ------------------------------------------------------
          // SEGURANÇA
          // ------------------------------------------------------

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFE4F7EF),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: verdePix,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pagamento seguro processado pelo Asaas.',
                    style: TextStyle(
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

          // ------------------------------------------------------
          // PEDIDO
          // ------------------------------------------------------

          if (pedidoId != null &&
              pedidoId!.isNotEmpty)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              margin:
                  const EdgeInsets.only(
                bottom: 18,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: laranja,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
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

          // ------------------------------------------------------
          // QR CODE
          // ------------------------------------------------------

          const Text(
            'Escaneie o QR Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Center(
            child: _qrCode(),
          ),

          const SizedBox(
            height: 20,
          ),

          // ------------------------------------------------------
          // PIX COPIA E COLA
          // ------------------------------------------------------

          const Text(
            'Ou copie o código Pix',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Container(
            padding:
                const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
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
                  onPressed: _copiarPix,
                  icon: const Icon(
                    Icons.copy_outlined,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ------------------------------------------------------
          // VALORES
          // ------------------------------------------------------

          Container(
            padding:
                const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Column(
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
                  destaque: true,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // ------------------------------------------------------
          // INFORMAÇÃO
          // ------------------------------------------------------

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: laranja,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Após o pagamento, o Asaas notificará o FoodJet automaticamente. O pedido será atualizado quando o pagamento for confirmado.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // ------------------------------------------------------
          // VOLTAR
          // ------------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: laranja,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'VOLTAR AO PEDIDO',
                style: TextStyle(
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
            child: Text(
              expirationDate != null &&
                      expirationDate!.isNotEmpty
                  ? 'QR Code válido até $expirationDate'
                  : 'Pix gerado com segurança pelo Asaas',
              style: TextStyle(
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black87,
        elevation: 0,
        title: const Text(
          'PIX',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: carregando
            ? _carregando()
            : erro
                ? _erro()
                : _conteudo(),
      ),
    );
  }
}

