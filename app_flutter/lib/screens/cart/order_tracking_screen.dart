
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../config/api.dart';

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

  // =====================================================
  // TIMER DE FALLBACK
  // =====================================================

  Timer? timer;

  // =====================================================
  // SOCKET.IO
  // =====================================================

  IO.Socket? socket;

  bool socketConectado = false;

  // =====================================================
  // ESTADO DA TELA
  // =====================================================

  bool carregando = true;

  String statusPedido =
      'AGUARDANDO_RESTAURANTE';

  Map<String, dynamic>? pedido;

  bool buscando = false;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    print(
      '==============================================',
    );

    print(
      '📦 ORDER TRACKING INICIADO',
    );

    print(
      '📦 PEDIDO: ${widget.pedidoId}',
    );

    print(
      '==============================================',
    );

    // =================================================
    // BUSCA INICIAL
    // =================================================

    buscarPedido();

    // =================================================
    // SOCKET.IO
    // =================================================

    conectarSocket();

    // =================================================
    // POLLING DE SEGURANÇA
    // =================================================

    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        buscarPedido();
      },
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {

    timer?.cancel();

    desconectarSocket();

    super.dispose();
  }

  // =====================================================
  // CONECTAR SOCKET.IO
  // =====================================================

  void conectarSocket() {

    try {

      print('');
      print(
        '==============================================',
      );

      print(
        '🔌 CONECTANDO SOCKET.IO',
      );

      print(
        '📦 PEDIDO: ${widget.pedidoId}',
      );

      print(
        '🌐 SERVIDOR: https://foodjet-backend.onrender.com',
      );

      print(
        '==============================================',
      );


      // =================================================
      // URL DO SOCKET
      // =================================================
      //
      // IMPORTANTE:
      //
      // Não colocar /api aqui.
      //
      // API:
      // https://foodjet-backend.onrender.com/api
      //
      // SOCKET:
      // https://foodjet-backend.onrender.com
      //
      // =================================================

      socket = IO.io(
        'https://foodjet-backend.onrender.com',
        IO.OptionBuilder()
            .setTransports([
              'websocket',
            ])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .build(),
      );


      // =================================================
      // CONECTOU
      // =================================================

      socket!.onConnect((_) {

        print('');
        print(
          '==============================================',
        );

        print(
          '🟢 SOCKET.IO CONECTADO',
        );

        print(
          '📦 PEDIDO: ${widget.pedidoId}',
        );

        print(
          '==============================================',
        );


        if (mounted) {

          setState(() {

            socketConectado = true;

          });

        }


        // =================================================
        // ENTRAR NA SALA DO PEDIDO
        // =================================================

        final salaPedido =
            widget.pedidoId.toString();

        print(
          '📡 ENTRANDO NA SALA:',
        );

        print(
          'pedido_$salaPedido',
        );


        socket!.emit(
          'entrar_pedido',
          salaPedido,
        );


        print(
          '✅ SALA DO PEDIDO SOLICITADA',
        );

      });


      // =================================================
      // EVENTO DE STATUS DO PEDIDO
      // =================================================

      socket!.on(
        'status_pedido_atualizado',
        (dados) {

          print('');
          print(
            '==============================================',
          );

          print(
            '📡 SOCKET.IO → STATUS PEDIDO',
          );

          print(
            '📦 DADOS RECEBIDOS:',
          );

          print(
            dados,
          );

          print(
            '==============================================',
          );


          processarAtualizacaoSocket(
            dados,
          );

        },
      );


      // =================================================
      // CONEXÃO RESTABELECIDA
      // =================================================

      socket!.on(
        'reconnect',
        (_) {

          print(
            '🔄 SOCKET.IO RECONectado',
          );

          if (mounted) {

            setState(() {

              socketConectado = true;

            });

          }

          // O onConnect normalmente entra novamente
          // na sala quando a conexão é restabelecida.
        },
      );


      // =================================================
      // ERRO DE CONEXÃO
      // =================================================

      socket!.on(
        'connect_error',
        (erro) {

          print(
            '❌ SOCKET.IO CONNECT ERROR: $erro',
          );

        },
      );


      // =================================================
      // DESCONEXÃO
      // =================================================

      socket!.onDisconnect(
        (_) {

          print(
            '🔴 SOCKET.IO DESCONECTADO',
          );

          if (mounted) {

            setState(() {

              socketConectado = false;

            });

          }

        },
      );


      // =================================================
      // ERRO
      // =================================================

      socket!.on(
        'error',
        (erro) {

          print(
            '❌ SOCKET.IO ERROR: $erro',
          );

        },
      );


      // =================================================
      // CONECTAR
      // =================================================

      socket!.connect();

    } catch (erro) {

      print(
        '❌ ERRO AO CONFIGURAR SOCKET.IO: $erro',
      );

      if (mounted) {

        setState(() {

          socketConectado = false;

        });

      }

    }

  }


  // =====================================================
  // DESCONECTAR SOCKET.IO
  // =====================================================

  void desconectarSocket() {

    try {

      if (socket == null) {
        return;
      }

      print(
        '🔌 DESCONECTANDO SOCKET.IO...',
      );


      socket!.off(
        'status_pedido_atualizado',
      );

      socket!.off(
        'connect',
      );

      socket!.off(
        'disconnect',
      );

      socket!.off(
        'connect_error',
      );

      socket!.off(
        'reconnect',
      );

      socket!.off(
        'error',
      );


      socket!.disconnect();

      socket!.dispose();

      socket = null;

      print(
        '✅ SOCKET.IO DESCONECTADO',
      );

    } catch (erro) {

      print(
        '⚠️ ERRO AO DESCONECTAR SOCKET.IO: $erro',
      );

    }

  }


  // =====================================================
  // PROCESSAR ATUALIZAÇÃO DO SOCKET
  // =====================================================

  void processarAtualizacaoSocket(
    dynamic dados,
  ) {

    try {

      Map<String, dynamic>? pedidoRecebido;


      // =================================================
      // SOCKET PODE ENVIAR MAP DIRETAMENTE
      // =================================================

      if (dados is Map) {

        pedidoRecebido =
            Map<String, dynamic>.from(
          dados,
        );

      }


      // =================================================
      // PODE VIR COMO:
      //
      // {
      //   pedido: {...}
      // }
      //
      // =================================================

      if (
        dados is Map &&
        dados['pedido'] is Map
      ) {

        pedidoRecebido =
            Map<String, dynamic>.from(
          dados['pedido'],
        );

      }


      if (pedidoRecebido == null) {

        print(
          '⚠️ SOCKET: dados do pedido inválidos.',
        );

        return;

      }


      // =================================================
      // CONFERIR ID
      // =================================================

      final idRecebido =
          pedidoRecebido['id'] ??
          pedidoRecebido['pedidoId'] ??
          pedidoRecebido['pedido_id'];


      if (idRecebido != null) {

        final idString =
            idRecebido.toString().trim();

        if (
          idString !=
          widget.pedidoId.toString()
        ) {

          print(
            '⚠️ SOCKET: atualização de outro pedido ignorada.',
          );

          print(
            '📦 PEDIDO ESPERADO: ${widget.pedidoId}',
          );

          print(
            '📦 PEDIDO RECEBIDO: $idString',
          );

          return;

        }

      }


      // =================================================
      // STATUS
      // =================================================

      dynamic statusRecebido;


      if (
        pedidoRecebido['status'] != null
      ) {

        statusRecebido =
            pedidoRecebido['status'];

      } else if (
        pedidoRecebido['statusPedido'] != null
      ) {

        statusRecebido =
            pedidoRecebido['statusPedido'];

      } else if (
        pedidoRecebido['situacao'] != null
      ) {

        statusRecebido =
            pedidoRecebido['situacao'];

      }


      final novoStatus =
          normalizarStatus(
        statusRecebido,
      );


      print(
        '📦 STATUS SOCKET RECEBIDO: $statusRecebido',
      );

      print(
        '📦 STATUS SOCKET NORMALIZADO: $novoStatus',
      );


      if (!mounted) {
        return;
      }


      // =================================================
      // ATUALIZAR IMEDIATAMENTE
      // =================================================

      setState(() {

        pedido =
            pedidoRecebido;

        statusPedido =
            novoStatus;

        carregando = false;

      });


      // =================================================
      // LOGS
      // =================================================

      if (
        novoStatus ==
        'CONFIRMADO'
      ) {

        print(
          '==============================================',
        );

        print(
          '✅ RESTAURANTE ACEITOU O PEDIDO!',
        );

        print(
          '📦 PEDIDO: ${widget.pedidoId}',
        );

        print(
          '==============================================',
        );

      }


      if (
        novoStatus ==
        'CANCELADO'
      ) {

        print(
          '❌ PEDIDO CANCELADO',
        );

      }

    } catch (erro) {

      print(
        '❌ ERRO PROCESSANDO SOCKET.IO: $erro',
      );

    }

  }


  // =====================================================
  // NORMALIZAR STATUS
  // =====================================================

  String normalizarStatus(
    dynamic valor,
  ) {

    if (valor == null) {

      return 'AGUARDANDO_RESTAURANTE';

    }


    String status =
        valor
            .toString()
            .trim()
            .toUpperCase();


    // ===================================================
    // ACEITO
    // ===================================================

    if (
      status == 'ACEITO' ||
      status == 'ACEITADO' ||
      status == 'CONFIRMADO' ||
      status == 'CONFIRMADO_RESTAURANTE' ||
      status == 'RESTAURANTE_ACEITOU'
    ) {

      return 'CONFIRMADO';

    }


    // ===================================================
    // PREPARAÇÃO
    // ===================================================

    if (
      status == 'EM_PREPARO' ||
      status == 'PREPARANDO'
    ) {

      return 'PREPARANDO';

    }


    // ===================================================
    // ENTREGA
    // ===================================================

    if (
      status == 'SAIU_PARA_ENTREGA' ||
      status == 'EM_ENTREGA'
    ) {

      return 'EM_ENTREGA';

    }


    // ===================================================
    // PRONTO
    // ===================================================

    if (
      status == 'PRONTO' ||
      status == 'PRONTO_PARA_ENTREGA'
    ) {

      return 'PRONTO';

    }


    // ===================================================
    // ENTREGUE
    // ===================================================

    if (
      status == 'ENTREGUE'
    ) {

      return 'ENTREGUE';

    }


    // ===================================================
    // CANCELADO
    // ===================================================

    if (
      status == 'CANCELADO' ||
      status == 'CANCELADA' ||
      status == 'CANCELLED' ||
      status == 'RECUSADO'
    ) {

      return 'CANCELADO';

    }


    return status;

  }


  // =====================================================
  // BUSCAR PEDIDO NA API
  // =====================================================

  Future<void> buscarPedido() async {

    if (buscando) {
      return;
    }


    buscando = true;


    try {

      final url =
          '${Api.baseUrl}/orders/${widget.pedidoId}';


      print(
        '📡 BUSCANDO PEDIDO: $url',
      );


      final resposta =
          await http.get(
        Uri.parse(url),
      );


      print(
        '📡 STATUS HTTP PEDIDO: ${resposta.statusCode}',
      );


      print(
        '📦 RESPOSTA PEDIDO: ${resposta.body}',
      );


      if (
        resposta.statusCode == 200
      ) {

        final dados =
            jsonDecode(
          resposta.body,
        );


        Map<String, dynamic>?
            pedidoRecebido;


        // =================================================
        // FORMATO:
        //
        // { "pedido": {...} }
        //
        // =================================================

        if (
          dados is Map<String, dynamic>
        ) {

          if (
            dados['pedido'] is Map
          ) {

            pedidoRecebido =
                Map<String, dynamic>.from(
              dados['pedido'],
            );

          } else {

            pedidoRecebido =
                dados;

          }

        }


        if (
          pedidoRecebido == null
        ) {

          print(
            '⚠️ PEDIDO NÃO ENCONTRADO NA RESPOSTA',
          );


          if (mounted) {

            setState(() {

              carregando = false;

            });

          }


          return;

        }


        // =================================================
        // PEGAR STATUS
        // =================================================

        dynamic statusRecebido;


        if (
          pedidoRecebido['status'] != null
        ) {

          statusRecebido =
              pedidoRecebido['status'];

        } else if (
          pedidoRecebido['statusPedido'] != null
        ) {

          statusRecebido =
              pedidoRecebido['statusPedido'];

        } else if (
          pedidoRecebido['situacao'] != null
        ) {

          statusRecebido =
              pedidoRecebido['situacao'];

        }


        final novoStatus =
            normalizarStatus(
          statusRecebido,
        );


        print(
          '==============================================',
        );

        print(
          '📦 PEDIDO ${widget.pedidoId}',
        );

        print(
          '📦 STATUS RECEBIDO: $statusRecebido',
        );

        print(
          '📦 STATUS NORMALIZADO: $novoStatus',
        );

        print(
          '==============================================',
        );


        if (!mounted) {
          return;
        }


        setState(() {

          pedido =
              pedidoRecebido;

          statusPedido =
              novoStatus;

          carregando = false;

        });


        // =================================================
        // RESTAURANTE ACEITOU
        // =================================================

        if (
          novoStatus ==
          'CONFIRMADO'
        ) {

          print(
            '✅ RESTAURANTE ACEITOU O PEDIDO ${widget.pedidoId}',
          );

        }


        // =================================================
        // CANCELADO
        // =================================================

        if (
          novoStatus ==
          'CANCELADO'
        ) {

          print(
            '❌ PEDIDO ${widget.pedidoId} FOI CANCELADO',
          );

        }

      } else {

        print(
          '❌ ERRO HTTP AO BUSCAR PEDIDO: ${resposta.statusCode}',
        );


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

    } finally {

      buscando = false;

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

        return 'Pedido confirmado pelo restaurante';


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


      case 'CONFIRMADO':

        return Colors.green;


      default:

        return const Color(0xFFF97316);

    }

  }


  // =====================================================
  // STATUS ATIVO
  // =====================================================

  bool statusAtivo(
    String status,
  ) {

    final ordem = [

      'AGUARDANDO_RESTAURANTE',

      'CONFIRMADO',

      'PREPARANDO',

      'PRONTO',

      'EM_ENTREGA',

      'ENTREGUE',

    ];


    final atual =
        ordem.indexOf(
      statusPedido,
    );


    final item =
        ordem.indexOf(
      status,
    );


    if (
      statusPedido ==
      'CANCELADO'
    ) {

      return false;

    }


    if (
      atual == -1 ||
      item == -1
    ) {

      return false;

    }


    return item <= atual;

  }


  // =====================================================
  // FORMATAR PREÇO
  // =====================================================

  String formatarPreco(
    double valor,
  ) {

    return
        'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  }


  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(
    BuildContext context,
  ) {

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

        actions: [

          // =============================================
          // INDICADOR SOCKET
          // =============================================

          Padding(

            padding:
                const EdgeInsets.only(
              right: 15,
            ),

            child: Row(

              children: [

                Container(

                  width: 9,

                  height: 9,

                  decoration:
                      BoxDecoration(

                    color:
                        socketConectado
                            ? Colors.greenAccent
                            : Colors.white54,

                    shape:
                        BoxShape.circle,

                  ),

                ),

                const SizedBox(
                  width: 6,
                ),

                Text(

                  socketConectado
                      ? 'ONLINE'
                      : 'OFFLINE',

                  style:
                      const TextStyle(

                    fontSize:
                        10,

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

              ],

            ),

          ),

        ],

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
                    const EdgeInsets.all(
                  20,
                ),

                child:
                    Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    // ===================================
                    // STATUS PRINCIPAL
                    // ===================================

                    Card(

                      color:
                          Colors.white,

                      elevation:
                          1,

                      shape:
                          RoundedRectangleBorder(

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),

                      ),

                      child:
                          Padding(

                        padding:
                            const EdgeInsets.all(
                          20,
                        ),

                        child:
                            Column(

                          children: [

                            Container(

                              width:
                                  90,

                              height:
                                  90,

                              decoration:
                                  BoxDecoration(

                                color:
                                    corStatus()
                                        .withValues(
                                  alpha:
                                      .10,
                                ),

                                shape:
                                    BoxShape.circle,

                              ),

                              child:
                                  Icon(

                                iconeStatus(),

                                size:
                                    50,

                                color:
                                    corStatus(),

                              ),

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


                            // =================================
                            // PEDIDO CONFIRMADO
                            // =================================

                            if (
                              statusPedido ==
                              'CONFIRMADO'
                            ) ...[

                              const SizedBox(
                                height: 18,
                              ),


                              Container(

                                width:
                                    double.infinity,

                                padding:
                                    const EdgeInsets.all(
                                  14,
                                ),

                                decoration:
                                    BoxDecoration(

                                  color:
                                      const Color(
                                    0xFFECFDF5,
                                  ),

                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),

                                  border:
                                      Border.all(

                                    color:
                                        const Color(
                                      0xFFBBF7D0,
                                    ),

                                  ),

                                ),

                                child:
                                    const Row(

                                  children: [

                                    Icon(

                                      Icons.check_circle,

                                      color:
                                          Color(
                                        0xFF16A34A,
                                      ),

                                      size:
                                          28,

                                    ),

                                    SizedBox(
                                      width: 12,
                                    ),

                                    Expanded(

                                      child:
                                          Column(

                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                        children: [

                                          Text(

                                            'Pedido aceito!',

                                            style:
                                                TextStyle(

                                              color:
                                                  Color(
                                                0xFF15803D,
                                              ),

                                              fontWeight:
                                                  FontWeight.bold,

                                              fontSize:
                                                  14,

                                            ),

                                          ),

                                          SizedBox(
                                            height: 3,
                                          ),

                                          Text(

                                            'O restaurante aceitou seu pedido e vai começar a preparar.',

                                            style:
                                                TextStyle(

                                              color:
                                                  Colors.black87,

                                              fontSize:
                                                  12,

                                            ),

                                          ),

                                        ],

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                            ],


                            // =================================
                            // EM ENTREGA
                            // =================================

                            if (
                              statusPedido ==
                              'EM_ENTREGA'
                            ) ...[

                              const SizedBox(
                                height: 18,
                              ),


                              Container(

                                width:
                                    double.infinity,

                                padding:
                                    const EdgeInsets.all(
                                  14,
                                ),

                                decoration:
                                    BoxDecoration(

                                  color:
                                      const Color(
                                    0xFFEFF6FF,
                                  ),

                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),

                                  border:
                                      Border.all(

                                    color:
                                        const Color(
                                      0xFFBFDBFE,
                                    ),

                                  ),

                                ),

                                child:
                                    const Row(

                                  children: [

                                    Icon(

                                      Icons.delivery_dining,

                                      color:
                                          Color(
                                        0xFF2563EB,
                                      ),

                                      size:
                                          28,

                                    ),

                                    SizedBox(
                                      width: 12,
                                    ),

                                    Expanded(

                                      child:
                                          Column(

                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                        children: [

                                          Text(

                                            'Seu pedido está a caminho!',

                                            style:
                                                TextStyle(

                                              color:
                                                  Color(
                                                0xFF1D4ED8,
                                              ),

                                              fontWeight:
                                                  FontWeight.bold,

                                              fontSize:
                                                  14,

                                            ),

                                          ),

                                          SizedBox(
                                            height: 3,
                                          ),

                                          Text(

                                            'O entregador está levando seu pedido até você.',

                                            style:
                                                TextStyle(

                                              color:
                                                  Colors.black87,

                                              fontSize:
                                                  12,

                                            ),

                                          ),

                                        ],

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                            ],

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

                      elevation:
                          1,

                      shape:
                          RoundedRectangleBorder(

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),

                      ),

                      child:
                          Padding(

                        padding:
                            const EdgeInsets.all(
                          20,
                        ),

                        child:
                            Column(

                          children: [

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


                            _statusItem(

                              titulo:
                                  'Pedido confirmado',

                              status:
                                  'CONFIRMADO',

                              icone:
                                  Icons.check_circle,

                            ),


                            _statusItem(

                              titulo:
                                  'Restaurante preparando',

                              status:
                                  'PREPARANDO',

                              icone:
                                  Icons.restaurant,

                            ),


                            _statusItem(

                              titulo:
                                  'Pedido pronto',

                              status:
                                  'PRONTO',

                              icone:
                                  Icons.inventory_2,

                            ),


                            _statusEntrega(),


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
                    // INFORMAÇÕES
                    // ===================================

                    if (
                      pedido != null
                    )

                      Card(

                        color:
                            Colors.white,

                        elevation:
                            1,

                        shape:
                            RoundedRectangleBorder(

                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),

                        ),

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


                              if (
                                pedido!['total'] !=
                                null
                              )

                                Row(

                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,

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


                              if (
                                pedido![
                                      'pagamento'] !=
                                    null
                              )

                                Row(

                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,

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
                    // BOTÃO
                    // ===================================

                    SizedBox(

                      width:
                          double.infinity,

                      child:
                          ElevatedButton.icon(

                        onPressed:
                            buscando
                                ? null
                                : buscarPedido,

                        icon:
                            const Icon(
                          Icons.refresh,
                        ),

                        label:
                            Text(

                          buscando
                              ? 'ATUALIZANDO...'
                              : 'ATUALIZAR PEDIDO',

                        ),

                        style:
                            ElevatedButton.styleFrom(

                          backgroundColor:
                              laranja,

                          foregroundColor:
                              Colors.white,

                          padding:
                              const EdgeInsets.symmetric(

                            vertical:
                                16,

                          ),

                          shape:
                              RoundedRectangleBorder(

                            borderRadius:
                                BorderRadius.circular(
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
  // STATUS ESPECIAL - ENTREGA
  // =====================================================

  Widget _statusEntrega() {

    if (
      statusPedido !=
      'EM_ENTREGA'
    ) {

      return _statusItem(

        titulo:
            'Saiu para entrega',

        status:
            'EM_ENTREGA',

        icone:
            Icons.delivery_dining,

      );

    }


    return Container(

      width:
          double.infinity,

      margin:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(

        color:
            const Color(
          0xFFEFF6FF,
        ),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(

          color:
              const Color(
            0xFFBFDBFE,
          ),

          width:
              1,

        ),

      ),

      child:
          Column(

        children: [

          Container(

            width:
                64,

            height:
                64,

            decoration:
                const BoxDecoration(

              color:
                  Color(
                0xFF2563EB,
              ),

              shape:
                  BoxShape.circle,

            ),

            child:
                const Icon(

              Icons.delivery_dining,

              color:
                  Colors.white,

              size:
                  34,

            ),

          ),


          const SizedBox(
            height: 12,
          ),


          const Text(

            'Saiu para entrega!',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(

              fontSize:
                  20,

              fontWeight:
                  FontWeight.bold,

              color:
                  Color(
                0xFF1D4ED8,
              ),

            ),

          ),


          const SizedBox(
            height: 5,
          ),


          const Text(

            'Seu pedido está a caminho.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(

              fontSize:
                  14,

              color:
                  Colors.black87,

            ),

          ),


          const SizedBox(
            height: 14,
          ),


          Container(

            width:
                double.infinity,

            padding:
                const EdgeInsets.symmetric(

              horizontal:
                  12,

              vertical:
                  11,

            ),

            decoration:
                BoxDecoration(

              color:
                  Colors.white,

              borderRadius:
                  BorderRadius.circular(
                12,
              ),

            ),

            child:
                const Row(

              children: [

                Icon(

                  Icons.location_on_outlined,

                  color:
                      Color(
                    0xFF2563EB,
                  ),

                  size:
                      20,

                ),

                SizedBox(
                  width: 8,
                ),

                Expanded(

                  child:
                      Text(

                    'O entregador está levando seu pedido até você.',

                    style:
                        TextStyle(

                      fontSize:
                          13,

                      color:
                          Colors.black87,

                    ),

                  ),

                ),

              ],

            ),

          ),


          const SizedBox(
            height: 12,
          ),


          Container(

            padding:
                const EdgeInsets.symmetric(

              horizontal:
                  12,

              vertical:
                  7,

            ),

            decoration:
                BoxDecoration(

              color:
                  const Color(
                0xFFDBEAFE,
              ),

              borderRadius:
                  BorderRadius.circular(
                20,
              ),

            ),

            child:
                const Row(

              mainAxisSize:
                  MainAxisSize.min,

              children: [

                Icon(

                  Icons.access_time_rounded,

                  size:
                      16,

                  color:
                      Color(
                    0xFF1D4ED8,
                  ),

                ),

                SizedBox(
                  width: 6,
                ),

                Text(

                  'Em rota de entrega',

                  style:
                      TextStyle(

                    color:
                        Color(
                      0xFF1D4ED8,
                    ),

                    fontSize:
                        12,

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

              ],

            ),

          ),

        ],

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
        statusAtivo(
      status,
    );


    const laranja =
        Color(
      0xFFF97316,
    );


    return Row(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

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

                color:
                    ativo
                        ? laranja
                        : Colors.grey.shade300,

              ),

              child:
                  Icon(

                icone,

                color:
                    ativo
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

                color:
                    ativo
                        ? laranja
                        : Colors.grey.shade300,

              ),

          ],

        ),


        const SizedBox(
          width: 15,
        ),


        Expanded(

          child:
              Padding(

            padding:
                const EdgeInsets.only(
              top: 10,
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

