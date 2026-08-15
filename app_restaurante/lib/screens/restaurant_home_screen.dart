import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/restaurant_service.dart';

import '../screens/orders/restaurant_orders_screen.dart';
import '../screens/products/products_screen.dart';
import '../finance/restaurant_finance_screen.dart';
import 'settings/restaurant_settings_screen.dart';

class RestaurantHomeScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const RestaurantHomeScreen({super.key, required this.usuario});

  @override
  State<RestaurantHomeScreen> createState() => _RestaurantHomeScreenState();
}

class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
  static const Color laranja = Color(0xFFF97316);

  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();
  final RestaurantService _restaurantService = RestaurantService();

  Map<String, dynamic>? dashboard;
  Map<String, dynamic>? restaurante;

  bool carregando = true;
  bool restauranteOnline = false;
  bool alterandoStatus = false;
  bool carregandoStatus = true;

  String restauranteId = "";
  String restauranteNome = "Meu Restaurante";

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      carregarRestaurante();
    });
  }

  // ============================================================
  // CARREGAR RESTAURANTE DA CONTA LOGADA
  // ============================================================

  Future<void> carregarRestaurante() async {
    try {
      setState(() {
        carregando = true;
        carregandoStatus = true;
      });

      String? id;

      // ========================================================
      // 1. RESTAURANTE SALVO NA SESSÃO
      // ========================================================

      final restauranteSessao = await _authService.buscarRestauranteSessao();

      if (restauranteSessao != null) {
        final idSessao = restauranteSessao["id"];

        if (idSessao != null && idSessao.toString().trim().isNotEmpty) {
          id = idSessao.toString();
        }
      }

      // ========================================================
      // 2. ID DO USUÁRIO
      // ========================================================

      if (id == null || id.isEmpty) {
        final usuarioSessao = await _authService.buscarUsuarioSessao();

        if (usuarioSessao != null) {
          final idUsuario = usuarioSessao["restauranteId"];

          if (idUsuario != null && idUsuario.toString().trim().isNotEmpty) {
            id = idUsuario.toString();
          }
        }
      }

      // ========================================================
      // 3. ID DO USUÁRIO RECEBIDO PELO HOME
      // ========================================================

      if (id == null || id.isEmpty) {
        final idWidget = widget.usuario["restauranteId"];

        if (idWidget != null && idWidget.toString().trim().isNotEmpty) {
          id = idWidget.toString();
        }
      }

      // ========================================================
      // 4. AUTH SERVICE
      // ========================================================

      if (id == null || id.isEmpty) {
        id = await _authService.obterRestauranteId();
      }

      // ========================================================
      // IMPORTANTE:
      // NÃO EXISTE MAIS ID FIXO DA PIZZARIA.
      // ========================================================

      if (id == null || id.isEmpty) {
        throw Exception("Esta conta não possui um restaurante vinculado.");
      }

      restauranteId = id;

      debugPrint("========================================");
      debugPrint("FOODJET - RESTAURANTE LOGADO");
      debugPrint("RESTAURANTE ID: $restauranteId");
      debugPrint("========================================");

      // ========================================================
      // 5. BUSCAR RESTAURANTE REAL NA API
      // ========================================================

      final dados = await _authService.buscarDadosRestaurante();

      if (dados == null) {
        throw Exception("Não foi possível carregar os dados do restaurante.");
      }

      if (!mounted) return;

      final nome =
          dados["nome"] ??
          dados["nomeFantasia"] ??
          dados["razaoSocial"] ??
          dados["nomeRestaurante"] ??
          "Meu Restaurante";

      final status = dados["status"]?.toString().toUpperCase();

      setState(() {
        restaurante = dados;

        restauranteNome = nome.toString();

        restauranteOnline = status == "ABERTO" || dados["online"] == true;

        carregando = false;
        carregandoStatus = false;
      });

      debugPrint("NOME RESTAURANTE: $restauranteNome");

      debugPrint("DADOS RESTAURANTE: $dados");

      // ========================================================
      // 6. DASHBOARD
      // ========================================================

      await carregarDashboard();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        carregandoStatus = false;
      });

      debugPrint("ERRO AO CARREGAR RESTAURANTE: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao carregar restaurante: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Future<void> carregarDashboard() async {
    if (restauranteId.isEmpty) {
      return;
    }

    try {
      final dados = await _dashboardService.buscarDashboard(restauranteId);

      if (!mounted) return;

      setState(() {
        dashboard = dados;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      debugPrint("ERRO DASHBOARD: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao carregar dashboard: $e")));
    }
  }

  // ============================================================
  // ATUALIZAR STATUS
  // ============================================================

  Future<void> alterarStatusRestaurante() async {
    if (alterandoStatus || restauranteId.isEmpty) {
      return;
    }

    final novoStatus = restauranteOnline ? "FECHADO" : "ABERTO";

    setState(() {
      alterandoStatus = true;
    });

    try {
      final resultado = await _restaurantService.alterarStatus(
        restauranteId,
        novoStatus,
      );

      if (!mounted) return;

      final status = resultado["status"]?.toString().toUpperCase();

      final online = status == "ABERTO";

      setState(() {
        restauranteOnline = online;
        alterandoStatus = false;

        if (restaurante != null) {
          restaurante!["status"] = status;

          restaurante!["online"] = online;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            online ? "Restaurante está ONLINE" : "Restaurante está OFFLINE",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        alterandoStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao alterar status: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final grafico =
        (dashboard?["graficoSemana"] as List?) ?? [0, 0, 0, 0, 0, 0, 0];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      body: carregando
          ? const Center(child: CircularProgressIndicator(color: laranja))
          : RefreshIndicator(
              color: laranja,
              onRefresh: () async {
                await carregarRestaurante();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // BANNER
                    // ==================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: AspectRatio(
                          aspectRatio: 16 / 5.2,
                          child: Image.asset(
                            'assets/images/95250.png',
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    _banner(restauranteNome),

                    const SizedBox(height: 15),

                    // ==================================================
                    // STATUS
                    // ==================================================
                    _statusRestaurante(),

                    const SizedBox(height: 20),

                    // ==================================================
                    // RESUMO
                    // ==================================================
                    Row(
                      children: [
                        _cardResumo(
                          "Pedidos",
                          "${dashboard?["pedidosHoje"] ?? 0}",
                          Icons.shopping_bag_rounded,
                        ),
                        _cardResumo(
                          "Vendas",
                          _dinheiro(_numero(dashboard?["vendasHoje"])),
                          Icons.attach_money_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        _cardResumo(
                          "Produtos",
                          "${dashboard?["produtos"] ?? 0}",
                          Icons.restaurant_menu_rounded,
                        ),
                        _cardResumo(
                          "Avaliação",
                          "⭐ ${dashboard?["avaliacao"] ?? 5}",
                          Icons.star_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // STATUS DOS PEDIDOS
                    // ==================================================
                    const Text(
                      "Status dos pedidos",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        _statusCard(
                          "Pendentes",
                          dashboard?["pedidosPendentes"] ?? 0,
                          Icons.schedule_rounded,
                          Colors.orange,
                        ),
                        _statusCard(
                          "Preparando",
                          dashboard?["preparando"] ?? 0,
                          Icons.restaurant_rounded,
                          Colors.blue,
                        ),
                        _statusCard(
                          "Em entrega",
                          dashboard?["entrega"] ?? 0,
                          Icons.delivery_dining_rounded,
                          Colors.deepOrange,
                        ),
                        _statusCard(
                          "Finalizados",
                          dashboard?["concluidos"] ?? 0,
                          Icons.check_circle_rounded,
                          Colors.green,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // ACESSO RÁPIDO
                    // ==================================================
                    const Text(
                      "Acesso rápido",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        _acao("Pedidos", Icons.shopping_bag_rounded, () {
                          if (restauranteId.isEmpty) {
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantOrdersScreen(
                                restauranteId: restauranteId,
                              ),
                            ),
                          );
                        }),
                        _acao("Cardápio", Icons.restaurant_menu_rounded, () {
                          if (restauranteId.isEmpty) {
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductsScreen(restauranteId: restauranteId),
                            ),
                          );
                        }),
                        _acao("Ganhos", Icons.attach_money_rounded, () {
                          if (restauranteId.isEmpty) {
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantFinanceScreen(
                                restauranteId: restauranteId,
                              ),
                            ),
                          );
                        }),
                        _acao("Configurações", Icons.settings_rounded, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RestaurantSettingsScreen(),
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // FATURAMENTO
                    // ==================================================
                    const Text(
                      "Faturamento da semana",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Container(
                      height: 250,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          barGroups: List.generate(
                            grafico.length,
                            (i) => _barra(i, _numero(grafico[i])),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // PRODUTOS MAIS VENDIDOS
                    // ==================================================
                    const Text(
                      "Produtos mais vendidos",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    _produtosMaisVendidos(),

                    const SizedBox(height: 30),

                    // ==================================================
                    // ÚLTIMOS PEDIDOS
                    // ==================================================
                    const Text(
                      "Últimos pedidos",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    _ultimosPedidos(),

                    const SizedBox(height: 30),

                    // ==================================================
                    // METAS
                    // ==================================================
                    const Text(
                      "Metas do restaurante",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    _metas(),

                    const SizedBox(height: 30),

                    // ==================================================
                    // AVALIAÇÕES
                    // ==================================================
                    const Text(
                      "Avaliações recentes",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    _avaliacoes(),

                    const SizedBox(height: 30),

                    // ==================================================
                    // IDENTIFICAÇÃO
                    // ==================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Conta do restaurante",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            restauranteNome,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ID: $restauranteId",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // STATUS DO RESTAURANTE
  // ============================================================

  Widget _statusRestaurante() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: restauranteOnline ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restauranteOnline
                      ? "RESTAURANTE ONLINE"
                      : "RESTAURANTE OFFLINE",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 3),
                Text(
                  restauranteOnline
                      ? "Aceitando pedidos"
                      : "Não está aceitando pedidos",
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: restauranteOnline,
            activeThumbColor: Colors.black,
            activeTrackColor: Colors.green,
            inactiveThumbColor: Colors.black,
            inactiveTrackColor: Colors.grey.shade400,
            onChanged: alterandoStatus
                ? null
                : (_) {
                    alterarStatusRestaurante();
                  },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BANNER
  // ============================================================

  Widget _banner(String nome) {
    final vendas = _numero(dashboard?["vendasHoje"]);

    final pedidos = dashboard?["pedidosHoje"] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFFF8C42)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: laranja.withValues(alpha: 0.20),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Olá,",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            nome,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _bannerInfo(
                  Icons.attach_money_rounded,
                  "Vendas hoje",
                  _dinheiro(vendas),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bannerInfo(
                  Icons.shopping_bag_rounded,
                  "Pedidos",
                  pedidos.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerInfo(IconData icon, String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 8),
          Text(titulo, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 2),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD RESUMO
  // ============================================================

  Widget _cardResumo(String titulo, String valor, IconData icone) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: laranja),
            const SizedBox(height: 15),
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            Text(titulo, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _statusCard(
    String titulo,
    dynamic quantidade,
    IconData icone,
    Color cor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: cor.withValues(alpha: 0.15),
            child: Icon(icone, color: cor),
          ),
          const SizedBox(height: 4),
          Text(
            quantidade.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AÇÕES
  // ============================================================

  Widget _acao(String titulo, IconData icone, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: laranja.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icone, size: 30, color: laranja),
            ),
            const SizedBox(height: 10),
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUTOS MAIS VENDIDOS
  // ============================================================

  Widget _produtosMaisVendidos() {
    final lista = dashboard?["produtosMaisVendidos"];

    if (lista is! List || lista.isEmpty) {
      return _emptyCard(
        Icons.restaurant_menu_rounded,
        "Nenhum produto vendido ainda",
      );
    }

    return Column(
      children: lista.map<Widget>((produto) {
        final quantidade = int.tryParse(produto["quantidade"].toString()) ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFEDD5),
                    child: Icon(Icons.restaurant, color: laranja),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      produto["nome"] ?? "Produto",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    "$quantidade vendas",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: (quantidade / 100).clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(20),
                color: laranja,
                backgroundColor: Colors.grey.shade200,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // ÚLTIMOS PEDIDOS
  // ============================================================

  Widget _ultimosPedidos() {
    final lista = dashboard?["ultimosPedidos"];

    if (lista is! List || lista.isEmpty) {
      return _emptyCard(Icons.receipt_long_rounded, "Nenhum pedido encontrado");
    }

    return Column(
      children: lista.map<Widget>((pedido) {
        final status = pedido["status"]?.toString() ?? "AGUARDANDO";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: laranja),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pedido["clienteNome"] ?? "Cliente",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _corStatus(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _corStatus(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _dinheiro(_numero(pedido["total"])),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: laranja,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // METAS
  // ============================================================

  Widget _metas() {
    final vendas = _numero(dashboard?["vendasHoje"]);

    final meta = _numero(dashboard?["metaVendas"] ?? 1000);

    final progresso = meta <= 0 ? 0.0 : (vendas / meta).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: laranja.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.flag_rounded, color: laranja),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Meta de vendas",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text(
                "${(progresso * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: laranja,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: progresso,
            minHeight: 10,
            borderRadius: BorderRadius.circular(20),
            color: laranja,
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(height: 10),
          Text(
            "${_dinheiro(vendas)} de ${_dinheiro(meta)}",
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AVALIAÇÕES
  // ============================================================

  Widget _avaliacoes() {
    final lista = dashboard?["avaliacoesRecentes"];

    if (lista is! List || lista.isEmpty) {
      return _emptyCard(Icons.star_border_rounded, "Nenhuma avaliação ainda");
    }

    return Column(
      children: lista.map<Widget>((avaliacao) {
        final nota = int.tryParse(avaliacao["nota"].toString()) ?? 5;

        final notaSegura = nota.clamp(0, 5);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("⭐" * notaSegura, style: const TextStyle(fontSize: 18)),
                  const Spacer(),
                  Text(
                    avaliacao["cliente"] ?? "Cliente",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                avaliacao["comentario"] ?? "Sem comentário.",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyCard(IconData icone, String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icone, size: 48, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRÁFICO
  // ============================================================

  BarChartGroupData _barra(int x, double valor) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: valor,
          width: 18,
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA046), Color(0xFFF97316)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS DOS PEDIDOS
  // ============================================================

  Color _corStatus(String? status) {
    switch (status?.toUpperCase()) {
      case "AGUARDANDO":
        return Colors.orange;

      case "PREPARANDO":
        return Colors.blue;

      case "ENTREGA":
      case "EM_ENTREGA":
        return Colors.deepOrange;

      case "FINALIZADO":
      case "CONCLUIDO":
        return Colors.green;

      case "CANCELADO":
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // NÚMERO SEGURO
  // ============================================================

  double _numero(dynamic valor) {
    if (valor == null) {
      return 0;
    }

    if (valor is num) {
      return valor.toDouble();
    }

    return double.tryParse(valor.toString().replaceAll(",", ".")) ?? 0;
  }

  // ============================================================
  // DINHEIRO
  // ============================================================

  String _dinheiro(double valor) {
    return "R\$ ${valor.toStringAsFixed(2).replaceAll(".", ",")}";
  }
}
