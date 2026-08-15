import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({
    super.key,
  });

  @override
  State<OrderHistoryScreen> createState() =>
      _OrderHistoryScreenState();
}

class _OrderHistoryScreenState
    extends State<OrderHistoryScreen> {
  final int clienteId = 1784355543711;

  final String apiUrl =
      'http://192.168.1.101:3000/api/orders';

  List pedidos = [];

  bool carregando = true;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    buscarPedidos();

    timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        buscarPedidos();
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> buscarPedidos() async {
    try {
      final resposta = await http.get(
        Uri.parse(apiUrl),
      );

      if (resposta.statusCode != 200) {
        return;
      }

      final dados = jsonDecode(
        resposta.body,
      );

      if (dados is! List) {
        return;
      }

      final pedidosCliente = dados.where(
        (pedido) {
          return pedido['clienteId'].toString() ==
              clienteId.toString();
        },
      ).toList();

      pedidosCliente.sort(
        (a, b) {
          final idA =
              int.tryParse(
                    a['id'].toString(),
                  ) ??
                  0;

          final idB =
              int.tryParse(
                    b['id'].toString(),
                  ) ??
                  0;

          return idB.compareTo(idA);
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        pedidos = pedidosCliente;
        carregando = false;
      });
    } catch (erro) {
      debugPrint(
        'Erro ao buscar histórico: $erro',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        carregando = false;
      });
    }
  }

  String formatarPreco(dynamic valor) {
    final numero =
        double.tryParse(
              valor.toString(),
            ) ??
            0;

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String tituloStatus(String status) {
    switch (status) {
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

  Color corStatus(String status) {
    switch (status) {
      case 'ENTREGUE':
        return Colors.green;

      case 'CANCELADO':
        return Colors.red;

      case 'EM_ENTREGA':
        return Colors.blue;

      case 'PREPARANDO':
        return Colors.orange;

      default:
        return const Color(0xFFF97316);
    }
  }

  IconData iconeStatus(String status) {
    switch (status) {
      case 'ENTREGUE':
        return Icons.check_circle;

      case 'CANCELADO':
        return Icons.cancel;

      case 'EM_ENTREGA':
        return Icons.delivery_dining;

      case 'PREPARANDO':
        return Icons.restaurant;

      default:
        return Icons.access_time;
    }
  }

  void abrirPedido(dynamic pedido) {
    final pedidoId =
        int.tryParse(
          pedido['id'].toString(),
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

  Future<void> atualizar() async {
    setState(() {
      carregando = true;
    });

    await buscarPedidos();
  }

  @override
  Widget build(BuildContext context) {
    const laranja =
        Color(0xFFF97316);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,

        title: const Text(
          'Meus Pedidos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
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
                  CircularProgressIndicator(),
            )
          : pedidos.isEmpty
              ? RefreshIndicator(
                  onRefresh: buscarPedidos,

                  child: ListView(
                    children: const [
                      SizedBox(
                        height: 180,
                      ),

                      Icon(
                        Icons.receipt_long,
                        size: 70,
                        color: Colors.grey,
                      ),

                      SizedBox(
                        height: 20,
                      ),

                      Center(
                        child: Text(
                          'Você ainda não fez nenhum pedido.',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: buscarPedidos,

                  child: ListView.builder(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),

                    itemCount:
                        pedidos.length,

                    itemBuilder:
                        (context, index) {
                      final pedido =
                          pedidos[index];

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
                                const EdgeInsets.all(
                              16,
                            ),

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

  style: const TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

                                    Icon(
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}