import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int pedidoId;

  const OrderTrackingScreen({
    super.key,
    required this.pedidoId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? timer;

  bool carregando = true;

  String statusPedido = 'AGUARDANDO_RESTAURANTE';

  Map<String, dynamic>? pedido;

  @override
  void initState() {
    super.initState();

    buscarPedido();

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
          '${Api.baseUrl}/orders/${widget.pedidoId}',
        ),
      );

      print(
        '📡 STATUS PEDIDO: ${resposta.statusCode}',
      );

      print(
        '📦 RESPOSTA PEDIDO: ${resposta.body}',
      );

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);

        if (!mounted) {
          return;
        }

        setState(() {
          pedido = dados['pedido'] ?? dados;

          statusPedido =
              pedido?['status'] ?? 'AGUARDANDO_RESTAURANTE';

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
  // VERIFICA STATUS ATIVO
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

    final atual = ordem.indexOf(statusPedido);

    final item = ordem.indexOf(status);

    if (statusPedido == 'CANCELADO') {
      return false;
    }

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
    const laranja = Color(0xFFF97316);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        title: const Text(
          'Acompanhar Pedido',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =================================================
      // BODY
      // =================================================

      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: buscarPedido,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===================================
                    // STATUS PRINCIPAL
                    // ===================================

                    Card(
                      color: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
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
                                fontWeight: FontWeight.bold,
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

                            // =================================
                            // DESTAQUE QUANDO ESTÁ EM ENTREGA
                            // =================================

                            if (statusPedido == 'EM_ENTREGA') ...[
                              const SizedBox(height: 18),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(15),
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
                                              fontWeight: FontWeight.bold,
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
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===================================
                    // TÍTULO
                    // ===================================

                    const Text(
                      'Status do pedido',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ===================================
                    // LINHA DO TEMPO
                    // ===================================

                    Card(
                      color: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _statusItem(
                              titulo:
                                  'Aguardando confirmação do restaurante',
                              status: 'AGUARDANDO_RESTAURANTE',
                              icone: Icons.receipt_long,
                              primeiro: true,
                            ),

                            _statusItem(
                              titulo: 'Pedido confirmado',
                              status: 'CONFIRMADO',
                              icone: Icons.check_circle,
                            ),

                            _statusItem(
                              titulo: 'Restaurante preparando',
                              status: 'PREPARANDO',
                              icone: Icons.restaurant,
                            ),

                            _statusItem(
                              titulo: 'Pedido pronto',
                              status: 'PRONTO',
                              icone: Icons.inventory_2,
                            ),

                            // =================================
                            // SAIU PARA ENTREGA
                            // =================================

                            _statusEntrega(),

                            _statusItem(
                              titulo: 'Pedido entregue',
                              status: 'ENTREGUE',
                              icone: Icons.done_all,
                              ultimo: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===================================
                    // INFORMAÇÕES DO PEDIDO
                    // ===================================

                    if (pedido != null)
                      Card(
                        color: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informações do pedido',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 15),

                              if (pedido!['total'] != null)
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
                                      formatarPreco(
                                        double.tryParse(
                                              pedido!['total']
                                                  .toString(),
                                            ) ??
                                            0,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 12),

                              if (pedido!['pagamento'] != null)
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
                                      pedido!['pagamento'].toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 25),

                    // ===================================
                    // BOTÃO ATUALIZAR
                    // ===================================

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: buscarPedido,
                        icon: const Icon(
                          Icons.refresh,
                        ),
                        label: const Text(
                          'ATUALIZAR PEDIDO',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: laranja,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
  // STATUS ESPECIAL - SAIU PARA ENTREGA
  // =====================================================

  Widget _statusEntrega() {
    // Quando ainda não chegou em entrega,
    // mantém exatamente o visual normal.
    if (statusPedido != 'EM_ENTREGA') {
      return _statusItem(
        titulo: 'Saiu para entrega',
        status: 'EM_ENTREGA',
        icone: Icons.delivery_dining,
      );
    }

    // Quando chegou em EM_ENTREGA,
    // transforma essa etapa em um destaque.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 34,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Saiu para entrega!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D4ED8),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Seu pedido está a caminho.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O entregador está levando seu pedido até você.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Color(0xFF1D4ED8),
                ),
                SizedBox(width: 6),
                Text(
                  'Em rota de entrega',
                  style: TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
    final ativo = statusAtivo(status);

    const laranja = Color(0xFFF97316);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===============================================
        // ÍCONE + LINHA
        // ===============================================

        Column(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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

        // ===============================================
        // TEXTO
        // ===============================================

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
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