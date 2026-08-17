import 'package:flutter/material.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF5F5F5);

  String filtro = 'Todos';

  final List<String> filtros = [
    'Todos',
    'Novos',
    'Preparando',
    'Prontos',
    'Entregues',
  ];

  // ============================================================
  // PEDIDOS
  // ============================================================
  //
  // IMPORTANTE:
  // Não existem mais pedidos fixos aqui.
  //
  // Essa lista ficará vazia até os pedidos reais
  // serem carregados da API.
  //
  final List<Map<String, dynamic>> pedidos = [];

  // ============================================================
  // FILTRAR PEDIDOS
  // ============================================================

  List<Map<String, dynamic>> get pedidosFiltrados {
    if (filtro == 'Todos') {
      return pedidos;
    }

    return pedidos.where((pedido) {
      final status = pedido['status']?.toString() ?? '';

      switch (filtro) {
        case 'Novos':
          return status == 'NOVO' ||
              status == 'AGUARDANDO_RESTAURANTE' ||
              status == 'Novo';

        case 'Preparando':
          return status == 'PREPARANDO' ||
              status == 'Preparando';

        case 'Prontos':
          return status == 'PRONTO' ||
              status == 'Pronto';

        case 'Entregues':
          return status == 'ENTREGUE' ||
              status == 'Entregue';

        default:
          return true;
      }
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final lista = pedidosFiltrados;

    return Scaffold(
      backgroundColor: fundo,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Pedidos',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Column(
        children: [
          // ======================================================
          // FILTROS
          // ======================================================

          SizedBox(
            height: 64,

            child: ListView.builder(
              scrollDirection: Axis.horizontal,

              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),

              itemCount: filtros.length,

              itemBuilder: (context, index) {
                final item = filtros[index];

                final selecionado = filtro == item;

                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),

                  child: ChoiceChip(
                    label: Text(item),

                    selected: selecionado,

                    selectedColor: laranja,

                    backgroundColor: Colors.white,

                    labelStyle: TextStyle(
                      color: selecionado
                          ? Colors.white
                          : Colors.black87,

                      fontWeight: selecionado
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),

                    side: BorderSide(
                      color: selecionado
                          ? laranja
                          : Colors.grey.shade300,
                    ),

                    onSelected: (_) {
                      setState(() {
                        filtro = item;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // ======================================================
          // LISTA
          // ======================================================

          Expanded(
            child: lista.isEmpty
                ? _estadoVazio()
                : RefreshIndicator(
                    onRefresh: _atualizarPedidos,

                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),

                      itemCount: lista.length,

                      itemBuilder: (context, index) {
                        final pedido = lista[index];

                        return _orderCard(
                          pedido,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _estadoVazio() {
    String mensagem;

    switch (filtro) {
      case 'Novos':
        mensagem = 'Nenhum pedido novo';
        break;

      case 'Preparando':
        mensagem = 'Nenhum pedido em preparação';
        break;

      case 'Prontos':
        mensagem = 'Nenhum pedido pronto';
        break;

      case 'Entregues':
        mensagem = 'Nenhum pedido entregue';
        break;

      default:
        mensagem = 'Nenhum pedido recebido';
    }

    return RefreshIndicator(
      onRefresh: _atualizarPedidos,

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,

            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(30),

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    Container(
                      width: 90,
                      height: 90,

                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFFE8D8,
                        ),

                        borderRadius:
                            BorderRadius.circular(25),
                      ),

                      child: const Icon(
                        Icons.receipt_long_outlined,

                        color: laranja,

                        size: 45,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Text(
                      mensagem,

                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'Os pedidos dos clientes aparecerão aqui automaticamente.',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    OutlinedButton.icon(
                      onPressed: _atualizarPedidos,

                      icon: const Icon(
                        Icons.refresh,
                        color: laranja,
                      ),

                      label: const Text(
                        'Atualizar pedidos',
                        style: TextStyle(
                          color: laranja,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: laranja,
                        ),

                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
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
    );
  }

  // ============================================================
  // CARD DO PEDIDO
  // ============================================================

  Widget _orderCard(
    Map<String, dynamic> pedido,
  ) {
    final id =
        pedido['id']?.toString() ?? '---';

    final cliente =
        pedido['clienteNome']?.toString() ??
            pedido['cliente']?.toString() ??
            'Cliente';

    final status =
        pedido['status']?.toString() ?? 'NOVO';

    final total =
        _valorDouble(pedido['total']);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),

            blurRadius: 8,

            offset: const Offset(
              0,
              3,
            ),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ======================================================
          // CABEÇALHO
          // ======================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [
              Text(
                'Pedido #$id',

                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,

                  fontSize: 18,
                ),
              ),

              _statusBadge(
                status,
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // CLIENTE
          // ======================================================

          Row(
            children: [
              Container(
                width: 38,
                height: 38,

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFE8D8),

                  borderRadius:
                      BorderRadius.circular(11),
                ),

                child: const Icon(
                  Icons.person_outline,

                  color: laranja,

                  size: 21,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  cliente,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // TOTAL
          // ======================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [
              const Text(
                'Total do pedido',

                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),

              Text(
                _formatarPreco(total),

                style: const TextStyle(
                  fontSize: 18,

                  fontWeight:
                      FontWeight.bold,

                  color: laranja,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          // ======================================================
          // BOTÃO
          // ======================================================

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed: () {
                _abrirPedido(
                  pedido,
                );
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    laranja,

                foregroundColor:
                    Colors.white,

                elevation: 0,

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),

              child: const Text(
                'Ver pedido',

                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusBadge(
    String status,
  ) {
    Color cor = laranja;

    String texto = status;

    switch (status) {
      case 'NOVO':
      case 'Novo':
      case 'AGUARDANDO_RESTAURANTE':
        cor = Colors.red;
        texto = 'Novo';
        break;

      case 'PREPARANDO':
      case 'Preparando':
        cor = Colors.orange;
        texto = 'Preparando';
        break;

      case 'PRONTO':
      case 'Pronto':
        cor = Colors.green;
        texto = 'Pronto';
        break;

      case 'ENTREGUE':
      case 'Entregue':
        cor = Colors.blue;
        texto = 'Entregue';
        break;

      case 'CANCELADO':
      case 'Cancelado':
        cor = Colors.red.shade800;
        texto = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: cor.withValues(
          alpha: 0.10,
        ),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        texto,

        style: TextStyle(
          color: cor,

          fontSize: 12,

          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // ABRIR PEDIDO
  // ============================================================

  void _abrirPedido(
    Map<String, dynamic> pedido,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Detalhes do pedido selecionado.',
        ),

        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ATUALIZAR
  // ============================================================

  Future<void> _atualizarPedidos() async {
    // ==========================================================
    // IMPORTANTE
    // ==========================================================
    //
    // Aqui vamos conectar a busca dos pedidos reais da API.
    //
    // Não adicionamos pedidos fictícios.
    //
    // Por enquanto apenas atualiza a tela.
    //

    if (!mounted) return;

    setState(() {});

    await Future.delayed(
      const Duration(
        milliseconds: 300,
      ),
    );
  }

  // ============================================================
  // CONVERTER VALOR
  // ============================================================

  double _valorDouble(
    dynamic valor,
  ) {
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

  // ============================================================
  // FORMATAR PREÇO
  // ============================================================

  String _formatarPreco(
    double valor,
  ) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}