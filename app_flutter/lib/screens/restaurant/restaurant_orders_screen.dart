import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api.dart';

class RestaurantOrdersScreen extends StatefulWidget {
  const RestaurantOrdersScreen({
    super.key,
  });

  @override
  State<RestaurantOrdersScreen> createState() =>
      _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState
    extends State<RestaurantOrdersScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color laranjaEscuro = Color(0xFFEA580C);
  static const Color fundo = Color(0xFFF5F5F5);

  Timer? _timer;

  bool carregando = true;
  bool atualizando = false;

  String? restauranteId;
  String? erro;

  List<Map<String, dynamic>> pedidos = [];

  @override
  void initState() {
    super.initState();

    _inicializar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // INICIALIZAÇÃO
  // ============================================================

  Future<void> _inicializar() async {
    await _carregarRestauranteId();

    if (!mounted) return;

    if (restauranteId == null ||
        restauranteId!.trim().isEmpty) {
      setState(() {
        carregando = false;
        erro =
            'Não foi possível identificar o restaurante.';
      });

      return;
    }

    await buscarPedidos();

    if (!mounted) return;

    // Atualização automática temporária.
    //
    // Depois podemos trocar completamente pelo Socket.IO
    // para receber os pedidos em tempo real.
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!atualizando) {
          buscarPedidos(
            silencioso: true,
          );
        }
      },
    );
  }

  // ============================================================
  // RESTAURANTE ID
  // ============================================================

  Future<void> _carregarRestauranteId() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      String? id =
          prefs.getString(
        'restauranteSelecionadoId',
      );

      id ??= prefs.getString(
        'restauranteId',
      );

      if (id == null || id.trim().isEmpty) {
        final dynamic idInt =
            prefs.getInt(
          'restauranteSelecionadoId',
        );

        if (idInt != null) {
          id = idInt.toString();
        }
      }

      if (id == null || id.trim().isEmpty) {
        final dynamic idInt =
            prefs.getInt(
          'restauranteId',
        );

        if (idInt != null) {
          id = idInt.toString();
        }
      }

      if (id != null &&
          id.trim().isNotEmpty) {
        restauranteId = id.trim();

        debugPrint(
          'RESTAURANTE ID PEDIDOS: $restauranteId',
        );
      } else {
        debugPrint(
          'RESTAURANTE ID NÃO ENCONTRADO.',
        );
      }
    } catch (e) {
      debugPrint(
        'ERRO AO CARREGAR RESTAURANTE ID: $e',
      );
    }
  }

  // ============================================================
  // BUSCAR PEDIDOS
  // ============================================================

  Future<void> buscarPedidos({
    bool silencioso = false,
  }) async {
    if (restauranteId == null ||
        restauranteId!.trim().isEmpty) {
      await _carregarRestauranteId();
    }

    final id = restauranteId?.trim();

    if (id == null || id.isEmpty) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        atualizando = false;
        erro =
            'Restaurante não identificado.';
      });

      return;
    }

    if (!silencioso) {
      if (mounted) {
        setState(() {
          atualizando = true;
          erro = null;
        });
      }
    }

    try {
      final uri = Uri.parse(
        '${Api.baseUrl}/orders/restaurante/$id',
      );

      debugPrint(
        'BUSCANDO PEDIDOS:',
      );

      debugPrint(
        uri.toString(),
      );

      final resposta = await http
          .get(
            uri,
            headers: {
              'Accept':
                  'application/json',
              'Content-Type':
                  'application/json',
            },
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      debugPrint(
        'PEDIDOS STATUS: ${resposta.statusCode}',
      );

      debugPrint(
        'PEDIDOS RESPOSTA: ${resposta.body}',
      );

      if (resposta.statusCode < 200 ||
          resposta.statusCode >= 300) {
        throw Exception(
          'Erro HTTP ${resposta.statusCode}',
        );
      }

      final resultado =
          jsonDecode(resposta.body);

      final lista =
          _extrairListaPedidos(
        resultado,
      );

      final pedidosNormalizados =
          <Map<String, dynamic>>[];

      for (final item in lista) {
        if (item is Map) {
          pedidosNormalizados.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }

      // Ordena colocando pedidos mais recentes
      // primeiro quando houver ID numérico.
      pedidosNormalizados.sort(
        (a, b) {
          final idA =
              _numeroSeguro(
            a['id'],
          );

          final idB =
              _numeroSeguro(
            b['id'],
          );

          return idB.compareTo(idA);
        },
      );

      if (!mounted) return;

      setState(() {
        pedidos =
            pedidosNormalizados;
        carregando = false;
        atualizando = false;
        erro = null;
      });
    } catch (e) {
      debugPrint(
        'ERRO AO BUSCAR PEDIDOS: $e',
      );

      if (!mounted) return;

      setState(() {
        carregando = false;
        atualizando = false;

        if (pedidos.isEmpty) {
          erro =
              'Não foi possível carregar os pedidos.';
        }
      });
    }
  }

  // ============================================================
  // EXTRAIR LISTA
  // ============================================================

  List<dynamic> _extrairListaPedidos(
    dynamic resultado,
  ) {
    if (resultado is List) {
      return resultado;
    }

    if (resultado is Map) {
      if (resultado['pedidos'] is List) {
        return resultado['pedidos']
            as List;
      }

      if (resultado['orders'] is List) {
        return resultado['orders']
            as List;
      }

      if (resultado['data'] is List) {
        return resultado['data']
            as List;
      }

      if (resultado['results'] is List) {
        return resultado['results']
            as List;
      }
    }

    throw Exception(
      'Formato de pedidos inválido.',
    );
  }

  // ============================================================
  // NÚMERO SEGURO
  // ============================================================

  int _numeroSeguro(
    dynamic valor,
  ) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(
          valor?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // PREÇO
  // ============================================================

  double _precoSeguro(
    dynamic valor,
  ) {
    if (valor is num) {
      return valor.toDouble();
    }

    final texto =
        valor?.toString().trim() ?? '';

    if (texto.isEmpty) {
      return 0;
    }

    final normalizado = texto
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    return double.tryParse(
          normalizado,
        ) ??
        0;
  }

  String _formatarPreco(
    double valor,
  ) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // ATUALIZAR STATUS
  // ============================================================

  Future<void> atualizarStatus(
    dynamic pedidoId,
    String novoStatus,
  ) async {
    final id = pedidoId.toString();

    if (id.trim().isEmpty) {
      _mensagem(
        'ID do pedido inválido.',
        vermelho: true,
      );

      return;
    }

    try {
      final uri = Uri.parse(
        '${Api.baseUrl}/orders/$id/status',
      );

      debugPrint(
        'ATUALIZANDO PEDIDO:',
      );

      debugPrint(
        'Pedido: $id',
      );

      debugPrint(
        'Novo status: $novoStatus',
      );

      final resposta = await http
          .put(
            uri,
            headers: {
              'Accept':
                  'application/json',
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode({
              'status': novoStatus,
            }),
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      debugPrint(
        'STATUS PEDIDO HTTP: ${resposta.statusCode}',
      );

      debugPrint(
        'STATUS PEDIDO RESPOSTA: ${resposta.body}',
      );

      if (!mounted) return;

      if (resposta.statusCode >= 200 &&
          resposta.statusCode < 300) {
        _mensagem(
          'Pedido atualizado para ${nomeStatus(novoStatus)}.',
        );

        await buscarPedidos();
      } else {
        _mensagem(
          'Erro ao atualizar pedido: ${resposta.body}',
          vermelho: true,
          duracao:
              const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint(
        'ERRO AO ATUALIZAR STATUS: $e',
      );

      if (!mounted) return;

      _mensagem(
        'Erro de conexão ao atualizar o pedido.',
        vermelho: true,
      );
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  String nomeStatus(
    String status,
  ) {
    switch (status.toUpperCase()) {
      case 'AGUARDANDO':
      case 'AGUARDANDO_RESTAURANTE':
        return 'Aguardando confirmação';

      case 'ACEITO':
        return 'Pedido aceito';

      case 'PREPARANDO':
        return 'Preparando pedido';

      case 'PRONTO':
        return 'Pedido pronto';

      case 'EM_ENTREGA':
        return 'Em entrega';

      case 'ENTREGUE':
        return 'Entregue';

      case 'CANCELADO':
        return 'Cancelado';

      default:
        return status.isEmpty
            ? 'Sem status'
            : status;
    }
  }

  // ============================================================
  // COR STATUS
  // ============================================================

  Color corStatus(
    String status,
  ) {
    switch (status.toUpperCase()) {
      case 'AGUARDANDO':
      case 'AGUARDANDO_RESTAURANTE':
        return Colors.orange;

      case 'ACEITO':
        return Colors.blue;

      case 'PREPARANDO':
        return Colors.deepOrange;

      case 'PRONTO':
        return Colors.green;

      case 'EM_ENTREGA':
        return Colors.purple;

      case 'ENTREGUE':
        return Colors.grey;

      case 'CANCELADO':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // BOTÃO DE AÇÃO
  // ============================================================

  Widget botaoAcao(
    Map<String, dynamic> pedido,
  ) {
    final pedidoId =
        pedido['id'] ??
            pedido['_id'] ??
            pedido['pedidoId'];

    final status =
        pedido['status']
                ?.toString()
                .toUpperCase() ??
            '';

    if (status ==
            'AGUARDANDO_RESTAURANTE' ||
        status == 'AGUARDANDO') {
      return _botaoStatus(
        texto: 'ACEITAR PEDIDO',
        icone:
            Icons.check_rounded,
        cor: laranja,
        onPressed: () {
          atualizarStatus(
            pedidoId,
            'ACEITO',
          );
        },
      );
    }

    if (status == 'ACEITO') {
      return _botaoStatus(
        texto: 'INICIAR PREPARO',
        icone:
            Icons.restaurant_rounded,
        cor: Colors.blue,
        onPressed: () {
          atualizarStatus(
            pedidoId,
            'PREPARANDO',
          );
        },
      );
    }

    if (status == 'PREPARANDO') {
      return _botaoStatus(
        texto: 'PEDIDO PRONTO',
        icone:
            Icons.check_circle_rounded,
        cor: Colors.green,
        onPressed: () {
          atualizarStatus(
            pedidoId,
            'PRONTO',
          );
        },
      );
    }

    if (status == 'PRONTO') {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration:
            BoxDecoration(
          color:
              Colors.green.withValues(
            alpha: 0.10,
          ),
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color:
                Colors.green.withValues(
              alpha: 0.15,
            ),
          ),
        ),
        child: const Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining_rounded,
              color: Colors.green,
            ),
            SizedBox(width: 8),
            Text(
              'Aguardando entregador',
              style: TextStyle(
                color: Colors.green,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'EM_ENTREGA') {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration:
            BoxDecoration(
          color:
              Colors.purple.withValues(
            alpha: 0.10,
          ),
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining_rounded,
              color: Colors.purple,
            ),
            SizedBox(width: 8),
            Text(
              'Pedido em entrega',
              style: TextStyle(
                color: Colors.purple,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'ENTREGUE') {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration:
            BoxDecoration(
          color:
              Colors.grey.withValues(
            alpha: 0.10,
          ),
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.grey,
            ),
            SizedBox(width: 8),
            Text(
              'Pedido entregue',
              style: TextStyle(
                color: Colors.grey,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'CANCELADO') {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration:
            BoxDecoration(
          color:
              Colors.red.withValues(
            alpha: 0.10,
          ),
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cancel_rounded,
              color: Colors.red,
            ),
            SizedBox(width: 8),
            Text(
              'Pedido cancelado',
              style: TextStyle(
                color: Colors.red,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  Widget _botaoStatus({
    required String texto,
    required IconData icone,
    required Color cor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icone),
        label: Text(texto),
        style:
            ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor:
              Colors.white,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD PEDIDO
  // ============================================================

  Widget cardPedido(
    Map<String, dynamic> pedido,
  ) {
    final pedidoId =
        pedido['id'] ??
            pedido['_id'] ??
            pedido['pedidoId'] ??
            '?';

    final status =
        pedido['status']
                ?.toString()
                .toUpperCase() ??
            '';

    final itens =
        pedido['itens'] is List
            ? pedido['itens'] as List
            : <dynamic>[];

    final total =
        _precoSeguro(
      pedido['total'],
    );

    final pagamento =
        pedido['pagamento'] ??
            pedido['formaPagamento'] ??
            pedido['metodoPagamento'] ??
            'Não informado';

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              Colors.black.withValues(
            alpha: 0.04,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.055,
            ),
            blurRadius: 20,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // CABEÇALHO
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        laranja,
                        laranjaEscuro,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #$pedidoId',
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        '${itens.length} ${itens.length == 1 ? 'item' : 'itens'}',
                        style:
                            TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        corStatus(status)
                            .withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    nomeStatus(status),
                    style:
                        TextStyle(
                      color:
                          corStatus(status),
                      fontWeight:
                          FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Divider(
              height: 1,
            ),

            const SizedBox(height: 18),

            // ITENS
            const Text(
              'Itens do pedido',
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            if (itens.isEmpty)
              const Text(
                'Nenhum item informado.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              )
            else
              ...itens.map(
                (item) {
                  if (item is! Map) {
                    return const SizedBox();
                  }

                  final itemMap =
                      Map<String, dynamic>.from(
                    item,
                  );

                  final nome =
                      itemMap['nome']
                              ?.toString()
                              .trim()
                              .isNotEmpty ==
                          true
                      ? itemMap['nome']
                          .toString()
                      : 'Produto';

                  final quantidade =
                      _numeroSeguro(
                    itemMap['quantidade'],
                  ) > 0
                      ? _numeroSeguro(
                          itemMap['quantidade'],
                        )
                      : 1;

                  final preco =
                      _precoSeguro(
                    itemMap['preco'],
                  );

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment:
                              Alignment.center,
                          decoration:
                              BoxDecoration(
                            color:
                                laranja.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              9,
                            ),
                          ),
                          child: Text(
                            '$quantidade',
                            style:
                                const TextStyle(
                              color: laranja,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: Text(
                            nome,
                            style:
                                const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Text(
                          _formatarPreco(
                            preco *
                                quantidade,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 6),

            const Divider(
              height: 1,
            ),

            const SizedBox(height: 15),

            // TOTAL
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total do pedido',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _formatarPreco(total),
                  style:
                      const TextStyle(
                    fontSize: 20,
                    color: laranja,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // PAGAMENTO
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .account_balance_wallet_rounded,
                    size: 19,
                    color: Colors.grey,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      'Pagamento: $pagamento',
                      style:
                          const TextStyle(
                        color:
                            Colors.black54,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // BOTÃO
            botaoAcao(pedido),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mensagem(
    String texto, {
    bool vermelho = false,
    Duration duracao =
        const Duration(seconds: 2),
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          backgroundColor:
              vermelho
                  ? Colors.redAccent
                  : laranja,
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          duration: duracao,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ============================================================
  // CABEÇALHO
  // ============================================================

  Widget _cabecalho() {
    final aguardando =
        pedidos.where((pedido) {
      final status =
          pedido['status']
                  ?.toString()
                  .toUpperCase() ??
              '';

      return status ==
              'AGUARDANDO' ||
          status ==
              'AGUARDANDO_RESTAURANTE';
    }).length;

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        4,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  laranja,
                  laranjaEscuro,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pedidos',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  restauranteId == null
                      ? 'Restaurante não identificado'
                      : 'Pedidos do seu restaurante',
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          if (aguardando > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.orange.withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$aguardando',
                    style:
                        const TextStyle(
                      color: Colors.orange,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'novos',
                    style:
                        TextStyle(
                      color: Colors.orange,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w700,
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
  // ESTADO DE ERRO
  // ============================================================

  Widget _estadoErro() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration:
                  BoxDecoration(
                color:
                    Colors.red.withValues(
                  alpha: 0.10,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
                size: 40,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Não foi possível carregar os pedidos',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              erro ??
                  'Verifique a conexão com o servidor.',
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                buscarPedidos();
              },
              icon: const Icon(
                Icons.refresh_rounded,
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
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _estadoVazio() {
    return RefreshIndicator(
      color: laranja,
      onRefresh: () =>
          buscarPedidos(),
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 130),

          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration:
                      BoxDecoration(
                    color:
                        laranja.withValues(
                      alpha: 0.10,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: laranja,
                    size: 44,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Nenhum pedido encontrado',
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Os novos pedidos aparecerão aqui.',
                  style:
                      TextStyle(
                    color:
                        Colors.black54,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  restauranteId == null
                      ? 'Restaurante não identificado'
                      : 'Restaurante: $restauranteId',
                  style:
                      const TextStyle(
                    color: Colors.black38,
                    fontSize: 11,
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: fundo,

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor:
            Colors.white,
        elevation: 0,

        title: const Text(
          'Pedidos do Restaurante',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),

        actions: [
          if (atualizando)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: Center(
                child:
                    SizedBox(
                  width: 19,
                  height: 19,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed:
                  () => buscarPedidos(),
              icon: const Icon(
                Icons.refresh_rounded,
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
          : erro != null &&
                  pedidos.isEmpty
              ? _estadoErro()
              : Column(
                  children: [
                    _cabecalho(),

                    const SizedBox(
                      height: 8,
                    ),

                    Expanded(
                      child:
                          pedidos.isEmpty
                              ? _estadoVazio()
                              : RefreshIndicator(
                                  color:
                                      laranja,
                                  onRefresh:
                                      () =>
                                          buscarPedidos(),
                                  child:
                                      ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      30,
                                    ),
                                    itemCount:
                                        pedidos.length,
                                    itemBuilder:
                                        (
                                      context,
                                      index,
                                    ) {
                                      return cardPedido(
                                        pedidos[
                                            index],
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
    );
  }
}