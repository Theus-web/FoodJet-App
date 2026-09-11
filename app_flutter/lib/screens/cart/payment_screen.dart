import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, String> endereco;
  final List<CartItem> itens;
  final double subtotal;
  final String restauranteId;
  final double taxaEntrega;
  final double taxaServico;
  final String formaPagamento;
  final String? pedidoId;

  const PaymentScreen({
    super.key,
    required this.endereco,
    required this.itens,
    required this.subtotal,
    required this.restauranteId,
    required this.taxaEntrega,
    this.taxaServico = 0.0,
    required this.formaPagamento,
    this.pedidoId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late String formaPagamento;

  @override
  void initState() {
    super.initState();

    formaPagamento =
        widget.formaPagamento.trim().toUpperCase();
  }

  double get totalPedido {
    return widget.subtotal +
        widget.taxaEntrega +
        widget.taxaServico;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Pagamento",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: formaPagamento == "PIX"
          ? PixCheckoutPage(
              endereco: widget.endereco,
              itens: widget.itens,
              subtotal: widget.subtotal,
              restauranteId: widget.restauranteId,
              taxaEntrega: widget.taxaEntrega,
              taxaServico: widget.taxaServico,

              // PIX NÃO possui pedido antes do pagamento.
              pedidoId: null,
            )
          : formaPagamento == "CREDITO"
              ? CardPaymentPage(
                  endereco: widget.endereco,
                  itens: widget.itens,
                  subtotal: widget.subtotal,
                  restauranteId: widget.restauranteId,
                  taxaEntrega: widget.taxaEntrega,
                  taxaServico: widget.taxaServico,
                  pedidoId: widget.pedidoId,
                )
              : Center(
                  child: Text(
                    "Forma de pagamento não suportada.",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                ),
    );
  }
}

// ============================================================
// PIX
// ============================================================

class PixCheckoutPage extends StatefulWidget {
  final Map<String, String> endereco;
  final List<CartItem> itens;
  final double subtotal;
  final String restauranteId;
  final double taxaEntrega;
  final double taxaServico;
  final String? pedidoId;

  const PixCheckoutPage({
    super.key,
    required this.endereco,
    required this.itens,
    required this.subtotal,
    required this.restauranteId,
    required this.taxaEntrega,
    required this.taxaServico,
    required this.pedidoId,
  });

  @override
  State<PixCheckoutPage> createState() =>
      _PixCheckoutPageState();
}

class _PixCheckoutPageState
    extends State<PixCheckoutPage> {
  bool carregando = false;
  bool pagamentoGerado = false;
  bool pagamentoAprovado = false;
  bool navegandoPedido = false;

  String? pagamentoId;
  String? qrCodeBase64;
  String? pixCopiaCola;
  String? ticketUrl;
  String? mensagem;

  DateTime? expiracao;

  Timer? timer;

  int tentativas = 0;

  double get totalPedido {
    return widget.subtotal +
        widget.taxaEntrega +
        widget.taxaServico;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> obterToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString("token") ??
        prefs.getString("jwt") ??
        prefs.getString("access_token") ??
        prefs.getString("auth_token");
  }

  // ============================================================
  // ITENS
  // ============================================================

  List<Map<String, dynamic>> prepararItens() {
    return widget.itens.map((item) {
      return {
        "produtoId": item.nome,
        "nome": item.nome,
        "quantidade": item.quantidade,
        "preco": item.preco,
      };
    }).toList();
  }

  // ============================================================
  // GERAR PIX
  //
  // ATENÇÃO:
  //
  // ESTE MÉTODO NÃO CRIA PEDIDO.
  //
  // Ele cria somente:
  //
  // 1. checkout pendente
  // 2. cobrança PIX no Asaas
  //
  // O pedido somente nasce no webhook
  // depois que o pagamento for aprovado.
  // ============================================================

  Future<void> gerarPix() async {
    if (carregando) {
      return;
    }

    setState(() {
      carregando = true;
      mensagem = null;
    });

    try {
      final token = await obterToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          "Sessão expirada. Faça login novamente.",
        );
      }

      final url = Uri.parse(
        "${Api.baseUrl}/pagamentos/pix",
      );

      // ========================================================
      // IMPORTANTE:
      //
      // NUNCA enviar um pedidoId existente no PIX.
      // ========================================================

      final body = {
        "valor": totalPedido,
        "total": totalPedido,
        "subtotal": widget.subtotal,
        "taxaEntrega": widget.taxaEntrega,
        "taxaServico": widget.taxaServico,
        "restauranteId": widget.restauranteId,

        // PAYMENT-FIRST
        "pedidoId": null,

        "endereco": widget.endereco,
        "itens": prepararItens(),
        "formaPagamento": "PIX",
        "pagamento": "PIX",
      };

      debugPrint("");
      debugPrint("========================================");
      debugPrint("💚 FOODJET - GERAR PIX");
      debugPrint("========================================");
      debugPrint(
        "🏪 RESTAURANTE: ${widget.restauranteId}",
      );
      debugPrint(
        "💰 TOTAL: ${totalPedido.toStringAsFixed(2)}",
      );
      debugPrint("🚫 PEDIDO ID: NULL");
      debugPrint("🚫 PEDIDO NÃO SERÁ CRIADO");
      debugPrint("➡️ CRIANDO SOMENTE PIX");
      debugPrint("========================================");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      debugPrint(
        "💚 PIX - HTTP: ${response.statusCode}",
      );

      Map<String, dynamic> dados;

      try {
        final decoded =
            jsonDecode(response.body);

        if (decoded is! Map) {
          throw Exception();
        }

        dados =
            Map<String, dynamic>.from(
          decoded,
        );
      } catch (_) {
        throw Exception(
          "Resposta inválida do servidor.",
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          dados["sucesso"] != true) {
        throw Exception(
          dados["erro"] ??
              dados["mensagem"] ??
              "Não foi possível gerar o PIX.",
        );
      }

      // ========================================================
      // PIX
      // ========================================================

      final pix = dados["pix"];

      if (pix == null || pix is! Map) {
        throw Exception(
          "O pagamento foi criado, mas os dados do PIX não foram retornados.",
        );
      }

      // ========================================================
      // PAGAMENTO ID
      // ========================================================

      String? novoPagamentoId;

      novoPagamentoId =
          dados["pagamentoId"]?.toString();

      novoPagamentoId ??=
          dados["paymentId"]?.toString();

      novoPagamentoId ??=
          dados["asaasPaymentId"]?.toString();

      novoPagamentoId ??=
          pix["pagamentoId"]?.toString();

      novoPagamentoId ??=
          pix["paymentId"]?.toString();

      novoPagamentoId ??=
          pix["id"]?.toString();

      if (novoPagamentoId == null ||
          novoPagamentoId.isEmpty) {
        throw Exception(
          "O Asaas criou o PIX, mas não retornou o ID do pagamento.",
        );
      }

      // ========================================================
      // QR CODE
      // ========================================================

      final novoQrCodeBase64 =
          pix["qrCodeBase64"]?.toString() ??
              pix["encodedImage"]?.toString() ??
              pix["imagem"]?.toString() ??
              "";

      // ========================================================
      // COPIA E COLA
      // ========================================================

      final novoPixCopiaCola =
          pix["qrCode"]?.toString() ??
              pix["payload"]?.toString() ??
              pix["pixCopiaCola"]?.toString() ??
              pix["copyPaste"]?.toString() ??
              "";

      // ========================================================
      // TICKET
      // ========================================================

      final novoTicketUrl =
          pix["ticketUrl"]?.toString() ??
              pix["invoiceUrl"]?.toString() ??
              "";

      // ========================================================
      // EXPIRAÇÃO
      // ========================================================

      final novaExpiracao =
          pix["expiracao"]?.toString() ??
              pix["expirationDate"]?.toString() ??
              pix["expiresAt"]?.toString() ??
              "";

      if (novoQrCodeBase64.isEmpty &&
          novoPixCopiaCola.isEmpty) {
        throw Exception(
          "O PIX foi criado, mas o QR Code não foi retornado pelo servidor.",
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        pagamentoId = novoPagamentoId;

        qrCodeBase64 =
            novoQrCodeBase64.isNotEmpty
                ? novoQrCodeBase64
                : null;

        pixCopiaCola =
            novoPixCopiaCola.isNotEmpty
                ? novoPixCopiaCola
                : null;

        ticketUrl =
            novoTicketUrl.isNotEmpty
                ? novoTicketUrl
                : null;

        pagamentoGerado = true;

        if (novaExpiracao.isNotEmpty) {
          expiracao =
              DateTime.tryParse(
            novaExpiracao,
          );
        }
      });

      debugPrint("");
      debugPrint("========================================");
      debugPrint("✅ PIX GERADO");
      debugPrint(
        "💳 PAGAMENTO: $novoPagamentoId",
      );
      debugPrint("🚫 PEDIDO: NÃO CRIADO");
      debugPrint("⏳ AGUARDANDO PAGAMENTO");
      debugPrint("========================================");

      // ========================================================
      // COMEÇAR CONSULTA
      // ========================================================

      iniciarConsultaPagamento();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        mensagem = e
            .toString()
            .replaceFirst(
              "Exception: ",
              "",
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  // ============================================================
  // CONSULTA
  // ============================================================

  void iniciarConsultaPagamento() {
    timer?.cancel();

    tentativas = 0;

    // Consulta imediatamente.
    consultarPagamento();

    // Depois consulta a cada 3 segundos.
    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) async {
        await consultarPagamento();
      },
    );
  }

  // ============================================================
  // CONSULTAR PAGAMENTO
  // ============================================================

  Future<void> consultarPagamento() async {
    if (pagamentoId == null ||
        pagamentoId!.isEmpty) {
      return;
    }

    if (navegandoPedido) {
      return;
    }

    tentativas++;

    try {
      final token = await obterToken();

      if (token == null ||
          token.isEmpty) {
        return;
      }

      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/pagamentos/$pagamentoId",
        ),
        headers: {
          "Authorization":
              "Bearer $token",
          "Content-Type":
              "application/json",
        },
      );

      debugPrint(
        "💚 PIX - CONSULTA #$tentativas - HTTP ${response.statusCode}",
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return;
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map) {
        return;
      }

      final dados =
          Map<String, dynamic>.from(
        decoded,
      );

      // ========================================================
      // STATUS
      // ========================================================

      final status =
          dados["statusPagamento"]
                  ?.toString()
                  .toUpperCase() ??
              dados["status"]
                  ?.toString()
                  .toUpperCase() ??
              dados["paymentStatus"]
                  ?.toString()
                  .toUpperCase() ??
              "";

      debugPrint(
        "💚 PIX - STATUS: $status",
      );

      // ========================================================
      // APROVAÇÃO
      // ========================================================

      final aprovado =
          dados["pagamentoAprovado"] == true ||
              dados["paymentApproved"] == true ||
              status == "APPROVED" ||
              status == "RECEIVED" ||
              status == "CONFIRMED";

      // ========================================================
      // PAGAMENTO AINDA PENDENTE
      // ========================================================

      if (!aprovado) {
        return;
      }

      // ========================================================
      // PAGAMENTO APROVADO
      // ========================================================

      if (!pagamentoAprovado) {
        pagamentoAprovado = true;

        debugPrint("");
        debugPrint(
          "========================================",
        );
        debugPrint(
          "✅ FOODJET - PIX APROVADO",
        );
        debugPrint(
          "💳 PAGAMENTO: $pagamentoId",
        );
        debugPrint(
          "⏳ AGUARDANDO WEBHOOK",
        );
        debugPrint(
          "⏳ AGUARDANDO CRIAÇÃO DO PEDIDO",
        );
        debugPrint(
          "========================================",
        );

        if (mounted) {
          setState(() {});
        }
      }

      // ========================================================
      // PROCURAR PEDIDO
      // ========================================================

      final pedidoId =
          extrairPedidoIdPagamento(
        dados,
      );

      if (pedidoId == null ||
          pedidoId.trim().isEmpty) {
        debugPrint(
          "⏳ PAGAMENTO APROVADO, MAS PEDIDO AINDA NÃO EXISTE.",
        );

        return;
      }

      final id =
          int.tryParse(
        pedidoId.trim(),
      );

      if (id == null) {
        debugPrint(
          "❌ ID DO PEDIDO INVÁLIDO: $pedidoId",
        );

        return;
      }

      debugPrint("");
      debugPrint(
        "========================================",
      );
      debugPrint(
        "🎉 FOODJET - PEDIDO ENCONTRADO",
      );
      debugPrint(
        "💳 PAGAMENTO: $pagamentoId",
      );
      debugPrint(
        "📦 PEDIDO: $id",
      );
      debugPrint(
        "➡️ ABRINDO ACOMPANHAMENTO",
      );
      debugPrint(
        "========================================",
      );

      await abrirAcompanhamento(id);
    } catch (e) {
      debugPrint(
        "⚠️ ERRO CONSULTANDO PIX: $e",
      );
    }
  }

  // ============================================================
  // EXTRAIR PEDIDO
  // ============================================================

  String? extrairPedidoIdPagamento(
    Map<String, dynamic> dados,
  ) {
    // ----------------------------------------------------------
    // DIRETO
    // ----------------------------------------------------------

    final diretos = [
      dados["pedidoId"],
      dados["orderId"],
      dados["pedido_id"],
      dados["order_id"],
    ];

    for (final valor in diretos) {
      if (valor != null &&
          valor.toString().trim().isNotEmpty) {
        return valor.toString();
      }
    }

    // ----------------------------------------------------------
    // PEDIDO
    // ----------------------------------------------------------

    final pedido = dados["pedido"];

    if (pedido is Map) {
      final id =
          pedido["id"] ??
              pedido["_id"] ??
              pedido["pedidoId"] ??
              pedido["orderId"];

      if (id != null) {
        return id.toString();
      }
    }

    // ----------------------------------------------------------
    // ORDER
    // ----------------------------------------------------------

    final order = dados["order"];

    if (order is Map) {
      final id =
          order["id"] ??
              order["_id"] ??
              order["pedidoId"] ??
              order["orderId"];

      if (id != null) {
        return id.toString();
      }
    }

    // ----------------------------------------------------------
    // PAGAMENTO
    // ----------------------------------------------------------

    final pagamento =
        dados["pagamento"];

    if (pagamento is Map) {
      final id =
          pagamento["pedidoId"] ??
              pagamento["orderId"] ??
              pagamento["pedido_id"] ??
              pagamento["order_id"];

      if (id != null) {
        return id.toString();
      }
    }

    return null;
  }

  // ============================================================
  // ABRIR PEDIDO
  // ============================================================

  Future<void> abrirAcompanhamento(
    int pedidoId,
  ) async {
    if (navegandoPedido) {
      return;
    }

    navegandoPedido = true;

    timer?.cancel();

    if (!mounted) {
      return;
    }

    debugPrint(
      "🚀 ABRINDO ORDER TRACKING: $pedidoId",
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          "Pagamento confirmado! Pedido criado.",
        ),
      ),
    );

    await Future.delayed(
      const Duration(
        milliseconds: 500,
      ),
    );

    if (!mounted) {
      return;
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OrderTrackingScreen(
          pedidoId: pedidoId,
        ),
      ),
    );
  }

  // ============================================================
  // COPIAR PIX
  // ============================================================

  void copiarPix() {
    if (pixCopiaCola == null ||
        pixCopiaCola!.isEmpty) {
      return;
    }

    Clipboard.setData(
      ClipboardData(
        text: pixCopiaCola!,
      ),
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "Código PIX copiado!",
        ),
      ),
    );
  }

  // ============================================================
  // BASE64
  // ============================================================

  String limparBase64(
    String valor,
  ) {
    return valor
        .replaceFirst(
          RegExp(
            r'^data:image\/\w+;base64,',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          '',
        );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),

          const Icon(
            Icons.pix,
            size: 70,
            color: Color(0xFF16A34A),
          ),

          const SizedBox(height: 15),

          const Text(
            "Pagamento via PIX",
            style: TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Total: R\$ ${totalPedido.toStringAsFixed(2).replaceAll('.', ',')}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 25),

          // ======================================================
          // ERRO
          // ======================================================

          if (mensagem != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(
                color:
                    Colors.red.shade50,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Text(
                mensagem!,
                style: TextStyle(
                  color:
                      Colors.red.shade700,
                  fontSize: 14,
                ),
              ),
            ),

          // ======================================================
          // GERAR PIX
          // ======================================================

          if (!pagamentoGerado)
            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton(
                onPressed:
                    carregando
                        ? null
                        : gerarPix,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFFF97316,
                  ),
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 16,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                  ),
                ),
                child: carregando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Text(
                        "Gerar PIX",
                        style:
                            TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),

          // ======================================================
          // PIX GERADO
          // ======================================================

          if (pagamentoGerado) ...[
            const SizedBox(height: 20),

            if (qrCodeBase64 != null &&
                qrCodeBase64!.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.06,
                      ),
                      blurRadius: 10,
                      offset:
                          const Offset(
                        0,
                        3,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Escaneie o QR Code",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Image.memory(
                      base64Decode(
                        limparBase64(
                          qrCodeBase64!,
                        ),
                      ),
                      width: 260,
                      height: 260,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Padding(
                          padding:
                              EdgeInsets.all(
                            20,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons
                                    .error_outline,
                                size: 50,
                                color:
                                    Colors.red,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Não foi possível carregar o QR Code.",
                                textAlign:
                                    TextAlign
                                        .center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // ====================================================
            // COPIA E COLA
            // ====================================================

            if (pixCopiaCola != null &&
                pixCopiaCola!.isNotEmpty)
              const SizedBox(height: 20),

            if (pixCopiaCola != null &&
                pixCopiaCola!.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color:
                        Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      "PIX Copia e Cola",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      pixCopiaCola!,
                      maxLines: 4,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey
                                .shade700,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton
                              .icon(
                        onPressed:
                            copiarPix,
                        icon:
                            const Icon(
                          Icons.copy,
                        ),
                        label:
                            const Text(
                          "Copiar código PIX",
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              const Color(
                            0xFFF97316,
                          ),
                          foregroundColor:
                              Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 22),

            // ====================================================
            // STATUS DO PAGAMENTO
            // ====================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(
                16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    pagamentoAprovado
                        ? Colors.green
                            .shade50
                        : Colors.orange
                            .shade50,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Icon(
                    pagamentoAprovado
                        ? Icons
                            .check_circle_outline
                        : Icons
                            .hourglass_top_rounded,
                    color:
                        pagamentoAprovado
                            ? Colors.green
                            : const Color(
                                0xFFF97316,
                              ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      pagamentoAprovado
                          ? "Pagamento confirmado! Aguardando a criação do pedido pelo servidor."
                          : "Aguardando confirmação do pagamento. Após pagar o PIX, a confirmação será feita automaticamente.",
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (expiracao != null) ...[
              const SizedBox(height: 10),
              Text(
                "Válido até: ${_formatarData(expiracao!)}",
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DATA
  // ============================================================

  String _formatarData(
    DateTime data,
  ) {
    final dia =
        data.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final mes =
        data.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final hora =
        data.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minuto =
        data.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return "$dia/$mes/${data.year} às $hora:$minuto";
  }
}


// ============================================================
// CARTÃO DE CRÉDITO
// ============================================================

class CardPaymentPage extends StatefulWidget {
  final Map<String, String> endereco;
  final List<CartItem> itens;
  final double subtotal;
  final String restauranteId;
  final double taxaEntrega;
  final double taxaServico;
  final String? pedidoId;

  const CardPaymentPage({
    super.key,
    required this.endereco,
    required this.itens,
    required this.subtotal,
    required this.restauranteId,
    required this.taxaEntrega,
    required this.taxaServico,
    this.pedidoId,
  });

  @override
  State<CardPaymentPage> createState() =>
      _CardPaymentPageState();
}

class _CardPaymentPageState
    extends State<CardPaymentPage> {

  final formKey =
      GlobalKey<FormState>();

  final nomeController =
      TextEditingController();

  final numeroController =
      TextEditingController();

  final validadeController =
      TextEditingController();

  final cvvController =
      TextEditingController();

  bool carregando = false;

  bool navegandoPedido = false;

  Timer? timer;

  double get totalPedido {
    return widget.subtotal +
        widget.taxaEntrega +
        widget.taxaServico;
  }

  @override
  void dispose() {
    timer?.cancel();

    nomeController.dispose();
    numeroController.dispose();
    validadeController.dispose();
    cvvController.dispose();

    super.dispose();
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> obterToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString("token") ??
        prefs.getString("jwt") ??
        prefs.getString("access_token") ??
        prefs.getString("auth_token");
  }

  // ============================================================
  // VALIDADE
  // ============================================================

  bool validadeExpirada(
    String validade,
  ) {
    final partes =
        validade.split("/");

    if (partes.length != 2) {
      return true;
    }

    final mes =
        int.tryParse(partes[0]);

    final anoDoisDigitos =
        int.tryParse(partes[1]);

    if (mes == null ||
        anoDoisDigitos == null ||
        mes < 1 ||
        mes > 12) {
      return true;
    }

    final ano =
        2000 + anoDoisDigitos;

    final agora =
        DateTime.now();

    if (ano < agora.year) {
      return true;
    }

    if (ano == agora.year &&
        mes < agora.month) {
      return true;
    }

    return false;
  }

  // ============================================================
  // PAGAR CARTÃO
  // ============================================================

  Future<void> pagar() async {

    if (carregando) {
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    final numero =
        numeroController.text
            .replaceAll(
          RegExp(r'\D'),
          '',
        );

    final cvv =
        cvvController.text
            .replaceAll(
          RegExp(r'\D'),
          '',
        );

    final validade =
        validadeController.text.trim();

    if (numero.length < 13 ||
        numero.length > 19) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Número do cartão inválido.",
          ),
        ),
      );

      return;
    }

    if (!RegExp(
      r'^\d{2}\/\d{2}$',
    ).hasMatch(validade)) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Informe a validade no formato MM/AA.",
          ),
        ),
      );

      return;
    }

    if (validadeExpirada(validade)) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "O cartão está vencido.",
          ),
        ),
      );

      return;
    }

    if (cvv.length < 3 ||
        cvv.length > 4) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "CVV inválido.",
          ),
        ),
      );

      return;
    }

    setState(() {
      carregando = true;
    });

    try {

      final token =
          await obterToken();

      if (token == null ||
          token.isEmpty) {

        throw Exception(
          "Sessão expirada. Faça login novamente.",
        );
      }

      // ========================================================
      // BODY
      //
      // CPF, telefone, e-mail e endereço de cobrança NÃO são
      // enviados pelo Flutter.
      //
      // O backend pega esses dados do PostgreSQL através do JWT.
      // ========================================================

      final body = {

        "valor":
            totalPedido,

        "total":
            totalPedido,

        "subtotal":
            widget.subtotal,

        "taxaEntrega":
            widget.taxaEntrega,

        "taxaServico":
            widget.taxaServico,

        "restauranteId":
            widget.restauranteId,

        // Se já existir, envia.
        // Se não existir, o backend mantém payment-first.
        "pedidoId":
            widget.pedidoId,

        // Este endereço é o endereço de ENTREGA.
        // O backend NÃO deve usar esse campo como
        // endereço de cobrança do cartão.
        "endereco":
            widget.endereco,

        "itens":
            prepararItens(),

        "formaPagamento":
            "CREDITO",

        "pagamento":
            "CREDITO",

        "cartao": {

          "numero":
              numero,

          "nome":
              nomeController.text.trim(),

          "validade":
              validade,

          "cvv":
              cvv,
        },
      };

      debugPrint("");
      debugPrint(
        "========================================",
      );
      debugPrint(
        "💳 FOODJET - PAGAMENTO CARTÃO",
      );
      debugPrint(
        "========================================",
      );
      debugPrint(
        "💰 VALOR: ${totalPedido.toStringAsFixed(2)}",
      );
      debugPrint(
        "🏪 RESTAURANTE: ${widget.restauranteId}",
      );
      debugPrint(
        "📦 PEDIDO INFORMADO: ${widget.pedidoId}",
      );
      debugPrint(
        "🔐 DADOS CADASTRAIS: BUSCADOS PELO BACKEND",
      );
      debugPrint(
        "💳 CARTÃO: ENVIADO",
      );
      debugPrint(
        "========================================",
      );

      final response =
          await http.post(
        Uri.parse(
          "${Api.baseUrl}/pagamentos/cartao",
        ),
        headers: {

          "Content-Type":
              "application/json",

          "Authorization":
              "Bearer $token",
        },
        body:
            jsonEncode(body),
      );

      debugPrint(
        "💳 CARTÃO HTTP: ${response.statusCode}",
      );

      Map<String, dynamic> dados;

      try {

        final decoded =
            jsonDecode(
          response.body,
        );

        if (decoded is! Map) {
          throw Exception();
        }

        dados =
            Map<String, dynamic>.from(
          decoded,
        );

      } catch (_) {

        throw Exception(
          "Resposta inválida do servidor.",
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          dados["sucesso"] != true) {

        throw Exception(
          dados["erro"] ??
              dados["mensagem"] ??
              "Não foi possível processar o pagamento.",
        );
      }

      // ========================================================
      // PEDIDO RETORNADO IMEDIATAMENTE
      // ========================================================

      final pedidoRetornado =
          extrairPedidoId(
        dados,
      );

      debugPrint(
        "📦 PEDIDO RETORNADO: $pedidoRetornado",
      );

      if (pedidoRetornado != null) {

        final pedidoNumero =
            int.tryParse(
          pedidoRetornado,
        );

        if (pedidoNumero != null) {

          debugPrint(
            "✅ PEDIDO JÁ EXISTE: $pedidoNumero",
          );

          await abrirAcompanhamento(
            pedidoNumero,
          );

          return;
        }
      }

      // ========================================================
      // PAGAMENTO ID
      // ========================================================

      final pagamentoId =
          extrairPagamentoId(
        dados,
      );

      debugPrint(
        "💳 PAGAMENTO ID: $pagamentoId",
      );

      if (pagamentoId == null ||
          pagamentoId.isEmpty) {

        throw Exception(
          "O pagamento foi enviado, mas o servidor não retornou o ID do pagamento.",
        );
      }

      // ========================================================
      // AVISAR USUÁRIO
      // ========================================================

      if (mounted) {

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            backgroundColor:
                Color(0xFFF97316),
            content: Text(
              "Pagamento aprovado! Aguardando confirmação do restaurante...",
            ),
          ),
        );
      }

      // ========================================================
      // COMEÇAR POLLING
      // ========================================================

      await aguardarPagamento(
        pagamentoId,
        token,
      );

    } catch (e) {

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString()
                .replaceFirst(
              "Exception: ",
              "",
            ),
          ),
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          carregando = false;
        });
      }
    }
  }

  // ============================================================
  // EXTRAIR PAGAMENTO ID
  // ============================================================

  String? extrairPagamentoId(
    Map<String, dynamic> dados,
  ) {

    final valores = [

      dados["pagamentoId"],

      dados["paymentId"],

      dados["asaasPaymentId"],

      dados["asaas_id"],

      dados["id"],

      if (dados["pagamento"] is Map)
        (dados["pagamento"]
            as Map)["id"],

      if (dados["payment"] is Map)
        (dados["payment"]
            as Map)["id"],

      if (dados["data"] is Map)
        (dados["data"]
            as Map)["pagamentoId"],

      if (dados["resultado"] is Map)
        (dados["resultado"]
            as Map)["pagamentoId"],
    ];

    for (final valor in valores) {

      if (valor != null &&
          valor.toString().trim().isNotEmpty) {

        return valor.toString().trim();
      }
    }

    return null;
  }

  // ============================================================
  // EXTRAIR PEDIDO ID
  // ============================================================

  String? extrairPedidoId(
    dynamic dados,
  ) {

    if (dados == null) {
      return null;
    }

    // ========================================================
    // SE FOR MAP
    // ========================================================

    if (dados is Map) {

      final valoresDiretos = [

        dados["pedidoId"],

        dados["orderId"],

        dados["pedido_id"],

        dados["order_id"],

        dados["idPedido"],

        dados["id_pedido"],
      ];

      for (final valor
          in valoresDiretos) {

        if (valor != null &&
            valor.toString()
                .trim()
                .isNotEmpty) {

          return valor.toString().trim();
        }
      }

      // ======================================================
      // PEDIDO
      // ======================================================

      final pedido =
          dados["pedido"];

      final pedidoId =
          extrairPedidoId(
        pedido,
      );

      if (pedidoId != null) {
        return pedidoId;
      }

      // ======================================================
      // ORDER
      // ======================================================

      final order =
          dados["order"];

      final orderId =
          extrairPedidoId(
        order,
      );

      if (orderId != null) {
        return orderId;
      }

      // ======================================================
      // PAGAMENTO
      // ======================================================

      final pagamento =
          dados["pagamento"];

      final pagamentoPedido =
          extrairPedidoId(
        pagamento,
      );

      if (pagamentoPedido != null) {
        return pagamentoPedido;
      }

      // ======================================================
      // PAYMENT
      // ======================================================

      final payment =
          dados["payment"];

      final paymentPedido =
          extrairPedidoId(
        payment,
      );

      if (paymentPedido != null) {
        return paymentPedido;
      }

      // ======================================================
      // CHECKOUT
      // ======================================================

      final checkout =
          dados["checkout"];

      final checkoutPedido =
          extrairPedidoId(
        checkout,
      );

      if (checkoutPedido != null) {
        return checkoutPedido;
      }

      // ======================================================
      // DATA
      // ======================================================

      final data =
          dados["data"];

      final dataPedido =
          extrairPedidoId(
        data,
      );

      if (dataPedido != null) {
        return dataPedido;
      }

      // ======================================================
      // RESULTADO
      // ======================================================

      final resultado =
          dados["resultado"];

      final resultadoPedido =
          extrairPedidoId(
        resultado,
      );

      if (resultadoPedido != null) {
        return resultadoPedido;
      }
    }

    // ========================================================
    // LISTA
    // ========================================================

    if (dados is List) {

      for (final item in dados) {

        final id =
            extrairPedidoId(item);

        if (id != null) {
          return id;
        }
      }
    }

    return null;
  }

  // ============================================================
  // AGUARDAR PAGAMENTO
  // ============================================================

  Future<void> aguardarPagamento(
    String pagamentoId,
    String token,
  ) async {

    timer?.cancel();

    int tentativas = 0;

    // ========================================================
    // CONSULTAR IMEDIATAMENTE
    // ========================================================

    await consultarStatusPagamento(
      pagamentoId,
      token,
    );

    if (navegandoPedido) {
      return;
    }

    // ========================================================
    // POLLING
    // ========================================================

    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) async {

        if (navegandoPedido) {
          timer?.cancel();
          return;
        }

        tentativas++;

        debugPrint(
          "💳 CARTÃO - CONSULTA #$tentativas",
        );

        await consultarStatusPagamento(
          pagamentoId,
          token,
        );
      },
    );

    // ========================================================
    // LIMITE DE 5 MINUTOS
    // ========================================================

    Future.delayed(
      const Duration(minutes: 5),
      () {

        if (navegandoPedido) {
          return;
        }

        timer?.cancel();

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "O pagamento foi processado. O pedido continua sendo atualizado pelo servidor.",
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CONSULTAR STATUS
  // ============================================================

  Future<void> consultarStatusPagamento(
    String pagamentoId,
    String token,
  ) async {

    if (navegandoPedido) {
      return;
    }

    try {

      final response =
          await http.get(
        Uri.parse(
          "${Api.baseUrl}/pagamentos/$pagamentoId",
        ),
        headers: {

          "Authorization":
              "Bearer $token",

          "Content-Type":
              "application/json",
        },
      );

      debugPrint(
        "💳 STATUS CARTÃO HTTP: ${response.statusCode}",
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {

        debugPrint(
          "⚠️ STATUS CARTÃO HTTP INVÁLIDO",
        );

        return;
      }

      final decoded =
          jsonDecode(
        response.body,
      );

      if (decoded is! Map) {
        return;
      }

      final dados =
          Map<String, dynamic>.from(
        decoded,
      );

      debugPrint(
        "💳 RESPOSTA STATUS CARTÃO: $dados",
      );

      // ========================================================
      // STATUS DO PAGAMENTO
      // ========================================================

      final status =
          dados["statusPagamento"]
                  ?.toString()
                  .toUpperCase() ??
              dados["status"]
                  ?.toString()
                  .toUpperCase() ??
              dados["paymentStatus"]
                  ?.toString()
                  .toUpperCase() ??
              dados["status_asaas"]
                  ?.toString()
                  .toUpperCase() ??
              "";

      final aprovado =
          dados["pagamentoAprovado"] == true ||
          dados["paymentApproved"] == true ||
          dados["aprovado"] == true ||
          status == "APPROVED" ||
          status == "RECEIVED" ||
          status == "CONFIRMED";

      debugPrint(
        "💳 STATUS PAGAMENTO: $status",
      );

      debugPrint(
        "💳 PAGAMENTO APROVADO: $aprovado",
      );

      if (!aprovado) {
        return;
      }

      // ========================================================
      // PAGAMENTO APROVADO
      // ========================================================

      debugPrint("");
      debugPrint(
        "========================================",
      );
      debugPrint(
        "✅ CARTÃO APROVADO",
      );
      debugPrint(
        "💳 PAGAMENTO: $pagamentoId",
      );
      debugPrint(
        "⏳ PROCURANDO PEDIDO",
      );
      debugPrint(
        "========================================",
      );

      // ========================================================
      // PROCURAR PEDIDO
      // ========================================================

      final pedidoId =
          extrairPedidoId(
        dados,
      );

      if (pedidoId == null ||
          pedidoId.trim().isEmpty) {

        debugPrint(
          "⏳ PAGAMENTO APROVADO, MAS PEDIDO AINDA NÃO FOI VINCULADO.",
        );

        return;
      }

      final id =
          int.tryParse(
        pedidoId.trim(),
      );

      if (id == null) {

        debugPrint(
          "❌ ID DO PEDIDO INVÁLIDO: $pedidoId",
        );

        return;
      }

      // ========================================================
      // PEDIDO ENCONTRADO
      // ========================================================

      debugPrint("");
      debugPrint(
        "========================================",
      );
      debugPrint(
        "🎉 PEDIDO ENCONTRADO",
      );
      debugPrint(
        "📦 PEDIDO: $id",
      );
      debugPrint(
        "➡️ ABRINDO ACOMPANHAMENTO",
      );
      debugPrint(
        "========================================",
      );

      await abrirAcompanhamento(
        id,
      );

    } catch (e) {

      debugPrint(
        "⚠️ ERRO CONSULTANDO CARTÃO: $e",
      );
    }
  }

  // ============================================================
  // ABRIR ACOMPANHAMENTO
  // ============================================================

  Future<void> abrirAcompanhamento(
    int pedidoId,
  ) async {

    if (navegandoPedido) {
      return;
    }

    navegandoPedido = true;

    timer?.cancel();

    if (!mounted) {
      return;
    }

    numeroController.clear();
    validadeController.clear();
    cvvController.clear();

    FocusScope.of(context).unfocus();

    debugPrint("");
    debugPrint(
      "========================================",
    );
    debugPrint(
      "🚀 FOODJET - ABRINDO ACOMPANHAMENTO",
    );
    debugPrint(
      "📦 PEDIDO: $pedidoId",
    );
    debugPrint(
      "⏳ STATUS SERÁ MOSTRADO NO TRACKING",
    );
    debugPrint(
      "========================================",
    );

    await Future.delayed(
      const Duration(
        milliseconds: 300,
      ),
    );

    if (!mounted) {
      return;
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OrderTrackingScreen(
          pedidoId: pedidoId,
        ),
      ),
    );
  }

  // ============================================================
  // ITENS
  // ============================================================

  List<Map<String, dynamic>>
      prepararItens() {

    return widget.itens.map((item) {

      return {

        "produtoId":
            item.nome,

        "nome":
            item.nome,

        "quantidade":
            item.quantidade,

        "preco":
            item.preco,
      };

    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Form(
      key: formKey,

      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              "Cartão de crédito",
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Total: R\$ ${totalPedido.toStringAsFixed(2).replaceAll('.', ',')}",
              style:
                  const TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // NOME
            // ==================================================

            campo(
              controller:
                  nomeController,

              label:
                  "Nome no cartão",

              hintText:
                  "Nome como aparece no cartão",

              icon:
                  Icons.person_outline,

              textCapitalization:
                  TextCapitalization.words,

              validator: (value) {

                if (value == null ||
                    value.trim().isEmpty) {

                  return
                      "Informe o nome do titular";
                }

                if (value.trim().length < 3) {

                  return
                      "Informe o nome completo";
                }

                return null;
              },
            ),

            const SizedBox(height: 15),

            // ==================================================
            // NÚMERO
            // ==================================================

            campo(
              controller:
                  numeroController,

              label:
                  "Número do cartão",

              hintText:
                  "Digite o número do cartão",

              icon:
                  Icons.credit_card,

              keyboardType:
                  TextInputType.number,

              inputFormatters: [

                FilteringTextInputFormatter
                    .digitsOnly,

                LengthLimitingTextInputFormatter(
                  19,
                ),

                CardNumberInputFormatter(),
              ],

              validator: (value) {

                final numero =
                    value?.replaceAll(
                          RegExp(r'\D'),
                          '',
                        ) ??
                        '';

                if (numero.isEmpty) {

                  return
                      "Informe o número do cartão";
                }

                if (numero.length < 13 ||
                    numero.length > 19) {

                  return
                      "Número do cartão inválido";
                }

                return null;
              },
            ),

            const SizedBox(height: 15),

            // ==================================================
            // VALIDADE + CVV
            // ==================================================

            Row(
              children: [

                Expanded(
                  child: campo(
                    controller:
                        validadeController,

                    label:
                        "Validade",

                    hintText:
                        "MM/AA",

                    icon:
                        Icons.calendar_month,

                    keyboardType:
                        TextInputType.number,

                    inputFormatters: [

                      FilteringTextInputFormatter
                          .digitsOnly,

                      LengthLimitingTextInputFormatter(
                        4,
                      ),

                      ValidityInputFormatter(),
                    ],

                    validator: (value) {

                      final texto =
                          value?.trim() ??
                              '';

                      if (!RegExp(
                        r'^\d{2}\/\d{2}$',
                      ).hasMatch(texto)) {

                        return
                            "Use MM/AA";
                      }

                      final partes =
                          texto.split("/");

                      final mes =
                          int.tryParse(
                        partes[0],
                      );

                      if (mes == null ||
                          mes < 1 ||
                          mes > 12) {

                        return
                            "Mês inválido";
                      }

                      if (validadeExpirada(
                        texto,
                      )) {

                        return
                            "Cartão vencido";
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: campo(
                    controller:
                        cvvController,

                    label:
                        "CVV",

                    hintText:
                        "123",

                    icon:
                        Icons.lock_outline,

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

                    validator: (value) {

                      final cvv =
                          value?.replaceAll(
                                RegExp(r'\D'),
                                '',
                              ) ??
                              '';

                      if (cvv.length < 3 ||
                          cvv.length > 4) {

                        return
                            "CVV inválido";
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // INFORMAÇÃO
            // ==================================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(14),

              decoration:
                  BoxDecoration(
                color:
                    Colors.orange.shade50,

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Icon(
                    Icons.info_outline,
                    color:
                        Color(0xFFF97316),
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      "Informe apenas os dados do cartão. CPF, telefone, e-mail e endereço de cobrança são obtidos automaticamente do seu cadastro.",
                      style:
                          TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // BOTÃO
            // ==================================================

            SizedBox(
              width:
                  double.infinity,

              child:
                  ElevatedButton(

                onPressed:
                    carregando
                        ? null
                        : pagar,

                style:
                    ElevatedButton.styleFrom(

                  backgroundColor:
                      const Color(
                    0xFFF97316,
                  ),

                  foregroundColor:
                      Colors.white,

                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 17,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),

                child:

                    carregando
                        ? const SizedBox(
                            height: 23,
                            width: 23,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            "Pagar com cartão",
                            style:
                                TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                "Pagamento seguro",
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CAMPO
  // ============================================================

  Widget campo({

    required TextEditingController
        controller,

    required String label,

    required String hintText,

    required IconData icon,

    TextInputType? keyboardType,

    List<TextInputFormatter>?
        inputFormatters,

    String? Function(String?)?
        validator,

    bool obscureText = false,

    TextCapitalization
        textCapitalization =
        TextCapitalization.none,

  }) {

    return TextFormField(

      controller:
          controller,

      keyboardType:
          keyboardType,

      inputFormatters:
          inputFormatters,

      validator:
          validator,

      obscureText:
          obscureText,

      textCapitalization:
          textCapitalization,

      decoration:
          InputDecoration(

        labelText:
            label,

        hintText:
            hintText,

        prefixIcon:
            Icon(icon),

        filled:
            true,

        fillColor:
            Colors.white,

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          borderSide:
              BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          borderSide:
              BorderSide(
            color:
                Colors.grey.shade300,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFFF97316),
            width: 2,
          ),
        ),
      ),
    );
  }
}



// ============================================================
// FORMATADOR DO NÚMERO DO CARTÃO
// ============================================================

class CardNumberInputFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue
      formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits =
        newValue.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    final limited =
        digits.length > 19
            ? digits.substring(
                0,
                19,
              )
            : digits;

    final buffer =
        StringBuffer();

    for (int i = 0;
        i < limited.length;
        i++) {
      if (i > 0 &&
          i % 4 == 0) {
        buffer.write(' ');
      }

      buffer.write(
        limited[i],
      );
    }

    final formatted =
        buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection:
          TextSelection.collapsed(
        offset:
            formatted.length,
      ),
    );
  }
}

// ============================================================
// FORMATADOR DA VALIDADE
// ============================================================

class ValidityInputFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue
      formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits =
        newValue.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    final limited =
        digits.length > 4
            ? digits.substring(
                0,
                4,
              )
            : digits;

    String formatted;

    if (limited.length <= 2) {
      formatted = limited;
    } else {
      formatted =
          "${limited.substring(0, 2)}/${limited.substring(2)}";
    }

    return TextEditingValue(
      text: formatted,
      selection:
          TextSelection.collapsed(
        offset:
            formatted.length,
      ),
    );
  }
}