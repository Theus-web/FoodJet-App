
import 'dart:async';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // FOODJET
  // ============================================================

  static const Color foodJetOrange = Color(0xFFF97316);
  static const Color foodJetDark = Color(0xFF171717);
  static const Color background = Color(0xFFF7F7F7);
  static const Color green = Color(0xFF16A34A);

  bool disponivel = false;
  int paginaAtual = 0;

  double ganhosHoje = 0.0;
  int entregasHoje = 0;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    // Simulação de atualização da tela.
    // Depois podemos conectar ao Socket.IO do FoodJet.
    timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // STATUS DO ENTREGADOR
  // ============================================================

  void alternarDisponibilidade() {
    setState(() {
      disponivel = !disponivel;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            disponivel ? green : const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            Icon(
              disponivel ? Icons.check_circle : Icons.pause_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                disponivel
                    ? 'Você está disponível para receber entregas.'
                    : 'Você está indisponível.',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HOME
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
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
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // INÍCIO
  // ============================================================

  Widget _buildInicio() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),

        SliverToBoxAdapter(
          child: _buildMap(),
        ),

        SliverToBoxAdapter(
          child: _buildResumoGanhos(),
        ),

        SliverToBoxAdapter(
          child: _buildDisponibilidade(),
        ),

        SliverToBoxAdapter(
          child: _buildEntregaAtual(),
        ),

        SliverToBoxAdapter(
          child: _buildDicas(),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 30),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: foodJetOrange.withOpacity(.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: foodJetOrange.withOpacity(.20),
              ),
            ),
            child: const Icon(
              Icons.person,
              color: foodJetOrange,
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          // Nome
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Olá, Entregador! 👋',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Matheus',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: foodJetDark,
                  ),
                ),
              ],
            ),
          ),

          // Notificações
          GestureDetector(
            onTap: () {
              _mostrarNotificacoes();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: foodJetDark,
                    size: 25,
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: foodJetOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAPA
  // ============================================================

  Widget _buildMap() {
    return Container(
      height: 330,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Stack(
        children: [
          // Fundo do mapa
          CustomPaint(
            painter: FoodJetMapPainter(),
            child: Container(),
          ),

          // Status
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: alternarDisponibilidade,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.10),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: disponivel
                            ? green
                            : const Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disponivel
                                ? 'Você está disponível'
                                : 'Você está indisponível',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            disponivel
                                ? 'Aguardando novas entregas'
                                : 'Fique disponível para receber rotas',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: disponivel
                            ? green.withOpacity(.10)
                            : foodJetOrange.withOpacity(.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        disponivel ? 'ONLINE' : 'ATIVAR',
                        style: TextStyle(
                          color: disponivel
                              ? green
                              : foodJetOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botão localização
          Positioned(
            right: 16,
            top: 105,
            child: _mapButton(
              Icons.my_location_rounded,
              () {},
            ),
          ),

          // Botão filtros
          Positioned(
            right: 16,
            top: 160,
            child: _mapButton(
              Icons.tune_rounded,
              () {},
            ),
          ),

          // SOS
          Positioned(
            right: 16,
            bottom: 72,
            child: GestureDetector(
              onTap: _mostrarSOS,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.12),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.emergency_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Card de ganhos sobre o mapa
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.13),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: foodJetOrange.withOpacity(.11),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: foodJetOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ganhos de hoje',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'R\$ ${ganhosHoje.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: foodJetDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black38,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.12),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: foodJetDark,
          size: 21,
        ),
      ),
    );
  }

  // ============================================================
  // RESUMO
  // ============================================================

  Widget _buildResumoGanhos() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.local_shipping_rounded,
              title: 'Entregas',
              value: '$entregasHoje',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              icon: Icons.timer_outlined,
              title: 'Tempo online',
              value: '0h 00m',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              icon: Icons.star_rounded,
              title: 'Avaliação',
              value: '5,0',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFEDEDED),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: foodJetOrange,
            size: 21,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPONIBILIDADE
  // ============================================================

  Widget _buildDisponibilidade() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: disponivel
                ? [
                    const Color(0xFF15803D),
                    const Color(0xFF22C55E),
                  ]
                : [
                    foodJetOrange,
                    const Color(0xFFFB923C),
                  ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: (disponivel ? green : foodJetOrange)
                  .withOpacity(.22),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                disponivel
                    ? Icons.delivery_dining_rounded
                    : Icons.pause_circle_outline_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disponivel
                        ? 'Pronto para entregar'
                        : 'Quer receber entregas?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    disponivel
                        ? 'O FoodJet avisará quando surgir uma rota.'
                        : 'Ative sua disponibilidade e comece a ganhar.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.88),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: disponivel,
              onChanged: (_) => alternarDisponibilidade(),
              activeColor: Colors.white,
              activeTrackColor: Colors.white.withOpacity(.35),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(.25),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ENTREGA ATUAL
  // ============================================================

  Widget _buildEntregaAtual() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entregas',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),

          if (!disponivel)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFEDEDED),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: foodJetOrange.withOpacity(.09),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.two_wheeler_rounded,
                      color: foodJetOrange,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Nenhuma entrega no momento',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Fique disponível para receber novas corridas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            _buildEntregaDisponivel(),
        ],
      ),
    );
  }

  Widget _buildEntregaDisponivel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: foodJetOrange.withOpacity(.30),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: foodJetOrange.withOpacity(.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: green.withOpacity(.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NOVA ENTREGA',
                  style: TextStyle(
                    color: green,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'R\$ 12,50',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  color: foodJetOrange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(
                      color: foodJetOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 36,
                    color: Colors.black12,
                  ),
                  const Icon(
                    Icons.location_on,
                    color: green,
                    size: 17,
                  ),
                ],
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restaurante Parceiro',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Av. Minas Gerais, 120',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cliente',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Rua das Flores, 250',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: foodJetDark,
                    side: const BorderSide(
                      color: Color(0xFFE5E5E5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'Ver rota',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: foodJetOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'Aceitar entrega',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DICAS
  // ============================================================

  Widget _buildDicas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: foodJetDark,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: foodJetOrange.withOpacity(.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                color: foodJetOrange,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dica FoodJet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mantenha sua localização ativada para receber melhores rotas.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GANHOS
  // ============================================================

  Widget _buildGanhos() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 15),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Meus ganhos',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Esta semana',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    foodJetOrange,
                    Color(0xFFFB923C),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ganhos esta semana',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'R\$ 0,00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 7),
                      Text(
                        '0 entregas realizadas',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _ganhoLinha(
                    'Segunda-feira',
                    'R\$ 0,00',
                  ),
                  _ganhoLinha(
                    'Terça-feira',
                    'R\$ 0,00',
                  ),
                  _ganhoLinha(
                    'Quarta-feira',
                    'R\$ 0,00',
                  ),
                  _ganhoLinha(
                    'Quinta-feira',
                    'R\$ 0,00',
                  ),
                  _ganhoLinha(
                    'Sexta-feira',
                    'R\$ 0,00',
                  ),
                  _ganhoLinha(
                    'Sábado',
                    'R\$ 0,00',
                  ),
                  _ganhoLinha(
                    'Domingo',
                    'R\$ 0,00',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ganhoLinha(String dia, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dia,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AJUDA
  // ============================================================

  Widget _buildAjuda() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
      children: [
        const Text(
          'Como podemos ajudar?',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Encontre respostas ou fale com o suporte FoodJet.',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const TextField(
            decoration: InputDecoration(
              icon: Icon(
                Icons.search,
                color: foodJetOrange,
              ),
              hintText: 'Digite sua dúvida',
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 18),

        _helpItem(
          Icons.security_rounded,
          'Central de segurança',
          'Precisa de ajuda durante uma entrega?',
        ),

        _helpItem(
          Icons.local_shipping_outlined,
          'Problemas com uma entrega',
          'Resolva problemas relacionados às suas corridas.',
        ),

        _helpItem(
          Icons.account_balance_wallet_outlined,
          'Ganhos e repasses',
          'Consulte informações sobre seus pagamentos.',
        ),

        _helpItem(
          Icons.person_outline_rounded,
          'Minha conta',
          'Atualize seus dados pessoais e documentos.',
        ),

        const SizedBox(height: 10),

        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Falar com suporte FoodJet'),
          style: ElevatedButton.styleFrom(
            backgroundColor: foodJetOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _helpItem(
    IconData icon,
    String titulo,
    String subtitulo,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: foodJetOrange.withOpacity(.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: foodJetOrange,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.black38,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENU
  // ============================================================

  Widget _buildMenu() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: foodJetOrange.withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: foodJetOrange,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Matheus',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Entregador FoodJet',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        _menuItem(
          Icons.person_outline,
          'Meu perfil',
        ),

        _menuItem(
          Icons.description_outlined,
          'Documentos',
        ),

        _menuItem(
          Icons.account_balance_outlined,
          'Dados bancários',
        ),

        _menuItem(
          Icons.two_wheeler_outlined,
          'Forma de entrega',
        ),

        _menuItem(
          Icons.notifications_none_rounded,
          'Notificações',
        ),

        _menuItem(
          Icons.settings_outlined,
          'Configurações',
        ),

        const SizedBox(height: 15),

        _menuItem(
          Icons.logout_rounded,
          'Sair da conta',
          danger: true,
        ),
      ],
    );
  }

  Widget _menuItem(
    IconData icon,
    String titulo, {
    bool danger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () {},
        leading: Icon(
          icon,
          color: danger
              ? const Color(0xFFDC2626)
              : foodJetDark,
        ),
        title: Text(
          titulo,
          style: TextStyle(
            color: danger
                ? const Color(0xFFDC2626)
                : foodJetDark,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black26,
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: paginaAtual,
        onDestinationSelected: (index) {
          setState(() {
            paginaAtual = index;
          });
        },
        indicatorColor: foodJetOrange.withOpacity(.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: foodJetOrange,
            ),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(
              Icons.account_balance_wallet_rounded,
              color: foodJetOrange,
            ),
            label: 'Ganhos',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline_rounded),
            selectedIcon: Icon(
              Icons.help_rounded,
              color: foodJetOrange,
            ),
            label: 'Ajuda',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_rounded),
            selectedIcon: Icon(
              Icons.menu_open_rounded,
              color: foodJetOrange,
            ),
            label: 'Menu',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFICAÇÕES
  // ============================================================

  void _mostrarNotificacoes() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              5,
              20,
              25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notificações',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        color: foodJetOrange,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Você ainda não possui novas notificações.',
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SOS
  // ============================================================

  void _mostrarSOS() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              5,
              20,
              30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: Color(0xFFDC2626),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Central de emergência',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Use esta opção somente em uma situação de emergência.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Preciso de ajuda',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
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
  }
}

// ================================================================
// MAPA VISUAL FOODJET
// ================================================================

class FoodJetMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = const Color(0xFFEFF2EA);

    canvas.drawRect(
      Offset.zero & size,
      backgroundPaint,
    );

    // Áreas verdes
    final greenPaint = Paint()
      ..color = const Color(0xFFE2E9D8);

    canvas.drawCircle(
      Offset(size.width * .17, size.height * .40),
      75,
      greenPaint,
    );

    canvas.drawCircle(
      Offset(size.width * .82, size.height * .30),
      85,
      greenPaint,
    );

    canvas.drawCircle(
      Offset(size.width * .78, size.height * .83),
      70,
      greenPaint,
    );

    // Ruas
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final smallRoadPaint = Paint()
      ..color = const Color(0xFFF8F8F8)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(0, size.height * .72)
      ..quadraticBezierTo(
        size.width * .25,
        size.height * .55,
        size.width * .52,
        size.height * .63,
      )
      ..quadraticBezierTo(
        size.width * .76,
        size.height * .72,
        size.width,
        size.height * .43,
      );

    canvas.drawPath(path1, roadPaint);

    final path2 = Path()
      ..moveTo(size.width * .62, 0)
      ..quadraticBezierTo(
        size.width * .58,
        size.height * .27,
        size.width * .70,
        size.height * .50,
      )
      ..quadraticBezierTo(
        size.width * .79,
        size.height * .67,
        size.width * .73,
        size.height,
      );

    canvas.drawPath(path2, roadPaint);

    final path3 = Path()
      ..moveTo(0, size.height * .23)
      ..quadraticBezierTo(
        size.width * .30,
        size.height * .30,
        size.width * .52,
        size.height * .18,
      )
      ..quadraticBezierTo(
        size.width * .76,
        size.height * .08,
        size.width,
        size.height * .18,
      );

    canvas.drawPath(path3, smallRoadPaint);

    // Rota FoodJet
    final routePaint = Paint()
      ..color = const Color(0xFFF97316)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final route = Path()
      ..moveTo(size.width * .20, size.height * .72)
      ..quadraticBezierTo(
        size.width * .33,
        size.height * .55,
        size.width * .51,
        size.height * .61,
      )
      ..quadraticBezierTo(
        size.width * .65,
        size.height * .67,
        size.width * .76,
        size.height * .43,
      );

    canvas.drawPath(route, routePaint);

    // Localização do entregador
    final locationPaint = Paint()
      ..color = const Color(0xFFF97316);

    canvas.drawCircle(
      Offset(
        size.width * .20,
        size.height * .72,
      ),
      15,
      locationPaint,
    );

    final innerPaint = Paint()
      ..color = Colors.white;

    canvas.drawCircle(
      Offset(
        size.width * .20,
        size.height * .72,
      ),
      6,
      innerPaint,
    );

    // Destino
    final destinationPaint = Paint()
      ..color = const Color(0xFF16A34A);

    canvas.drawCircle(
      Offset(
        size.width * .76,
        size.height * .43,
      ),
      13,
      destinationPaint,
    );

    final pinPaint = Paint()
      ..color = Colors.white;

    canvas.drawCircle(
      Offset(
        size.width * .76,
        size.height * .43,
      ),
      5,
      pinPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

