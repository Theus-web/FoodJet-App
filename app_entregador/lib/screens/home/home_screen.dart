import 'package:flutter/material.dart';

import '../../models/entregador.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {

  Entregador? entregador;

  List<Map<String, dynamic>>
      pedidos = [];

  bool carregando = true;
  bool alterandoStatus = false;

  @override
  void initState() {
    super.initState();

    carregar();
  }

  Future<void> carregar() async {
    setState(() {
      carregando = true;
    });

    try {
      final resultado =
          await DeliveryService
              .buscarEntregador();

      final lista =
          await DeliveryService
              .meusPedidos();

      if (!mounted) return;

      setState(() {
        entregador = resultado;
        pedidos = lista;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  Future<void> alterarStatus() async {
    if (entregador == null ||
        alterandoStatus) {
      return;
    }

    setState(() {
      alterandoStatus = true;
    });

    try {
      final novoStatus =
          !entregador!.online;

      final atualizado =
          await DeliveryService
              .alterarStatus(
        id: entregador!.id,
        online: novoStatus,
      );

      if (!mounted) return;

      setState(() {
        entregador = atualizado;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          alterandoStatus = false;
        });
      }
    }
  }

  Future<void> sair() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(
            color: Color(0xFFF97316),
          ),
        ),
      );
    }

    final e = entregador;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F6F6),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF97316),
        foregroundColor: Colors.white,
        title: const Text(
          'FoodJet Entregador',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: carregar,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'sair') {
                sair();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'sair',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: carregar,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            if (e != null) ...[
              Text(
                'Olá, ${e.nome.split(' ').first}! 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                e.veiculo ??
                    'Veículo não informado',
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // STATUS
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(18),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration:
                          BoxDecoration(
                        color: e.online
                            ? Colors.green
                                .withValues(
                            alpha: .12,
                          )
                            : Colors.grey
                                .withValues(
                            alpha: .12,
                          ),
                        shape:
                            BoxShape.circle,
                      ),
                      child: Icon(
                        e.online
                            ? Icons
                                .power_settings_new
                            : Icons
                                .power_off,
                        color: e.online
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            e.online
                                ? 'Você está ONLINE'
                                : 'Você está OFFLINE',
                            style:
                                const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            e.online
                                ? 'Você pode receber entregas.'
                                : 'Fique online para receber entregas.',
                            style:
                                TextStyle(
                              color: Colors
                                  .grey
                                  .shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Switch(
                      value: e.online,
                      activeThumbColor:
                          const Color(
                        0xFFF97316,
                      ),
                      onChanged:
                          alterandoStatus
                              ? null
                              : (_) {
                                  alterarStatus();
                                },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // RESUMO
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child:
                        _cardResumo(
                      icon:
                          Icons.delivery_dining,
                      titulo:
                          'Entregas',
                      valor:
                          pedidos.length
                              .toString(),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                        _cardResumo(
                      icon:
                          Icons
                              .account_balance_wallet,
                      titulo:
                          'Hoje',
                      valor:
                          'R\$ 0,00',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Minhas entregas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (pedidos.isEmpty)
                Container(
                  padding:
                      const EdgeInsets.all(
                    28,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons
                            .delivery_dining,
                        size: 54,
                        color: Colors
                            .grey
                            .shade400,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      const Text(
                        'Nenhuma entrega ainda',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        e.online
                            ? 'Aguardando novas entregas.'
                            : 'Fique online para começar.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...pedidos.map(
                  (pedido) =>
                      _pedidoCard(pedido),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cardResumo({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                const Color(0xFFF97316),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              color:
                  Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pedidoCard(
    Map<String, dynamic> pedido,
  ) {
    final id =
        pedido['id'] ??
        pedido['pedidoId'] ??
        '-';

    final status =
        pedido['status'] ??
        pedido['statusPedido'] ??
        'PENDENTE';

    final valor =
        pedido['total'] ??
        pedido['valor'] ??
        0;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF97316,
              ).withValues(
                alpha: .1,
              ),
              shape:
                  BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining,
              color:
                  Color(0xFFF97316),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'Pedido #$id',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  status.toString(),
                  style:
                      TextStyle(
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),
              ],
            ),
          ),

          Text(
            'R\$ ${valor.toString()}',
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}