
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrderTrackingScreen extends StatefulWidget {
  final int pedidoId;

  const OrderTrackingScreen({
    super.key,
    required this.pedidoId,
  });

  @override
  State<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState
    extends State<OrderTrackingScreen> {
  Timer? timer;

  bool carregando = true;

  String statusPedido =
      'AGUARDANDO_RESTAURANTE';

  Map<String, dynamic>? pedido;

  final String apiUrl =
      'http://192.168.1.101:3000';

  @override
  void initState() {
    super.initState();

    // Busca o pedido assim que a tela abre
    buscarPedido();

    // Atualiza automaticamente a cada 10 segundos
    timer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) {
        buscarPedido();
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();

    super.dispose();
  }

  // =====================================================
  // BUSCAR PEDIDO NA API
  // =====================================================

  Future<void> buscarPedido() async {
    try {
      final resposta = await http.get(
        Uri.parse(
          '$apiUrl/api/orders/${widget.pedidoId}',
        ),
      );

      print(
        '📡 STATUS PEDIDO: ${resposta.statusCode}',
      );

      print(
        '📦 RESPOSTA PEDIDO: ${resposta.body}',
      );

      if (resposta.statusCode == 200) {
        final dados =
            jsonDecode(resposta.body);

        if (!mounted) {
          return;
        }

        setState(() {
          // Caso a API retorne:
          // { pedido: {...} }
          pedido = dados['pedido'] ?? dados;

          statusPedido =
              pedido?['status'] ??
              'AGUARDANDO_RESTAURANTE';

          carregando = false;
        });
      } else {
        if (!mounted) {
          return;
        }

        setState(() {
          carregando = false;
        });
      }
    } catch (erro) {
      print(
        '❌ ERRO AO BUSCAR PEDIDO: $erro',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        carregando = false;
      });
    }
  }

  // =====================================================
  // TEXTO DO STATUS PRINCIPAL
  // =====================================================

  String textoStatus() {
    switch (statusPedido) {
      case 'AGUARDANDO_RESTAURANTE':
        return 'Aguardando confirmação do restaurante';

      case 'CONFIRMADO':
        return 'Pedido confirmado';

      case 'PREPARANDO':
        return 'Restaurante preparando';

      case 'PRONTO':
        return 'Pedido pronto';

      case 'EM_ENTREGA':
        return 'Saiu para entrega';

      case 'ENTREGUE':
        return 'Pedido entregue';

      case 'CANCELADO':
        return 'Pedido cancelado';

      default:
        return statusPedido;
    }
  }

  // =====================================================
  // ÍCONE DO STATUS
  // =====================================================

  IconData iconeStatus() {
    switch (statusPedido) {
      case 'AGUARDANDO_RESTAURANTE':
        return Icons.receipt_long;

      case 'CONFIRMADO':
        return Icons.check_circle;

      case 'PREPARANDO':
        return Icons.restaurant;

      case 'PRONTO':
        return Icons.inventory_2;

      case 'EM_ENTREGA':
        return Icons.delivery_dining;

      case 'ENTREGUE':
        return Icons.done_all;

      case 'CANCELADO':
        return Icons.cancel;

      default:
        return Icons.receipt_long;
    }
  }

  // =====================================================
  // COR DO STATUS
  // =====================================================

  Color corStatus() {
    switch (statusPedido) {
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
        return const Color(0xFFF97316);
    }
  }

  // =====================================================
  // VERIFICA SE O STATUS ESTÁ ATIVO
  // =====================================================

  bool statusAtivo(String status) {
    final ordem = [
      'AGUARDANDO_RESTAURANTE',
      'CONFIRMADO',
      'PREPARANDO',
      'PRONTO',
      'EM_ENTREGA',
      'ENTREGUE',
    ];

    final atual =
        ordem.indexOf(statusPedido);

    final item =
        ordem.indexOf(status);

    // Se o pedido foi cancelado,
    // nenhum status fica ativo
    if (statusPedido == 'CANCELADO') {
      return false;
    }

    // Evita erro caso o backend retorne
    // um status que ainda não cadastramos
    if (atual == -1 || item == -1) {
      return false;
    }

    return item <= atual;
  }

  // =====================================================
  // FORMATAR PREÇO
  // =====================================================

  String formatarPreco(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    const laranja =
        Color(0xFFF97316);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5),

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor:
            laranja,

        foregroundColor:
            Colors.white,

        title: const Text(
          'Acompanhar Pedido',

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      // =================================================
      // BODY
      // =================================================

      body: carregando
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh:
                  buscarPedido,

              child:
                  SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    // ===================================
                    // STATUS PRINCIPAL
                    // ===================================

                    Card(
                      color:
                          Colors.white,

                      child:
                          Padding(
                        padding:
                            const EdgeInsets.all(
                          20,
                        ),

                        child:
                            Column(
                          children: [
                            Icon(
                              iconeStatus(),

                              size: 70,

                              color:
                                  corStatus(),
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            Text(
                              textoStatus(),

                              textAlign:
                                  TextAlign.center,

                              style:
                                  TextStyle(
                                fontSize:
                                    23,

                                fontWeight:
                                    FontWeight.bold,

                                color:
                                    corStatus(),
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            Text(
                              'Pedido #${widget.pedidoId}',

                              style:
                                  const TextStyle(
                                color:
                                    Colors.grey,

                                fontSize:
                                    16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ===================================
                    // TÍTULO
                    // ===================================

                    const Text(
                      'Status do pedido',

                      style:
                          TextStyle(
                        fontSize:
                            20,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    // ===================================
                    // LINHA DO TEMPO
                    // ===================================

                    Card(
                      color:
                          Colors.white,

                      child:
                          Padding(
                        padding:
                            const EdgeInsets.all(
                          20,
                        ),

                        child:
                            Column(
                          children: [
                            // RECEBIDO
                            _statusItem(
                              titulo:
                                  'Aguardando confirmação do restaurante',

                              status:
                                  'AGUARDANDO_RESTAURANTE',

                              icone:
                                  Icons.receipt_long,

                              primeiro:
                                  true,
                            ),

                            // CONFIRMADO
                            _statusItem(
                              titulo:
                                  'Pedido confirmado',

                              status:
                                  'CONFIRMADO',

                              icone:
                                  Icons.check_circle,
                            ),

                            // PREPARANDO
                            _statusItem(
                              titulo:
                                  'Restaurante preparando',

                              status:
                                  'PREPARANDO',

                              icone:
                                  Icons.restaurant,
                            ),

                            // PRONTO
                            _statusItem(
                              titulo:
                                  'Pedido pronto',

                              status:
                                  'PRONTO',

                              icone:
                                  Icons.inventory_2,
                            ),

                            // EM ENTREGA
                            _statusItem(
                              titulo:
                                  'Saiu para entrega',

                              status:
                                  'EM_ENTREGA',

                              icone:
                                  Icons.delivery_dining,
                            ),

                            // ENTREGUE
                            _statusItem(
                              titulo:
                                  'Pedido entregue',

                              status:
                                  'ENTREGUE',

                              icone:
                                  Icons.done_all,

                              ultimo:
                                  true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ===================================
                    // INFORMAÇÕES DO PEDIDO
                    // ===================================

                    if (pedido != null)
                      Card(
                        color:
                            Colors.white,

                        child:
                            Padding(
                          padding:
                              const EdgeInsets.all(
                            20,
                          ),

                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              const Text(
                                'Informações do pedido',

                                style:
                                    TextStyle(
                                  fontSize:
                                      18,

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 15,
                              ),

                              // TOTAL
                              if (pedido![
                                      'total'] !=
                                  null)
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
                                            Colors.grey,
                                      ),
                                    ),

                                    Text(
                                      formatarPreco(
                                        double.tryParse(
                                              pedido![
                                                      'total']
                                                  .toString(),
                                            ) ??
                                            0,
                                      ),

                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,

                                        fontSize:
                                            18,
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(
                                height: 12,
                              ),

                              // PAGAMENTO
                              if (pedido![
                                      'pagamento'] !=
                                  null)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,

                                  children: [
                                    const Text(
                                      'Pagamento',

                                      style:
                                          TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),

                                    Text(
                                      pedido![
                                              'pagamento']
                                          .toString(),

                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(
                      height: 25,
                    ),

                    // ===================================
                    // BOTÃO ATUALIZAR
                    // ===================================

                    SizedBox(
                      width:
                          double.infinity,

                      child:
                          ElevatedButton.icon(
                        onPressed:
                            buscarPedido,

                        icon:
                            const Icon(
                          Icons.refresh,
                        ),

                        label:
                            const Text(
                          'ATUALIZAR PEDIDO',
                        ),

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              laranja,

                          foregroundColor:
                              Colors.white,

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical:
                                16,
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

  // =====================================================
  // ITEM DA LINHA DO TEMPO
  // =====================================================

  Widget _statusItem({
    required String titulo,
    required String status,
    required IconData icone,
    bool primeiro = false,
    bool ultimo = false,
  }) {
    final ativo =
        statusAtivo(status);

    const laranja =
        Color(0xFFF97316);

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        // ===============================================
        // ÍCONE + LINHA
        // ===============================================

        Column(
          children: [
            Container(
              width:
                  45,

              height:
                  45,

              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,

                color: ativo
                    ? laranja
                    : Colors.grey.shade300,
              ),

              child:
                  Icon(
                icone,

                color: ativo
                    ? Colors.white
                    : Colors.grey,

                size:
                    22,
              ),
            ),

            if (!ultimo)
              Container(
                width:
                    2,

                height:
                    45,

                color: ativo
                    ? laranja
                    : Colors.grey.shade300,
              ),
          ],
        ),

        const SizedBox(
          width:
              15,
        ),

        // ===============================================
        // TEXTO
        // ===============================================

        Expanded(
          child:
              Padding(
            padding:
                const EdgeInsets.only(
              top:
                  10,
            ),

            child:
                Text(
              titulo,

              style:
                  TextStyle(
                fontSize:
                    16,

                fontWeight:
                    ativo
                        ? FontWeight.bold
                        : FontWeight.normal,

                color:
                    ativo
                        ? Colors.black
                        : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
