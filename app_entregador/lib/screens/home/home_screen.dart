import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../../widgets/map_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // ESTADO
  // ============================================================

  bool disponivel = false;
  bool alterandoDisponibilidade = false;

  String? entregadorId;
  String nomeEntregador = 'Entregador';

  int paginaAtual = 0;

  // ============================================================
  // FINANCEIRO
  // ============================================================

  double ganhosHoje = 0.0;
  int entregasHoje = 0;

  double saldoCarteira = 0.0;
  double dinheiroEmMaos = 0.0;
  double recebidoHoje = 0.0;

  double ganhosTotais = 0.0;
  int entregasTotais = 0;
  double recebidoTotal = 0.0;

  double totalDevidoRestaurante = 0.0;
  double totalDevidoFoodjet = 0.0;
  double limiteNegativo = 200.0;

  List<Map<String, dynamic>> extratoCarteira = [];

  bool carregandoCarteira = false;

  // ============================================================
  // OFERTAS
  // ============================================================

  Timer? _timerOfertas;

  bool _buscandoOferta = false;
  bool _ofertaAberta = false;

  Map<String, dynamic>? _ofertaAtual;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // ============================================================
  // CORES FOODJET
  // ============================================================

  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF7F7F7);
  static const Color verde = Color(0xFF16A34A);
  static const Color vermelho = Color(0xFFDC2626);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _carregarDados();

    _timerOfertas = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _verificarOfertas();
      },
    );
  }

  // ============================================================
  // CARREGAR DADOS
  // ============================================================

  Future<void> _carregarDados() async {
    try {
      final usuario = await AuthService.getUsuario();

      if (!mounted) return;

      if (usuario == null) {
        return;
      }

      final id =
          usuario['id'] ??
          usuario['usuario_id'] ??
          usuario['entregador_id'];

      final nome =
          usuario['nome'] ??
          usuario['name'] ??
          'Entregador';

      final online =
          usuario['online'] == true ||
          usuario['online']?.toString().toLowerCase() == 'true';

      setState(() {
        entregadorId = id?.toString();
        nomeEntregador = nome.toString();
        disponivel = online;
      });

      await _carregarResumo();

      if (disponivel) {
        _verificarOfertas();
      }
    } catch (e) {
      debugPrint(
        '❌ Erro ao carregar Home: $e',
      );
    }
  }

  // ============================================================
  // RESUMO FINANCEIRO / CARTEIRA
  // ============================================================

  Future<void> _carregarResumo() async {
    if (entregadorId == null ||
        entregadorId!.trim().isEmpty) {
      debugPrint(
        '⚠️ Não foi possível carregar carteira: ID do entregador vazio.',
      );
      return;
    }

    if (carregandoCarteira) {
      return;
    }

    if (mounted) {
      setState(() {
        carregandoCarteira = true;
      });
    }

    try {
      debugPrint(
        '💰 Consultando carteira do entregador: $entregadorId',
      );

      final dados = await DeliveryService.carteira(
        entregadorId!,
      );

      if (!mounted) return;

      double numero(dynamic valor) {
        if (valor == null) {
          return 0.0;
        }

        if (valor is num) {
          return valor.toDouble();
        }

        final texto = valor
            .toString()
            .trim()
            .replaceAll(',', '.');

        return double.tryParse(texto) ?? 0.0;
      }

      int inteiro(dynamic valor) {
        if (valor == null) {
          return 0;
        }

        if (valor is num) {
          return valor.toInt();
        }

        return int.tryParse(
              valor.toString(),
            ) ??
            0;
      }

      final extrato = dados['extrato'];

      setState(() {
        ganhosHoje = numero(
          dados['ganhosHoje'],
        );

        entregasHoje = inteiro(
          dados['entregasHoje'],
        );

        recebidoHoje = numero(
          dados['recebidoHoje'],
        );

        ganhosTotais = numero(
          dados['ganhosTotais'],
        );

        entregasTotais = inteiro(
          dados['entregasTotais'],
        );

        recebidoTotal = numero(
          dados['recebidoTotal'],
        );

        // IMPORTANTE:
        // Saldo da carteira é diferente dos ganhos de hoje.
        saldoCarteira = numero(
          dados['saldo'],
        );

        dinheiroEmMaos = numero(
          dados['dinheiroEmMaos'],
        );

        totalDevidoRestaurante = numero(
          dados['totalDevidoRestaurante'],
        );

        totalDevidoFoodjet = numero(
          dados['totalDevidoFoodjet'],
        );

        limiteNegativo = numero(
          dados['limiteNegativo'],
        );

        if (extrato is List) {
          extratoCarteira = extrato
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();
        } else {
          extratoCarteira = [];
        }
      });

      debugPrint(
        '💰 CARTEIRA OK',
      );

      debugPrint(
        '   Saldo: R\$ ${saldoCarteira.toStringAsFixed(2)}',
      );

      debugPrint(
        '   Ganhos hoje: R\$ ${ganhosHoje.toStringAsFixed(2)}',
      );

      debugPrint(
        '   Recebido hoje: R\$ ${recebidoHoje.toStringAsFixed(2)}',
      );

      debugPrint(
        '   Entregas hoje: $entregasHoje',
      );
    } catch (e) {
      debugPrint(
        '❌ Erro ao carregar carteira: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          carregandoCarteira = false;
        });
      }
    }
  }

  // ============================================================
  // ONLINE / OFFLINE
  // ============================================================

  Future<void> alternarDisponibilidade() async {
    if (alterandoDisponibilidade) return;

    if (entregadorId == null ||
        entregadorId!.isEmpty) {
      _mostrarMensagem(
        'ID do entregador não encontrado.',
        erro: true,
      );
      return;
    }

    final novoStatus = !disponivel;

    setState(() {
      alterandoDisponibilidade = true;
    });

    try {
      final entregador =
          await DeliveryService.alterarStatus(
        id: entregadorId!,
        online: novoStatus,
      );

      if (!mounted) return;

      final online = entregador.online;

      setState(() {
        disponivel = online;
      });

      if (online) {
        _mostrarMensagem(
          'Você está online e pode receber ofertas.',
        );

        await _verificarOfertas();
      } else {
        _mostrarMensagem(
          'Você está offline.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          alterandoDisponibilidade = false;
        });
      }
    }
  }

  // ============================================================
  // BUSCAR OFERTAS
  // ============================================================

  Future<void> _verificarOfertas() async {
    if (!mounted) return;

    if (!disponivel) return;

    if (entregadorId == null ||
        entregadorId!.isEmpty) {
      return;
    }

    if (_buscandoOferta ||
        _ofertaAberta) {
      return;
    }

    _buscandoOferta = true;

    try {
      final pedidos =
          await DeliveryService.buscarPedidosDisponiveis();

      if (!mounted || pedidos.isEmpty) {
        return;
      }

      final oferta = pedidos.first;

      final pedidoId = _obterPedidoId(
        oferta,
      );

      if (pedidoId == null ||
          pedidoId.isEmpty) {
        debugPrint(
          '⚠️ Pedido sem ID: $oferta',
        );
        return;
      }

      debugPrint(
        '🚨 NOVA OFERTA: $pedidoId',
      );

      _ofertaAtual = oferta;
      _ofertaAberta = true;

      await _tocarSomOferta();

      if (!mounted) return;

      final resultado =
          await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Nova oferta',
        barrierColor:
            Colors.black.withOpacity(0.72),
        transitionDuration:
            const Duration(
          milliseconds: 300,
        ),
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return _OfertaEntregaDialog(
            pedido: oferta,
            entregadorId: entregadorId!,
          );
        },
        transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final curva =
              CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          );

          return ScaleTransition(
            scale: curva,
            child: child,
          );
        },
      );

      if (!mounted) return;

      if (resultado == true) {
        await _carregarResumo();

        _mostrarMensagem(
          'Entrega aceita! Vá até o restaurante.',
        );
      } else if (resultado == false) {
        debugPrint(
          'Oferta recusada.',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ Erro ao verificar ofertas: $e',
      );
    } finally {
      _ofertaAtual = null;
      _ofertaAberta = false;
      _buscandoOferta = false;
    }
  }

  // ============================================================
  // SOM
  // ============================================================

  Future<void> _tocarSomOferta() async {
    try {
      await _audioPlayer.stop();

      await _audioPlayer.play(
        AssetSource(
          'sounds/nova_oferta.wav',
        ),
      );
    } catch (e) {
      debugPrint(
        '⚠️ Erro ao tocar som: $e',
      );
    }
  }

  // ============================================================
  // ID DO PEDIDO
  // ============================================================

  String? _obterPedidoId(
    Map<String, dynamic> pedido,
  ) {
    final id =
        pedido['id'] ??
        pedido['pedido_id'] ??
        pedido['order_id'];

    if (id == null) {
      return null;
    }

    return id.toString();
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
          content: Text(
            mensagem,
          ),
          backgroundColor:
              erro ? vermelho : verde,
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timerOfertas?.cancel();
    _audioPlayer.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: IndexedStack(
          index: paginaAtual,
          children: [
            _buildInicio(),
            _buildGanhos(),
            _buildAjuda(),
            _buildMenu(),
          ],
        ),
      ),
      bottomNavigationBar:
          _buildBottomNavigation(),
    );
  }

  // ============================================================
  // INÍCIO
  // ============================================================

  Widget _buildInicio() {
    return RefreshIndicator(
      color: laranja,
      onRefresh: () async {
        await _carregarDados();
      },
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.only(bottom: 30),
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildStatusCard(),
          const SizedBox(height: 14),
          _buildMapa(),
          const SizedBox(height: 14),
          _buildResumoHoje(),
          const SizedBox(height: 14),
          _buildSos(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        14,
        18,
        4,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFFFEBDD),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: laranja,
              size: 29,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(
                top: 1,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Olá, entregador! 🛵',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nomeEntregador,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 14,
                      color:
                          Colors.black54,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(
                    0.05,
                  ),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                _mostrarMensagem(
                  'Nenhuma nova notificação.',
                );
              },
              icon: const Icon(
                Icons.notifications_none,
                size: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS ONLINE
  // ============================================================

  Widget _buildStatusCard() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Container(
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
                  Colors.black.withOpacity(
                0.05,
              ),
              blurRadius: 15,
              offset:
                  const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 250,
              ),
              width: 52,
              height: 52,
              decoration:
                  BoxDecoration(
                color: disponivel
                    ? const Color(
                        0xFFE9F9EF,
                      )
                    : const Color(
                        0xFFF1F1F1,
                      ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                disponivel
                    ? Icons
                        .radio_button_checked
                    : Icons
                        .radio_button_off,
                color: disponivel
                    ? verde
                    : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    disponivel
                        ? 'Você está online'
                        : 'Você está offline',
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    disponivel
                        ? 'Aguardando novas ofertas'
                        : 'Fique online para receber ofertas',
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: disponivel,
              activeColor: laranja,
              onChanged:
                  alterandoDisponibilidade
                      ? null
                      : (_) {
                          alternarDisponibilidade();
                        },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAPA
  // ============================================================

  Widget _buildMapa() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Container(
        height: 285,
        clipBehavior:
            Clip.antiAlias,
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(
                0.06,
              ),
              blurRadius: 16,
              offset:
                  const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: MapWidget(),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.12,
                      ),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(
                        color: disponivel
                            ? verde
                            : Colors.grey,
                        shape:
                            BoxShape.circle,
                      ),
                    ),
                    const SizedBox(
                      width: 7,
                    ),
                    Text(
                      disponivel
                          ? 'Procurando entregas'
                          : 'Offline',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESUMO HOJE
  // ============================================================

  Widget _buildResumoHoje() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildResumoCard(
              titulo: 'Ganhos hoje',
              valor:
                  'R\$ ${ganhosHoje.toStringAsFixed(2).replaceAll('.', ',')}',
              icone:
                  Icons.account_balance_wallet_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildResumoCard(
              titulo: 'Entregas',
              valor:
                  entregasHoje.toString(),
              icone:
                  Icons.local_shipping_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoCard({
    required String titulo,
    required String valor,
    required IconData icone,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(17),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.04,
            ),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFFFF1E8),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icone,
              color: laranja,
              size: 21,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            titulo,
            style:
                const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style:
                const TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SOS
  // ============================================================

  Widget _buildSos() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: const Text(
                  'SOS FoodJet',
                ),
                content:
                    const Text(
                  'Em uma situação de emergência, procure um local seguro e acione os serviços de emergência.',
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(
                      context,
                    ),
                    child:
                        const Text(
                      'Fechar',
                    ),
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          padding:
              const EdgeInsets.all(17),
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFFFF0F0),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    const BoxDecoration(
                  color: vermelho,
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons.emergency,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'SOS',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w900,
                        fontSize: 15,
                        color:
                            vermelho,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Precisa de ajuda?',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color:
                    Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GANHOS
  // ============================================================

  Widget _buildGanhos() {
    // CORREÇÃO:
    // saldo disponível é o saldo da carteira,
    // e não os ganhos de hoje.
    final saldo = saldoCarteira;

    final saldoFormatado =
        'R\$ ${saldo.toStringAsFixed(2).replaceAll('.', ',')}';

    final ganhosHojeFormatado =
        'R\$ ${ganhosHoje.toStringAsFixed(2).replaceAll('.', ',')}';

    final recebidoHojeFormatado =
        'R\$ ${recebidoHoje.toStringAsFixed(2).replaceAll('.', ',')}';

    return RefreshIndicator(
      color: laranja,
      onRefresh: () async {
        await _carregarResumo();
      },
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          30,
        ),
        children: [
          // ======================================================
          // CABEÇALHO
          // ======================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meus ganhos',
                      style:
                          TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing:
                            -0.6,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Seu dinheiro, seu ritmo.',
                      style:
                          TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFFFEBDD),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .account_balance_wallet_rounded,
                  color: laranja,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          // ======================================================
          // CARD PRINCIPAL - SALDO
          // ======================================================

          Container(
            padding:
                const EdgeInsets.fromLTRB(
              22,
              22,
              22,
              20,
            ),
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                begin:
                    Alignment.topLeft,
                end: Alignment
                    .bottomRight,
                colors: [
                  Color(0xFFFF8A3D),
                  Color(0xFFF97316),
                  Color(0xFFE85D04),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color:
                      laranja.withOpacity(
                    0.24,
                  ),
                  blurRadius: 22,
                  offset:
                      const Offset(
                    0,
                    10,
                  ),
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
                      width: 38,
                      height: 38,
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withOpacity(
                          0.18,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .payments_rounded,
                        color:
                            Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Expanded(
                      child: Text(
                        'Saldo disponível',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withOpacity(
                          0.16,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                      child:
                          const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                                .lock_open_rounded,
                            color:
                                Colors.white,
                            size: 12,
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Text(
                            'Disponível',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  10,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // SALDO
                // ==================================================

                carregandoCarteira
                    ? const SizedBox(
                        height: 43,
                        child:
                            Align(
                          alignment:
                              Alignment
                                  .centerLeft,
                          child:
                              SizedBox(
                            width: 30,
                            height: 30,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  3,
                              color:
                                  Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        saldoFormatado,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 36,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing:
                              -1,
                        ),
                      ),

                const SizedBox(
                  height: 4,
                ),

                const Text(
                  'Saldo atual da carteira',
                  style:
                      TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // PIX
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,
                  height: 54,
                  child:
                      ElevatedButton(
                    onPressed:
                        (!carregandoCarteira &&
                                saldo > 0)
                            ? _abrirSaquePix
                            : null,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.white,
                      disabledBackgroundColor:
                          Colors.white
                              .withOpacity(
                        0.45,
                      ),
                      foregroundColor:
                          laranja,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          17,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFFFEBDD,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              9,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons.pix,
                            color:
                                laranja,
                            size: 19,
                          ),
                        ),
                        const SizedBox(
                          width: 9,
                        ),
                        const Text(
                          'SACAR VIA PIX',
                          style:
                              TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight
                                    .w900,
                            letterSpacing:
                                0.3,
                          ),
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        const Icon(
                          Icons
                              .arrow_forward_rounded,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // RESUMO
          // ======================================================

          Row(
            children: [
              Expanded(
                child:
                    _buildGanhoMiniCard(
                  icone: Icons
                      .local_shipping_rounded,
                  titulo:
                      'Entregas',
                  valor:
                      '$entregasHoje',
                  subtitulo:
                      'hoje',
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                    _buildGanhoMiniCard(
                  icone: Icons
                      .trending_up_rounded,
                  titulo:
                      'Média',
                  valor:
                      entregasHoje > 0
                          ? 'R\$ ${(ganhosHoje / entregasHoje).toStringAsFixed(2).replaceAll('.', ',')}'
                          : 'R\$ 0,00',
                  subtitulo:
                      'por entrega',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          // ======================================================
          // PIX
          // ======================================================

          Container(
            padding:
                const EdgeInsets.all(17),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                21,
              ),
              border: Border.all(
                color:
                    const Color(
                  0xFFEFEFEF,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(
                    0.035,
                  ),
                  blurRadius: 12,
                  offset:
                      const Offset(
                    0,
                    4,
                  ),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFE9F9EF,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons.pix,
                    color:
                        Color(0xFF16A34A),
                    size: 25,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Receba via PIX',
                        style:
                            TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(
                        height: 3,
                      ),
                      Text(
                        'Cadastre sua chave PIX para receber seus ganhos.',
                        style:
                            TextStyle(
                          fontSize:
                              11.5,
                          color:
                              Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      Colors.black38,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // ======================================================
          // RESUMO FINANCEIRO
          // ======================================================

          const Text(
            'Resumo de hoje',
            style:
                TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          _buildInfoLinha(
            Icons.local_shipping_rounded,
            'Entregas concluídas',
            '$entregasHoje',
          ),

          _buildInfoLinha(
            Icons.payments_rounded,
            'Total recebido',
            recebidoHojeFormatado,
          ),

          _buildInfoLinha(
            Icons.account_balance_wallet_outlined,
            'Saldo disponível',
            saldoFormatado,
          ),

          _buildInfoLinha(
            Icons.trending_up_rounded,
            'Ganhos hoje',
            ganhosHojeFormatado,
          ),

          _buildInfoLinha(
            Icons.account_balance_rounded,
            'Dinheiro em mãos',
            'R\$ ${dinheiroEmMaos.toStringAsFixed(2).replaceAll('.', ',')}',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MINI CARD GANHOS
  // ============================================================

  Widget _buildGanhoMiniCard({
    required IconData icone,
    required String titulo,
    required String valor,
    required String subtitulo,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.04,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFFFF1E8),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icone,
              color: laranja,
              size: 20,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            titulo,
            style:
                const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 3,
          ),
          Text(
            valor,
            style:
                const TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            subtitulo,
            style:
                const TextStyle(
              fontSize: 10,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAQUE PIX
  // ============================================================

  Future<void> _abrirSaquePix() async {
    final controller =
        TextEditingController();

    final saldoDisponivel =
        saldoCarteira;

    final valor =
        await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(
            bottom:
                MediaQuery.of(context)
                    .viewInsets
                    .bottom,
          ),
          child: Container(
            padding:
                const EdgeInsets.fromLTRB(
              22,
              12,
              22,
              28,
            ),
            decoration:
                const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.black12,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFE9F9EF,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons.pix,
                        color:
                            Color(
                          0xFF16A34A,
                        ),
                        size: 27,
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Saque via PIX',
                          style:
                              TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          'Receba seus ganhos',
                          style:
                              TextStyle(
                            fontSize: 12,
                            color:
                                Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(
                  height: 24,
                ),

                const Text(
                  'Saldo disponível',
                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        Colors.black54,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'R\$ ${saldoDisponivel.toStringAsFixed(2).replaceAll('.', ',')}',
                  style:
                      const TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                const Text(
                  'Quanto deseja sacar?',
                  style:
                      TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                TextField(
                  controller:
                      controller,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      InputDecoration(
                    prefixText:
                        'R\$ ',
                    hintText:
                        '0,00',
                    filled: true,
                    fillColor:
                        const Color(
                      0xFFF7F7F7,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            laranja,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                Container(
                  padding:
                      const EdgeInsets.all(
                    13,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFF0FDF4,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child:
                      const Row(
                    children: [
                      Icon(
                        Icons
                            .verified_user_outlined,
                        color:
                            Color(
                          0xFF16A34A,
                        ),
                        size: 19,
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          'O saque será enviado para sua chave PIX cadastrada.',
                          style:
                              TextStyle(
                            fontSize:
                                11,
                            color:
                                Color(
                              0xFF166534,
                            ),
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 55,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      final texto =
                          controller
                              .text
                              .replaceAll(
                                '.',
                                '',
                              )
                              .replaceAll(
                                ',',
                                '.',
                              )
                              .trim();

                      final valorDigitado =
                          double.tryParse(
                        texto,
                      );

                      if (valorDigitado ==
                              null ||
                          valorDigitado <=
                              0) {
                        _mostrarMensagem(
                          'Digite um valor válido.',
                          erro: true,
                        );
                        return;
                      }

                      if (valorDigitado >
                          saldoDisponivel) {
                        _mostrarMensagem(
                          'O valor do saque é maior que seu saldo disponível.',
                          erro: true,
                        );
                        return;
                      }

                      Navigator.pop(
                        context,
                        valorDigitado,
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          laranja,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          17,
                        ),
                      ),
                    ),
                    child:
                        const Text(
                      'CONTINUAR COM O SAQUE',
                      style:
                          TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();

    if (!mounted ||
        valor == null) {
      return;
    }

    _mostrarMensagem(
      'Saque de R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')} solicitado.',
    );
  }

  // ============================================================
  // AJUDA
  // ============================================================

  Widget _buildAjuda() {
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        30,
      ),
      children: [
        const Text(
          'Ajuda',
          style:
              TextStyle(
            fontSize: 27,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        const Text(
          'Como podemos ajudar?',
          style:
              TextStyle(
            color: Colors.black54,
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        _buildAjudaItem(
          Icons.local_shipping_outlined,
          'Como funciona uma entrega?',
        ),
        _buildAjudaItem(
          Icons.payments_outlined,
          'Dúvidas sobre ganhos',
        ),
        _buildAjudaItem(
          Icons.support_agent,
          'Falar com suporte',
        ),
        _buildAjudaItem(
          Icons.report_problem_outlined,
          'Reportar um problema',
        ),
      ],
    );
  }

  Widget _buildAjudaItem(
    IconData icone,
    String titulo,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFFFF1E8),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icone,
            color: laranja,
          ),
        ),
        title: Text(
          titulo,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
        trailing:
            const Icon(
          Icons.chevron_right,
        ),
        onTap: () {
          _mostrarMensagem(
            'Em breve você poderá acessar esta opção.',
          );
        },
      ),
    );
  }

  // ============================================================
  // MENU
  // ============================================================

  Widget _buildMenu() {
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        30,
      ),
      children: [
        const Text(
          'Menu',
          style:
              TextStyle(
            fontSize: 27,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Container(
          padding:
              const EdgeInsets.all(18),
          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFFFEBDD),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons.person,
                  color: laranja,
                  size: 30,
                ),
              ),
              const SizedBox(
                width: 13,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      nomeEntregador,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    const Text(
                      'Entregador FoodJet',
                      style:
                          TextStyle(
                        color:
                            Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 14,
        ),
        _buildMenuItem(
          Icons.person_outline,
          'Meu perfil',
        ),
        _buildMenuItem(
          Icons
              .account_balance_wallet_outlined,
          'Financeiro',
        ),
        _buildMenuItem(
          Icons.description_outlined,
          'Termos e condições',
        ),
        _buildMenuItem(
          Icons.privacy_tip_outlined,
          'Privacidade',
        ),
        _buildMenuItem(
          Icons.logout,
          'Sair',
          vermelho,
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icone,
    String titulo, [
    Color? cor,
  ]) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),
      ),
      child: ListTile(
        leading: Icon(
          icone,
          color:
              cor ?? Colors.black87,
        ),
        title: Text(
          titulo,
          style:
              TextStyle(
            fontWeight:
                FontWeight.w600,
            color:
                cor ?? Colors.black87,
          ),
        ),
        trailing:
            const Icon(
          Icons.chevron_right,
          color:
              Colors.black38,
        ),
        onTap: () {
          _mostrarMensagem(
            titulo,
          );
        },
      ),
    );
  }

  // ============================================================
  // INFO
  // ============================================================

  Widget _buildInfoLinha(
    IconData icone,
    String titulo,
    String valor,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(
            icone,
            color: laranja,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              titulo,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          Text(
            valor,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex:
          paginaAtual,
      onDestinationSelected:
          (index) {
        setState(() {
          paginaAtual = index;
        });

        // Atualiza Home
        if (index == 0) {
          _carregarDados();
        }

        // CORREÇÃO:
        // Ao entrar em Ganhos, consulta novamente
        // a carteira no backend.
        if (index == 1) {
          _carregarResumo();
        }
      },
      backgroundColor:
          Colors.white,
      elevation: 8,
      indicatorColor:
          const Color(0xFFFFEBDD),
      destinations: const [
        NavigationDestination(
          icon: Icon(
            Icons.home_outlined,
          ),
          selectedIcon:
              Icon(
            Icons.home,
            color: laranja,
          ),
          label: 'Início',
        ),
        NavigationDestination(
          icon: Icon(
            Icons
                .account_balance_wallet_outlined,
          ),
          selectedIcon:
              Icon(
            Icons
                .account_balance_wallet,
            color: laranja,
          ),
          label: 'Ganhos',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.help_outline,
          ),
          selectedIcon:
              Icon(
            Icons.help,
            color: laranja,
          ),
          label: 'Ajuda',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.menu,
          ),
          selectedIcon:
              Icon(
            Icons.menu,
            color: laranja,
          ),
          label: 'Menu',
        ),
      ],
    );
  }
}

// ==================================================================
// DIALOG DA OFERTA
// ==================================================================

class _OfertaEntregaDialog
    extends StatefulWidget {
  final Map<String, dynamic> pedido;
  final String entregadorId;

  const _OfertaEntregaDialog({
    required this.pedido,
    required this.entregadorId,
  });

  @override
  State<_OfertaEntregaDialog>
      createState() =>
          _OfertaEntregaDialogState();
}

class _OfertaEntregaDialogState
    extends State<_OfertaEntregaDialog> {
  static const int tempoInicial = 20;

  int segundos =
      tempoInicial;

  Timer? timer;

  bool processando = false;

  String? erro;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        if (segundos <= 1) {
          timer?.cancel();

          Navigator.of(context)
              .pop();

          return;
        }

        setState(() {
          segundos--;
        });
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();

    super.dispose();
  }

  // ============================================================
  // ACEITAR
  // ============================================================

  Future<void> aceitar() async {
    if (processando) return;

    final pedidoId =
        obterPedidoId();

    if (pedidoId == null) {
      setState(() {
        erro =
            'Não foi possível identificar o pedido.';
      });

      return;
    }

    setState(() {
      processando = true;
      erro = null;
    });

    try {
      await DeliveryService
          .aceitarEntrega(
        entregadorId:
            widget.entregadorId,
        pedidoId:
            pedidoId,
      );

      if (!mounted) return;

      timer?.cancel();

      Navigator.of(context)
          .pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        processando = false;
        erro = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // RECUSAR
  // ============================================================

  void recusar() {
    if (processando) return;

    timer?.cancel();

    Navigator.of(context)
        .pop(false);
  }

  // ============================================================
  // ID
  // ============================================================

  String? obterPedidoId() {
    final id =
        widget.pedido['id'] ??
        widget.pedido['pedido_id'] ??
        widget.pedido['order_id'];

    if (id == null) {
      return null;
    }

    return id.toString();
  }

  // ============================================================
  // TEXTO
  // ============================================================

  String texto(dynamic valor) {
    if (valor == null) {
      return '';
    }

    final resultado =
        valor.toString().trim();

    if (resultado.isEmpty ||
        resultado == 'null') {
      return '';
    }

    return resultado;
  }

  String campo(
    List<String> nomes,
  ) {
    for (final nome in nomes) {
      final valor =
          texto(widget.pedido[nome]);

      if (valor.isNotEmpty) {
        return valor;
      }
    }

    return '';
  }

  // ============================================================
  // RESTAURANTE
  // ============================================================

  String nomeRestaurante() {
    final direto = campo([
      'restaurante_nome',
      'nome_restaurante',
    ]);

    if (direto.isNotEmpty) {
      return direto;
    }

    final restaurante =
        widget.pedido['restaurante'];

    if (restaurante is Map) {
      final nome =
          restaurante['nome'] ??
          restaurante['name'];

      if (nome != null) {
        return nome.toString();
      }
    }

    return 'Restaurante';
  }

  String enderecoRestaurante() {
  final direto = campo([
    'endereco_restaurante',
    'restaurante_endereco',
    'endereco_retirada',
    'endereco_coleta',
  ]);

  if (direto.isNotEmpty) {
    return direto;
  }

  final restaurante = widget.pedido['restaurante'];

  if (restaurante is Map) {
    final endereco =
        restaurante['endereco'] ??
        restaurante['address'];

    final formatado = formatarEndereco(endereco);

    if (formatado.isNotEmpty) {
      return formatado;
    }
  }

  return 'Endereço não informado';
}

String formatarEndereco(dynamic endereco) {
  if (endereco == null) {
    return '';
  }

  // ================================================
  // ENDEREÇO JÁ COMO TEXTO
  // ================================================

  if (endereco is String) {
    final texto = endereco.trim();

    if (texto.isEmpty ||
        texto == 'null' ||
        texto == '{}') {
      return '';
    }

    return texto;
  }

  // ================================================
  // ENDEREÇO COMO OBJETO
  // ================================================

  if (endereco is Map) {
    String valor(List<String> chaves) {
      for (final chave in chaves) {
        final item = endereco[chave];

        if (item != null) {
          final texto = item.toString().trim();

          if (texto.isNotEmpty &&
              texto != 'null') {
            return texto;
          }
        }
      }

      return '';
    }

    final rua = valor([
      'logradouro',
      'rua',
      'endereco',
      'avenida',
      'av',
    ]);

    final numero = valor([
      'numero',
      'número',
    ]);

    final complemento = valor([
      'complemento',
      'complement',
    ]);

    final bairro = valor([
      'bairro',
    ]);

    final cidade = valor([
      'cidade',
      'municipio',
      'município',
    ]);

    final estado = valor([
      'estado',
      'uf',
    ]);

    final cep = valor([
      'cep',
      'CEP',
    ]);

    final partes = <String>[];

    if (rua.isNotEmpty) {
      partes.add(rua);
    }

    if (numero.isNotEmpty) {
      if (partes.isNotEmpty) {
        partes[0] =
            '${partes[0]}, $numero';
      } else {
        partes.add(numero);
      }
    }

    if (complemento.isNotEmpty) {
      partes.add(complemento);
    }

    if (bairro.isNotEmpty) {
      partes.add(bairro);
    }

    if (cidade.isNotEmpty &&
        estado.isNotEmpty) {
      partes.add('$cidade - $estado');
    } else if (cidade.isNotEmpty) {
      partes.add(cidade);
    } else if (estado.isNotEmpty) {
      partes.add(estado);
    }

    if (cep.isNotEmpty) {
      partes.add('CEP $cep');
    }

    return partes.join(' • ');
  }

  return '';
}

  // ============================================================
  // CLIENTE
  // ============================================================

  String nomeCliente() {
    final direto = campo([
      'cliente_nome',
      'nome_cliente',
      'usuario_nome',
      'nome_usuario',
    ]);

    if (direto.isNotEmpty) {
      return direto;
    }

    final cliente =
        widget.pedido['cliente'];

    if (cliente is Map) {
      final nome =
          cliente['nome'] ??
          cliente['name'];

      if (nome != null) {
        return nome.toString();
      }
    }

    return 'Cliente';
  }

  String enderecoEntrega() {
    final direto = campo([
      'endereco_entrega',
      'endereco_cliente',
      'endereco_destino',
      'endereco',
    ]);

    if (direto.isNotEmpty) {
      return direto;
    }

    final cliente =
        widget.pedido['cliente'];

    if (cliente is Map) {
      final endereco =
          cliente['endereco'] ??
          cliente['address'];

      if (endereco != null) {
        return endereco.toString();
      }
    }

    return 'Endereço não informado';
  }

  // ============================================================
  // VALOR
  // ============================================================

  double? valorEntrega() {
  final valor =
      widget.pedido['valor_entrega'] ??
      widget.pedido['taxa_entrega'] ??
      widget.pedido['valor_entregador'] ??
      widget.pedido['ganho_entregador'];

  if (valor == null) {
    return null;
  }

  if (valor is num) {
    return valor.toDouble();
  }

  final texto = valor
      .toString()
      .trim()
      .replaceAll('R\$', '')
      .replaceAll(' ', '');

  if (texto.isEmpty) {
    return null;
  }

  // Formato brasileiro:
  // R$ 1.234,50
  if (texto.contains(',') && texto.contains('.')) {
    final normalizado = texto
        .replaceAll('.', '')
        .replaceAll(',', '.');

    return double.tryParse(normalizado);
  }

  // Formato brasileiro simples:
  // R$ 12,50
  if (texto.contains(',')) {
    return double.tryParse(
      texto.replaceAll(',', '.'),
    );
  }

  // Formato decimal da API/PostgreSQL:
  // 12.50
  return double.tryParse(texto);
}

  String valorFormatado() {
    final valor =
        valorEntrega();

    if (valor == null) {
      return 'R\$ --';
    }

    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // DISTÂNCIA
  // ============================================================

  String distancia() {
    final valor = campo([
      'distancia_km',
      'distancia',
      'km',
    ]);

    if (valor.isEmpty) {
      return '';
    }

    if (valor
        .toLowerCase()
        .contains('km')) {
      return valor;
    }

    return '$valor km';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final km = distancia();

    final urgente =
        segundos <= 5;

    return Material(
      color:
          Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment:
              Alignment.bottomCenter,
          child: Padding(
            padding:
                const EdgeInsets.all(
              14,
            ),
            child: Container(
              width:
                  double.infinity,
              constraints:
                  const BoxConstraints(
                maxWidth: 500,
              ),
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                20,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  28,
                ),
                boxShadow:
                    const [
                  BoxShadow(
                    color:
                        Colors.black38,
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset:
                        Offset(
                      0,
                      -8,
                    ),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  // ------------------------------------------------
                  // TOPO
                  // ------------------------------------------------

                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFFFF1E8,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            30,
                          ),
                        ),
                        child:
                            const Row(
                          mainAxisSize:
                              MainAxisSize
                                  .min,
                          children: [
                            Icon(
                              Icons
                                  .local_shipping,
                              size: 17,
                              color:
                                  Color(
                                0xFFF97316,
                              ),
                            ),
                            SizedBox(
                              width: 6,
                            ),
                            Text(
                              'NOVA OFERTA',
                              style:
                                  TextStyle(
                                color:
                                    Color(
                                  0xFFF97316,
                                ),
                                fontWeight:
                                    FontWeight
                                        .w900,
                                fontSize:
                                    12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 52,
                        height: 52,
                        decoration:
                            BoxDecoration(
                          shape:
                              BoxShape
                                  .circle,
                          color: urgente
                              ? Colors
                                  .red
                                  .shade50
                              : const Color(
                                  0xFFFFF1E8,
                                ),
                          border:
                              Border.all(
                            color: urgente
                                ? Colors.red
                                : const Color(
                                    0xFFF97316,
                                  ),
                            width: 3,
                          ),
                        ),
                        child:
                            Center(
                          child:
                              Text(
                            '$segundos',
                            style:
                                TextStyle(
                              fontSize:
                                  18,
                              fontWeight:
                                  FontWeight
                                      .w900,
                              color: urgente
                                  ? Colors
                                      .red
                                  : const Color(
                                      0xFFF97316,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ------------------------------------------------
                  // VALOR
                  // ------------------------------------------------

                  Row(
                    children: [
                      const Text(
                        'Você recebe',
                        style:
                            TextStyle(
                          color:
                              Colors.black54,
                          fontSize:
                              14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        valorFormatado(),
                        style:
                            const TextStyle(
                          fontSize:
                              30,
                          fontWeight:
                              FontWeight
                                  .w900,
                        ),
                      ),
                    ],
                  ),

                  if (km.isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.route,
                          size: 17,
                          color:
                              Colors.black54,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Text(
                          km,
                          style:
                              const TextStyle(
                            color:
                                Colors.black54,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(
                    height: 20,
                  ),

                  // ------------------------------------------------
                  // RESTAURANTE
                  // ------------------------------------------------

                  _local(
                    icone:
                        Icons.storefront,
                    titulo:
                        'Retirar em',
                    nome:
                        nomeRestaurante(),
                    endereco:
                        enderecoRestaurante(),
                    cor:
                        const Color(
                      0xFFF97316,
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      left: 19,
                    ),
                    child:
                        Container(
                      width: 2,
                      height: 20,
                      color:
                          Colors.black12,
                    ),
                  ),

                  // ------------------------------------------------
                  // CLIENTE
                  // ------------------------------------------------

                  _local(
                    icone:
                        Icons.person,
                    titulo:
                        'Entregar para',
                    nome:
                        nomeCliente(),
                    endereco:
                        enderecoEntrega(),
                    cor:
                        const Color(
                      0xFF333333,
                    ),
                  ),

                  // ------------------------------------------------
                  // ERRO
                  // ------------------------------------------------

                  if (erro != null) ...[
                    const SizedBox(
                      height: 14,
                    ),
                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets
                              .all(
                        12,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors
                            .red
                            .shade50,
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                      child:
                          Text(
                        erro!,
                        style:
                            TextStyle(
                          color: Colors
                              .red
                              .shade700,
                          fontWeight:
                              FontWeight
                                  .w600,
                          fontSize:
                              13,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 20,
                  ),

                  // ------------------------------------------------
                  // BOTÕES
                  // ------------------------------------------------

                  Row(
                    children: [
                      Expanded(
                        child:
                            SizedBox(
                          height: 56,
                          child:
                              OutlinedButton(
                            onPressed:
                                processando
                                    ? null
                                    : recusar,
                            style:
                                OutlinedButton
                                    .styleFrom(
                              side:
                                  const BorderSide(
                                color:
                                    Colors.black12,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                              ),
                            ),
                            child:
                                const Text(
                              'Recusar',
                              style:
                                  TextStyle(
                                color:
                                    Colors.black87,
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        flex: 2,
                        child:
                            SizedBox(
                          height: 56,
                          child:
                              ElevatedButton(
                            onPressed:
                                processando
                                    ? null
                                    : aceitar,
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFFF97316,
                              ),
                              foregroundColor:
                                  Colors.white,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                              ),
                            ),
                            child: processando
                                ? const SizedBox(
                                    width:
                                        23,
                                    height:
                                        23,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.5,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'ACEITAR ENTREGA',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          15,
                                      fontWeight:
                                          FontWeight
                                              .w900,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCAL
  // ============================================================

  Widget _local({
    required IconData icone,
    required String titulo,
    required String nome,
    required String endereco,
    required Color cor,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration:
              BoxDecoration(
            color:
                cor.withOpacity(0.10),
            shape:
                BoxShape.circle,
          ),
          child: Icon(
            icone,
            color: cor,
            size: 20,
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
                titulo,
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      Colors.black45,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                nome,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                endereco,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}