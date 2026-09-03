
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

  // PIX pode receber o pedido já criado.
  //
  // CREDITO NÃO precisa de pedidoId antes do pagamento.
  // O backend cria o pedido somente após a aprovação do cartão.
  final String? pedidoId;

  const PaymentScreen({
    super.key,
    required this.endereco,
    required this.itens,
    required this.subtotal,
    required this.restauranteId,
    required this.taxaEntrega,
    required this.taxaServico,
    required this.formaPagamento,
    this.pedidoId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF6F7F9);

  late String formaPagamento;

  @override
  void initState() {
    super.initState();

    formaPagamento = widget.formaPagamento.trim().toUpperCase();
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String> obterToken() async {
    final prefs = await SharedPreferences.getInstance();

    final tokens = [
      prefs.getString("token"),
      prefs.getString("jwt"),
      prefs.getString("access_token"),
      prefs.getString("auth_token"),
    ];

    for (final token in tokens) {
      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }
    }

    return "";
  }

  // ============================================================
  // VALORES
  // ============================================================

  double get totalPedido {
    return widget.subtotal +
        widget.taxaServico +
        widget.taxaEntrega;
  }

  String dinheiro(double valor) {
    return "R\$ ${valor.toStringAsFixed(2).replaceAll(".", ",")}";
  }

  // ============================================================
  // ENDEREÇO DE ENTREGA
  // ============================================================

  String enderecoCompleto() {
    return [
      "${widget.endereco["rua"] ?? ""}, ${widget.endereco["numero"] ?? ""}",
      widget.endereco["complemento"] ?? "",
      widget.endereco["bairro"] ?? "",
      "${widget.endereco["cidade"] ?? ""} - ${widget.endereco["estado"] ?? ""}",
      widget.endereco["cep"] ?? "",
    ]
        .where(
          (e) => e.trim().isNotEmpty,
        )
        .join("\n");
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
        "valor": item.preco * item.quantidade,
      };
    }).toList();
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void mostrarMensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.red.shade700 : laranja,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // NAVEGAR PARA PEDIDO
  // ============================================================

  void abrirPedido(int pedidoId) {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(
          pedidoId: pedidoId,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  // ============================================================
  // EXTRAIR PEDIDO ID
  // ============================================================

  int? extrairPedidoId(
    Map<String, dynamic> dados,
  ) {
    dynamic valor;

    final pedido = dados["pedido"];

    if (pedido is Map) {
      valor =
          pedido["id"] ??
          pedido["_id"] ??
          pedido["pedidoId"];
    }

    valor ??= dados["pedidoId"];
    valor ??= dados["orderId"];

    if (valor == null) {
      return null;
    }

    if (valor is int) {
      return valor;
    }

    return int.tryParse(
      valor.toString().trim(),
    );
  }

  // ============================================================
  // EXIBIR ERRO DO BACKEND
  // ============================================================

  String extrairMensagemErro(
    Map<String, dynamic> dados,
  ) {
    final erro =
        dados["erro"] ??
        dados["mensagem"] ??
        dados["message"] ??
        dados["error"];

    if (erro != null && erro.toString().trim().isNotEmpty) {
      return erro.toString();
    }

    return "Não foi possível processar o pagamento.";
  }

  // ============================================================
  // CARD PRINCIPAL
  // ============================================================

  Widget cardPadrao(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (formaPagamento == "PIX") {
      return PixCheckoutPage(
        endereco: widget.endereco,
        itens: widget.itens,
        subtotal: widget.subtotal,
        restauranteId: widget.restauranteId,
        taxaEntrega: widget.taxaEntrega,
        taxaServico: widget.taxaServico,
        pedidoId: widget.pedidoId,
      );
    }

    if (formaPagamento == "CREDITO") {
      return CardPaymentPage(
        endereco: widget.endereco,
        itens: widget.itens,
        subtotal: widget.subtotal,
        restauranteId: widget.restauranteId,
        taxaEntrega: widget.taxaEntrega,
        taxaServico: widget.taxaServico,
        pedidoId: widget.pedidoId,
      );
    }

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          "Pagamento",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: cardPadrao(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 50,
                ),
                const SizedBox(height: 15),
                const Text(
                  "Forma de pagamento inválida.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Volte e selecione outra forma de pagamento.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
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
// PIX
// ============================================================================

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
    this.pedidoId,
  });

  @override
  State<PixCheckoutPage> createState() =>
      _PixCheckoutPageState();
}

class _PixCheckoutPageState
    extends State<PixCheckoutPage> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF6F7F9);

  bool carregando = true;
  bool erro = false;

  String mensagemErro = "";

  String? pagamentoId;
  String? qrCodeBase64;
  String? copiaECola;
  String? vencimento;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _gerarPix();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String> obterToken() async {
    final prefs = await SharedPreferences.getInstance();

    final tokens = [
      prefs.getString("token"),
      prefs.getString("jwt"),
      prefs.getString("access_token"),
      prefs.getString("auth_token"),
    ];

    for (final token in tokens) {
      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }
    }

    return "";
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
        "valor": item.preco * item.quantidade,
      };
    }).toList();
  }

  // ============================================================
  // VALORES
  // ============================================================

  double get totalPedido {
    return widget.subtotal +
        widget.taxaServico +
        widget.taxaEntrega;
  }

  // ============================================================
  // GERAR PIX
  // ============================================================

  Future<void> _gerarPix() async {
    final token = await obterToken();

    if (token.isEmpty) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = true;
        mensagemErro =
            "Sessão expirada. Faça login novamente.";
      });

      return;
    }

    final url = Uri.parse(
      "${Api.baseUrl}/pagamentos/pix",
    );

    final body = {
      "valor": totalPedido,
      "total": totalPedido,
      "subtotal": widget.subtotal,
      "taxaEntrega": widget.taxaEntrega,
      "taxaServico": widget.taxaServico,
      "restauranteId": widget.restauranteId,
      "pedidoId": widget.pedidoId,
      "endereco": widget.endereco,
      "itens": prepararItens(),
    };

    debugPrint("");
    debugPrint("========================================");
    debugPrint("💠 FOODJET - GERAR PIX");
    debugPrint("========================================");
    debugPrint("POST: $url");
    debugPrint("PEDIDO ID: ${widget.pedidoId}");
    debugPrint("RESTAURANTE: ${widget.restauranteId}");
    debugPrint("VALOR: $totalPedido");
    debugPrint("========================================");

    try {
      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      debugPrint(
        "PIX STATUS: ${response.statusCode}",
      );

      Map<String, dynamic> dados = {};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          dados = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        if (!mounted) return;

        setState(() {
          carregando = false;
          erro = true;
          mensagemErro =
              dados["erro"] ??
              dados["mensagem"] ??
              dados["message"] ??
              "Não foi possível gerar o Pix.";
        });

        return;
      }

      if (dados["sucesso"] != true &&
          dados["pagamentoId"] == null &&
          dados["paymentId"] == null) {
        if (!mounted) return;

        setState(() {
          carregando = false;
          erro = true;
          mensagemErro =
              dados["erro"] ??
              dados["mensagem"] ??
              dados["message"] ??
              "Não foi possível gerar o Pix.";
        });

        return;
      }

      final pix =
          dados["pix"] is Map
              ? Map<String, dynamic>.from(
                  dados["pix"],
                )
              : <String, dynamic>{};

      final id =
          dados["pagamentoId"] ??
          dados["paymentId"] ??
          dados["id"];

      final qr =
          dados["qrCodeBase64"] ??
          dados["qrCode"] ??
          pix["qrCodeBase64"] ??
          pix["encodedImage"] ??
          pix["qrCode"];

      final copia =
          dados["copiaECola"] ??
          dados["payload"] ??
          dados["pixCopiaECola"] ??
          pix["payload"] ??
          pix["copiaECola"];

      final venc =
          dados["dataExpiracao"] ??
          dados["expirationDate"] ??
          pix["expirationDate"];

      if (!mounted) return;

      setState(() {
        pagamentoId = id?.toString();
        qrCodeBase64 = qr?.toString();
        copiaECola = copia?.toString();
        vencimento = venc?.toString();
        carregando = false;
      });

      if (pagamentoId != null &&
          pagamentoId!.trim().isNotEmpty) {
        _iniciarConsultaPagamento();
      }
    } catch (e) {
      debugPrint(
        "❌ ERRO AO GERAR PIX: $e",
      );

      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = true;
        mensagemErro =
            "Erro ao conectar com o servidor.";
      });
    }
  }

  // ============================================================
  // CONSULTAR PIX
  // ============================================================

  void _iniciarConsultaPagamento() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        _consultarPagamento();
      },
    );
  }

  Future<void> _consultarPagamento() async {
    final id = pagamentoId;

    if (id == null || id.trim().isEmpty) {
      return;
    }

    final token = await obterToken();

    if (token.isEmpty) {
      return;
    }

    try {
      final url = Uri.parse(
        "${Api.baseUrl}/pagamentos/$id",
      );

      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return;
      }

      final dados =
          Map<String, dynamic>.from(decoded);

      final aprovado =
          dados["pagamentoAprovado"] == true ||
          dados["statusPagamento"]
                  ?.toString()
                  .toLowerCase() ==
              "approved" ||
          dados["status"]
                  ?.toString()
                  .toUpperCase() ==
              "RECEIVED" ||
          dados["status"]
                  ?.toString()
                  .toUpperCase() ==
              "CONFIRMED";

      if (!aprovado) {
        return;
      }

      final pedidoId =
          _extrairPedidoId(dados);

      if (pedidoId == null) {
        debugPrint(
          "⚠️ PIX aprovado, mas pedidoId ainda não retornado.",
        );
        return;
      }

      _timer?.cancel();

      if (!mounted) return;

      mostrarMensagem(
        "Pagamento aprovado! Pedido confirmado.",
      );

      await Future.delayed(
        const Duration(milliseconds: 600),
      );

      if (!mounted) return;

      abrirPedido(pedidoId);
    } catch (e) {
      debugPrint(
        "⚠️ Erro consultando PIX: $e",
      );
    }
  }

  int? _extrairPedidoId(
    Map<String, dynamic> dados,
  ) {
    dynamic valor;

    final pedido = dados["pedido"];

    if (pedido is Map) {
      valor =
          pedido["id"] ??
          pedido["_id"] ??
          pedido["pedidoId"];
    }

    valor ??= dados["pedidoId"];
    valor ??= dados["orderId"];

    if (valor == null) {
      return null;
    }

    if (valor is int) {
      return valor;
    }

    return int.tryParse(
      valor.toString(),
    );
  }

  // ============================================================
  // COPIAR PIX
  // ============================================================

  Future<void> _copiarPix() async {
    if (copiaECola == null ||
        copiaECola!.trim().isEmpty) {
      mostrarMensagem(
        "Código Pix indisponível.",
        erro: true,
      );
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: copiaECola!,
      ),
    );

    mostrarMensagem(
      "Código Pix copiado.",
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void mostrarMensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor:
            erro ? Colors.red.shade700 : laranja,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ABRIR PEDIDO
  // ============================================================

  void abrirPedido(int pedidoId) {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(
          pedidoId: pedidoId,
        ),
      ),
      (route) => route.isFirst,
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          "Pagamento Pix",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: carregando
            ? const Center(
                child: CircularProgressIndicator(
                  color: laranja,
                ),
              )
            : erro
                ? _telaErro()
                : _telaPix(),
      ),
    );
  }

  Widget _telaErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 55,
              ),
              const SizedBox(height: 15),
              const Text(
                "Não foi possível gerar o Pix",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                mensagemErro,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      carregando = true;
                      erro = false;
                      mensagemErro = "";
                    });

                    _gerarPix();
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Tentar novamente",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
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

  Widget _telaPix() {
    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFBF7),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Aguardando confirmação do pagamento Pix.",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (qrCodeBase64 != null &&
              qrCodeBase64!.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Text(
                    "Escaneie o QR Code",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Image.memory(
                    base64Decode(
                      qrCodeBase64!.replaceFirst(
                        RegExp(
                          r"^data:image\/[a-zA-Z]+;base64,",
                        ),
                        "",
                      ),
                    ),
                    width: 260,
                    height: 260,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 18),

          if (copiaECola != null &&
              copiaECola!.trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pix Copia e Cola",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Text(
                      copiaECola!,
                      maxLines: 4,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _copiarPix,
                      icon: const Icon(
                        Icons.copy,
                      ),
                      label: const Text(
                        "COPIAR CÓDIGO PIX",
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor: laranja,
                        side:
                            const BorderSide(
                          color: laranja,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Text(
                  "Valor do pagamento",
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "R\$ ${totalPedido.toStringAsFixed(2).replaceAll(".", ",")}",
                  style: const TextStyle(
                    color: laranja,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (vencimento != null &&
                    vencimento!
                        .trim()
                        .isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Vencimento: $vencimento",
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            "Depois que o pagamento for confirmado, "
            "o pedido será criado automaticamente.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CARTÃO DE CRÉDITO
// ============================================================================

class CardPaymentPage extends StatefulWidget {
  final Map<String, String> endereco;
  final List<CartItem> itens;
  final double subtotal;
  final String restauranteId;
  final double taxaEntrega;
  final double taxaServico;

  // Mantido opcional por compatibilidade.
  //
  // NÃO é utilizado para iniciar o pagamento.
  // O pedido só deve nascer após a aprovação do cartão.
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
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF6F7F9);

  final formKey = GlobalKey<FormState>();

  final numeroController =
      TextEditingController();

  final validadeController =
      TextEditingController();

  final cvvController =
      TextEditingController();

  bool processando = false;

  String? pagamentoId;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();

    numeroController.dispose();
    validadeController.dispose();
    cvvController.dispose();

    super.dispose();
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String> obterToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    final tokens = [
      prefs.getString("token"),
      prefs.getString("jwt"),
      prefs.getString("access_token"),
      prefs.getString("auth_token"),
    ];

    for (final token in tokens) {
      if (token != null &&
          token.trim().isNotEmpty) {
        return token.trim();
      }
    }

    return "";
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
        "valor": item.preco * item.quantidade,
      };
    }).toList();
  }

  // ============================================================
  // TOTAL
  // ============================================================

  double get totalPedido {
    return widget.subtotal +
        widget.taxaServico +
        widget.taxaEntrega;
  }

  String dinheiro(double valor) {
    return "R\$ ${valor.toStringAsFixed(2).replaceAll(".", ",")}";
  }

  // ============================================================
  // LIMPAR NÚMERO
  // ============================================================

  String somenteNumeros(String valor) {
    return valor.replaceAll(
      RegExp(r"[^0-9]"),
      "",
    );
  }

  // ============================================================
  // VALIDAR
  // ============================================================

  bool validarCampos() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    final numero =
        somenteNumeros(
      numeroController.text,
    );

    final cvv =
        somenteNumeros(
      cvvController.text,
    );

    final validade =
        validadeController.text.trim();

    if (numero.length < 13 ||
        numero.length > 19) {
      mostrarMensagem(
        "Informe um número de cartão válido.",
        erro: true,
      );
      return false;
    }

    if (cvv.length < 3 ||
        cvv.length > 4) {
      mostrarMensagem(
        "Informe um CVV válido.",
        erro: true,
      );
      return false;
    }

    if (!RegExp(
      r"^\d{2}\/\d{2,4}$",
    ).hasMatch(validade)) {
      mostrarMensagem(
        "Informe a validade no formato MM/AA.",
        erro: true,
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // PAGAR
  // ============================================================

  Future<void> _pagar() async {
    if (processando) {
      return;
    }

    if (!validarCampos()) {
      return;
    }

    final token = await obterToken();

    if (token.isEmpty) {
      mostrarMensagem(
        "Sessão expirada. Faça login novamente.",
        erro: true,
      );
      return;
    }

    setState(() {
      processando = true;
    });

    final numero =
        somenteNumeros(
      numeroController.text,
    );

    final cvv =
        somenteNumeros(
      cvvController.text,
    );

    final validade =
        validadeController.text.trim();

    final partes =
        validade.split("/");

    String mes = "";
    String ano = "";

    if (partes.length == 2) {
      mes = partes[0].trim();
      ano = partes[1].trim();

      if (ano.length == 2) {
        ano = "20$ano";
      }
    }

    // ==========================================================
    // IMPORTANTE
    //
    // NÃO enviamos:
    //
    // - nome do titular
    // - CPF
    // - telefone do titular
    // - CEP de cobrança
    // - endereço de cobrança
    //
    // O backend deverá obter os dados do usuário autenticado
    // a partir do cadastro dele.
    //
    // Também NÃO enviamos pedidoId.
    //
    // O pedido só deve nascer após a aprovação do cartão.
    // ==========================================================

    final body = {
      "valor": totalPedido,
      "total": totalPedido,
      "subtotal": widget.subtotal,
      "taxaEntrega": widget.taxaEntrega,
      "taxaServico": widget.taxaServico,

      // Endereço de ENTREGA.
      "restauranteId":
          widget.restauranteId,

      "endereco":
          widget.endereco,

      "itens":
          prepararItens(),

      "formaPagamento":
          "CREDITO",

      "pagamento":
          "CREDITO",

      // Somente os dados necessários do cartão.
      //
      // NÃO enviar dados do titular aqui.
      "cartao": {
        "numero": numero,
        "mes": mes,
        "ano": ano,
        "cvv": cvv,
      },
    };

    final url = Uri.parse(
      "${Api.baseUrl}/pagamentos/cartao",
    );

    debugPrint("");
    debugPrint("========================================");
    debugPrint("💳 FOODJET - PAGAMENTO CARTÃO");
    debugPrint("========================================");
    debugPrint("POST: $url");
    debugPrint(
      "RESTAURANTE: ${widget.restauranteId}",
    );
    debugPrint(
      "VALOR: $totalPedido",
    );
    debugPrint(
      "DADOS DO TITULAR: NÃO ENVIADOS PELO APP",
    );
    debugPrint(
      "ENDEREÇO DE COBRANÇA: NÃO ENVIADO",
    );
    debugPrint(
      "FLUXO: CARTÃO → ASAAS → APROVAÇÃO → PEDIDO",
    );
    debugPrint(
      "PEDIDO ID PRÉVIO: NÃO UTILIZADO",
    );
    debugPrint("========================================");

    try {
      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization":
                  "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 45),
          );

      debugPrint("");
      debugPrint("========================================");
      debugPrint("📥 RESPOSTA CARTÃO");
      debugPrint("========================================");
      debugPrint(
        "STATUS: ${response.statusCode}",
      );
      debugPrint(
        "RESPOSTA RECEBIDA DO BACKEND.",
      );
      debugPrint("========================================");

      Map<String, dynamic> dados = {};

      try {
        final decoded =
            jsonDecode(response.body);

        if (decoded is Map) {
          dados =
              Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint(
          "⚠️ Resposta não é JSON: $e",
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        mostrarMensagem(
          _extrairMensagemErro(dados),
          erro: true,
        );

        if (mounted) {
          setState(() {
            processando = false;
          });
        }

        return;
      }

      final sucesso =
          dados["sucesso"] == true ||
          dados["pagamentoId"] != null ||
          dados["paymentId"] != null;

      if (!sucesso) {
        mostrarMensagem(
          _extrairMensagemErro(dados),
          erro: true,
        );

        if (mounted) {
          setState(() {
            processando = false;
          });
        }

        return;
      }

      final id =
          dados["pagamentoId"] ??
          dados["paymentId"] ??
          dados["id"];

      if (id == null ||
          id.toString().trim().isEmpty) {
        mostrarMensagem(
          "O pagamento foi iniciado, mas o identificador não foi retornado.",
          erro: true,
        );

        if (mounted) {
          setState(() {
            processando = false;
          });
        }

        return;
      }

      pagamentoId =
          id.toString().trim();

      // ==========================================================
      // VERIFICAR SE JÁ FOI APROVADO
      // ==========================================================

      final aprovadoNaResposta =
          dados["pagamentoAprovado"] == true ||
          dados["statusPagamento"]
                  ?.toString()
                  .toLowerCase() ==
              "approved" ||
          dados["status"]
                  ?.toString()
                  .toUpperCase() ==
              "RECEIVED" ||
          dados["status"]
                  ?.toString()
                  .toUpperCase() ==
              "CONFIRMED";

      if (aprovadoNaResposta) {
        final pedidoId =
            extrairPedidoId(dados);

        if (pedidoId != null) {
          await pagamentoAprovado(
            pedidoId,
          );
          return;
        }
      }

      // ==========================================================
      // PAGAMENTO AINDA SENDO PROCESSADO
      // ==========================================================

      if (!mounted) return;

      mostrarMensagem(
        "Pagamento enviado. Aguardando confirmação...",
      );

      _iniciarConsultaPagamento();
    } catch (e) {
      debugPrint(
        "❌ ERRO PAGAMENTO CARTÃO: $e",
      );

      if (!mounted) return;

      setState(() {
        processando = false;
      });

      mostrarMensagem(
        "Erro ao conectar com o servidor. Tente novamente.",
        erro: true,
      );
    }
  }

  // ============================================================
  // CONSULTAR PAGAMENTO
  // ============================================================

  void _iniciarConsultaPagamento() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        _consultarPagamento();
      },
    );
  }

  Future<void> _consultarPagamento() async {
    final id = pagamentoId;

    if (id == null ||
        id.trim().isEmpty) {
      return;
    }

    final token = await obterToken();

    if (token.isEmpty) {
      return;
    }

    try {
      final url = Uri.parse(
        "${Api.baseUrl}/pagamentos/$id",
      );

      final response = await http
          .get(
            url,
            headers: {
              "Accept":
                  "application/json",
              "Authorization":
                  "Bearer $token",
            },
          )
          .timeout(
            const Duration(seconds: 15),
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
          Map<String, dynamic>.from(decoded);

      debugPrint(
        "💳 STATUS PAGAMENTO: "
        "${dados["status"] ?? dados["statusPagamento"]}",
      );

      final pedidoId =
          extrairPedidoId(dados);

      final aprovado =
          dados["pagamentoAprovado"] == true ||
          dados["statusPagamento"]
                  ?.toString()
                  .toLowerCase() ==
              "approved" ||
          dados["status"]
                  ?.toString()
                  .toUpperCase() ==
              "RECEIVED" ||
          dados["status"]
                  ?.toString()
                  .toUpperCase() ==
              "CONFIRMED";

      if (aprovado &&
          pedidoId != null) {
        await pagamentoAprovado(
          pedidoId,
        );

        return;
      }

      // ==========================================================
      // PAGAMENTO RECUSADO
      // ==========================================================

      final status =
          (dados["status"] ??
                  dados["statusPagamento"] ??
                  "")
              .toString()
              .toUpperCase();

      if (status == "REFUSED" ||
          status == "DENIED" ||
          status == "CANCELLED" ||
          status == "CANCELED" ||
          status == "OVERDUE" ||
          status == "FAILED") {
        _timer?.cancel();

        if (!mounted) return;

        setState(() {
          processando = false;
        });

        mostrarMensagem(
          dados["mensagem"] ??
              dados["erro"] ??
              "O pagamento foi recusado.",
          erro: true,
        );
      }
    } catch (e) {
      debugPrint(
        "⚠️ Erro consultando pagamento: $e",
      );
    }
  }

  // ============================================================
  // PAGAMENTO APROVADO
  // ============================================================

  Future<void> pagamentoAprovado(
    int pedidoId,
  ) async {
    _timer?.cancel();

    if (!mounted) return;

    setState(() {
      processando = false;
    });

    mostrarMensagem(
      "Pagamento aprovado! Pedido confirmado.",
    );

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(
          pedidoId: pedidoId,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  // ============================================================
  // EXTRAIR PEDIDO ID
  // ============================================================

  int? extrairPedidoId(
    Map<String, dynamic> dados,
  ) {
    dynamic valor;

    final pedido = dados["pedido"];

    if (pedido is Map) {
      valor =
          pedido["id"] ??
          pedido["_id"] ??
          pedido["pedidoId"];
    }

    valor ??= dados["pedidoId"];
    valor ??= dados["orderId"];

    // NÃO utilizar externalReference como pedidoId.
    //
    // No novo fluxo de cartão, externalReference pode ser:
    //
    // FOODJET-CHK-123-175...
    //
    // portanto não é o ID numérico do pedido.

    if (valor == null) {
      return null;
    }

    if (valor is int) {
      return valor;
    }

    return int.tryParse(
      valor.toString().trim(),
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  String _extrairMensagemErro(
    Map<String, dynamic> dados,
  ) {
    final erro =
        dados["erro"] ??
        dados["mensagem"] ??
        dados["message"] ??
        dados["error"];

    if (erro != null &&
        erro.toString().trim().isNotEmpty) {
      return erro.toString();
    }

    return "Não foi possível processar o pagamento.";
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void mostrarMensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor:
            erro ? Colors.red.shade700 : laranja,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // CAMPO
  // ============================================================

  Widget campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? hintText,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textCapitalization:
            textCapitalization,
        inputFormatters:
            inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(
            icon,
            color: laranja,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(13),
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(13),
            borderSide:
                const BorderSide(
              color: Colors.black12,
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(13),
            borderSide:
                const BorderSide(
              color: laranja,
              width: 2,
            ),
          ),
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          "Cartão de Crédito",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // SEGURANÇA
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF0FBF5),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Colors.green,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Pagamento seguro processado pelo Asaas.",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // DADOS DO CARTÃO
                // ==================================================

                const Text(
                  "Dados do cartão",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 12),

                campo(
                  controller:
                      numeroController,
                  label: "Número do cartão",
                  hintText:
                      "0000 0000 0000 0000",
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
                  ],
                  validator: (value) {
                    final numero =
                        somenteNumeros(
                      value ?? "",
                    );

                    if (numero.isEmpty) {
                      return "Informe o número do cartão";
                    }

                    if (numero.length <
                            13 ||
                        numero.length >
                            19) {
                      return "Número inválido";
                    }

                    return null;
                  },
                ),

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
                            Icons.date_range_outlined,
                        keyboardType:
                            TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .allow(
                            RegExp(
                              r"[0-9/]",
                            ),
                          ),
                          LengthLimitingTextInputFormatter(
                            7,
                          ),
                        ],
                        validator:
                            (value) {
                          final texto =
                              value
                                  ?.trim() ??
                              "";

                          if (!RegExp(
                            r"^\d{2}\/\d{2,4}$",
                          ).hasMatch(
                            texto,
                          )) {
                            return "MM/AA";
                          }

                          return null;
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: campo(
                        controller:
                            cvvController,
                        label: "CVV",
                        icon:
                            Icons.lock_outline,
                        keyboardType:
                            TextInputType.number,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                          LengthLimitingTextInputFormatter(
                            4,
                          ),
                        ],
                        validator:
                            (value) {
                          final cvv =
                              somenteNumeros(
                            value ?? "",
                          );

                          if (cvv.length <
                                  3 ||
                              cvv.length >
                                  4) {
                            return "Inválido";
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ==================================================
                // INFORMAÇÃO
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color:
                        Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color:
                            Colors.grey.shade700,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          "Os dados do titular são obtidos automaticamente "
                          "do cadastro da sua conta. Não é necessário "
                          "preencher essas informações aqui.",
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // TOTAL
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          Text(
                            dinheiro(
                              totalPedido,
                            ),
                            style:
                                const TextStyle(
                              color:
                                  laranja,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // BOTÃO
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        processando
                            ? null
                            : _pagar,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          laranja,
                      disabledBackgroundColor:
                          Colors.grey.shade400,
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
                    child: processando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Icon(
                                Icons
                                    .lock_outline,
                                size: 20,
                              ),
                              SizedBox(
                                width: 9,
                              ),
                              Text(
                                "PAGAR COM CARTÃO",
                                style:
                                    TextStyle(
                                  fontSize:
                                      16,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                          .verified_user_outlined,
                      size: 14,
                      color:
                          Colors.green.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Pagamento protegido",
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

