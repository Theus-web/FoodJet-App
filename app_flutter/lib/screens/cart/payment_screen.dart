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

    final forma =
        widget.formaPagamento.trim().toUpperCase();

    debugPrint('========================================');
    debugPrint('💳 FOODJET - INICIAR PAGAMENTO');
    debugPrint('🆔 PEDIDO ID: ${widget.pedidoId}');
    debugPrint('🏪 RESTAURANTE: ${widget.restauranteId}');
    debugPrint('💰 TOTAL: $total');
    debugPrint('💳 FORMA: $forma');
    debugPrint('========================================');

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
  State<CardPaymentPage> createState() =>
      _CardPaymentPageState();
}

class _CardPaymentPageState
    extends State<CardPaymentPage> {
  static const Color laranja =
      Color(0xFFF97316);

  static const Color verde =
      Color(0xFF00A884);

  final _formKey =
      GlobalKey<FormState>();

  final numeroController =
      TextEditingController();

  final nomeController =
      TextEditingController();

  final validadeController =
      TextEditingController();

  final cvvController =
      TextEditingController();

  bool carregando = false;

  bool aguardandoPagamento = false;

  bool pagamentoConfirmado = false;

  bool navegando = false;

  Timer? _timerPagamento;

  String? pagamentoId;

  String? statusPagamento;

  @override
  void dispose() {
    _timerPagamento?.cancel();

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
    if (widget.formaPagamento ==
        'CREDITO') {
      return 'Cartão de crédito';
    }

    return 'Cartão de débito';
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
  // PAGAR
  // ============================================================

  Future<void> _pagar() async {
    if (carregando ||
        aguardandoPagamento ||
        pagamentoConfirmado) {
      return;
    }

    if (!_formKey.currentState!
        .validate()) {
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

    if (widget.pedidoId
        .trim()
        .isEmpty) {
      _mensagem(
        'Pedido não identificado.',
        erro: true,
      );

      return;
    }

    if (widget.total <= 0) {
      _mensagem(
        'Valor do pedido inválido.',
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

      if (widget.formaPagamento ==
          'DEBITO') {
        endpoint =
            '/pagamentos/debito';
      } else {
        endpoint =
            '/pagamentos/cartao';
      }

      final url = Uri.parse(
        '${Api.baseUrl}$endpoint',
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

      final body = {
        'pedidoId':
            widget.pedidoId,

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

        'cartao': {
          'numero':
              numeroController.text
                  .replaceAll(' ', '')
                  .trim(),

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

      debugPrint(
        '========================================',
      );

      debugPrint(
        '💳 FOODJET - PAGAMENTO',
      );

      debugPrint(
        '🆔 PEDIDO: ${widget.pedidoId}',
      );

      debugPrint(
        '💳 FORMA: ${widget.formaPagamento}',
      );

      debugPrint(
        '💰 TOTAL: ${widget.total}',
      );

      debugPrint(
        '📍 ENDPOINT: $endpoint',
      );

      debugPrint(
        '========================================',
      );

      // IMPORTANTE:
      // Não fazemos debugPrint(body), pois o body
      // contém os dados do cartão.

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
                  seconds: 60,
                ),
              );

      debugPrint(
        '💳 HTTP: ${response.statusCode}',
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
              dados['message']
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
          if (!mounted) return;

          setState(() {
            carregando = false;
          });

          _mensagem(
            'Cobrança criada. Continue o pagamento pela fatura do Asaas.',
          );

          await Future.delayed(
            const Duration(
              milliseconds: 700,
            ),
          );

          if (!mounted) return;

          await showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: const Text(
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
                          text: invoiceUrl,
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
      // CARTÃO DE CRÉDITO
      // ========================================================

      if (widget.formaPagamento ==
          'CREDITO') {
        final id =
            _extrairPagamentoId(
          dados,
        );

        if (id == null ||
            id.trim().isEmpty) {
          throw Exception(
            'O pagamento foi criado, mas o servidor não retornou o ID do pagamento.',
          );
        }

        pagamentoId =
            id.trim();

        final statusInicial =
            _extrairStatusPagamento(
          dados,
        );

        debugPrint(
          '========================================',
        );

        debugPrint(
          '💳 CARTÃO CRIADO NO ASAAS',
        );

        debugPrint(
          '🆔 PEDIDO: ${widget.pedidoId}',
        );

        debugPrint(
          '💳 PAGAMENTO ASAAS: $pagamentoId',
        );

        debugPrint(
          '📊 STATUS: ${statusInicial ?? "DESCONHECIDO"}',
        );

        debugPrint(
          '🔎 INICIANDO MONITORAMENTO',
        );

        debugPrint(
          '========================================',
        );

        if (!mounted) return;

        setState(() {
          carregando = false;
          aguardandoPagamento = true;
          statusPagamento =
              statusInicial;
        });

        _mensagem(
          'Pagamento enviado. Aguardando confirmação...',
        );

        await _iniciarMonitoramentoPagamento();

        return;
      }

      // ========================================================
      // OUTRAS FORMAS
      // ========================================================

      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      _mensagem(
        'Pagamento enviado para processamento.',
      );
    } catch (e) {
      debugPrint(
        '❌ ERRO PAGAMENTO: $e',
      );

      if (!mounted) return;

      setState(() {
        carregando = false;
        aguardandoPagamento = false;
      });

      _mensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        erro: true,
      );
    }
  }

  // ============================================================
  // EXTRAIR PAGAMENTO ID
  // ============================================================

  String? _extrairPagamentoId(
    dynamic dados,
  ) {
    if (dados is! Map) {
      return null;
    }

    final candidatos = [
      dados['pagamentoId'],
      dados['paymentId'],
      dados['payment_id'],
      dados['id'],
    ];

    for (final candidato
        in candidatos) {
      if (candidato == null) {
        continue;
      }

      final valor =
          candidato.toString().trim();

      if (valor.isNotEmpty) {
        return valor;
      }
    }

    final pagamento =
        dados['pagamento'];

    if (pagamento is Map) {
      final candidatosPagamento = [
        pagamento['pagamentoId'],
        pagamento['paymentId'],
        pagamento['id'],
      ];

      for (final candidato
          in candidatosPagamento) {
        if (candidato == null) {
          continue;
        }

        final valor =
            candidato.toString().trim();

        if (valor.isNotEmpty) {
          return valor;
        }
      }
    }

    return null;
  }

  // ============================================================
  // INICIAR MONITORAMENTO
  // ============================================================

  Future<void>
      _iniciarMonitoramentoPagamento() async {
    if (pagamentoId == null ||
        pagamentoId!.trim().isEmpty) {
      return;
    }

    _timerPagamento?.cancel();

    // Primeira consulta imediatamente.
    await _verificarPagamento();

    if (pagamentoConfirmado ||
        navegando) {
      return;
    }

    // Depois verifica a cada 2 segundos.
    _timerPagamento =
        Timer.periodic(
      const Duration(
        seconds: 2,
      ),
      (_) {
        _verificarPagamento();
      },
    );
  }

  // ============================================================
  // VERIFICAR PAGAMENTO
  // ============================================================

  Future<void>
      _verificarPagamento() async {
    if (pagamentoConfirmado ||
        navegando) {
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
        '🔎 VERIFICANDO CARTÃO: $pagamentoId',
      );

      debugPrint(
        '📡 HTTP: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        return;
      }

      dynamic dados;

      try {
        dados =
            jsonDecode(
          response.body,
        );
      } catch (_) {
        return;
      }

      final status =
          _extrairStatusPagamento(
        dados,
      );

      if (status != null) {
        statusPagamento =
            status;
      }

      debugPrint(
        '💳 STATUS CARTÃO: ${status ?? "DESCONHECIDO"}',
      );

      // ========================================================
      // APROVADO
      // ========================================================

      if (_statusPagamentoAprovado(
        status,
      )) {
        debugPrint(
          '========================================',
        );

        debugPrint(
          '🎉 CARTÃO APROVADO',
        );

        debugPrint(
          '💳 PAGAMENTO: $pagamentoId',
        );

        debugPrint(
          '🆔 PEDIDO: ${widget.pedidoId}',
        );

        debugPrint(
          '📊 STATUS: $status',
        );

        debugPrint(
          '========================================',
        );

        await _pagamentoFoiConfirmado();

        return;
      }

      // ========================================================
      // RECUSADO
      // ========================================================

      if (_statusPagamentoRecusado(
        status,
      )) {
        _timerPagamento?.cancel();

        _timerPagamento = null;

        if (!mounted) return;

        setState(() {
          aguardandoPagamento = false;
          carregando = false;
        });

        _mensagem(
          'O pagamento com cartão não foi aprovado.',
          erro: true,
        );
      }
    } catch (e) {
      // Erro temporário de consulta.
      // O próximo ciclo tenta novamente.
      debugPrint(
        '⚠️ Erro ao consultar cartão: $e',
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

    final candidatos = [
      dados['status'],
      dados['statusPagamento'],
      dados['status_pagamento'],
      dados['statusAsaas'],
      dados['status_asaas'],
      dados['paymentStatus'],
      dados['payment_status'],
    ];

    for (final candidato
        in candidatos) {
      if (candidato == null) {
        continue;
      }

      final valor =
          candidato.toString().trim();

      if (valor.isNotEmpty) {
        return valor;
      }
    }

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
        if (candidato == null) {
          continue;
        }

        final valor =
            candidato.toString().trim();

        if (valor.isNotEmpty) {
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
  // STATUS RECUSADO
  // ============================================================

  bool _statusPagamentoRecusado(
    String? status,
  ) {
    if (status == null) {
      return false;
    }

    final normalizado =
        status
            .trim()
            .toUpperCase();

    const recusados = {
      'DENIED',
      'DECLINED',
      'REFUSED',
      'REJECTED',
      'RECUSADO',
      'NEGADO',
      'CANCELED',
      'CANCELLED',
      'CANCELADO',
    };

    return recusados.contains(
      normalizado,
    );
  }

  // ============================================================
  // PAGAMENTO CONFIRMADO
  // ============================================================

  Future<void>
      _pagamentoFoiConfirmado() async {
    if (pagamentoConfirmado ||
        navegando ||
        !mounted) {
      return;
    }

    pagamentoConfirmado = true;

    _timerPagamento?.cancel();
    _timerPagamento = null;

    if (!mounted) return;

    setState(() {
      carregando = true;
      aguardandoPagamento = false;
    });

    _mensagem(
      'Pagamento aprovado! Abrindo seu pedido...',
    );

    await Future.delayed(
      const Duration(
        milliseconds: 700,
      ),
    );

    if (!mounted ||
        navegando) {
      return;
    }

    final idPedido =
        int.tryParse(
      widget.pedidoId.trim(),
    );

    if (idPedido == null) {
      setState(() {
        carregando = false;
      });

      _mensagem(
        'Pagamento aprovado, mas o ID do pedido é inválido.',
        erro: true,
      );

      return;
    }

    navegando = true;

    debugPrint(
      '➡️ ABRINDO OrderTrackingScreen',
    );

    debugPrint(
      '🆔 PEDIDO: $idPedido',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OrderTrackingScreen(
          pedidoId: idPedido,
        ),
      ),
    );
  }

  // ============================================================
  // DECORAÇÃO
  // ============================================================

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

  // ============================================================
  // AGUARDANDO PAGAMENTO
  // ============================================================

  Widget _aguardandoPagamentoWidget() {
    return Container(
      width:
          double.infinity,
      margin:
          const EdgeInsets.only(
        top: 18,
      ),
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFE4F7EF),
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        border:
            Border.all(
          color:
              const Color(0xFFB7E4D1),
        ),
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child:
                CircularProgressIndicator(
              strokeWidth: 2.5,
              color: verde,
            ),
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
                const Text(
                  'Aguardando confirmação do pagamento',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize:
                        14,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                const Text(
                  'O Asaas está confirmando seu cartão. Não feche esta tela.',
                  style:
                      TextStyle(
                    fontSize:
                        12,
                    height:
                        1.4,
                  ),
                ),

                if (statusPagamento != null &&
                    statusPagamento!
                        .isNotEmpty) ...[
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Status: $statusPagamento',
                    style:
                        TextStyle(
                      fontSize:
                          11,
                      color:
                          Colors.grey.shade700,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
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

      appBar:
          AppBar(
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black87,
        elevation: 0,
        title:
            Text(
          titulo,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body:
          SafeArea(
        child:
            Form(
          key:
              _formKey,

          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              18,
            ),

            child:
                Column(
              children: [
                // ==================================================
                // RESUMO
                // ==================================================

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

                  child:
                      Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        color:
                            laranja,
                        size:
                            30,
                      ),

                      const SizedBox(
                        width:
                            12,
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
                              height:
                                  4,
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
                              height:
                                  3,
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
                  height:
                      18,
                ),

                // ==================================================
                // NÚMERO
                // ==================================================

                TextFormField(
                  controller:
                      numeroController,

                  keyboardType:
                      TextInputType.number,

                  enabled:
                      !aguardandoPagamento &&
                      !pagamentoConfirmado,

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

                  validator:
                      (value) {
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
                  height:
                      14,
                ),

                // ==================================================
                // NOME
                // ==================================================

                TextFormField(
                  controller:
                      nomeController,

                  enabled:
                      !aguardandoPagamento &&
                      !pagamentoConfirmado,

                  textCapitalization:
                      TextCapitalization.words,

                  decoration:
                      _decoracao(
                    'Nome no cartão',
                    Icons.person_outline,
                  ),

                  validator:
                      (value) {
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
                  height:
                      14,
                ),

                // ==================================================
                // VALIDADE + CVV
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child:
                          TextFormField(
                        controller:
                            validadeController,

                        enabled:
                            !aguardandoPagamento &&
                            !pagamentoConfirmado,

                        keyboardType:
                            TextInputType.number,

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

                          final mes =
                              int.tryParse(
                            value.substring(
                              0,
                              2,
                            ),
                          );

                          if (mes ==
                                  null ||
                              mes < 1 ||
                              mes > 12) {
                            return 'Mês inválido';
                          }

                          return null;
                        },
                      ),
                    ),

                    const SizedBox(
                      width:
                          12,
                    ),

                    Expanded(
                      child:
                          TextFormField(
                        controller:
                            cvvController,

                        enabled:
                            !aguardandoPagamento &&
                            !pagamentoConfirmado,

                        keyboardType:
                            TextInputType.number,

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
                                  3 ||
                              value.length >
                                  4) {
                            return 'CVV inválido';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      22,
                ),

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
                        const Color(
                      0xFFEFFAF4,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),

                  child:
                      const Row(
                    children: [
                      Icon(
                        Icons
                            .verified_user_outlined,
                        color:
                            Colors.green,
                      ),

                      SizedBox(
                        width:
                            9,
                      ),

                      Expanded(
                        child:
                            Text(
                          'Pagamento processado com segurança pelo Asaas.',
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

                // ==================================================
                // AGUARDANDO
                // ==================================================

                if (aguardandoPagamento)
                  _aguardandoPagamentoWidget(),

                const SizedBox(
                  height:
                      22,
                ),

                // ==================================================
                // BOTÃO
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,

                  height:
                      56,

                  child:
                      ElevatedButton(
                    onPressed:
                        carregando ||
                                aguardandoPagamento ||
                                pagamentoConfirmado
                            ? null
                            : _pagar,

                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          laranja,

                      foregroundColor:
                          Colors.white,

                      disabledBackgroundColor:
                          Colors.grey.shade400,

                      elevation:
                          0,

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
                            : aguardandoPagamento
                                ? const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width:
                                            20,
                                        height:
                                            20,
                                        child:
                                            CircularProgressIndicator(
                                          color:
                                              Colors.white,
                                          strokeWidth:
                                              2.2,
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            10,
                                      ),
                                      Text(
                                        'AGUARDANDO CONFIRMAÇÃO',
                                        style:
                                            TextStyle(
                                          fontWeight:
                                              FontWeight.w800,
                                          fontSize:
                                              12,
                                        ),
                                      ),
                                    ],
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

                if (aguardandoPagamento)
                  const Padding(
                    padding:
                        EdgeInsets.only(
                      top: 14,
                    ),
                    child:
                        Text(
                      'Não feche esta tela. A confirmação será verificada automaticamente.',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        fontSize:
                            11,
                        color:
                            Colors.grey,
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

  Future<void>
      _confirmarPedido() async {
    if (carregando) return;

    if (!mounted) return;

    setState(() {
      carregando = true;
    });

    try {
      debugPrint(
        '========================================',
      );

      debugPrint(
        '💵 FOODJET - DINHEIRO',
      );

      debugPrint(
        '🆔 PEDIDO: ${widget.pedidoId}',
      );

      debugPrint(
        '💰 TOTAL: ${widget.total}',
      );

      debugPrint(
        '========================================',
      );

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

      appBar:
          AppBar(
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

      body:
          SafeArea(
        child:
            Padding(
          padding:
              const EdgeInsets.all(
            18,
          ),

          child:
              Column(
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

                child:
                    Column(
                  children: [
                    const Icon(
                      Icons
                          .payments_outlined,
                      color:
                          laranja,
                      size:
                          60,
                    ),

                    const SizedBox(
                      height:
                          18,
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
                      height:
                          8,
                    ),

                    const Text(
                      'Você pagará ao entregador quando receber seu pedido.',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        fontSize:
                            13,
                        color:
                            Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height:
                          14,
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
                      height:
                          10,
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

                height:
                    56,

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
                    elevation:
                        0,
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
    );
  }
}

// ============================================================================
// PIX
// ============================================================================

class PixCheckoutPage extends StatefulWidget {
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

  late String pedidoId;

  String? pagamentoId;

  String? pixPayload;
  String? encodedImage;
  String? expirationDate;

  Timer? _timerPagamento;

  bool _pagamentoConfirmado =
      false;

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

      if (valor == null) continue;

      var token =
          valor.trim();

      if (token.isEmpty) continue;

      if (token
          .toLowerCase()
          .startsWith('bearer ')) {
        token =
            token.substring(7).trim();
      }

      if (token.isNotEmpty) {
        return token;
      }
    }

    return null;
  }

  dynamic _decodificarResposta(
    http.Response response,
    String origem,
  ) {
    final body =
        response.body.trim();

    if (body.isEmpty) {
      throw Exception(
        '$origem: resposta vazia do servidor.',
      );
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      throw Exception(
        '$origem: resposta inválida.',
      );
    }
  }

  Future<void> _iniciarFluxoPix() async {
    if (!mounted) return;

    setState(() {
      carregando = true;
      erro = false;
      mensagemErro = '';
    });

    try {
      if (widget.itens.isEmpty) {
        throw Exception(
          'Seu carrinho está vazio.',
        );
      }

      if (widget.restauranteId
          .trim()
          .isEmpty) {
        throw Exception(
          'Restaurante não identificado.',
        );
      }

      if (widget.pedidoId
          .trim()
          .isEmpty) {
        throw Exception(
          'Pedido não identificado.',
        );
      }

      if (widget.total <= 0) {
        throw Exception(
          'O valor do pedido é inválido.',
        );
      }

      final token =
          await _obterToken();

      if (token == null) {
        throw Exception(
          'Sessão expirada. Faça login novamente.',
        );
      }

      await _gerarPix(token);

      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = false;
      });

      await _iniciarMonitoramentoPagamento();
    } catch (e) {
      debugPrint(
        '❌ ERRO PIX: $e',
      );

      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = true;
        mensagemErro =
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }

  Future<void> _gerarPix(
    String token,
  ) async {
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
      'pedidoId':
          pedidoId,
      'formaPagamento':
          'PIX',
      'endereco':
          widget.endereco,
      'itens':
          itens,
    };

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

    final dados =
        _decodificarResposta(
      response,
      'GERAR PIX',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        dados is Map
            ? dados['erro']
                    ?.toString() ??
                'Não foi possível gerar o Pix.'
            : 'Não foi possível gerar o Pix.',
      );
    }

    if (dados is! Map) {
      throw Exception(
        'Resposta inválida do servidor.',
      );
    }

    if (dados['sucesso'] == false) {
      throw Exception(
        dados['erro']?.toString() ??
            'Não foi possível gerar o Pix.',
      );
    }

    pagamentoId =
        dados['pagamentoId']
            ?.toString();

    pagamentoId ??=
        dados['paymentId']
            ?.toString();

    pagamentoId ??=
        dados['id']
            ?.toString();

    final pix =
        dados['pix'] is Map
            ? dados['pix']
            : <dynamic, dynamic>{};

    pixPayload =
        pix['qrCode']
            ?.toString();

    encodedImage =
        pix['qrCodeBase64']
            ?.toString();

    expirationDate =
        pix['expiracao']
            ?.toString();

    pixPayload ??=
        pix['payload']
            ?.toString();

    encodedImage ??=
        pix['encodedImage']
            ?.toString();

    expirationDate ??=
        pix['expirationDate']
            ?.toString();

    pixPayload ??=
        dados['qrCode']
            ?.toString();

    encodedImage ??=
        dados['qrCodeBase64']
            ?.toString();

    if ((pixPayload == null ||
            pixPayload!.isEmpty) &&
        (encodedImage == null ||
            encodedImage!.isEmpty)) {
      throw Exception(
        'O servidor não retornou os dados do Pix.',
      );
    }
  }

  // ============================================================
  // MONITORAMENTO PIX
  // ============================================================

  Future<void>
      _iniciarMonitoramentoPagamento() async {
    if (pagamentoId == null ||
        pagamentoId!.trim().isEmpty) {
      return;
    }

    _timerPagamento?.cancel();

    await _verificarPagamento();

    if (_pagamentoConfirmado ||
        _navegando) {
      return;
    }

    _timerPagamento =
        Timer.periodic(
      const Duration(
        seconds: 2,
      ),
      (_) {
        _verificarPagamento();
      },
    );
  }

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

      if (token == null) return;

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

      if (response.statusCode != 200) {
        return;
      }

      final dados =
          _decodificarResposta(
        response,
        'VERIFICAR PAGAMENTO',
      );

      final status =
          _extrairStatusPagamento(
        dados,
      );

      debugPrint(
        '💳 STATUS PIX: ${status ?? "DESCONHECIDO"}',
      );

      if (_statusPagamentoAprovado(
        status,
      )) {
        await _pagamentoFoiConfirmado();
      }
    } catch (e) {
      debugPrint(
        '⚠️ Erro ao consultar PIX: $e',
      );
    }
  }

  String? _extrairStatusPagamento(
    dynamic dados,
  ) {
    if (dados is! Map) {
      return null;
    }

    final candidatos = [
      dados['status'],
      dados['statusPagamento'],
      dados['status_pagamento'],
      dados['statusAsaas'],
      dados['status_asaas'],
      dados['paymentStatus'],
      dados['payment_status'],
    ];

    for (final candidato
        in candidatos) {
      if (candidato == null) continue;

      final valor =
          candidato.toString().trim();

      if (valor.isNotEmpty) {
        return valor;
      }
    }

    final pagamento =
        dados['pagamento'];

    if (pagamento is Map) {
      final status =
          pagamento['status']
              ?.toString()
              .trim();

      if (status != null &&
          status.isNotEmpty) {
        return status;
      }
    }

    return null;
  }

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

  Future<void>
      _pagamentoFoiConfirmado() async {
    if (_pagamentoConfirmado ||
        _navegando ||
        !mounted) {
      return;
    }

    _pagamentoConfirmado = true;

    _timerPagamento?.cancel();
    _timerPagamento = null;

    final idPedido =
        int.tryParse(
      pedidoId.trim(),
    );

    if (idPedido == null) {
      return;
    }

    _navegando = true;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OrderTrackingScreen(
          pedidoId: idPedido,
        ),
      ),
    );
  }

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
        .showSnackBar(
      const SnackBar(
        content:
            Text(
          'Código Pix copiado!',
        ),
        backgroundColor:
            verdePix,
      ),
    );
  }

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
      var base64String =
          encodedImage!.trim();

      if (base64String
          .contains(',')) {
        base64String =
            base64String
                .split(',')
                .last;
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
      return const SizedBox(
        width: 240,
        height: 240,
        child:
            Center(
          child:
              Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 42,
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar:
          AppBar(
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

      body:
          SafeArea(
        child:
            carregando
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          verdePix,
                    ),
                  )
                : erro
                    ? Center(
                        child:
                            Padding(
                          padding:
                              const EdgeInsets.all(
                            25,
                          ),
                          child:
                              Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons
                                    .error_outline,
                                color:
                                    Colors.red,
                                size:
                                    55,
                              ),

                              const SizedBox(
                                height:
                                    15,
                              ),

                              const Text(
                                'Não foi possível preparar o Pix',
                                textAlign:
                                    TextAlign.center,
                                style:
                                    TextStyle(
                                  fontSize:
                                      18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height:
                                    10,
                              ),

                              Text(
                                mensagemErro,
                                textAlign:
                                    TextAlign.center,
                              ),

                              const SizedBox(
                                height:
                                    20,
                              ),

                              ElevatedButton(
                                onPressed:
                                    _iniciarFluxoPix,
                                child:
                                    const Text(
                                  'TENTAR NOVAMENTE',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        child:
                            Column(
                          children: [
                            const Text(
                              'Escaneie o QR Code',
                              style:
                                  TextStyle(
                                fontSize:
                                    17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  18,
                            ),

                            _qrCode(),

                            const SizedBox(
                              height:
                                  20,
                            ),

                            Container(
                              padding:
                                  const EdgeInsets.all(
                                13,
                              ),
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
                                      maxLines:
                                          3,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            10,
                                      ),
                                    ),
                                  ),

                                  IconButton(
                                    onPressed:
                                        _copiarPix,
                                    icon:
                                        const Icon(
                                      Icons.copy,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height:
                                  20,
                            ),

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
                                    const Color(
                                  0xFFE4F7EF,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                              child:
                                  const Row(
                                children: [
                                  SizedBox(
                                    width:
                                        20,
                                    height:
                                        20,
                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          verdePix,
                                      strokeWidth:
                                          2,
                                    ),
                                  ),

                                  SizedBox(
                                    width:
                                        12,
                                  ),

                                  Expanded(
                                    child:
                                        Text(
                                      'Aguardando confirmação do pagamento. Esta tela será atualizada automaticamente.',
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
                              height:
                                  20,
                            ),

                            Text(
                              'Total: ${dinheiro(widget.total)}',
                              style:
                                  const TextStyle(
                                fontSize:
                                    20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}