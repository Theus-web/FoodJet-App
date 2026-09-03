
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
    required this.taxaServico,
    required this.formaPagamento,
    this.pedidoId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  double get totalPedido =>
      widget.subtotal + widget.taxaEntrega + widget.taxaServico;

  @override
  Widget build(BuildContext context) {
    final forma = widget.formaPagamento.toUpperCase();

    if (forma == "PIX") {
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

    if (forma == "CREDITO") {
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
      appBar: AppBar(
        title: const Text("Pagamento"),
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text("Forma de pagamento não disponível."),
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
    this.pedidoId,
  });

  @override
  State<PixCheckoutPage> createState() => _PixCheckoutPageState();
}

class _PixCheckoutPageState extends State<PixCheckoutPage> {
  bool carregando = true;
  bool erro = false;

  String? pagamentoId;
  String? qrCodeBase64;
  String? copiaCola;
  String? expiracao;

  Timer? timer;

  double get totalPedido =>
      widget.subtotal + widget.taxaEntrega + widget.taxaServico;

  @override
  void initState() {
    super.initState();
    gerarPix();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<String?> obterToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("token") ??
        prefs.getString("jwt") ??
        prefs.getString("access_token") ??
        prefs.getString("auth_token");
  }

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

  Future<void> gerarPix() async {
    try {
      setState(() {
        carregando = true;
        erro = false;
      });

      final token = await obterToken();

      if (token == null || token.isEmpty) {
        throw Exception("Token de autenticação não encontrado.");
      }

      final url = Uri.parse(
        "${Api.baseUrl}/pagamentos/pix",
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "valor": totalPedido,
          "total": totalPedido,
          "subtotal": widget.subtotal,
          "taxaEntrega": widget.taxaEntrega,
          "taxaServico": widget.taxaServico,
          "restauranteId": widget.restauranteId,
          "pedidoId": widget.pedidoId,
          "endereco": widget.endereco,
          "itens": prepararItens(),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          "Erro ao gerar PIX: ${response.statusCode}",
        );
      }

      final dados = jsonDecode(response.body);

      if (dados["sucesso"] != true) {
        throw Exception(
          dados["mensagem"] ??
              "Não foi possível gerar o PIX.",
        );
      }

      final pagamento = dados["pagamento"] ?? dados;

      pagamentoId =
          pagamento["pagamentoId"]?.toString() ??
          dados["pagamentoId"]?.toString();

      qrCodeBase64 =
          pagamento["qrCodeBase64"]?.toString() ??
          pagamento["qrCode"]?.toString() ??
          dados["qrCodeBase64"]?.toString();

      copiaCola =
          pagamento["payload"]?.toString() ??
          pagamento["copiaCola"]?.toString() ??
          dados["payload"]?.toString();

      expiracao =
          pagamento["expirationDate"]?.toString() ??
          pagamento["expiracao"]?.toString() ??
          dados["expirationDate"]?.toString();

      if (pagamentoId == null || pagamentoId!.isEmpty) {
        throw Exception(
          "O servidor não retornou o ID do pagamento.",
        );
      }

      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      iniciarConsultaPagamento();
    } catch (e) {
      debugPrint("ERRO AO GERAR PIX: $e");

      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = true;
      });
    }
  }

  void iniciarConsultaPagamento() {
    timer?.cancel();

    timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        consultarPagamento();
      },
    );
  }

  Future<void> consultarPagamento() async {
    if (pagamentoId == null) return;

    try {
      final token = await obterToken();

      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse(
          "${Api.baseUrl}/pagamentos/$pagamentoId",
        ),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return;
      }

      final dados = jsonDecode(response.body);

      final status =
          dados["statusPagamento"]?.toString().toUpperCase() ??
          dados["status"]?.toString().toUpperCase() ??
          "";

      final aprovado =
          dados["pagamentoAprovado"] == true ||
          status == "APPROVED" ||
          status == "RECEIVED" ||
          status == "CONFIRMED";

      if (!aprovado) return;

      timer?.cancel();

      final pedidoId =
          dados["pedidoId"]?.toString() ??
          dados["pedido"]?["id"]?.toString();

      if (pedidoId == null || pedidoId.isEmpty) {
        debugPrint(
          "PIX APROVADO, MAS PEDIDO NÃO FOI RETORNADO.",
        );
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            pedidoId: int.tryParse(pedidoId) ?? 0,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        "ERRO AO CONSULTAR PAGAMENTO PIX: $e",
      );
    }
  }

  Future<void> copiarPix() async {
    if (copiaCola == null || copiaCola!.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: copiaCola!),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Código PIX copiado."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Pagamento PIX"),
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : erro
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Não foi possível gerar o PIX.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: gerarPix,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            "Tentar novamente",
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.pix,
                        size: 64,
                        color: Color(0xFFF97316),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Pague com PIX",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Escaneie o QR Code ou copie o código PIX.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (qrCodeBase64 != null &&
                          qrCodeBase64!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: Image.memory(
                            base64Decode(
                              qrCodeBase64!
                                  .replaceFirst(
                                    RegExp(
                                      r'^data:image\/[a-zA-Z]+;base64,',
                                    ),
                                    '',
                                  ),
                            ),
                            width: 250,
                            height: 250,
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (copiaCola != null &&
                          copiaCola!.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: copiarPix,
                            icon: const Icon(
                              Icons.copy,
                            ),
                            label: const Text(
                              "Copiar código PIX",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFF97316),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        "Total: R\$ ${totalPedido.toStringAsFixed(2).replaceAll('.', ',')}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (expiracao != null &&
                          expiracao!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          "Expiração: $expiracao",
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                      const Text(
                        "Aguardando confirmação do pagamento...",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
    );
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
  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final numeroController = TextEditingController();
  final validadeController = TextEditingController();
  final cvvController = TextEditingController();

  bool processando = false;

  double get totalPedido =>
      widget.subtotal +
      widget.taxaEntrega +
      widget.taxaServico;

  @override
  void dispose() {
    nomeController.dispose();
    numeroController.dispose();
    validadeController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  Future<String?> obterToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("token") ??
        prefs.getString("jwt") ??
        prefs.getString("access_token") ??
        prefs.getString("auth_token");
  }

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

  bool validarCampos() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    final numero =
        numeroController.text.replaceAll(RegExp(r'\D'), '');

    if (numero.length < 13 || numero.length > 19) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Informe um número de cartão válido.",
          ),
        ),
      );
      return false;
    }

    final cvv =
        cvvController.text.replaceAll(RegExp(r'\D'), '');

    if (cvv.length < 3 || cvv.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Informe um CVV válido."),
        ),
      );
      return false;
    }

    final validade = validadeController.text.trim();

    final match = RegExp(
      r'^(\d{2})\/(\d{2}|\d{4})$',
    ).firstMatch(validade);

    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Informe a validade no formato MM/AA.",
          ),
        ),
      );
      return false;
    }

    final mes = int.tryParse(match.group(1)!);

    if (mes == null || mes < 1 || mes > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mês de validade inválido."),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> pagar() async {
    if (!validarCampos()) return;

    setState(() {
      processando = true;
    });

    try {
      final token = await obterToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          "Token de autenticação não encontrado.",
        );
      }

      final numero =
          numeroController.text.replaceAll(RegExp(r'\D'), '');

      final cvv =
          cvvController.text.replaceAll(RegExp(r'\D'), '');

      final validade = validadeController.text.trim();

      final partes = validade.split('/');

      final mes = int.parse(partes[0]);

      int ano = int.parse(partes[1]);

      if (partes[1].length == 2) {
        ano += 2000;
      }

      final body = {
        "valor": totalPedido,
        "total": totalPedido,
        "subtotal": widget.subtotal,
        "taxaEntrega": widget.taxaEntrega,
        "taxaServico": widget.taxaServico,
        "restauranteId": widget.restauranteId,

        // Endereço de ENTREGA.
        "endereco": widget.endereco,

        "itens": prepararItens(),

        "formaPagamento": "CREDITO",
        "pagamento": "CREDITO",

        "cartao": {
          "numero": numero,
          "nome": nomeController.text.trim(),
          "mes": mes,
          "ano": ano,
          "cvv": cvv,
        },
      };

      debugPrint(
        "PAGAMENTO CARTAO: ENVIANDO PARA O BACKEND",
      );
      debugPrint(
        "NOME DO TITULAR: ENVIADO",
      );
      debugPrint(
        "CPF/TELEFONE: NAO ENVIADOS",
      );
      debugPrint(
        "ENDERECO DE COBRANCA: NAO ENVIADO",
      );

      final response = await http.post(
        Uri.parse(
          "${Api.baseUrl}/pagamentos/cartao",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      debugPrint(
        "STATUS PAGAMENTO CARTAO: ${response.statusCode}",
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String mensagem =
            "Não foi possível processar o pagamento.";

        try {
          final erro = jsonDecode(response.body);

          mensagem =
              erro["mensagem"]?.toString() ??
              erro["erro"]?.toString() ??
              mensagem;
        } catch (_) {}

        throw Exception(mensagem);
      }

      final dados = jsonDecode(response.body);

      if (dados["sucesso"] != true) {
        throw Exception(
          dados["mensagem"] ??
              dados["erro"] ??
              "Pagamento não aprovado.",
        );
      }

      final pagamentoAprovado =
          dados["pagamentoAprovado"] == true ||
          dados["statusPagamento"]
                  ?.toString()
                  .toUpperCase() ==
              "APPROVED" ||
          dados["status"]
                  ?.toString()
                  .toUpperCase() ==
              "RECEIVED" ||
          dados["status"]
                  ?.toString()
                  .toUpperCase() ==
              "CONFIRMED";

      if (!pagamentoAprovado) {
        final pagamentoId =
            dados["pagamentoId"]?.toString();

        if (pagamentoId != null &&
            pagamentoId.isNotEmpty) {
          await aguardarPagamento(
            pagamentoId,
            token,
          );
        } else {
          throw Exception(
            "Pagamento ainda não confirmado.",
          );
        }

        return;
      }

      final pedidoId =
          extrairPedidoId(dados);

      if (pedidoId == null) {
        throw Exception(
          "Pagamento aprovado, mas o pedido ainda não foi localizado.",
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            pedidoId: pedidoId,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        "ERRO PAGAMENTO CARTAO: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  "Exception: ",
                  "",
                ),
          ),
          duration: const Duration(seconds: 5),
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

  int? extrairPedidoId(
    Map<String, dynamic> dados,
  ) {
    final valor =
        dados["pedidoId"] ??
        dados["pedido"]?["id"];

    if (valor == null) {
      return null;
    }

    return int.tryParse(
      valor.toString(),
    );
  }

  Future<void> aguardarPagamento(
    String pagamentoId,
    String token,
  ) async {
    for (int tentativa = 0;
        tentativa < 24;
        tentativa++) {
      await Future.delayed(
        const Duration(seconds: 5),
      );

      if (!mounted) return;

      try {
        final response = await http.get(
          Uri.parse(
            "${Api.baseUrl}/pagamentos/$pagamentoId",
          ),
          headers: {
            "Authorization": "Bearer $token",
          },
        );

        if (response.statusCode < 200 ||
            response.statusCode >= 300) {
          continue;
        }

        final dados = jsonDecode(response.body);

        final status =
            dados["statusPagamento"]
                    ?.toString()
                    .toUpperCase() ??
                dados["status"]
                    ?.toString()
                    .toUpperCase() ??
                "";

        final aprovado =
            dados["pagamentoAprovado"] == true ||
            status == "APPROVED" ||
            status == "RECEIVED" ||
            status == "CONFIRMED";

        if (aprovado) {
          final pedidoId =
              extrairPedidoId(dados);

          if (pedidoId == null) {
            continue;
          }

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(
                pedidoId: pedidoId,
              ),
            ),
          );

          return;
        }

        if (status == "REFUSED" ||
            status == "FAILED" ||
            status == "CANCELED" ||
            status == "CANCELLED") {
          throw Exception(
            "O pagamento foi recusado.",
          );
        }
      } catch (e) {
        if (e.toString().contains(
              "pagamento foi recusado",
            )) {
          rethrow;
        }
      }
    }

    throw Exception(
      "O pagamento ainda não foi confirmado. Tente novamente em alguns instantes.",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Cartão de crédito"),
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(14),
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
                        "Pagamento seguro",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Dados do cartão",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // NOME DO TITULAR
              // ==================================================

              campo(
                controller: nomeController,
                label: "Nome no cartão",
                hintText:
                    "Nome como aparece no cartão",
                icon: Icons.person_outline,
                textCapitalization:
                    TextCapitalization.words,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Informe o nome do titular";
                  }

                  if (value.trim().length < 3) {
                    return "Informe o nome completo";
                  }

                  return null;
                },
              ),

              // ==================================================
              // NUMERO
              // ==================================================

              campo(
                controller: numeroController,
                label: "Número do cartão",
                hintText: "0000 0000 0000 0000",
                icon: Icons.credit_card,
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
                    return "Informe o número do cartão";
                  }

                  if (numero.length < 13 ||
                      numero.length > 19) {
                    return "Número de cartão inválido";
                  }

                  return null;
                },
              ),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: campo(
                      controller:
                          validadeController,
                      label: "Validade",
                      hintText: "MM/AA",
                      icon:
                          Icons.calendar_month,
                      keyboardType:
                          TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                        LengthLimitingTextInputFormatter(
                          6,
                        ),
                        ValidityInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return "Informe a validade";
                        }

                        final match =
                            RegExp(
                          r'^(\d{2})\/(\d{2}|\d{4})$',
                        ).firstMatch(
                          value.trim(),
                        );

                        if (match == null) {
                          return "MM/AA";
                        }

                        final mes =
                            int.tryParse(
                          match.group(1)!,
                        );

                        if (mes == null ||
                            mes < 1 ||
                            mes > 12) {
                          return "Mês inválido";
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: campo(
                      controller: cvvController,
                      label: "CVV",
                      hintText: "123",
                      icon: Icons.lock_outline,
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
                      validator: (value) {
                        final cvv =
                            value?.replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                ) ??
                                '';

                        if (cvv.isEmpty) {
                          return "Informe o CVV";
                        }

                        if (cvv.length < 3 ||
                            cvv.length > 4) {
                          return "CVV inválido";
                        }

                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Text(
                  "Informe apenas o nome do titular exatamente como aparece no cartão. CPF, telefone e endereço de cobrança não são necessários nesta etapa.",
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      "R\$ ${totalPedido.toStringAsFixed(2).replaceAll('.', ',')}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFFF97316),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      processando ? null : pagar,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFF97316),
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: processando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Pagar com cartão",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
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

  Widget campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    List<TextInputFormatter>?
        inputFormatters,
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
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFF97316),
              width: 2,
            ),
          ),
          errorBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
            borderSide:
                const BorderSide(
              color: Colors.red,
            ),
          ),
          focusedErrorBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
            borderSide:
                const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FORMATADOR DO NUMERO DO CARTAO
// ============================================================

class CardNumberInputFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits =
        newValue.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    final buffer = StringBuffer();

    for (int i = 0;
        i < digits.length && i < 19;
        i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }

      buffer.write(digits[i]);
    }

    final result = buffer.toString();

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: result.length,
      ),
    );
  }
}

// ============================================================
// FORMATADOR DE VALIDADE
// ============================================================

class ValidityInputFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits =
        newValue.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (digits.length <= 2) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(
          offset: digits.length,
        ),
      );
    }

    final result =
        "${digits.substring(0, 2)}/${digits.substring(2)}";

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: result.length,
      ),
    );
  }
}

