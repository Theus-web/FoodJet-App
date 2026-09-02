
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';
import 'payment_screen.dart';

class OrderReviewScreen extends StatefulWidget {
  final List<CartItem> itens;
  final double subtotal;
  final Map<String, String> endereco;
  final String restauranteId;
  final String pagamento;

  const OrderReviewScreen({
    super.key,
    required this.itens,
    required this.subtotal,
    required this.endereco,
    required this.restauranteId,
    this.pagamento = "PIX",
  });

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF6F7F9);

  final double taxaEntrega = 5.0;
  final double percentualTaxaServico = 0.15;

  late String formaPagamento;

  bool precisaTroco = false;
  bool enviandoPedido = false;

  final TextEditingController trocoController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    formaPagamento = widget.pagamento.trim().toUpperCase();

    if (![
      "PIX",
      "CREDITO",
      "DEBITO",
      "DINHEIRO",
    ].contains(formaPagamento)) {
      formaPagamento = "PIX";
    }
  }

  @override
  void dispose() {
    trocoController.dispose();
    super.dispose();
  }

  // ============================================================
  // VALORES
  // ============================================================

  double get taxaServico {
    return widget.subtotal * percentualTaxaServico;
  }

  double get totalPedido {
    return widget.subtotal + taxaServico + taxaEntrega;
  }

  String dinheiro(double valor) {
    return "R\$ ${valor.toStringAsFixed(2).replaceAll(".", ",")}";
  }

  // ============================================================
  // TROCO
  // ============================================================

  double? get valorTrocoPara {
    if (!precisaTroco) {
      return null;
    }

    String valor = trocoController.text.trim();

    if (valor.isEmpty) {
      return null;
    }

    valor = valor.replaceAll("R\$", "").trim();

    if (valor.contains(",") && valor.contains(".")) {
      valor = valor.replaceAll(".", "");
      valor = valor.replaceAll(",", ".");
    } else if (valor.contains(",")) {
      valor = valor.replaceAll(",", ".");
    }

    return double.tryParse(valor);
  }

  bool validarTroco() {
    if (formaPagamento != "DINHEIRO") {
      return true;
    }

    if (!precisaTroco) {
      return true;
    }

    final valor = valorTrocoPara;

    if (valor == null) {
      mostrarMensagem(
        "Informe o valor para o qual precisa de troco.",
        erro: true,
      );
      return false;
    }

    if (valor < totalPedido) {
      mostrarMensagem(
        "O valor informado deve ser maior ou igual ao total do pedido.",
        erro: true,
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // ENDEREÇO
  // ============================================================

  String enderecoCompleto() {
    return [
      "${widget.endereco["rua"] ?? ""}, ${widget.endereco["numero"] ?? ""}",
      widget.endereco["complemento"] ?? "",
      widget.endereco["bairro"] ?? "",
      "${widget.endereco["cidade"] ?? ""} - ${widget.endereco["estado"] ?? ""}",
      widget.endereco["cep"] ?? "",
    ].where((e) => e.trim().isNotEmpty).join("\n");
  }

  Future<void> criarPedidoParaCartao() async {
  final dados = await criarPedido();

  if (dados == null) {
    return;
  }

  final pedidoId = extrairPedidoId(dados);

  if (pedidoId == null) {
    mostrarMensagem(
      "Pedido criado, mas o ID não foi retornado.",
      erro: true,
    );
    return;
  }

  final pedidoIdString =
      pedidoId.toString().trim();

  if (!mounted) {
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PaymentScreen(
        endereco: widget.endereco,
        itens: widget.itens,
        subtotal: widget.subtotal,
        restauranteId: widget.restauranteId,
        taxaEntrega: taxaEntrega,
        taxaServico: taxaServico,
        formaPagamento: "CREDITO",
        pedidoId: pedidoIdString,
      ),
    ),
  );
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
  // CRIAR PEDIDO
  //
  // IMPORTANTE:
  // O backend FoodJet usa:
  //
  // POST /api/orders
  //
  // NÃO:
  // /api/pedidos
  // ============================================================

  Future<Map<String, dynamic>?> criarPedido() async {
    final token = await obterToken();

    if (token.isEmpty) {
      mostrarMensagem(
        "Sessão expirada. Faça login novamente.",
        erro: true,
      );
      return null;
    }

    final url = Uri.parse(
      "${Api.baseUrl}/orders",
    );

    final valorTroco = formaPagamento == "DINHEIRO"
        ? valorTrocoPara
        : null;

    final body = {
      "restauranteId": widget.restauranteId,
      "itens": prepararItens(),
      "endereco": widget.endereco,
      "pagamento": formaPagamento,
      "subtotal": widget.subtotal,
      "taxaServico": taxaServico,
      "taxaEntrega": taxaEntrega,
      "total": totalPedido,
      "precisaTroco":
          formaPagamento == "DINHEIRO"
              ? precisaTroco
              : false,
      "trocoPara": valorTroco,
      "valorTroco":
          valorTroco != null
              ? valorTroco - totalPedido
              : 0,
    };

    debugPrint("");
    debugPrint("========================================");
    debugPrint("📦 FOODJET - CRIAR PEDIDO");
    debugPrint("========================================");
    debugPrint("POST: $url");
    debugPrint("RESTAURANTE: ${widget.restauranteId}");
    debugPrint("PAGAMENTO: $formaPagamento");
    debugPrint("SUBTOTAL: ${widget.subtotal}");
    debugPrint("TAXA SERVIÇO: $taxaServico");
    debugPrint("TAXA ENTREGA: $taxaEntrega");
    debugPrint("TOTAL: $totalPedido");
    debugPrint("BODY:");
    debugPrint(jsonEncode(body));
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

      debugPrint("");
      debugPrint("========================================");
      debugPrint("📥 RESPOSTA DO BACKEND");
      debugPrint("========================================");
      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");
      debugPrint("========================================");

      Map<String, dynamic> dados = {};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          dados = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint(
          "⚠️ Backend não retornou JSON: $e",
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final erro =
            dados["erro"] ??
            dados["mensagem"] ??
            dados["message"] ??
            "Não foi possível criar o pedido.";

        mostrarMensagem(
          erro.toString(),
          erro: true,
        );

        return null;
      }

      // Aceita sucesso=true quando o controller retorna isso.
      // Também aceita uma resposta contendo pedido/pedidoId,
      // evitando falso erro caso o backend não envie sucesso.
      final sucessoExplicito =
          dados["sucesso"] == true;

      final possuiPedido =
          dados["pedido"] != null ||
          dados["pedidoId"] != null;

      if (!sucessoExplicito && !possuiPedido) {
        final erro =
            dados["erro"] ??
            dados["mensagem"] ??
            dados["message"] ??
            "Não foi possível criar o pedido.";

        mostrarMensagem(
          erro.toString(),
          erro: true,
        );

        return null;
      }

      return dados;
    } catch (e) {
      debugPrint("");
      debugPrint("========================================");
      debugPrint("❌ ERRO AO CRIAR PEDIDO");
      debugPrint("========================================");
      debugPrint("$e");
      debugPrint("========================================");

      mostrarMensagem(
        "Erro ao conectar com o servidor.",
        erro: true,
      );

      return null;
    }
  }

  // ============================================================
  // PEGAR ID
  // ============================================================

  dynamic extrairPedidoId(
    Map<String, dynamic> dados,
  ) {
    final pedido = dados["pedido"];

    if (pedido is Map) {
      final id = pedido["id"];

      if (id != null) {
        return id;
      }

      final pedidoId = pedido["_id"];

      if (pedidoId != null) {
        return pedidoId;
      }
    }

    if (dados["pedidoId"] != null) {
      return dados["pedidoId"];
    }

    if (dados["id"] != null) {
      return dados["id"];
    }

    return null;
  }

  // ============================================================
  // FLUXO PIX
  // ============================================================

  Future<void> criarPedidoParaPix() async {
    final dados = await criarPedido();

    if (dados == null) {
      return;
    }

    final pedidoId = extrairPedidoId(dados);

    if (pedidoId == null) {
      debugPrint(
        "❌ Pedido criado, mas ID não encontrado.",
      );

      mostrarMensagem(
        "O pedido foi criado, mas o servidor não retornou o ID.",
        erro: true,
      );

      return;
    }

    final pedidoIdString =
        pedidoId.toString().trim();

    debugPrint("");
    debugPrint("========================================");
    debugPrint("✅ PEDIDO CRIADO");
    debugPrint("🆔 ID: $pedidoIdString");
    debugPrint("========================================");

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          endereco: widget.endereco,
          itens: widget.itens,
          subtotal: widget.subtotal,
          restauranteId: widget.restauranteId,
          taxaEntrega: taxaEntrega,
          taxaServico: taxaServico,
          formaPagamento: "PIX",
          pedidoId: pedidoIdString,
        ),
      ),
    );
  }

  // ============================================================
  // FLUXO PAGAMENTO LOCAL
  // ============================================================

  Future<void> criarPedidoPagamentoLocal() async {
    final dados = await criarPedido();

    if (dados == null) {
      return;
    }

    final pedidoId = extrairPedidoId(dados);

    if (pedidoId == null) {
      mostrarMensagem(
        "Pedido criado, mas o ID não foi retornado.",
        erro: true,
      );
      return;
    }

    if (!mounted) {
      return;
    }

    String mensagem;

    if (formaPagamento == "DINHEIRO") {
      mensagem =
          "Pedido confirmado! Pagamento em dinheiro na entrega.";
    } else if (formaPagamento == "DEBITO") {
      mensagem =
          "Pedido confirmado! Pagamento no cartão de débito na entrega.";
    } else {
      mensagem = "Pedido confirmado!";
    }

    mostrarMensagem(mensagem);

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(
          pedidoId:
              int.tryParse(
                    pedidoId.toString(),
                  ) ??
                  0,
        ),
      ),
    );
  }

  // ============================================================
  // IR PARA PAGAMENTO
  // ============================================================

  Future<void> _irParaPagamento() async {
    if (enviandoPedido) {
      return;
    }

    if (widget.itens.isEmpty) {
      mostrarMensagem(
        "Seu carrinho está vazio.",
        erro: true,
      );
      return;
    }

    if (widget.restauranteId.trim().isEmpty) {
      mostrarMensagem(
        "Restaurante não identificado.",
        erro: true,
      );
      return;
    }

    if (totalPedido <= 0) {
      mostrarMensagem(
        "O valor do pedido é inválido.",
        erro: true,
      );
      return;
    }

    if (!validarTroco()) {
      return;
    }

    setState(() {
      enviandoPedido = true;
    });

    try {
      // ========================================================
      // PIX
      // ========================================================

      if (formaPagamento == "PIX") {
        await criarPedidoParaPix();
        return;
      }

      // ========================================================
      // DÉBITO
      // ========================================================

      if (formaPagamento == "DEBITO") {
        await criarPedidoPagamentoLocal();
        return;
      }

      // ========================================================
      // DINHEIRO
      // ========================================================

      if (formaPagamento == "DINHEIRO") {
        await criarPedidoPagamentoLocal();
        return;
      }

      // ========================================================
      // CRÉDITO
      // ========================================================

      if (formaPagamento == "CREDITO") {
  await criarPedidoParaCartao();
  return;
}

      mostrarMensagem(
        "Forma de pagamento inválida.",
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          enviandoPedido = false;
        });
      }
    }
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget cardPadrao(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 18),
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

  Widget titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // ITEM
  // ============================================================

  Widget itemPedido(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8D8),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              "${item.quantidade}x",
              style: const TextStyle(
                color: laranja,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dinheiro(item.preco),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            dinheiro(
              item.preco * item.quantidade,
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ENDEREÇO
  // ============================================================

  Widget enderecoEntrega() {
    return cardPadrao(
      Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8D8),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: laranja,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "Endereço de entrega",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  enderecoCompleto(),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OPÇÃO PAGAMENTO
  // ============================================================

  Widget opcaoPagamento({
    required String valor,
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
  }) {
    final selecionado =
        formaPagamento == valor;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          formaPagamento = valor;

          if (formaPagamento != "DINHEIRO") {
            precisaTroco = false;
            trocoController.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: selecionado
              ? laranja.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    cor.withValues(alpha: 0.10),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                icone,
                color: cor,
              ),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: valor,
              groupValue: formaPagamento,
              activeColor: laranja,
              onChanged: (v) {
                if (v == null) return;

                setState(() {
                  formaPagamento = v;

                  if (formaPagamento !=
                      "DINHEIRO") {
                    precisaTroco = false;
                    trocoController.clear();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAGAMENTOS
  // ============================================================

  Widget pagamentos() {
    return cardPadrao(
      Column(
        children: [
          opcaoPagamento(
            valor: "PIX",
            titulo: "Pix",
            subtitulo:
                "Pagamento instantâneo",
            icone: Icons.pix,
            cor: const Color(0xFF00A884),
          ),

          const Divider(),

          opcaoPagamento(
            valor: "CREDITO",
            titulo: "Cartão de Crédito",
            subtitulo:
                "Pagamento seguro pelo Asaas",
            icone: Icons.credit_card,
            cor: Colors.blue,
          ),

          const Divider(),

          opcaoPagamento(
            valor: "DEBITO",
            titulo: "Cartão de Débito",
            subtitulo:
                "Pagamento na entrega",
            icone:
                Icons.credit_card_outlined,
            cor: Colors.indigo,
          ),

          const Divider(),

          opcaoPagamento(
            valor: "DINHEIRO",
            titulo: "Dinheiro",
            subtitulo:
                "Pague quando receber o pedido",
            icone:
                Icons.payments_outlined,
            cor: laranja,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TROCO
  // ============================================================

  Widget opcaoTroco() {
    if (formaPagamento != "DINHEIRO") {
      return const SizedBox.shrink();
    }

    return cardPadrao(
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Precisa de troco?",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Informe se precisa que o entregador leve troco.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      precisaTroco = false;
                      trocoController.clear();
                    });
                  },
                  borderRadius:
                      BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: !precisaTroco
                          ? laranja.withValues(
                              alpha: 0.08,
                            )
                          : Colors.grey.shade50,
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: !precisaTroco
                            ? laranja
                            : Colors.black12,
                        width:
                            !precisaTroco ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          !precisaTroco
                              ? Icons
                                  .radio_button_checked
                              : Icons
                                  .radio_button_off,
                          color: !precisaTroco
                              ? laranja
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Não",
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      precisaTroco = true;
                    });
                  },
                  borderRadius:
                      BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: precisaTroco
                          ? laranja.withValues(
                              alpha: 0.08,
                            )
                          : Colors.grey.shade50,
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: precisaTroco
                            ? laranja
                            : Colors.black12,
                        width:
                            precisaTroco ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          precisaTroco
                              ? Icons
                                  .radio_button_checked
                              : Icons
                                  .radio_button_off,
                          color: precisaTroco
                              ? laranja
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Sim",
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (precisaTroco) ...[
            const SizedBox(height: 16),
            TextField(
              controller: trocoController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: "Troco para quanto?",
                hintText: "Ex.: 50,00",
                prefixText: "R\$ ",
                prefixIcon: const Icon(
                  Icons.payments_outlined,
                  color: laranja,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(
                    color: Colors.black12,
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(
                    color: laranja,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Total do pedido: ${dinheiro(totalPedido)}",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
            if (valorTrocoPara != null &&
                valorTrocoPara! >= totalPedido) ...[
              const SizedBox(height: 5),
              Text(
                "Troco: ${dinheiro(valorTrocoPara! - totalPedido)}",
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ============================================================
  // RESUMO
  // ============================================================

  Widget linhaResumo(
    String titulo,
    double valor, {
    bool destaque = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: destaque ? 15 : 13,
            fontWeight: destaque
                ? FontWeight.bold
                : FontWeight.w500,
          ),
        ),
        Text(
          dinheiro(valor),
          style: TextStyle(
            color: destaque
                ? laranja
                : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: destaque ? 18 : 13,
          ),
        ),
      ],
    );
  }

  Widget resumoPedido() {
    return cardPadrao(
      Column(
        children: [
          linhaResumo(
            "Subtotal dos produtos",
            widget.subtotal,
          ),
          const SizedBox(height: 12),
          linhaResumo(
            "Taxa de serviço",
            taxaServico,
          ),
          const SizedBox(height: 12),
          linhaResumo(
            "Taxa de entrega",
            taxaEntrega,
          ),
          const Padding(
            padding:
                EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          linhaResumo(
            "Total do pedido",
            totalPedido,
            destaque: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEGURANÇA
  // ============================================================

  Widget seguranca() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF5),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFD8F1E1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Colors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Pagamento seguro. Seus dados são protegidos durante toda a transação.",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
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
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final pagamentoLocal =
        formaPagamento == "DINHEIRO" ||
        formaPagamento == "DEBITO";

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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  25,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Confira seu pedido",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Revise os detalhes antes de realizar o pagamento.",
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 22),
                    titulo("Itens do pedido"),
                    cardPadrao(
                      Column(
                        children: [
                          for (final item
                              in widget.itens)
                            itemPedido(item),
                        ],
                      ),
                    ),
                    titulo("Endereço de entrega"),
                    enderecoEntrega(),
                    titulo("Forma de pagamento"),
                    pagamentos(),
                    opcaoTroco(),
                    titulo("Resumo do pedido"),
                    resumoPedido(),
                    seguranca(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                13,
                18,
                18,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 18,
                    offset:
                        const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          "Total a pagar",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Colors.black54,
                          ),
                        ),
                        Text(
                          dinheiro(totalPedido),
                          style:
                              const TextStyle(
                            fontSize: 21,
                            fontWeight:
                                FontWeight.w900,
                            color: laranja,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            enviandoPedido
                                ? null
                                : _irParaPagamento,
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
                                BorderRadius
                                    .circular(16),
                          ),
                        ),
                        child: enviandoPedido
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    pagamentoLocal
                                        ? Icons
                                            .check_circle_outline
                                        : Icons
                                            .lock_outline,
                                    size: 20,
                                  ),
                                  const SizedBox(
                                    width: 9,
                                  ),
                                  Text(
                                    formaPagamento ==
                                            "PIX"
                                        ? "PAGAR COM PIX"
                                        : formaPagamento ==
                                                "CREDITO"
                                            ? "PAGAR COM CARTÃO"
                                            : "CONFIRMAR PEDIDO",
                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 9),
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
                          "Ambiente 100% seguro",
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
