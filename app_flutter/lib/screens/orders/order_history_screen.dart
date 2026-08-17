import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final Map<String, dynamic>? usuario;

  const OrderHistoryScreen({
    super.key,
    this.usuario,
  });

  @override
  State<OrderHistoryScreen> createState() =>
      _OrderHistoryScreenState();
}

class _OrderHistoryScreenState
    extends State<OrderHistoryScreen> {
  static const Color laranja =
      Color(0xFFF97316);

  List<dynamic> pedidos = [];

  bool carregando = true;

  String? erro;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    buscarPedidos();

    timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        buscarPedidos(
          mostrarCarregamento: false,
        );
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // ID DO CLIENTE LOGADO
  // ============================================================

  String _obterClienteId() {
    final usuario = widget.usuario;

    if (usuario == null) {
      return '';
    }

    final id =
        usuario['id'] ??
        usuario['clienteId'] ??
        usuario['_id'] ??
        usuario['usuarioId'];

    if (id == null) {
      return '';
    }

    return id.toString().trim();
  }

  // ============================================================
  // BUSCAR PEDIDOS
  // ============================================================

  Future<void> buscarPedidos({
    bool mostrarCarregamento = true,
  }) async {
    if (mounted && mostrarCarregamento) {
      setState(() {
        carregando = true;
        erro = null;
      });
    }

    try {
      final clienteId =
          _obterClienteId();

      debugPrint(
        '====================================',
      );

      debugPrint(
        'FOODJET - HISTÓRICO DE PEDIDOS',
      );

      debugPrint(
        'CLIENTE LOGADO: $clienteId',
      );

      debugPrint(
        '====================================',
      );

      // ----------------------------------------------------------
      // SEM CLIENTE LOGADO
      // ----------------------------------------------------------

      if (clienteId.isEmpty) {
        if (!mounted) return;

        setState(() {
          pedidos = [];
          carregando = false;
        });

        debugPrint(
          'Nenhum cliente identificado.',
        );

        return;
      }

      final resposta = await http
          .get(
            Uri.parse(
              '${Api.baseUrl}/orders',
            ),
            headers: {
              'Content-Type':
                  'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        'STATUS PEDIDOS: ${resposta.statusCode}',
      );

      if (resposta.statusCode < 200 ||
          resposta.statusCode >= 300) {
        throw Exception(
          'Erro HTTP ${resposta.statusCode}',
        );
      }

      final dados =
          jsonDecode(resposta.body);

      List<dynamic> listaPedidos;

      // ----------------------------------------------------------
      // API PODE RETORNAR LISTA DIRETA
      // ----------------------------------------------------------

      if (dados is List) {
        listaPedidos = dados;
      }

      // ----------------------------------------------------------
      // OU { pedidos: [...] }
      // ----------------------------------------------------------

      else if (
          dados is Map &&
          dados['pedidos'] is List) {
        listaPedidos =
            dados['pedidos'];
      }

      // ----------------------------------------------------------
      // OU { orders: [...] }
      // ----------------------------------------------------------

      else if (
          dados is Map &&
          dados['orders'] is List) {
        listaPedidos =
            dados['orders'];
      }

      else {
        throw Exception(
          'Formato de pedidos inválido.',
        );
      }

      // ==========================================================
      // FILTRAR SOMENTE PEDIDOS DO CLIENTE LOGADO
      // ==========================================================

      final pedidosCliente =
          listaPedidos.where(
        (pedido) {
          if (pedido is! Map) {
            return false;
          }

          final idPedidoCliente =
              pedido['clienteId'] ??
              pedido['cliente_id'] ??
              pedido['clientId'];

          if (idPedidoCliente == null) {
            return false;
          }

          return idPedidoCliente
                  .toString()
                  .trim() ==
              clienteId;
        },
      ).toList();

      // ==========================================================
      // ORDENAR DO MAIS NOVO PARA O MAIS ANTIGO
      // ==========================================================

      pedidosCliente.sort(
        (a, b) {
          final idA =
              int.tryParse(
                    a['id']
                        ?.toString() ??
                        '',
                  ) ??
                  0;

          final idB =
              int.tryParse(
                    b['id']
                        ?.toString() ??
                        '',
                  ) ??
                  0;

          return idB.compareTo(idA);
        },
      );

      debugPrint(
        'TOTAL PEDIDOS NA API: '
        '${listaPedidos.length}',
      );

      debugPrint(
        'TOTAL PEDIDOS DO CLIENTE: '
        '${pedidosCliente.length}',
      );

      if (!mounted) return;

      setState(() {
        pedidos = pedidosCliente;
        carregando = false;
        erro = null;
      });
    } catch (e) {
      debugPrint(
        '❌ ERRO AO BUSCAR HISTÓRICO: $e',
      );

      if (!mounted) return;

      setState(() {
        carregando = false;
        erro =
            'Não foi possível carregar seus pedidos.';
      });
    }
  }

  // ============================================================
  // PREÇO
  // ============================================================

  String formatarPreco(
    dynamic valor,
  ) {
    final numero =
        double.tryParse(
              valor
                      ?.toString()
                      .replaceAll(',', '.') ??
                  '',
            ) ??
            0;

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // STATUS
  // ============================================================

  String tituloStatus(
    String status,
  ) {
    switch (status.toUpperCase()) {
      case 'AGUARDANDO':
      case 'AGUARDANDO_RESTAURANTE':
        return 'Aguardando restaurante';

      case 'ACEITO':
        return 'Pedido aceito';

      case 'PREPARANDO':
        return 'Preparando pedido';

      case 'PRONTO':
        return 'Pedido pronto';

      case 'EM_ENTREGA':
        return 'Em entrega';

      case 'ENTREGUE':
        return 'Pedido entregue';

      case 'CANCELADO':
        return 'Pedido cancelado';

      default:
        return status;
    }
  }

  Color corStatus(
    String status,
  ) {
    switch (status.toUpperCase()) {
      case 'ENTREGUE':
        return Colors.green;

      case 'CANCELADO':
        return Colors.red;

      case 'EM_ENTREGA':
        return Colors.blue;

      case 'PREPARANDO':
        return Colors.orange;

      case 'PRONTO':
        return Colors.green;

      default:
        return laranja;
    }
  }

  IconData iconeStatus(
    String status,
  ) {
    switch (status.toUpperCase()) {
      case 'ENTREGUE':
        return Icons.check_circle;

      case 'CANCELADO':
        return Icons.cancel;

      case 'EM_ENTREGA':
        return Icons.delivery_dining;

      case 'PREPARANDO':
        return Icons.restaurant;

      case 'PRONTO':
        return Icons.check_circle_outline;

      default:
        return Icons.access_time;
    }
  }

  // ============================================================
  // ABRIR PEDIDO
  // ============================================================

  void abrirPedido(
    dynamic pedido,
  ) {
    final pedidoId =
        int.tryParse(
      pedido['id']?.toString() ?? '',
    );

    if (pedidoId == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OrderTrackingScreen(
          pedidoId: pedidoId,
        ),
      ),
    );
  }

  // ============================================================
  // ATUALIZAR
  // ============================================================

  Future<void> atualizar() async {
    await buscarPedidos();
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
          const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Meus Pedidos',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: atualizar,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: carregando
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: laranja,
              ),
            )
          : erro != null
              ? _estadoErro()
              : pedidos.isEmpty
                  ? _estadoVazio()
                  : RefreshIndicator(
                      color: laranja,
                      onRefresh:
                          atualizar,
                      child:
                          ListView.builder(
                        padding:
                            const EdgeInsets
                                .all(16),
                        itemCount:
                            pedidos.length,
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          final pedido =
                              pedidos[index];

                          return _pedidoCard(
                            pedido,
                          );
                        },
                      ),
                    ),
    );
  }

  // ============================================================
  // CARD PEDIDO
  // ============================================================

  Widget _pedidoCard(
    dynamic pedido,
  ) {
    final status =
        pedido['status']
                ?.toString() ??
            'AGUARDANDO_RESTAURANTE';

    final pedidoId =
        pedido['id'];

    final total =
        pedido['total'];

    final itens =
        pedido['itens'];

    return Card(
      color: Colors.white,

      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),

      elevation: 2,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          16,
        ),

        onTap: () {
          abrirPedido(
            pedido,
          );
        },

        child: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  Text(
                    'Pedido #$pedidoId',

                    style:
                        const TextStyle(
                      color:
                          Colors.black,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 18,
                    color:
                        Colors.grey,
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              Row(
                children: [
                  Icon(
                    iconeStatus(
                      status,
                    ),
                    size: 22,
                    color:
                        corStatus(
                      status,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Text(
                    tituloStatus(
                      status,
                    ),

                    style:
                        TextStyle(
                      color:
                          corStatus(
                        status,
                      ),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              if (itens is List)
                Text(
                  '${itens.length} item(ns)',
                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
                  ),
                ),

              const SizedBox(
                height: 10,
              ),

              const Divider(),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [
                  const Text(
                    'Total',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  Text(
                    formatarPreco(
                      total,
                    ),

                    style:
                        const TextStyle(
                      fontSize: 18,
                      color:
                          laranja,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              SizedBox(
                width:
                    double.infinity,

                child:
                    OutlinedButton.icon(
                  onPressed: () {
                    abrirPedido(
                      pedido,
                    );
                  },

                  icon:
                      const Icon(
                    Icons
                        .local_shipping_outlined,
                  ),

                  label:
                      const Text(
                    'Acompanhar pedido',
                  ),

                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        laranja,

                    side:
                        const BorderSide(
                      color:
                          laranja,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VAZIO
  // ============================================================

  Widget _estadoVazio() {
    return RefreshIndicator(
      color: laranja,
      onRefresh: atualizar,

      child: ListView(
        children: [
          const SizedBox(
            height: 160,
          ),

          const Icon(
            Icons.receipt_long,
            size: 70,
            color: Colors.grey,
          ),

          const SizedBox(
            height: 20,
          ),

          const Center(
            child: Text(
              'Você ainda não fez nenhum pedido.',
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Center(
            child: Text(
              'Quando você fizer um pedido,\nele aparecerá aqui.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _estadoErro() {
    return RefreshIndicator(
      color: laranja,
      onRefresh: atualizar,

      child: ListView(
        children: [
          const SizedBox(
            height: 150,
          ),

          const Icon(
            Icons.cloud_off,
            size: 65,
            color: laranja,
          ),

          const SizedBox(
            height: 20,
          ),

          const Center(
            child: Text(
              'Não foi possível carregar seus pedidos.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Center(
            child:
                ElevatedButton.icon(
              onPressed: atualizar,

              icon:
                  const Icon(
                Icons.refresh,
              ),

              label:
                  const Text(
                'Tentar novamente',
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    laranja,
                foregroundColor:
                    Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}