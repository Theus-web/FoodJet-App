
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
              pedidoId: widget.pedidoId,
            )
          : formaPagamento == "CREDITO"
              ? CardPaymentPage(
                  endereco: widget.endereco,
                  itens: widget.itens,
                  subtotal: widget.subtotal,
                  restauranteId: widget.restauranteId,
                  taxaEntrega: widget.taxaEntrega,
                  taxaServico: widget.taxaServico,
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

  String? pagamentoId;
  String? qrCodeBase64;
  String? pixCopiaCola;
  String? mensagem;
  DateTime? expiracao;

  Timer? timer;

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

  Future<String?> obterToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString("token") ??
        prefs.getString("jwt") ??
        prefs.getString("access_token") ??
        prefs.getString("auth_token");
  }

  Future<void> gerarPix() async {
    if (carregando) return;

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

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final dados =
          jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          dados["sucesso"] != true) {
        throw Exception(
          dados["erro"] ??
              dados["mensagem"] ??
              "Não foi possível gerar o PIX.",
        );
      }

      final pagamento =
          dados["pagamento"] ?? {};

      setState(() {
        pagamentoId =
            dados["pagamentoId"]?.toString() ??
                pagamento["id"]?.toString();

        qrCodeBase64 =
            dados["qrCodeBase64"]?.toString() ??
                pagamento["qrCodeBase64"]?.toString();

        pixCopiaCola =
            dados["pixCopiaCola"]?.toString() ??
                dados["payload"]?.toString() ??
                pagamento["payload"]?.toString();

        pagamentoGerado = true;

        if (dados["dataExpiracao"] != null) {
          expiracao = DateTime.tryParse(
            dados["dataExpiracao"].toString(),
          );
        }
      });

      if (pagamentoId != null) {
        iniciarConsultaPagamento();
      }
    } catch (e) {
      setState(() {
        mensagem =
            e.toString().replaceFirst(
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

  void iniciarConsultaPagamento() {
    timer?.cancel();

    timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        await consultarPagamento();
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

      final dados =
          jsonDecode(response.body);

      final status =
          dados["statusPagamento"]
              ?.toString()
              .toUpperCase();

      final aprovado =
          dados["pagamentoAprovado"] == true ||
          status == "APPROVED" ||
          status == "RECEIVED" ||
          status == "CONFIRMED";

      if (!aprovado) return;

      final pedidoId =
          dados["pedidoId"] ??
              dados["orderId"];

      if (pedidoId == null) return;

      timer?.cancel();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
    OrderTrackingScreen(
  pedidoId: int.parse(pedidoId.toString()),
),
        ),
      );
    } catch (_) {
      // Continua consultando até o pagamento ser aprovado.
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Total: R\$ ${totalPedido.toStringAsFixed(2).replaceAll('.', ',')}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 25),

          if (mensagem != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Text(
                mensagem!,
                style: TextStyle(
                  color: Colors.red.shade700,
                ),
              ),
            ),

          if (!pagamentoGerado)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    carregando ? null : gerarPix,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: carregando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Gerar PIX",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),

          if (pagamentoGerado) ...[
            if (qrCodeBase64 != null &&
                qrCodeBase64!.isNotEmpty) ...[
              const SizedBox(height: 20),

              Container(
                padding:
                    const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Image.memory(
                  base64Decode(
                    qrCodeBase64!
                        .replaceFirst(
                      RegExp(
                        r'^data:image\/\w+;base64,',
                      ),
                      '',
                    ),
                  ),
                  width: 260,
                  height: 260,
                  fit: BoxFit.contain,
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (pixCopiaCola != null &&
                pixCopiaCola!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: copiarPix,
                  icon: const Icon(
                    Icons.copy,
                  ),
                  label: const Text(
                    "Copiar código PIX",
                  ),
                ),
              ),

            const SizedBox(height: 20),

            const Text(
              "Aguardando confirmação do pagamento...",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
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

  const CardPaymentPage({
    super.key,
    required this.endereco,
    required this.itens,
    required this.subtotal,
    required this.restauranteId,
    required this.taxaEntrega,
    required this.taxaServico,
  });

  @override
  State<CardPaymentPage> createState() =>
      _CardPaymentPageState();
}

class _CardPaymentPageState
    extends State<CardPaymentPage> {
  final formKey = GlobalKey<FormState>();

  final nomeController =
      TextEditingController();

  final numeroController =
      TextEditingController();

  final validadeController =
      TextEditingController();

  final cvvController =
      TextEditingController();

  bool carregando = false;

  double get totalPedido {
    return widget.subtotal +
        widget.taxaEntrega +
        widget.taxaServico;
  }

  @override
  void dispose() {
    nomeController.dispose();
    numeroController.dispose();
    validadeController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  Future<String?> obterToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString("token") ??
        prefs.getString("jwt") ??
        prefs.getString("access_token") ??
        prefs.getString("auth_token");
  }

  bool validadeExpirada(String validade) {
    final partes = validade.split("/");

    if (partes.length != 2) {
      return true;
    }

    final mes = int.tryParse(partes[0]);
    final anoDoisDigitos =
        int.tryParse(partes[1]);

    if (mes == null ||
        anoDoisDigitos == null ||
        mes < 1 ||
        mes > 12) {
      return true;
    }

    final ano = 2000 + anoDoisDigitos;

    final agora = DateTime.now();

    final anoAtual = agora.year;
    final mesAtual = agora.month;

    if (ano < anoAtual) {
      return true;
    }

    if (ano == anoAtual &&
        mes < mesAtual) {
      return true;
    }

    return false;
  }

  Future<void> pagar() async {
    if (carregando) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    final numero =
        numeroController.text
            .replaceAll(RegExp(r'\D'), '');

    final cvv =
        cvvController.text
            .replaceAll(RegExp(r'\D'), '');

    final validade =
        validadeController.text.trim();

    if (numero.length < 13 ||
        numero.length > 19) {
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
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final token = await obterToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          "Sessão expirada. Faça login novamente.",
        );
      }

      // IMPORTANTE:
      // O backend espera:
      //
      // cartao.validade = "MM/AA"
      //
      // Não enviar mes/ano separados.
      final body = {
        "valor": totalPedido,
        "total": totalPedido,
        "subtotal": widget.subtotal,
        "taxaEntrega": widget.taxaEntrega,
        "taxaServico": widget.taxaServico,
        "restauranteId": widget.restauranteId,
        "endereco": widget.endereco,
        "itens": prepararItens(),
        "formaPagamento": "CREDITO",
        "pagamento": "CREDITO",

        "cartao": {
          "numero": numero,
          "nome": nomeController.text.trim(),
          "validade": validade,
          "cvv": cvv,
        },
      };

      debugPrint(
        "💳 PAGAMENTO CARTAO: ENVIANDO PARA O BACKEND",
      );

      debugPrint(
        "💳 NOME DO TITULAR: ENVIADO",
      );

      debugPrint(
        "💳 CPF/TELEFONE: NAO ENVIADOS",
      );

      debugPrint(
        "💳 ENDERECO DE COBRANCA: NAO ENVIADO",
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

      final dados =
          jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          dados["sucesso"] != true) {
        throw Exception(
          dados["erro"] ??
              dados["mensagem"] ??
              "Não foi possível processar o pagamento.",
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Pagamento enviado! Aguardando confirmação.",
          ),
        ),
      );

      final pagamentoId =
          dados["pagamentoId"]?.toString();

      if (pagamentoId == null ||
          pagamentoId.isEmpty) {
        return;
      }

      await aguardarPagamento(
        pagamentoId,
        token,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
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

  Future<void> aguardarPagamento(
    String pagamentoId,
    String token,
  ) async {
    for (int i = 0; i < 60; i++) {
      await Future.delayed(
        const Duration(seconds: 3),
      );

      if (!mounted) return;

      try {
        final response = await http.get(
          Uri.parse(
            "${Api.baseUrl}/pagamentos/$pagamentoId",
          ),
          headers: {
            "Authorization":
                "Bearer $token",
          },
        );

        if (response.statusCode < 200 ||
            response.statusCode >= 300) {
          continue;
        }

        final dados =
            jsonDecode(response.body);

        final status =
            dados["statusPagamento"]
                ?.toString()
                .toUpperCase();

        final aprovado =
            dados["pagamentoAprovado"] ==
                true ||
            status == "APPROVED" ||
            status == "RECEIVED" ||
            status == "CONFIRMED";

        if (!aprovado) {
          continue;
        }

        final pedidoId =
            dados["pedidoId"] ??
                dados["orderId"];

        if (pedidoId == null) {
          continue;
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
    OrderTrackingScreen(
  pedidoId: int.parse(pedidoId.toString()),
),
          ),
        );

        return;
      } catch (_) {
        // Continua tentando.
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "O pagamento ainda está sendo processado. Verifique o pedido em alguns instantes.",
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              "Cartão de crédito",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Total: R\$ ${totalPedido.toStringAsFixed(2).replaceAll('.', ',')}",
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

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

            const SizedBox(height: 15),

            // ==================================================
            // NÚMERO
            // ==================================================

            campo(
              controller: numeroController,
              label: "Número do cartão",
              hintText:
                  "Digite o número do cartão",
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
                  return "Número do cartão inválido";
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
                    label: "Validade",
                    hintText: "MM/AA",
                    icon: Icons.calendar_month,
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
                          value?.trim() ?? '';

                      if (!RegExp(
                        r'^\d{2}\/\d{2}$',
                      ).hasMatch(texto)) {
                        return "Use MM/AA";
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
                        return "Mês inválido";
                      }

                      if (validadeExpirada(
                        texto,
                      )) {
                        return "Cartão vencido";
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

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFFF97316),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Informe o nome do titular exatamente como aparece no cartão. CPF, telefone e endereço de cobrança não são necessários nesta etapa.",
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    carregando ? null : pagar,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 17,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: carregando
                    ? const SizedBox(
                        height: 23,
                        width: 23,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Pagar com cartão",
                        style: TextStyle(
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
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget campo({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      obscureText: obscureText,
      textCapitalization:
          textCapitalization,
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
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFF97316),
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
  TextEditingValue formatEditUpdate(
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
            ? digits.substring(0, 19)
            : digits;

    final buffer = StringBuffer();

    for (int i = 0;
        i < limited.length;
        i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }

      buffer.write(limited[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}

// ============================================================
// FORMATADOR DA VALIDADE
// MM/AA
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

    final limited =
        digits.length > 4
            ? digits.substring(0, 4)
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
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}
