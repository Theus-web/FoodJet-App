import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';

class CheckoutPaymentScreen extends StatefulWidget {
  final double total;
  final String pagamento;
  final String restauranteId;

  final List<CartItem> itens;
  final Map<String, String> endereco;

  final double subtotal;
  final double taxaServico;
  final double taxaEntrega;

  const CheckoutPaymentScreen({
    super.key,
    required this.total,
    required this.pagamento,
    required this.restauranteId,
    required this.itens,
    required this.endereco,
    required this.subtotal,
    required this.taxaServico,
    required this.taxaEntrega,
  });

  @override
  State<CheckoutPaymentScreen> createState() =>
      _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState
    extends State<CheckoutPaymentScreen> {
  static const Color laranja =
      Color(0xFFF97316);

  static const Color fundo =
      Color(0xFFF5F5F5);

  String metodoSelecionado = '';

  bool processando = false;

  bool pagamentoGerado = false;

  bool verificandoPagamento = false;

  bool pagamentoConfirmado = false;

  String? emailUsuario;

  String? cpfCnpjUsuario;

  String? pagamentoId;

  String? referenciaPedido;

  String qrCode = '';

  String qrCodeBase64 = '';

  String ticketUrl = '';

  Timer? timer;

  @override
  void initState() {
    super.initState();

    metodoSelecionado =
        widget.pagamento.isNotEmpty
            ? widget.pagamento
            : 'PIX';

    carregarDadosUsuario();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // DADOS DO USUÁRIO
  // ============================================================

  Future<void> carregarDadosUsuario() async {
    final prefs =
        await SharedPreferences.getInstance();

    String? email;
    String? cpfCnpj;

    final usuarioJson =
        prefs.getString('usuario');

    if (usuarioJson != null &&
        usuarioJson.isNotEmpty) {
      try {
        final usuario =
            jsonDecode(usuarioJson);

        if (usuario is Map) {
          email =
              usuario['email']?.toString();

          cpfCnpj =
              usuario['cpfCnpj']?.toString() ??
              usuario['cpf_cnpj']?.toString() ??
              usuario['cpf']?.toString() ??
              usuario['documento']?.toString();
        }
      } catch (e) {
        debugPrint(
          '⚠️ Erro lendo usuário: $e',
        );
      }
    }

    email ??=
        prefs.getString('email');

    cpfCnpj ??=
        prefs.getString('cpfCnpj');

    cpfCnpj ??=
        prefs.getString('cpf');

    cpfCnpj ??=
        prefs.getString('documento');

    if (!mounted) return;

    setState(() {
      emailUsuario = email;
      cpfCnpjUsuario = cpfCnpj;
    });

    debugPrint(
      '📧 EMAIL DO CLIENTE: $emailUsuario',
    );

    debugPrint(
      '🪪 CPF/CNPJ DO CLIENTE: '
      '${cpfCnpjUsuario != null && cpfCnpjUsuario!.isNotEmpty ? "CONFIGURADO" : "NÃO CONFIGURADO"}',
    );
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> obterToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  // ============================================================
  // PREÇO
  // ============================================================

  String formatarPreco(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // NORMALIZAR CPF/CNPJ
  // ============================================================

  String limparDocumento(String valor) {
    return valor.replaceAll(
      RegExp(r'\D'),
      '',
    );
  }

  // ============================================================
  // GERAR PIX
  // ============================================================

  Future<void> gerarPix() async {
    if (processando) return;

    if (pagamentoGerado) {
      mensagem(
        'O PIX já foi gerado. Aguardando confirmação.',
      );
      return;
    }

    final email = emailUsuario;

    if (email == null ||
        email.trim().isEmpty) {
      mensagem(
        'Não encontramos o e-mail da sua conta. Faça login novamente.',
        erro: true,
      );
      return;
    }

    final documento =
        cpfCnpjUsuario == null
            ? ''
            : limparDocumento(
                cpfCnpjUsuario!,
              );

    if (documento.isEmpty) {
      mensagem(
        'Seu CPF/CNPJ não está cadastrado. Atualize seus dados da conta para continuar.',
        erro: true,
      );
      return;
    }

    if (documento.length != 11 &&
        documento.length != 14) {
      mensagem(
        'O CPF/CNPJ cadastrado é inválido.',
        erro: true,
      );
      return;
    }

    if (widget.total <= 0) {
      mensagem(
        'O valor do pedido é inválido.',
        erro: true,
      );
      return;
    }

    if (widget.itens.isEmpty) {
      mensagem(
        'Seu carrinho está vazio.',
        erro: true,
      );
      return;
    }

    if (widget.restauranteId.isEmpty) {
      mensagem(
        'Restaurante não identificado.',
        erro: true,
      );
      return;
    }

    setState(() {
      processando = true;
    });

    try {
      final token =
          await obterToken();

      if (token == null ||
          token.isEmpty) {
        throw Exception(
          'Sessão expirada. Faça login novamente.',
        );
      }

      final referencia =
          'FOODJET-${DateTime.now().millisecondsSinceEpoch}';

      referenciaPedido = referencia;

      final url = Uri.parse(
        '${Api.baseUrl}/pagamentos/pix',
      );

      debugPrint(
        '========================================',
      );

      debugPrint(
        '💳 FOODJET - GERANDO PIX ASAAS',
      );

      debugPrint(
        '📧 EMAIL: $email',
      );

      debugPrint(
        '🪪 CPF/CNPJ: CONFIGURADO',
      );

      debugPrint(
        '💰 VALOR: ${widget.total}',
      );

      debugPrint(
        '🔖 REFERÊNCIA: $referencia',
      );

      debugPrint(
        '========================================',
      );

      final resposta =
          await http.post(
        url,
        headers: {
          'Content-Type':
              'application/json',
          'Accept':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
        body: jsonEncode({
          'valor': widget.total,
          'email': email.trim(),
          'pedidoId': referencia,

          'nome':
              await obterNomeUsuario(),

          'cpfCnpj':
              documento,
        }),
      ).timeout(
        const Duration(seconds: 30),
      );

      debugPrint(
        '📡 STATUS PIX: ${resposta.statusCode}',
      );

      debugPrint(
        '📡 RESPOSTA PIX: ${resposta.body}',
      );

      if (!mounted) return;

      Map<String, dynamic> dados = {};

      try {
        final decoded =
            jsonDecode(resposta.body);

        if (decoded
            is Map<String, dynamic>) {
          dados = decoded;
        }
      } catch (_) {}

      if (resposta.statusCode < 200 ||
          resposta.statusCode >= 300) {
        throw Exception(
          dados['erro']?.toString() ??
              dados['mensagem']?.toString() ??
              'Não foi possível gerar o pagamento PIX.',
        );
      }

      final pix =
          dados['pix'];

      if (pix is! Map) {
        throw Exception(
          'O Asaas não retornou os dados do PIX.',
        );
      }

      final id =
          dados['pagamentoId']?.toString() ??
          dados['paymentId']?.toString();

      final codigo =
          pix['qrCode']?.toString() ?? '';

      final base64 =
          pix['qrCodeBase64']?.toString() ?? '';

      final ticket =
          pix['ticketUrl']?.toString() ?? '';

      if (id == null ||
          id.isEmpty) {
        throw Exception(
          'O Asaas não retornou um ID de pagamento válido.',
        );
      }

      if (codigo.isEmpty &&
          base64.isEmpty) {
        throw Exception(
          'O Asaas não retornou o QR Code PIX.',
        );
      }

      setState(() {
        pagamentoId = id;
        qrCode = codigo;
        qrCodeBase64 = base64;
        ticketUrl = ticket;
        pagamentoGerado = true;
      });

      debugPrint(
        '========================================',
      );

      debugPrint(
        '✅ PIX ASAAS GERADO',
      );

      debugPrint(
        '🆔 PAYMENT ID ASAAS: $id',
      );

      debugPrint(
        '🔖 REFERÊNCIA FOODJET: $referencia',
      );

      debugPrint(
        '========================================',
      );

      iniciarVerificacao();

      mensagem(
        'PIX gerado. Escaneie o QR Code para pagar.',
      );
    } catch (e) {
      debugPrint(
        '❌ ERRO AO GERAR PIX ASAAS: $e',
      );

      if (!mounted) return;

      mensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
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
  // NOME DO USUÁRIO
  // ============================================================

  Future<String?> obterNomeUsuario() async {
    final prefs =
        await SharedPreferences.getInstance();

    final usuarioJson =
        prefs.getString('usuario');

    if (usuarioJson == null ||
        usuarioJson.isEmpty) {
      return null;
    }

    try {
      final usuario =
          jsonDecode(usuarioJson);

      if (usuario is Map) {
        return usuario['nome']?.toString() ??
            usuario['name']?.toString();
      }
    } catch (_) {}

    return null;
  }

  // ============================================================
  // INICIAR VERIFICAÇÃO
  // ============================================================

  void iniciarVerificacao() {
    timer?.cancel();

    timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        consultarPagamento();
      },
    );

    consultarPagamento();
  }

  // ============================================================
  // CONSULTAR PAGAMENTO
  // ============================================================

  Future<void> consultarPagamento() async {
    if (verificandoPagamento) return;

    final id = pagamentoId;

    if (id == null ||
        id.isEmpty) {
      return;
    }

    verificandoPagamento = true;

    try {
      final token =
          await obterToken();

      if (token == null ||
          token.isEmpty) {
        return;
      }

      /*
       * IMPORTANTE:
       *
       * Aqui usamos o ID REAL DO ASAAS.
       *
       * NÃO usamos:
       *
       * FOODJET-...
       *
       * nem:
       *
       * ORD...
       */

      final url = Uri.parse(
        '${Api.baseUrl}/pagamentos/${Uri.encodeComponent(id)}',
      );

      final resposta =
          await http.get(
        url,
        headers: {
          'Accept':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
      );

      debugPrint(
        '🔎 ASAAS STATUS: ${resposta.body}',
      );

      if (resposta.statusCode != 200) {
        return;
      }

      final decoded =
          jsonDecode(resposta.body);

      if (decoded
          is! Map<String, dynamic>) {
        return;
      }

      final status =
          decoded['status']
              ?.toString()
              .toUpperCase();

      debugPrint(
        '📊 STATUS ASAAS: $status',
      );

      // ========================================================
      // ASAAS PAGAMENTO CONFIRMADO
      // ========================================================

      if (status == 'RECEIVED' ||
          status == 'CONFIRMED') {
        timer?.cancel();

        if (!mounted) return;

        setState(() {
          verificandoPagamento = false;
          pagamentoConfirmado = true;
        });

        mensagem(
          'Pagamento confirmado! Finalizando pedido.',
        );

        await confirmarPedidoDepoisDoPagamento();

        return;
      }

      // ========================================================
      // PAGAMENTO VENCIDO
      // ========================================================

      if (status == 'OVERDUE' ||
          status == 'REFUNDED' ||
          status == 'REFUND_REQUESTED' ||
          status == 'CHARGEBACK_REQUESTED' ||
          status == 'CHARGEBACK_DISPUTE' ||
          status == 'AWAITING_CHARGEBACK_REVERSAL') {
        timer?.cancel();

        if (!mounted) return;

        mensagem(
          'O pagamento PIX não está disponível.',
          erro: true,
        );

        return;
      }
    } catch (e) {
      debugPrint(
        '⚠️ Erro consultando pagamento Asaas: $e',
      );
    } finally {
      verificandoPagamento = false;
    }
  }

  // ============================================================
  // MONTAR ITENS
  // ============================================================

  List<Map<String, dynamic>>
      montarItensPedido() {
    return widget.itens.map(
      (item) {
        return {
          'produtoId':
              item.produtoId,

          'nome':
              item.nome,

          'preco':
              item.preco,

          'quantidade':
              item.quantidade,

          'subtotal':
              item.preco *
                  item.quantidade,
        };
      },
    ).toList();
  }

  // ============================================================
  // CRIAR PEDIDO DEPOIS DO PAGAMENTO
  // ============================================================

  Future<void>
      confirmarPedidoDepoisDoPagamento() async {
    if (!mounted) return;

    if (pagamentoId == null ||
        pagamentoId!.isEmpty) {
      mensagem(
        'ID do pagamento não encontrado.',
        erro: true,
      );
      return;
    }

    setState(() {
      processando = true;
    });

    try {
      final token =
          await obterToken();

      if (token == null ||
          token.isEmpty) {
        throw Exception(
          'Sessão expirada.',
        );
      }

      final pedido = {
        'restauranteId':
            widget.restauranteId,

        'itens':
            montarItensPedido(),

        'endereco':
            widget.endereco,

        'pagamento':
            metodoSelecionado,

        /*
         * ID REAL DO ASAAS
         */
        'pagamentoId':
            pagamentoId,

        /*
         * Referência criada pelo FoodJet.
         */
        'externalReference':
            referenciaPedido,

        'statusPagamento':
            'RECEIVED',

        'subtotal':
            widget.subtotal,

        'taxaServico':
            widget.taxaServico,

        'taxaEntrega':
            widget.taxaEntrega,

        'total':
            widget.total,
      };

      debugPrint(
        '========================================',
      );

      debugPrint(
        '📦 CRIANDO PEDIDO FOODJET',
      );

      debugPrint(
        '💳 PAYMENT ID ASAAS: $pagamentoId',
      );

      debugPrint(
        '🔖 REFERÊNCIA: $referenciaPedido',
      );

      debugPrint(
        '========================================',
      );

      final resposta =
          await http.post(
        Uri.parse(
          '${Api.baseUrl}/orders',
        ),
        headers: {
          'Content-Type':
              'application/json',

          'Accept':
              'application/json',

          'Authorization':
              'Bearer $token',
        },
        body:
            jsonEncode(pedido),
      ).timeout(
        const Duration(seconds: 15),
      );

      debugPrint(
        '📦 STATUS CRIAÇÃO PEDIDO: '
        '${resposta.statusCode}',
      );

      debugPrint(
        '📦 RESPOSTA PEDIDO: '
        '${resposta.body}',
      );

      if (!mounted) return;

      if (resposta.statusCode != 200 &&
          resposta.statusCode != 201) {
        Map<String, dynamic> dados = {};

        try {
          final decoded =
              jsonDecode(resposta.body);

          if (decoded
              is Map<String, dynamic>) {
            dados = decoded;
          }
        } catch (_) {}

        throw Exception(
          dados['erro']?.toString() ??
              dados['mensagem']?.toString() ??
              'Pagamento aprovado, mas não foi possível criar o pedido.',
        );
      }

      final dados =
          jsonDecode(resposta.body);

      dynamic pedidoCriado =
          dados['pedido'];

      if (pedidoCriado == null &&
          dados['id'] != null) {
        pedidoCriado = dados;
      }

      if (pedidoCriado is! Map) {
        throw Exception(
          'Pedido criado sem retorno dos dados.',
        );
      }

      final id =
          pedidoCriado['id'];

      if (id == null) {
        throw Exception(
          'Pedido criado sem ID.',
        );
      }

      final pedidoId =
          int.tryParse(
        id.toString(),
      );

      if (pedidoId == null) {
        throw Exception(
          'ID do pedido inválido.',
        );
      }

      timer?.cancel();

      debugPrint(
        '========================================',
      );

      debugPrint(
        '🎉 PAGAMENTO ASAAS CONFIRMADO',
      );

      debugPrint(
        '💳 PAYMENT ID: $pagamentoId',
      );

      debugPrint(
        '📦 PEDIDO FOODJET: $pedidoId',
      );

      debugPrint(
        '========================================',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OrderTrackingScreen(
            pedidoId:
                pedidoId,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        '❌ ERRO CRIANDO PEDIDO: $e',
      );

      if (!mounted) return;

      mensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
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

    final bloqueado =
        pagamentoGerado ||
        processando;

    return GestureDetector(
      onTap: bloqueado
          ? null
          : () {
              setState(() {
                metodoSelecionado = id;
              });
            },
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 200,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bloqueado
              ? Colors.grey.shade100
              : Colors.white,
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
                  .withValues(
                alpha: 0.035,
              ),
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
                    ? const Color(
                        0xFFFFE8D8,
                      )
                    : Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),
              child:
                  logo ??
                  Icon(
                    icone,
                    color: laranja,
                    size: 27,
                  ),
            ),

            const SizedBox(
              width: 14,
            ),

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

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    descricao,
                    style:
                        TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            if (selecionado)
              const Icon(
                Icons.check_circle,
                color: laranja,
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
        content:
            Text(texto),
        backgroundColor:
            erro
                ? Colors.red.shade700
                : laranja,
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QR CODE
  // ============================================================

  Widget areaPix() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.pix,
            size: 42,
            color:
                Color(0xFF32BCAD),
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'PIX gerado',
            style:
                TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            pagamentoConfirmado
                ? 'Pagamento confirmado!'
                : 'Pague pelo aplicativo do seu banco.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          if (qrCodeBase64.isNotEmpty)
            Container(
              width: 230,
              height: 230,
              padding:
                  const EdgeInsets.all(
                12,
              ),
              color:
                  Colors.white,
              child:
                  Image.memory(
                base64Decode(
                  qrCodeBase64
                          .contains(',')
                      ? qrCodeBase64
                          .split(',')
                          .last
                      : qrCodeBase64,
                ),
                fit:
                    BoxFit.contain,
                errorBuilder:
                    (_, __, ___) {
                  return const Icon(
                    Icons.qr_code_2,
                    size: 180,
                  );
                },
              ),
            )
          else
            const Icon(
              Icons.qr_code_2,
              size: 200,
            ),

          const SizedBox(
            height: 20,
          ),

          if (qrCode.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child:
                  SelectableText(
                qrCode,
                maxLines: 6,
                style:
                    const TextStyle(
                  fontSize: 11,
                ),
              ),
            ),

          const SizedBox(
            height: 15,
          ),

          if (pagamentoId != null)
            Text(
              'Pagamento: $pagamentoId',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 11,
                color:
                    Colors.grey.shade500,
              ),
            ),

          const SizedBox(
            height: 10,
          ),

          if (verificandoPagamento &&
              !pagamentoConfirmado)
            const Column(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),

                SizedBox(
                  height: 10,
                ),

                Text(
                  'Aguardando confirmação do pagamento...',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),

          if (pagamentoConfirmado)
            const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color:
                      Colors.green,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(
                  'Pagamento confirmado',
                  style:
                      TextStyle(
                    color:
                        Colors.green,
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
      backgroundColor:
          fundo,

      appBar:
          AppBar(
        backgroundColor:
            laranja,
        foregroundColor:
            Colors.white,
        elevation:
            0,
        title:
            const Text(
          'Pagamento',
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
            Column(
          children: [
            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                        gradient:
                            const LinearGradient(
                          begin:
                              Alignment.topLeft,
                          end:
                              Alignment.bottomRight,
                          colors: [
                            Color(
                              0xFFF97316,
                            ),
                            Color(
                              0xFFEA580C,
                            ),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          22,
                        ),
                      ),
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total do pedido',
                            style:
                                TextStyle(
                              color:
                                  Colors.white70,
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
                      'Seu pedido só será confirmado após o pagamento aprovado.',
                      style:
                          TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    opcao(
                      id:
                          'PIX',
                      icone:
                          Icons.pix,
                      titulo:
                          'PIX',
                      descricao:
                          'Pagamento instantâneo pelo seu banco.',
                    ),

                    opcao(
                      id:
                          'MERCADO_PAGO',
                      icone:
                          Icons.account_balance_wallet_outlined,
                      titulo:
                          'Mercado Pago',
                      descricao:
                          'Pague com PIX pelo Mercado Pago.',
                    ),

                    opcao(
                      id:
                          'NUBANK',
                      icone:
                          Icons.account_balance,
                      titulo:
                          'Nubank',
                      descricao:
                          'Pague pelo aplicativo Nubank usando PIX.',
                      logo:
                          Container(
                        alignment:
                            Alignment.center,
                        child:
                            const Text(
                          'Nu',
                          style:
                              TextStyle(
                            color:
                                Color(
                              0xFF820AD1,
                            ),
                            fontSize:
                                22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    opcao(
                      id:
                          'CARTAO',
                      icone:
                          Icons.credit_card,
                      titulo:
                          'Cartão',
                      descricao:
                          'Pagamento com cartão.',
                    ),

                    opcao(
                      id:
                          'DINHEIRO',
                      icone:
                          Icons.payments_outlined,
                      titulo:
                          'Dinheiro',
                      descricao:
                          'Pagar na entrega.',
                    ),

                    if (pagamentoGerado &&
                        metodoSelecionado !=
                            'DINHEIRO' &&
                        metodoSelecionado !=
                            'CARTAO') ...[
                      const SizedBox(
                        height: 20,
                      ),
                      areaPix(),
                    ],
                  ],
                ),
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20,
              ),
              color:
                  Colors.white,
              child:
                  SizedBox(
                width:
                    double.infinity,
                height:
                    56,
                child:
                    ElevatedButton(
                  onPressed:
                      processando ||
                              pagamentoGerado
                          ? null
                          : gerarPix,
                  style:
                      ElevatedButton.styleFrom(
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
                        15,
                      ),
                    ),
                  ),
                  child:
                      processando
                          ? const SizedBox(
                              width:
                                  24,
                              height:
                                  24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    3,
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
                                const SizedBox(
                                  width:
                                      8,
                                ),
                                Text(
                                  pagamentoGerado
                                      ? 'AGUARDANDO PAGAMENTO'
                                      : 'PAGAR ${formatarPreco(widget.total)}',
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        16,
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