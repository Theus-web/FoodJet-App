
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

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? timer;
  IO.Socket? socket;

  bool socketConectado = false;
  bool carregando = true;
  bool buscando = false;

  // IMPORTANTE:
  // Assim que o pedido chegar nesta tela, o estado inicial
  // já será "Aguardando confirmação do restaurante".
  String statusPedido = 'AGUARDANDO_RESTAURANTE';

  Map<String, dynamic>? pedido;

  @override
  void initState() {
    super.initState();

    debugPrint('==============================================');
    debugPrint('📦 ORDER TRACKING INICIADO');
    debugPrint('📦 PEDIDO: ${widget.pedidoId}');
    debugPrint('📦 STATUS INICIAL: AGUARDANDO_RESTAURANTE');
    debugPrint('==============================================');

    buscarPedido();
    conectarSocket();

    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        buscarPedido();
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    desconectarSocket();
    super.dispose();
  }

  // ============================================================
  // SOCKET.IO
  // ============================================================

  void conectarSocket() {
    try {
      debugPrint('🔌 CONECTANDO SOCKET.IO...');

      socket = IO.io(
        'https://foodjet-backend.onrender.com',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .build(),
      );

      socket!.onConnect((_) {
        debugPrint('🟢 SOCKET.IO CONECTADO');
        debugPrint('📦 PEDIDO: ${widget.pedidoId}');

        if (mounted) {
          setState(() {
            socketConectado = true;
          });
        }

        socket!.emit(
          'entrar_pedido',
          widget.pedidoId.toString(),
        );

        debugPrint(
          '📡 ENTRANDO NA SALA pedido_${widget.pedidoId}',
        );
      });

      socket!.on(
        'status_pedido_atualizado',
        (dados) {
          debugPrint('📡 STATUS DO PEDIDO RECEBIDO VIA SOCKET');
          debugPrint('📦 $dados');

          processarAtualizacaoSocket(dados);
        },
      );

      socket!.on(
        'pagamento_atualizado',
        (dados) {
          debugPrint('💳 PAGAMENTO ATUALIZADO VIA SOCKET');
          debugPrint('📦 $dados');

          // O pagamento pode ser aprovado antes de o pedido
          // estar disponível. Neste caso o polling continua.
          buscarPedido();
        },
      );

      socket!.on(
        'connect_error',
        (erro) {
          debugPrint('❌ SOCKET CONNECT ERROR: $erro');
        },
      );

      socket!.onDisconnect((_) {
        debugPrint('🔴 SOCKET.IO DESCONECTADO');

        if (mounted) {
          setState(() {
            socketConectado = false;
          });
        }
      });

      socket!.on(
        'reconnect',
        (_) {
          debugPrint('🔄 SOCKET.IO RECONECTADO');
        },
      );

      socket!.on(
        'error',
        (erro) {
          debugPrint('❌ SOCKET ERROR: $erro');
        },
      );

      socket!.connect();
    } catch (erro) {
      debugPrint(
        '❌ ERRO AO CONFIGURAR SOCKET.IO: $erro',
      );

      if (mounted) {
        setState(() {
          socketConectado = false;
        });
      }
    }
  }

  void desconectarSocket() {
    try {
      socket?.off('status_pedido_atualizado');
      socket?.off('pagamento_atualizado');
      socket?.off('connect');
      socket?.off('disconnect');
      socket?.off('connect_error');
      socket?.off('reconnect');
      socket?.off('error');

      socket?.disconnect();
      socket?.dispose();

      socket = null;
    } catch (erro) {
      debugPrint(
        '⚠️ ERRO AO DESCONECTAR SOCKET: $erro',
      );
    }
  }

  // ============================================================
  // EXTRAIR PEDIDO DO SOCKET
  // ============================================================

  Map<String, dynamic>? extrairPedido(dynamic dados) {
    if (dados is Map) {
      final mapa = Map<String, dynamic>.from(dados);

      if (mapa['pedido'] is Map) {
        return Map<String, dynamic>.from(
          mapa['pedido'],
        );
      }

      if (mapa['order'] is Map) {
        return Map<String, dynamic>.from(
          mapa['order'],
        );
      }

      if (mapa['data'] is Map) {
        final data = Map<String, dynamic>.from(
          mapa['data'],
        );

        if (data['pedido'] is Map) {
          return Map<String, dynamic>.from(
            data['pedido'],
          );
        }

        if (data['order'] is Map) {
          return Map<String, dynamic>.from(
            data['order'],
          );
        }

        return data;
      }

      return mapa;
    }

    return null;
  }

  // ============================================================
  // PROCESSAR SOCKET
  // ============================================================

  void processarAtualizacaoSocket(dynamic dados) {
    try {
      final pedidoRecebido = extrairPedido(dados);

      if (pedidoRecebido == null) {
        debugPrint(
          '⚠️ SOCKET: pedido inválido.',
        );
        return;
      }

      final idRecebido =
          pedidoRecebido['id'] ??
          pedidoRecebido['pedidoId'] ??
          pedidoRecebido['pedido_id'] ??
          pedidoRecebido['orderId'] ??
          pedidoRecebido['order_id'];

      if (idRecebido != null) {
        if (idRecebido.toString() !=
            widget.pedidoId.toString()) {
          debugPrint(
            '⚠️ SOCKET: pedido diferente ignorado.',
          );
          return;
        }
      }

      final statusRecebido = extrairStatus(
        pedidoRecebido,
      );

      final novoStatus = normalizarStatus(
        statusRecebido,
      );

      debugPrint(
        '📦 SOCKET STATUS ORIGINAL: $statusRecebido',
      );

      debugPrint(
        '📦 SOCKET STATUS NORMALIZADO: $novoStatus',
      );

      if (!mounted) return;

      setState(() {
        pedido = pedidoRecebido;
        statusPedido = novoStatus;
        carregando = false;
      });

      if (novoStatus == 'AGUARDANDO_RESTAURANTE') {
        debugPrint(
          '🟠 PEDIDO AGUARDANDO CONFIRMAÇÃO DO RESTAURANTE',
        );
      }

      if (novoStatus == 'CONFIRMADO') {
        debugPrint(
          '🟢 RESTAURANTE ACEITOU O PEDIDO',
        );
      }

      if (novoStatus == 'CANCELADO') {
        debugPrint(
          '🔴 PEDIDO CANCELADO/RECUSADO',
        );
      }
    } catch (erro) {
      debugPrint(
        '❌ ERRO PROCESSANDO SOCKET: $erro',
      );
    }
  }

  // ============================================================
  // EXTRAIR STATUS
  // ============================================================

  dynamic extrairStatus(
    Map<String, dynamic> dados,
  ) {
    final possibilidades = [
      'status',
      'statusPedido',
      'status_pedido',
      'situacao',
      'situacaoPedido',
      'situacao_pedido',
      'estado',
    ];

    for (final campo in possibilidades) {
      if (dados[campo] != null) {
        return dados[campo];
      }
    }

    return null;
  }

  // ============================================================
  // NORMALIZAR STATUS
  // ============================================================

  String normalizarStatus(dynamic valor) {
    if (valor == null) {
      return 'AGUARDANDO_RESTAURANTE';
    }

    final status = valor
        .toString()
        .trim()
        .toUpperCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    // ==========================================================
    // AGUARDANDO RESTAURANTE
    // ==========================================================

    if ([
      'AGUARDANDO_RESTAURANTE',
      'AGUARDANDO_CONFIRMACAO',
      'AGUARDANDO_CONFIRMAR',
      'AGUARDANDO_CONFIRMACAO_RESTAURANTE',
      'AGUARDANDO_CONFIRMAR_RESTAURANTE',
      'AGUARDANDO_ACEITE',
      'AGUARDANDO_ACEITACAO',
      'PENDENTE_RESTAURANTE',
      'PENDENTE_ACEITACAO',
      'WAITING_RESTAURANT',
      'WAITING_CONFIRMATION',
    ].contains(status)) {
      return 'AGUARDANDO_RESTAURANTE';
    }

    // ==========================================================
    // CONFIRMADO
    // ==========================================================

    if ([
      'ACEITO',
      'ACEITADO',
      'CONFIRMADO',
      'CONFIRMADO_RESTAURANTE',
      'RESTAURANTE_ACEITOU',
      'PEDIDO_ACEITO',
      'ACEITO_RESTAURANTE',
    ].contains(status)) {
      return 'CONFIRMADO';
    }

    // ==========================================================
    // PREPARANDO
    // ==========================================================

    if ([
      'EM_PREPARO',
      'PREPARANDO',
      'PREPARO',
      'EM_PREPARACAO',
    ].contains(status)) {
      return 'PREPARANDO';
    }

    // ==========================================================
    // PRONTO
    // ==========================================================

    if ([
      'PRONTO',
      'PRONTO_PARA_ENTREGA',
      'AGUARDANDO_ENTREGADOR',
    ].contains(status)) {
      return 'PRONTO';
    }

    // ==========================================================
    // ENTREGA
    // ==========================================================

    if ([
      'SAIU_PARA_ENTREGA',
      'EM_ENTREGA',
      'A_CAMINHO',
      'EM_ROTA',
    ].contains(status)) {
      return 'EM_ENTREGA';
    }

    // ==========================================================
    // ENTREGUE
    // ==========================================================

    if ([
      'ENTREGUE',
      'FINALIZADO',
      'CONCLUIDO',
    ].contains(status)) {
      return 'ENTREGUE';
    }

    // ==========================================================
    // CANCELADO
    // ==========================================================

    if ([
      'CANCELADO',
      'CANCELADA',
      'CANCELLED',
      'RECUSADO',
      'RECUSADA',
      'REJEITADO',
      'REJEITADA',
    ].contains(status)) {
      return 'CANCELADO';
    }

    return status;
  }

  // ============================================================
  // BUSCAR PEDIDO
  // ============================================================

  Future<void> buscarPedido() async {
    if (buscando) return;

    buscando = true;

    try {
      final url =
          '${Api.baseUrl}/orders/${widget.pedidoId}';

      debugPrint(
        '📡 BUSCANDO PEDIDO: $url',
      );

      final resposta = await http.get(
        Uri.parse(url),
      );

      debugPrint(
        '📡 HTTP PEDIDO: ${resposta.statusCode}',
      );

      debugPrint(
        '📦 RESPOSTA: ${resposta.body}',
      );

      if (resposta.statusCode != 200) {
        debugPrint(
          '⚠️ PEDIDO AINDA NÃO DISPONÍVEL: '
          '${resposta.statusCode}',
        );

        // Não troca o status inicial.
        // Continua mostrando:
        // "Aguardando confirmação do restaurante"
        if (mounted) {
          setState(() {
            carregando = false;
          });
        }

        return;
      }

      final dados = jsonDecode(
        resposta.body,
      );

      Map<String, dynamic>? pedidoRecebido;

      if (dados is Map) {
        final mapa = Map<String, dynamic>.from(
          dados,
        );

        if (mapa['pedido'] is Map) {
          pedidoRecebido =
              Map<String, dynamic>.from(
            mapa['pedido'],
          );
        } else if (mapa['order'] is Map) {
          pedidoRecebido =
              Map<String, dynamic>.from(
            mapa['order'],
          );
        } else if (mapa['data'] is Map) {
          final data =
              Map<String, dynamic>.from(
            mapa['data'],
          );

          if (data['pedido'] is Map) {
            pedidoRecebido =
                Map<String, dynamic>.from(
              data['pedido'],
            );
          } else {
            pedidoRecebido = data;
          }
        } else {
          pedidoRecebido = mapa;
        }
      }

      if (pedidoRecebido == null) {
        debugPrint(
          '⚠️ PEDIDO NÃO ENCONTRADO NA RESPOSTA.',
        );

        if (mounted) {
          setState(() {
            carregando = false;
          });
        }

        return;
      }

      final statusRecebido =
          extrairStatus(
        pedidoRecebido,
      );

      final novoStatus =
          normalizarStatus(
        statusRecebido,
      );

      debugPrint('==============================================');
      debugPrint(
        '📦 PEDIDO ${widget.pedidoId}',
      );
      debugPrint(
        '📦 STATUS ORIGINAL: $statusRecebido',
      );
      debugPrint(
        '📦 STATUS NORMALIZADO: $novoStatus',
      );
      debugPrint('==============================================');

      if (!mounted) return;

      setState(() {
        pedido = pedidoRecebido;
        statusPedido = novoStatus;
        carregando = false;
      });
    } catch (erro) {
      debugPrint(
        '❌ ERRO AO BUSCAR PEDIDO: $erro',
      );

      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    } finally {
      buscando = false;
    }
  }

  // ============================================================
  // TEXTO
  // ============================================================

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

  // ============================================================
  // ÍCONE
  // ============================================================

  IconData iconeStatus() {
    switch (statusPedido) {
      case 'AGUARDANDO_RESTAURANTE':
        return Icons.hourglass_top_rounded;

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

  // ============================================================
  // COR
  // ============================================================

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

  // ============================================================
  // STATUS ATIVO
  // ============================================================

  bool statusAtivo(String status) {
    final ordem = [
      'AGUARDANDO_RESTAURANTE',
      'CONFIRMADO',
      'PREPARANDO',
      'PRONTO',
      'EM_ENTREGA',
      'ENTREGUE',
    ];

    if (statusPedido == 'CANCELADO') {
      return false;
    }

    final atual = ordem.indexOf(statusPedido);
    final item = ordem.indexOf(status);

    if (atual == -1 || item == -1) {
      return false;
    }

    return item <= atual;
  }

  // ============================================================
  // PREÇO
  // ============================================================

  String formatarPreco(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const laranja = Color(0xFFF97316);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        title: const Text(
          'Acompanhar Pedido',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 15,
            ),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: socketConectado
                        ? Colors.greenAccent
                        : Colors.white54,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  socketConectado
                      ? 'ONLINE'
                      : 'OFFLINE',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: buscarPedido,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _cardStatus(),

                    const SizedBox(height: 20),

                    const Text(
                      'Status do pedido',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    _timeline(),

                    const SizedBox(height: 20),

                    if (pedido != null)
                      _informacoesPedido(),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            buscando
                                ? null
                                : buscarPedido,
                        icon: const Icon(
                          Icons.refresh,
                        ),
                        label: Text(
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
                            vertical: 16,
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

  // ============================================================
  // CARD PRINCIPAL
  // ============================================================

  Widget _cardStatus() {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: corStatus().withValues(
                  alpha: .10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconeStatus(),
                size: 50,
                color: corStatus(),
              ),
            ),

            const SizedBox(height: 15),

            Text(
              textoStatus(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.bold,
                color: corStatus(),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Pedido #${widget.pedidoId}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            if (statusPedido ==
                'AGUARDANDO_RESTAURANTE')
              _cardAguardando(),

            if (statusPedido ==
                'CONFIRMADO')
              _cardConfirmado(),

            if (statusPedido ==
                'EM_ENTREGA')
              _cardEntrega(),

            if (statusPedido ==
                'CANCELADO')
              _cardCancelado(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AGUARDANDO
  // ============================================================

  Widget _cardAguardando() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(top: 18),
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFED7AA),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.storefront,
            color: Color(0xFFF97316),
            size: 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido enviado!',
                  style: TextStyle(
                    color: Color(0xFFC2410C),
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Estamos aguardando o restaurante confirmar seu pedido.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
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
  // CONFIRMADO
  // ============================================================

  Widget _cardConfirmado() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(top: 18),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Color(0xFF16A34A),
            size: 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido aceito!',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'O restaurante aceitou seu pedido e vai começar a preparar.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
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
  // ENTREGA
  // ============================================================

  Widget _cardEntrega() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(top: 18),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.delivery_dining,
            color: Color(0xFF2563EB),
            size: 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu pedido está a caminho!',
                  style: TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'O entregador está levando seu pedido até você.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
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
  // CANCELADO
  // ============================================================

  Widget _cardCancelado() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(top: 18),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.cancel,
            color: Colors.red,
            size: 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Este pedido foi cancelado ou recusado.',
              style: TextStyle(
                color: Colors.red,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIMELINE
  // ============================================================

  Widget _timeline() {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            _statusItem(
              titulo:
                  'Aguardando confirmação do restaurante',
              status:
                  'AGUARDANDO_RESTAURANTE',
              icone:
                  Icons.hourglass_top_rounded,
            ),

            _statusItem(
              titulo:
                  'Pedido confirmado',
              status: 'CONFIRMADO',
              icone:
                  Icons.check_circle,
            ),

            _statusItem(
              titulo:
                  'Restaurante preparando',
              status: 'PREPARANDO',
              icone:
                  Icons.restaurant,
            ),

            _statusItem(
              titulo:
                  'Pedido pronto',
              status: 'PRONTO',
              icone:
                  Icons.inventory_2,
            ),

            _statusItem(
              titulo:
                  'Saiu para entrega',
              status: 'EM_ENTREGA',
              icone:
                  Icons.delivery_dining,
            ),

            _statusItem(
              titulo:
                  'Pedido entregue',
              status: 'ENTREGUE',
              icone:
                  Icons.done_all,
              ultimo: true,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMAÇÕES
  // ============================================================

  Widget _informacoesPedido() {
    final total = double.tryParse(
          (pedido!['total'] ??
                  pedido!['valor'] ??
                  pedido!['valorTotal'] ??
                  0)
              .toString(),
        ) ??
        0;

    final pagamento =
        pedido!['pagamento'] ??
            pedido!['formaPagamento'] ??
            pedido!['forma_pagamento'];

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações do pedido',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  formatarPreco(total),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            if (pagamento != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pagamento',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    pagamento.toString(),
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ITEM TIMELINE
  // ============================================================

  Widget _statusItem({
    required String titulo,
    required String status,
    required IconData icone,
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
        Column(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color: ativo
                    ? laranja
                    : Colors.grey.shade300,
              ),
              child: Icon(
                icone,
                color: ativo
                    ? Colors.white
                    : Colors.grey,
                size: 22,
              ),
            ),

            if (!ultimo)
              Container(
                width: 2,
                height: 45,
                color: ativo
                    ? laranja
                    : Colors.grey.shade300,
              ),
          ],
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(
              top: 10,
            ),
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: ativo
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: ativo
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

