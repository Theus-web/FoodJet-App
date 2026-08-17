import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';

class OrderReviewScreen extends StatefulWidget {
  final List<CartItem> itens;
  final double subtotal;
  final Map<String, String> endereco;
  final String pagamento;
  final String restauranteId;

  const OrderReviewScreen({
    super.key,
    required this.itens,
    required this.subtotal,
    required this.endereco,
    required this.pagamento,
    required this.restauranteId,
  });

  @override
  State<OrderReviewScreen> createState() =>
      _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF5F5F5);

  bool enviando = false;

  // ============================================================
  // CLIENTE
  // ============================================================

  // Temporário conforme sua estrutura atual.
  // Depois podemos pegar automaticamente do usuário logado.
  final int clienteId = 1784355543711;

  // ============================================================
  // TAXAS
  // ============================================================

  final double taxaEntrega = 6.50;

  final double percentualTaxaServico = 0.10;

  double get taxaServico {
    return widget.subtotal * percentualTaxaServico;
  }

  double get totalPedido {
    return widget.subtotal + taxaServico + taxaEntrega;
  }

  // ============================================================
  // FORMATAR PREÇO
  // ============================================================

  String formatarPreco(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // ENDEREÇO
  // ============================================================

  String enderecoCompleto() {
    final rua = widget.endereco['rua'] ?? '';
    final numero = widget.endereco['numero'] ?? '';
    final complemento = widget.endereco['complemento'] ?? '';
    final bairro = widget.endereco['bairro'] ?? '';
    final cidade = widget.endereco['cidade'] ?? '';
    final estado = widget.endereco['estado'] ?? '';

    String resultado = '$rua, $numero';

    if (complemento.isNotEmpty) {
      resultado += ' - $complemento';
    }

    if (bairro.isNotEmpty) {
      resultado += '\n$bairro';
    }

    if (cidade.isNotEmpty || estado.isNotEmpty) {
      resultado += '\n$cidade - $estado';
    }

    return resultado;
  }

  // ============================================================
  // MONTAR ITENS
  // ============================================================

  List<Map<String, dynamic>> _montarItensPedido() {
    return widget.itens.map((item) {
      return {
        'produtoId': item.produtoId,
        'nome': item.nome,
        'preco': item.preco,
        'quantidade': item.quantidade,
        'subtotal': item.preco * item.quantidade,
      };
    }).toList();
  }

  // ============================================================
  // CONFIRMAR PEDIDO
  // ============================================================

  Future<void> confirmarPedido() async {
    if (enviando) return;

    FocusScope.of(context).unfocus();

    if (widget.itens.isEmpty) {
      _mensagem(
        'Seu carrinho está vazio.',
        erro: true,
      );
      return;
    }

    if (widget.restauranteId.isEmpty) {
      _mensagem(
        'Restaurante não identificado.',
        erro: true,
      );
      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      final itensPedido = _montarItensPedido();

      // ========================================================
      // PEDIDO
      // ========================================================

      final pedido = {
        'clienteId': clienteId,
        'restauranteId': widget.restauranteId,
        'itens': itensPedido,
        'endereco': widget.endereco,
        'pagamento': widget.pagamento,
        'subtotal': widget.subtotal,
        'taxaServico': taxaServico,
        'percentualTaxaServico': percentualTaxaServico,
        'taxaEntrega': taxaEntrega,
        'total': totalPedido,
      };

      debugPrint('========================================');
      debugPrint('📦 ENVIANDO PEDIDO PARA API');
      debugPrint('👤 CLIENTE: $clienteId');
      debugPrint(
        '🏪 RESTAURANTE: ${widget.restauranteId}',
      );
      debugPrint('🛒 ITENS: $itensPedido');
      debugPrint(
        '📍 ENDEREÇO: ${widget.endereco}',
      );
      debugPrint(
        '💳 PAGAMENTO: ${widget.pagamento}',
      );
      debugPrint(
        '💵 SUBTOTAL: ${widget.subtotal}',
      );
      debugPrint(
        '🧾 TAXA SERVIÇO: $taxaServico',
      );
      debugPrint(
        '🛵 TAXA ENTREGA: $taxaEntrega',
      );
      debugPrint(
        '💰 TOTAL: $totalPedido',
      );
      debugPrint('========================================');

      // ========================================================
      // URL
      // ========================================================

      final url = Uri.parse(
        '${Api.baseUrl}/orders',
      );

      debugPrint('🌐 URL PEDIDO: $url');

      // ========================================================
      // POST
      // ========================================================

      final resposta = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(pedido),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        '📡 STATUS API: ${resposta.statusCode}',
      );

      debugPrint(
        '📡 RESPOSTA API: ${resposta.body}',
      );

      if (!mounted) return;

      // ========================================================
      // SUCESSO
      // ========================================================

      if (resposta.statusCode == 200 ||
          resposta.statusCode == 201) {
        Map<String, dynamic> dados = {};

        try {
          final resultado = jsonDecode(resposta.body);

          if (resultado is Map<String, dynamic>) {
            dados = resultado;
          }
        } catch (e) {
          debugPrint(
            '⚠️ ERRO AO DECODIFICAR RESPOSTA: $e',
          );
        }

        // ======================================================
        // LOCALIZAR PEDIDO CRIADO
        // ======================================================

        dynamic pedidoCriado = dados['pedido'];

        // Caso a API retorne diretamente:
        // { id: 123, ... }
        if (pedidoCriado == null &&
            dados['id'] != null) {
          pedidoCriado = dados;
        }

        if (pedidoCriado is! Map<String, dynamic>) {
          _mensagem(
            'Pedido criado, mas a API não retornou os dados do pedido.',
            erro: true,
          );
          return;
        }

        // ======================================================
        // ID DO PEDIDO
        // ======================================================

        final idRecebido = pedidoCriado['id'];

        if (idRecebido == null) {
          _mensagem(
            'Pedido criado, mas não recebemos o ID do pedido.',
            erro: true,
          );
          return;
        }

        final pedidoId = int.tryParse(
          idRecebido.toString(),
        );

        if (pedidoId == null) {
          _mensagem(
            'O ID do pedido retornado pela API é inválido.',
            erro: true,
          );
          return;
        }

        debugPrint(
          '========================================',
        );

        debugPrint(
          '✅ PEDIDO CRIADO COM SUCESSO',
        );

        debugPrint(
          '🆔 PEDIDO ID: $pedidoId',
        );

        debugPrint(
          '🏪 RESTAURANTE: ${widget.restauranteId}',
        );

        debugPrint(
          '💳 PAGAMENTO: ${widget.pagamento}',
        );

        debugPrint(
          '========================================',
        );

        // ======================================================
        // ABRIR ACOMPANHAMENTO DO PEDIDO
        // ======================================================

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderTrackingScreen(
              pedidoId: pedidoId,
            ),
          ),
        );

        return;
      }

      // ========================================================
      // ERRO DA API
      // ========================================================

      Map<String, dynamic> erro = {};

      try {
        final resultado = jsonDecode(resposta.body);

        if (resultado is Map<String, dynamic>) {
          erro = resultado;
        }
      } catch (_) {}

      final mensagem =
          erro['erro']?.toString() ??
          erro['mensagem']?.toString() ??
          erro['error']?.toString() ??
          'Não foi possível criar o pedido.';

      _mensagem(
        mensagem,
        erro: true,
      );
    } catch (erro) {
      debugPrint(
        '❌ ERRO AO ENVIAR PEDIDO: $erro',
      );

      if (!mounted) return;

      _mensagem(
        'Não foi possível criar o pedido. Verifique sua conexão.',
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
        });
      }
    }
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

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
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: child,
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
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Revisar Pedido',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Confira seu pedido',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ITENS
            // ==================================================

            const Text(
              'Itens do pedido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _card(
              child: Column(
                children: List.generate(
                  widget.itens.length,
                  (index) {
                    final item = widget.itens[index];

                    final subtotalItem =
                        item.preco * item.quantidade;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            index == widget.itens.length - 1
                                ? 0
                                : 14,
                      ),

                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                Text(
                                  item.nome,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  '${item.quantidade}x ${formatarPreco(item.preco)}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Text(
                            formatarPreco(subtotalItem),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ENDEREÇO
            // ==================================================

            const Text(
              'Endereço de entrega',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _card(
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Container(
                    width: 42,
                    height: 42,

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8D8),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),

                    child: const Icon(
                      Icons.location_on,
                      color: laranja,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      enderecoCompleto(),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // PAGAMENTO
            // ==================================================

            const Text(
              'Forma de pagamento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _card(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8D8),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),

                    child: const Icon(
                      Icons.payment,
                      color: laranja,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      widget.pagamento,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // RESUMO
            // ==================================================

            const Text(
              'Resumo dos valores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _card(
              child: Column(
                children: [
                  _linhaValor(
                    'Subtotal',
                    widget.subtotal,
                  ),

                  const SizedBox(height: 10),

                  _linhaValor(
                    'Taxa de serviço',
                    taxaServico,
                  ),

                  const SizedBox(height: 10),

                  _linhaValor(
                    'Taxa de entrega',
                    taxaEntrega,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: Divider(),
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,

                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        formatarPreco(totalPedido),
                        style: const TextStyle(
                          color: laranja,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // BOTÃO
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 56,

              child: ElevatedButton(
                onPressed:
                    enviando ? null : confirmarPedido,

                style: ElevatedButton.styleFrom(
                  backgroundColor: laranja,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.grey.shade400,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),

                child: enviando
                    ? const SizedBox(
                        width: 25,
                        height: 25,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 3,

                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )

                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [
                          Icon(
                            Icons.check_circle_outline,
                          ),

                          SizedBox(width: 8),

                          Text(
                            'CONFIRMAR PEDIDO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
    );
  }

  // ============================================================
  // LINHA VALOR
  // ============================================================

  Widget _linhaValor(
    String titulo,
    double valor,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
          ),
        ),

        Text(
          formatarPreco(valor),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}