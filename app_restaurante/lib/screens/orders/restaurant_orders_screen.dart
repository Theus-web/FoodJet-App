import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/order_service.dart';
import '../../services/socket_service.dart';

class RestaurantOrdersScreen extends StatefulWidget {
  final String restauranteId;

  const RestaurantOrdersScreen({
    super.key,
    required this.restauranteId,
  });

  @override
  State<RestaurantOrdersScreen> createState() =>
      _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState
    extends State<RestaurantOrdersScreen> {
  final OrderService _orderService = OrderService();

  final SocketService _socketService =
      SocketService();

  List<dynamic> _pedidos = [];

  bool _carregando = true;
  bool _atualizando = false;
  bool _socketConectado = false;

  String _filtro = 'TODOS';

  // Evita recarregamentos simultâneos
  bool _recarregandoAutomaticamente = false;

  @override
  void initState() {
    super.initState();

    _inicializar();
  }

  // ============================================================
  // INICIALIZAÇÃO
  // ============================================================

  Future<void> _inicializar() async {
    await _carregarPedidos();

    if (!mounted) return;

    _conectarSocket();
  }

  // ============================================================
  // SOCKET.IO
  // ============================================================

  void _conectarSocket() {
    final restauranteId =
        widget.restauranteId.trim();

    if (restauranteId.isEmpty) {
      print(
        'FOODJET SOCKET: restauranteId vazio.',
      );

      return;
    }

    print(
      'FOODJET SOCKET: conectando restaurante $restauranteId',
    );

    _socketService.conectar(
      restauranteId: restauranteId,
      onNovoPedido: _receberNovoPedido,
    );

    if (mounted) {
      setState(() {
        _socketConectado = true;
      });
    }
  }

  // ============================================================
  // RECEBER NOVO PEDIDO
  // ============================================================

  Future<void> _receberNovoPedido(
    dynamic pedidoRecebido,
  ) async {
    print('==========================================');
    print('FOODJET RESTAURANTE');
    print('NOVO PEDIDO RECEBIDO PELO SOCKET');
    print(pedidoRecebido);
    print('==========================================');

    if (!mounted) return;

    // Primeiro tentamos inserir imediatamente o pedido
    // recebido pelo Socket.IO.
    if (pedidoRecebido is Map) {
      final pedidoMap =
          Map<String, dynamic>.from(
        pedidoRecebido,
      );

      final idNovo =
          _valorString(
            pedidoMap,
            [
              'id',
              '_id',
              'pedidoId',
            ],
          );

      if (idNovo != null &&
          idNovo.isNotEmpty) {
        final existe = _pedidos.any(
          (pedido) {
            final idExistente =
                _valorString(
              pedido,
              [
                'id',
                '_id',
                'pedidoId',
              ],
            );

            return idExistente == idNovo;
          },
        );

        if (!existe) {
          setState(() {
            _pedidos = [
              pedidoMap,
              ..._pedidos,
            ];
          });
        }
      }
    }

    // Depois sincronizamos com a API.
    // Isso garante que o card tenha todos os dados
    // mesmo que o Socket envie somente parte do pedido.
    await _sincronizarPedidosAutomaticamente();

    if (!mounted) return;

    _mostrarNovoPedido();
  }

  // ============================================================
  // SINCRONIZAR PEDIDOS
  // ============================================================

  Future<void>
      _sincronizarPedidosAutomaticamente() async {
    if (_recarregandoAutomaticamente) {
      return;
    }

    _recarregandoAutomaticamente = true;

    try {
      final pedidos =
          await _orderService
              .buscarPedidosRestaurante(
        widget.restauranteId,
      );

      if (!mounted) return;

      setState(() {
        _pedidos = pedidos;
      });
    } catch (e) {
      print(
        'FOODJET: erro na sincronização automática: $e',
      );
    } finally {
      _recarregandoAutomaticamente = false;
    }
  }

  // ============================================================
  // NOTIFICAÇÃO DE NOVO PEDIDO
  // ============================================================

  void _mostrarNovoPedido() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration:
              const Duration(seconds: 4),
          backgroundColor:
              const Color(0xFFF97316),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Novo pedido recebido!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _socketService.desconectar();

    super.dispose();
  }

  // ============================================================
  // CARREGAR PEDIDOS
  // ============================================================

  Future<void> _carregarPedidos() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
    });

    try {
      final pedidos =
          await _orderService
              .buscarPedidosRestaurante(
        widget.restauranteId,
      );

      if (!mounted) return;

      setState(() {
        _pedidos = pedidos;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        'Não foi possível carregar os pedidos.',
        erro: true,
      );

      print(
        'FOODJET - erro ao carregar pedidos: $e',
      );
    }
  }

  // ============================================================
  // ATUALIZAR STATUS
  // ============================================================

  Future<void> _atualizarStatus(
    dynamic pedido,
    String novoStatus,
  ) async {
    if (_atualizando) return;

    final String? pedidoId =
        _valorString(
      pedido,
      [
        'id',
        '_id',
        'pedidoId',
      ],
    );

    if (pedidoId == null ||
        pedidoId.isEmpty) {
      _mostrarMensagem(
        'ID do pedido não encontrado.',
        erro: true,
      );

      return;
    }

    setState(() {
      _atualizando = true;
    });

    try {
      final sucesso =
          await _orderService
              .atualizarStatusPedido(
        pedidoId,
        novoStatus,
      );

      if (!mounted) return;

      if (!sucesso) {
        throw Exception(
          'API não confirmou a atualização.',
        );
      }

      _mostrarMensagem(
        'Pedido atualizado para '
        '${_nomeStatus(novoStatus)}.',
      );

      await _carregarPedidos();
    } catch (e) {
      if (!mounted) return;

      print(
        'FOODJET - erro status pedido: $e',
      );

      _mostrarMensagem(
        'Erro ao atualizar o pedido.',
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _atualizando = false;
        });
      }
    }
  }

  // ============================================================
  // FILTRO
  // ============================================================

  List<dynamic> get _pedidosFiltrados {
    if (_filtro == 'TODOS') {
      return _pedidos;
    }

    return _pedidos.where(
      (pedido) {
        final status =
            (_valorString(
                  pedido,
                  ['status'],
                ) ??
                '')
            .toUpperCase();

        if (_filtro == 'AGUARDANDO') {
          return [
            'AGUARDANDO',
            'AGUARDANDO_RESTAURANTE',
            'PENDENTE',
            'NOVO',
          ].contains(status);
        }

        if (_filtro == 'PREPARANDO') {
          return [
            'ACEITO',
            'PREPARANDO',
            'EM_PREPARO',
            'PREPARANDO_PEDIDO',
          ].contains(status);
        }

        if (_filtro == 'PRONTO') {
          return [
            'PRONTO',
            'PRONTO_PARA_ENTREGA',
          ].contains(status);
        }

        if (_filtro ==
            'SAIU_PARA_ENTREGA') {
          return [
            'SAIU_PARA_ENTREGA',
            'EM_ENTREGA',
          ].contains(status);
        }

        if (_filtro == 'CONCLUIDO') {
          return [
            'CONCLUIDO',
            'ENTREGUE',
          ].contains(status);
        }

        return status == _filtro;
      },
    ).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF171717),
        title: Row(
          children: [
            const Text(
              'Pedidos',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            _indicadorSocket(),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando
                ? null
                : _carregarPedidos,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color:
            const Color(0xFFF97316),
        onRefresh: _carregarPedidos,
        child: Column(
          children: [
            _cabecalhoResumo(),
            _filtros(),
            Expanded(
              child:
                  _conteudoPedidos(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INDICADOR SOCKET
  // ============================================================

  Widget _indicadorSocket() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _socketConectado
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFEF2F2),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration:
                BoxDecoration(
              shape: BoxShape.circle,
              color: _socketConectado
                  ? const Color(
                      0xFF16A34A,
                    )
                  : const Color(
                      0xFFDC2626,
                    ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _socketConectado
                ? 'Online'
                : 'Offline',
            style: TextStyle(
              fontSize: 9,
              fontWeight:
                  FontWeight.w800,
              color: _socketConectado
                  ? const Color(
                      0xFF15803D,
                    )
                  : const Color(
                      0xFFB91C1C,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CABEÇALHO
  // ============================================================

  Widget _cabecalhoResumo() {
    final pendentes =
        _contarStatus([
      'AGUARDANDO',
      'AGUARDANDO_RESTAURANTE',
      'PENDENTE',
      'NOVO',
    ]);

    final preparando =
        _contarStatus([
      'ACEITO',
      'PREPARANDO',
      'EM_PREPARO',
      'PREPARANDO_PEDIDO',
    ]);

    final prontos =
        _contarStatus([
      'PRONTO',
      'PRONTO_PARA_ENTREGA',
    ]);

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: _cardResumo(
              titulo: 'Novos',
              valor: pendentes,
              icone: Icons
                  .notifications_active_rounded,
              cor:
                  const Color(0xFFF97316),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _cardResumo(
              titulo: 'Preparando',
              valor: preparando,
              icone:
                  Icons.restaurant_rounded,
              cor:
                  const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _cardResumo(
              titulo: 'Prontos',
              valor: prontos,
              icone:
                  Icons.check_circle_rounded,
              cor:
                  const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardResumo({
    required String titulo,
    required int valor,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.04),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(
                  color: cor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Icon(
                  icone,
                  color: cor,
                  size: 19,
                ),
              ),
              const Spacer(),
              Text(
                '$valor',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w900,
                  color: cor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            titulo,
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF6B7280),
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTROS
  // ============================================================

  Widget _filtros() {
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: [
          _filtroBotao(
            'TODOS',
            'Todos',
            Icons.list_alt_rounded,
          ),
          _filtroBotao(
            'AGUARDANDO',
            'Novos',
            Icons
                .notifications_active_rounded,
          ),
          _filtroBotao(
            'PREPARANDO',
            'Preparando',
            Icons.restaurant_rounded,
          ),
          _filtroBotao(
            'PRONTO',
            'Prontos',
            Icons
                .check_circle_outline_rounded,
          ),
          _filtroBotao(
            'SAIU_PARA_ENTREGA',
            'Em entrega',
            Icons
                .delivery_dining_rounded,
          ),
          _filtroBotao(
            'CONCLUIDO',
            'Concluídos',
            Icons.done_all_rounded,
          ),
        ],
      ),
    );
  }

  Widget _filtroBotao(
    String valor,
    String titulo,
    IconData icone,
  ) {
    final selecionado =
        _filtro == valor;

    return Padding(
      padding:
          const EdgeInsets.only(
        right: 8,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _filtro = valor;
          });
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          decoration:
              BoxDecoration(
            color: selecionado
                ? const Color(
                    0xFFF97316,
                  )
                : Colors.white,
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: selecionado
                  ? const Color(
                      0xFFF97316,
                    )
                  : const Color(
                      0xFFE5E7EB,
                    ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icone,
                size: 17,
                color: selecionado
                    ? Colors.white
                    : const Color(
                        0xFF6B7280,
                      ),
              ),
              const SizedBox(
                width: 7,
              ),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                  color: selecionado
                      ? Colors.white
                      : const Color(
                          0xFF374151,
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
  // CONTEÚDO
  // ============================================================

  Widget _conteudoPedidos() {
    if (_carregando) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              Color(0xFFF97316),
        ),
      );
    }

    final pedidos =
        _pedidosFiltrados;

    if (pedidos.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 380,
            child: _estadoVazio(),
          ),
        ],
      );
    }

    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        30,
      ),
      itemCount: pedidos.length,
      itemBuilder:
          (context, index) {
        return _cardPedido(
          pedidos[index],
        );
      },
    );
  }

  Widget _estadoVazio() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFFFEDD5),
              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),
            child: const Icon(
              Icons
                  .receipt_long_rounded,
              size: 44,
              color:
                  Color(0xFFF97316),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Nenhum pedido encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Os novos pedidos aparecerão aqui.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed:
                _carregarPedidos,
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(
                0xFFF97316,
              ),
              foregroundColor:
                  Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
            ),
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label: const Text(
              'Atualizar pedidos',
              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DO PEDIDO
  // ============================================================

  Widget _cardPedido(
    dynamic pedido,
  ) {
    final id =
        _valorString(
              pedido,
              [
                'id',
                '_id',
                'pedidoId',
              ],
            ) ??
            '---';

    final status =
        (_valorString(
              pedido,
              ['status'],
            ) ??
            'AGUARDANDO')
        .toUpperCase();

    final pagamento =
        _valorString(
              pedido,
              [
                'pagamento',
                'formaPagamento',
              ],
            ) ??
            'PIX';

    final total =
        _valorDouble(
      pedido,
      ['total'],
    );

    final subtotal =
        _valorDouble(
      pedido,
      ['subtotal'],
    );

    final taxa =
        _valorDouble(
      pedido,
      [
        'taxaEntrega',
        'taxa',
      ],
    );

    final itens =
        _valorLista(
      pedido,
      [
        'itens',
        'produtos',
      ],
    );

    final endereco =
        _valorMapa(
      pedido,
      ['endereco'],
    );

    final clienteNome =
        _valorString(
              pedido,
              [
                'clienteNome',
                'nomeCliente',
                'cliente',
              ],
            ) ??
            'Cliente';

    final corStatus =
        _corStatus(status);

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.035,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    color:
                        corStatus.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    Icons
                        .receipt_long_rounded,
                    color: corStatus,
                    size: 24,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Pedido #${_resumirId(id)}',
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .w900,
                          color:
                              Color(0xFF171717),
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        clienteNome,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 13,
                          color:
                              Color(0xFF6B7280),
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(
                  status,
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            const Divider(
              height: 1,
              color:
                  Color(0xFFF0F0F0),
            ),
            const SizedBox(
              height: 14,
            ),
            if (itens.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons
                        .shopping_bag_outlined,
                    size: 18,
                    color:
                        Color(0xFF6B7280),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    '${itens.length} item(ns)',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              ...itens
                  .take(5)
                  .map(
                    (item) =>
                        _itemPedido(
                      item,
                    ),
                  ),
            ],
            const SizedBox(
              height: 12,
            ),
            Container(
              padding:
                  const EdgeInsets.all(
                13,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFFF9FAFB),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Column(
                children: [
                  _linhaValor(
                    'Subtotal',
                    subtotal,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  _linhaValor(
                    'Entrega',
                    taxa,
                  ),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    child: Divider(
                      height: 1,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Total',
                        style:
                            TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight
                                  .w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _moeda(total),
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight
                                  .w900,
                          color:
                              Color(0xFFF97316),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              children: [
                const Icon(
                  Icons.payment_rounded,
                  size: 17,
                  color:
                      Color(0xFF6B7280),
                ),
                const SizedBox(
                  width: 7,
                ),
                Text(
                  'Pagamento: ${_nomePagamento(pagamento)}',
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF6B7280),
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (endereco.isNotEmpty) ...[
              const SizedBox(
                height: 9,
              ),
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Icon(
                    Icons
                        .location_on_outlined,
                    size: 17,
                    color:
                        Color(0xFF6B7280),
                  ),
                  const SizedBox(
                    width: 7,
                  ),
                  Expanded(
                    child: Text(
                      _formatarEndereco(
                        endereco,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF6B7280),
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(
              height: 16,
            ),
            _botoesStatus(
              pedido,
              status,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ITEM
  // ============================================================

  Widget _itemPedido(
    dynamic item,
  ) {
    final nome =
        _valorString(
              item,
              [
                'nome',
                'produto',
                'nomeProduto',
              ],
            ) ??
            'Produto';

    final quantidade =
        _valorInt(
      item,
      [
        'quantidade',
        'qtd',
      ],
    );

    final preco =
        _valorDouble(
      item,
      [
        'preco',
        'valor',
        'precoUnitario',
      ],
    );

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFFFF7ED),
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),
            child: Text(
              '$quantidade',
              style:
                  const TextStyle(
                color:
                    Color(0xFFF97316),
                fontSize: 12,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child: Text(
              nome,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          Text(
            _moeda(
              preco * quantidade,
            ),
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTÕES DE STATUS
  // ============================================================

  Widget _botoesStatus(
    dynamic pedido,
    String status,
  ) {
    switch (status) {
      case 'AGUARDANDO':
      case 'AGUARDANDO_RESTAURANTE':
      case 'PENDENTE':
      case 'NOVO':
        return Row(
          children: [
            Expanded(
              child: _botaoStatus(
                texto: 'Recusar',
                icone:
                    Icons.close_rounded,
                cor: Colors.red,
                preenchido: false,
                onTap: () =>
                    _confirmarStatus(
                  pedido,
                  'CANCELADO',
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              flex: 2,
              child: _botaoStatus(
                texto:
                    'Aceitar pedido',
                icone:
                    Icons.check_rounded,
                cor:
                    const Color(0xFFF97316),
                preenchido: true,
                onTap: () =>
                    _atualizarStatus(
                  pedido,
                  'ACEITO',
                ),
              ),
            ),
          ],
        );

      case 'ACEITO':
        return SizedBox(
          width: double.infinity,
          child: _botaoStatus(
            texto:
                'Iniciar preparo',
            icone:
                Icons.restaurant_rounded,
            cor:
                const Color(0xFF2563EB),
            preenchido: true,
            onTap: () =>
                _atualizarStatus(
              pedido,
              'PREPARANDO',
            ),
          ),
        );

      case 'PREPARANDO':
      case 'EM_PREPARO':
      case 'PREPARANDO_PEDIDO':
        return SizedBox(
          width: double.infinity,
          child: _botaoStatus(
            texto:
                'Marcar como pronto',
            icone: Icons
                .check_circle_outline_rounded,
            cor:
                const Color(0xFF16A34A),
            preenchido: true,
            onTap: () =>
                _atualizarStatus(
              pedido,
              'PRONTO',
            ),
          ),
        );

      case 'PRONTO':
      case 'PRONTO_PARA_ENTREGA':
        return SizedBox(
          width: double.infinity,
          child: _botaoStatus(
            texto:
                'Enviar para entrega',
            icone: Icons
                .delivery_dining_rounded,
            cor:
                const Color(0xFF2563EB),
            preenchido: true,
            onTap: () =>
                _atualizarStatus(
              pedido,
              'SAIU_PARA_ENTREGA',
            ),
          ),
        );

      case 'SAIU_PARA_ENTREGA':
      case 'EM_ENTREGA':
        return Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(
            12,
          ),
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFEFF6FF),
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons
                    .delivery_dining_rounded,
                color:
                    Color(0xFF2563EB),
              ),
              SizedBox(
                width: 9,
              ),
              Expanded(
                child: Text(
                  'Pedido está com o entregador.',
                  style:
                      TextStyle(
                    color:
                        Color(0xFF1D4ED8),
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );

      case 'CONCLUIDO':
      case 'ENTREGUE':
        return Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(
            12,
          ),
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFF0FDF4),
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons
                    .check_circle_rounded,
                color:
                    Color(0xFF16A34A),
              ),
              SizedBox(
                width: 9,
              ),
              Text(
                'Pedido concluído',
                style:
                    TextStyle(
                  color:
                      Color(0xFF15803D),
                  fontWeight:
                      FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

      case 'CANCELADO':
      case 'RECUSADO':
        return Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(
            12,
          ),
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFFEF2F2),
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.cancel_rounded,
                color:
                    Color(0xFFDC2626),
              ),
              SizedBox(
                width: 9,
              ),
              Text(
                'Pedido cancelado',
                style:
                    TextStyle(
                  color:
                      Color(0xFFB91C1C),
                  fontWeight:
                      FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

      default:
        return SizedBox(
          width: double.infinity,
          child: _botaoStatus(
            texto:
                'Atualizar pedido',
            icone:
                Icons.refresh_rounded,
            cor:
                const Color(0xFFF97316),
            preenchido: true,
            onTap: () =>
                _atualizarStatus(
              pedido,
              'ACEITO',
            ),
          ),
        );
    }
  }

  Widget _botaoStatus({
    required String texto,
    required IconData icone,
    required Color cor,
    required bool preenchido,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child:
          ElevatedButton.icon(
        onPressed:
            _atualizando
                ? null
                : onTap,
        style:
            ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
              preenchido
                  ? cor
                  : Colors.white,
          foregroundColor:
              preenchido
                  ? Colors.white
                  : cor,
          disabledBackgroundColor:
              Colors.grey.shade300,
          side: preenchido
              ? null
              : BorderSide(
                  color: cor,
                  width: 1.2,
                ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),
        ),
        icon: Icon(
          icone,
          size: 19,
        ),
        label: Text(
          texto,
          style:
              const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONFIRMAÇÃO
  // ============================================================

  Future<void> _confirmarStatus(
    dynamic pedido,
    String status,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Recusar pedido?',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: const Text(
            'Tem certeza que deseja recusar este pedido?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child: const Text(
                'Voltar',
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Recusar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await _atualizarStatus(
        pedido,
        status,
      );
    }
  }

  // ============================================================
  // CONTADORES
  // ============================================================

  int _contarStatus(
    List<String> statusPermitidos,
  ) {
    return _pedidos.where(
      (pedido) {
        final status =
            (_valorString(
                  pedido,
                  ['status'],
                ) ??
                '')
            .toUpperCase();

        return statusPermitidos
            .contains(status);
      },
    ).length;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _linhaValor(
    String titulo,
    double valor,
  ) {
    return Row(
      children: [
        Text(
          titulo,
          style:
              const TextStyle(
            fontSize: 12,
            color:
                Color(0xFF6B7280),
            fontWeight:
                FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          _moeda(valor),
          style:
              const TextStyle(
            fontSize: 12,
            color:
                Color(0xFF374151),
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }

  dynamic _valor(
    dynamic objeto,
    List<String> chaves,
  ) {
    if (objeto is Map) {
      for (final chave in chaves) {
        if (objeto.containsKey(chave)) {
          return objeto[chave];
        }
      }
    }

    return null;
  }

  String? _valorString(
    dynamic objeto,
    List<String> chaves,
  ) {
    final valor =
        _valor(objeto, chaves);

    if (valor == null) {
      return null;
    }

    return valor.toString();
  }

  double _valorDouble(
    dynamic objeto,
    List<String> chaves,
  ) {
    final valor =
        _valor(objeto, chaves);

    if (valor == null) {
      return 0;
    }

    if (valor is num) {
      return valor.toDouble();
    }

    return double.tryParse(
          valor
              .toString()
              .replaceAll(',', '.'),
        ) ??
        0;
  }

  int _valorInt(
    dynamic objeto,
    List<String> chaves,
  ) {
    final valor =
        _valor(objeto, chaves);

    if (valor == null) {
      return 1;
    }

    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(
          valor.toString(),
        ) ??
        1;
  }

  List<dynamic> _valorLista(
    dynamic objeto,
    List<String> chaves,
  ) {
    final valor =
        _valor(objeto, chaves);

    if (valor is List) {
      return valor;
    }

    return [];
  }

  Map<String, dynamic> _valorMapa(
    dynamic objeto,
    List<String> chaves,
  ) {
    final valor =
        _valor(objeto, chaves);

    if (valor is Map) {
      return Map<String, dynamic>.from(
        valor,
      );
    }

    return {};
  }

  // ============================================================
  // STATUS
  // ============================================================

  Color _corStatus(
    String status,
  ) {
    switch (status) {
      case 'AGUARDANDO':
      case 'AGUARDANDO_RESTAURANTE':
      case 'PENDENTE':
      case 'NOVO':
        return const Color(
          0xFFF97316,
        );

      case 'ACEITO':
      case 'PREPARANDO':
      case 'EM_PREPARO':
      case 'PREPARANDO_PEDIDO':
        return const Color(
          0xFF2563EB,
        );

      case 'PRONTO':
      case 'PRONTO_PARA_ENTREGA':
        return const Color(
          0xFF16A34A,
        );

      case 'SAIU_PARA_ENTREGA':
      case 'EM_ENTREGA':
        return const Color(
          0xFF7C3AED,
        );

      case 'CONCLUIDO':
      case 'ENTREGUE':
        return const Color(
          0xFF16A34A,
        );

      case 'CANCELADO':
      case 'RECUSADO':
        return const Color(
          0xFFDC2626,
        );

      default:
        return const Color(
          0xFF6B7280,
        );
    }
  }

  Widget _statusBadge(
    String status,
  ) {
    final cor =
        _corStatus(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color: cor.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        _nomeStatus(status),
        style:
            TextStyle(
          color: cor,
          fontSize: 10,
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  String _nomeStatus(
    String status,
  ) {
    switch (status) {
      case 'AGUARDANDO':
      case 'AGUARDANDO_RESTAURANTE':
      case 'PENDENTE':
      case 'NOVO':
        return 'NOVO';

      case 'ACEITO':
        return 'ACEITO';

      case 'PREPARANDO':
      case 'EM_PREPARO':
      case 'PREPARANDO_PEDIDO':
        return 'PREPARANDO';

      case 'PRONTO':
      case 'PRONTO_PARA_ENTREGA':
        return 'PRONTO';

      case 'SAIU_PARA_ENTREGA':
      case 'EM_ENTREGA':
        return 'EM ENTREGA';

      case 'CONCLUIDO':
      case 'ENTREGUE':
        return 'CONCLUÍDO';

      case 'CANCELADO':
      case 'RECUSADO':
        return 'CANCELADO';

      default:
        return status;
    }
  }

  String _nomePagamento(
    String pagamento,
  ) {
    switch (pagamento.toUpperCase()) {
      case 'PIX':
        return 'PIX';

      case 'DINHEIRO':
        return 'Dinheiro';

      case 'CARTAO':
      case 'CARTÃO':
        return 'Cartão';

      default:
        return pagamento;
    }
  }

  // ============================================================
  // ENDEREÇO
  // ============================================================

  String _formatarEndereco(
    Map<String, dynamic> endereco,
  ) {
    final rua =
        endereco['rua']
                ?.toString() ??
            '';

    final numero =
        endereco['numero']
                ?.toString() ??
            '';

    final bairro =
        endereco['bairro']
                ?.toString() ??
            '';

    final complemento =
        endereco['complemento']
                ?.toString() ??
            '';

    final cidade =
        endereco['cidade']
                ?.toString() ??
            '';

    final partes =
        <String>[];

    if (rua.isNotEmpty) {
      partes.add(
        numero.isNotEmpty
            ? '$rua, $numero'
            : rua,
      );
    }

    if (bairro.isNotEmpty) {
      partes.add(bairro);
    }

    if (complemento.isNotEmpty) {
      partes.add(complemento);
    }

    if (cidade.isNotEmpty) {
      partes.add(cidade);
    }

    if (partes.isEmpty) {
      return 'Endereço não informado';
    }

    return partes.join(' • ');
  }

  // ============================================================
  // FORMATADORES
  // ============================================================

  String _moeda(
    double valor,
  ) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _resumirId(
    String id,
  ) {
    if (id.length <= 8) {
      return id;
    }

    return id.substring(
      id.length - 8,
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mostrarMensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(mensagem),
          backgroundColor:
              erro
                  ? Colors.red.shade700
                  : const Color(
                      0xFF16A34A,
                    ),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      );
  }
}