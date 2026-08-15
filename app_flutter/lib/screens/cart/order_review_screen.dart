import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api.dart';
import '../orders/order_tracking_screen.dart';
import 'cart_screen.dart';

class OrderReviewScreen extends StatefulWidget {
  final List<CartItem> itens;
  final double subtotal;
  final Map<String, String> endereco;
  final String pagamento;

  const OrderReviewScreen({
    super.key,
    required this.itens,
    required this.subtotal,
    required this.endereco,
    required this.pagamento,
  });

  @override
  State<OrderReviewScreen> createState() =>
      _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  static const Color laranja = Color(0xFFF97316);

  bool enviando = false;

  // ============================================================
  // DADOS ATUAIS
  // ============================================================

  final int clienteId = 1784355543711;

  final int restauranteId = 1784400784535;

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
  // ENDEREÇO COMPLETO
  // ============================================================

  String enderecoCompleto() {
    final complemento =
        widget.endereco['complemento'] ?? '';

    String resultado =
        '${widget.endereco['rua'] ?? ''}, '
        '${widget.endereco['numero'] ?? ''}';

    if (complemento.isNotEmpty) {
      resultado += ' - $complemento';
    }

    resultado +=
        '\n${widget.endereco['bairro'] ?? ''}';

    resultado +=
        '\n${widget.endereco['cidade'] ?? ''} - '
        '${widget.endereco['estado'] ?? ''}';

    return resultado;
  }

  // ============================================================
  // MONTAR ITENS PARA API
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
    if (enviando) {
      return;
    }

    if (widget.itens.isEmpty) {
      _mensagem(
        'Seu carrinho está vazio.',
      );
      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      final itensPedido = _montarItensPedido();

      final pedido = {
        'clienteId': clienteId,
        'restauranteId': restauranteId,
        'itens': itensPedido,
        'endereco': widget.endereco,
        'pagamento': widget.pagamento,
        'subtotal': widget.subtotal,
        'taxaServico': taxaServico,
        'percentualTaxaServico': percentualTaxaServico,
        'taxaEntrega': taxaEntrega,
        'total': totalPedido,
      };

      print(
        '========================================',
      );

      print(
        '📦 ENVIANDO PEDIDO PARA API',
      );

      print(
        '👤 CLIENTE: $clienteId',
      );

      print(
        '🏪 RESTAURANTE: $restauranteId',
      );

      print(
        '🛒 ITENS: $itensPedido',
      );

      print(
        '📍 ENDEREÇO: ${widget.endereco}',
      );

      print(
        '💳 PAGAMENTO: ${widget.pagamento}',
      );

      print(
        '💵 SUBTOTAL: ${widget.subtotal}',
      );

      print(
        '🧾 TAXA SERVIÇO: $taxaServico',
      );

      print(
        '🛵 TAXA ENTREGA: $taxaEntrega',
      );

      print(
        '💰 TOTAL: $totalPedido',
      );

      print(
        '========================================',
      );

      final url = Uri.parse(
        '${Api.baseUrl}/orders',
      );

      print(
        '🌐 URL PEDIDO: $url',
      );

      final resposta = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(pedido),
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      print(
        '📡 STATUS API: ${resposta.statusCode}',
      );

      print(
        '📡 RESPOSTA API: ${resposta.body}',
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // PEDIDO CRIADO
      // ========================================================

      if (resposta.statusCode == 200 ||
          resposta.statusCode == 201) {
        Map<String, dynamic> dados = {};

        try {
          final resultado = jsonDecode(
            resposta.body,
          );

          if (resultado is Map<String, dynamic>) {
            dados = resultado;
          }
        } catch (e) {
          print(
            'ERRO AO LER RESPOSTA DO PEDIDO: $e',
          );
        }

        final pedidoCriado = dados['pedido'];

        if (pedidoCriado is! Map<String, dynamic>) {
          _mensagem(
            'Pedido criado, mas a API não retornou os dados do pedido.',
            erro: true,
          );

          return;
        }

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

        print(
          '🆔 ID DO PEDIDO: $pedidoId',
        );

        // ======================================================
        // ABRIR ACOMPANHAMENTO
        // ======================================================

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderTrackingScreen(
              pedidoId: pedidoId,
            ),
          ),
        );
      } else {
        Map<String, dynamic> erro = {};

        try {
          final resultado = jsonDecode(
            resposta.body,
          );

          if (resultado is Map<String, dynamic>) {
            erro = resultado;
          }
        } catch (_) {}

        final mensagem =
            erro['erro']?.toString() ??
            erro['mensagem']?.toString() ??
            'Não foi possível criar o pedido.';

        _mensagem(
          mensagem,
          erro: true,
        );
      }
    } catch (erro) {
      print(
        '❌ ERRO AO ENVIAR PEDIDO: $erro',
      );

      if (!mounted) {
        return;
      }

      _mensagem(
        'Não foi possível criar o pedido: $erro',
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
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          texto,
        ),
        backgroundColor:
            erro ? Colors.red : laranja,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(
          seconds: 3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
        ),
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
      backgroundColor: const Color(
        0xFFF5F5F5,
      ),
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
        padding: const EdgeInsets.all(
          20,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Confira seu pedido',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // =====================================================
            // ITENS DO PEDIDO
            // =====================================================

            const Text(
              'Itens do pedido',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child: Column(
                children: widget.itens.map((item) {
                  final subtotalItem =
                      item.preco *
                          item.quantidade;

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 14,
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
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.black,
                                  fontSize:
                                      16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                '${item.quantidade}x ${formatarPreco(item.preco)}',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.black54,
                                  fontSize:
                                      14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatarPreco(
                            subtotalItem,
                          ),
                          style:
                              const TextStyle(
                            color:
                                Colors.black,
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // =====================================================
            // ENDEREÇO
            // =====================================================

            const Text(
              'Endereço de entrega',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: laranja,
                    size: 26,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Text(
                      enderecoCompleto(),
                      style:
                          const TextStyle(
                        color:
                            Colors.black87,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // =====================================================
            // PAGAMENTO
            // =====================================================

            const Text(
              'Forma de pagamento',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payment,
                    color: laranja,
                    size: 26,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    widget.pagamento,
                    style:
                        const TextStyle(
                      color:
                          Colors.black,
                      fontSize:
                          16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // =====================================================
            // VALORES
            // =====================================================

            const Text(
              'Resumo dos valores',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  16,
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
                        'Subtotal',
                        style:
                            TextStyle(
                          color:
                              Colors.black87,
                          fontSize:
                              15,
                        ),
                      ),
                      Text(
                        formatarPreco(
                          widget.subtotal,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.black87,
                          fontSize:
                              15,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        'Taxa de serviço',
                        style:
                            TextStyle(
                          color:
                              Colors.black87,
                          fontSize:
                              15,
                        ),
                      ),
                      Text(
                        formatarPreco(
                          taxaServico,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.black87,
                          fontSize:
                              15,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        'Taxa de entrega',
                        style:
                            TextStyle(
                          color:
                              Colors.black87,
                          fontSize:
                              15,
                        ),
                      ),
                      Text(
                        formatarPreco(
                          taxaEntrega,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.black87,
                          fontSize:
                              15,
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: Divider(),
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style:
                            TextStyle(
                          color:
                              Colors.black,
                          fontSize:
                              20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatarPreco(
                          totalPedido,
                        ),
                        style:
                            const TextStyle(
                          color:
                              laranja,
                          fontSize:
                              20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // =====================================================
            // BOTÃO CONFIRMAR PEDIDO
            // =====================================================

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    enviando
                        ? null
                        : confirmarPedido,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      laranja,
                  foregroundColor:
                      Colors.white,
                  disabledBackgroundColor:
                      Colors.grey.shade400,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  elevation: 0,
                ),
                child:
                    enviando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<
                                      Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Confirmar Pedido',
                            style:
                                TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}