import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api.dart';
import '../restaurant/restaurant_screen.dart';
import '../orders/order_history_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const HomeScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF5F5F5);

  int indiceSelecionado = 0;

  bool carregando = true;
  String? erro;

  List<Map<String, dynamic>> restaurantes = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> restaurantesFiltrados = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> promocoes = <Map<String, dynamic>>[];

  bool carregandoPromocoes = false;

  final TextEditingController buscaController = TextEditingController();

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    carregarRestaurantes();
    carregarPromocoes();

    buscaController.addListener(_quandoBuscar);

    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          _timer = Timer.periodic(
            const Duration(seconds: 30),
            (_) {
              if (mounted) {
                carregarRestaurantes(
                  silencioso: true,
                );

                carregarPromocoes(
                  silencioso: true,
                );
              }
            },
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    buscaController.removeListener(_quandoBuscar);
    buscaController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUSCA DIGITADA
  // ============================================================

  void _quandoBuscar() {
    if (!mounted) return;

    final texto = buscaController.text;

    final filtrados = _aplicarFiltro(
      restaurantes,
      texto,
    );

    setState(() {
      restaurantesFiltrados = filtrados;
    });
  }

  // ============================================================
// CARREGAR PROMOÇÕES
// ============================================================

  Future<void> carregarPromocoes({
    bool silencioso = false,
  }) async {
    if (!silencioso && mounted) {
      setState(() {
        carregandoPromocoes = true;
      });
    }

    try {
      final url = Uri.parse(
        '${Api.baseUrl}/promocoes',
      );

      debugPrint('========================================');
      debugPrint('FOODJET CLIENTE');
      debugPrint('BUSCANDO PROMOÇÕES');
      debugPrint('URL: $url');
      debugPrint('========================================');

      final resposta = await http.get(
        url,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      debugPrint(
        'HTTP PROMOÇÕES: ${resposta.statusCode}',
      );

      debugPrint(
        'RESPOSTA PROMOÇÕES: ${resposta.body}',
      );

      if (resposta.statusCode != 200) {
        throw Exception(
          'Servidor retornou HTTP ${resposta.statusCode}',
        );
      }

      final body = resposta.body.trim();

      if (body.isEmpty) {
        throw Exception(
          'Resposta vazia da API de promoções.',
        );
      }

      final dados = jsonDecode(body);

      final List<Map<String, dynamic>> resultado = <Map<String, dynamic>>[];

      if (dados is List) {
        for (final item in dados) {
          if (item is Map) {
            resultado.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        promocoes = resultado;
        carregandoPromocoes = false;
      });

      debugPrint(
        'PROMOÇÕES CARREGADAS: ${resultado.length}',
      );
    } catch (e) {
      debugPrint(
        'ERRO AO CARREGAR PROMOÇÕES: $e',
      );

      if (!mounted) return;

      setState(() {
        carregandoPromocoes = false;
      });
    }
  }

  // ============================================================
  // CARREGAR RESTAURANTES
  // ============================================================

  Future<void> carregarRestaurantes({
    bool silencioso = false,
  }) async {
    if (!silencioso && mounted) {
      setState(() {
        carregando = true;
        erro = null;
      });
    }

    try {
      final url = Uri.parse(
        '${Api.baseUrl}/restaurants',
      );

      debugPrint('========================================');
      debugPrint('FOODJET CLIENTE');
      debugPrint('BUSCANDO RESTAURANTES');
      debugPrint('URL: $url');
      debugPrint('========================================');

      final resposta = await http.get(
        url,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      debugPrint(
        'HTTP RESTAURANTES: ${resposta.statusCode}',
      );

      debugPrint(
        'RESPOSTA: ${resposta.body}',
      );

      if (resposta.statusCode != 200) {
        throw Exception(
          'Servidor retornou HTTP ${resposta.statusCode}',
        );
      }

      final body = resposta.body.trim();

      if (body.isEmpty) {
        throw Exception(
          'Resposta vazia da API.',
        );
      }

      dynamic dados;

      try {
        dados = jsonDecode(body);
      } catch (_) {
        throw Exception(
          'A API retornou conteúdo que não é JSON válido.',
        );
      }

      // ==========================================================
      // NORMALIZAR RESPOSTA
      // ==========================================================

      final List<dynamic> lista = _extrairLista(dados);

      final List<Map<String, dynamic>> resultado = <Map<String, dynamic>>[];

      for (final item in lista) {
        if (item is Map) {
          try {
            final restaurante = Map<String, dynamic>.from(item);

            _normalizarRestaurante(restaurante);

            resultado.add(restaurante);
          } catch (e) {
            debugPrint(
              'Restaurante ignorado: $e',
            );
          }
        }
      }

      ordenarRestaurantes(resultado);

      if (!mounted) return;

      final filtrados = _aplicarFiltro(
        resultado,
        buscaController.text,
      );

      setState(() {
        restaurantes = List<Map<String, dynamic>>.from(
          resultado,
        );

        restaurantesFiltrados = List<Map<String, dynamic>>.from(
          filtrados,
        );

        carregando = false;
        erro = null;
      });

      debugPrint(
        'RESTAURANTES CARREGADOS: ${resultado.length}',
      );
    } catch (e) {
      debugPrint('========================================');
      debugPrint('ERRO AO CARREGAR RESTAURANTES');
      debugPrint('$e');
      debugPrint('========================================');

      if (!mounted) return;

      if (restaurantes.isNotEmpty) {
        setState(() {
          carregando = false;
          erro = null;
        });

        return;
      }

      setState(() {
        carregando = false;
        erro = 'Não foi possível carregar os restaurantes.';
      });
    }
  }

  // ============================================================
  // EXTRAIR LISTA DA API
  // ============================================================

  List<dynamic> _extrairLista(dynamic dados) {
    if (dados is List) {
      return List<dynamic>.from(dados);
    }

    if (dados is! Map) {
      return <dynamic>[];
    }

    final mapa = Map<String, dynamic>.from(dados);

    final possiveis = <dynamic>[
      mapa['restaurantes'],
      mapa['restaurants'],
      mapa['data'],
      mapa['resultado'],
      mapa['items'],
      mapa['results'],
    ];

    for (final item in possiveis) {
      if (item is List) {
        return List<dynamic>.from(item);
      }
    }

    // Caso a API envie somente um restaurante.
    if (mapa['id'] != null ||
        mapa['_id'] != null ||
        mapa['restauranteId'] != null ||
        mapa['nome'] != null ||
        mapa['nomeFantasia'] != null) {
      return <dynamic>[mapa];
    }

    return <dynamic>[];
  }

  // ============================================================
  // NORMALIZAR RESTAURANTE
  // ============================================================

  void _normalizarRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    restaurante['id'] = restaurante['id'] ??
        restaurante['_id'] ??
        restaurante['restauranteId'] ??
        '';

    restaurante['nome'] = restaurante['nome'] ??
        restaurante['nomeFantasia'] ??
        restaurante['nomeRestaurante'] ??
        'Restaurante';

    restaurante['categoria'] = restaurante['categoria'] ?? 'Comida';

    restaurante['descricao'] = restaurante['descricao'] ?? '';

    restaurante['avaliacao'] =
        restaurante['avaliacao'] ?? restaurante['nota'] ?? 5.0;

    restaurante['tempoEntrega'] = restaurante['tempoEntrega'] ?? '30-45 min';

    restaurante['taxaEntrega'] = restaurante['taxaEntrega'] ?? 0;

    if (restaurante['status'] == null) {
      restaurante['status'] =
          restaurante['online'] == true ? 'ABERTO' : 'FECHADO';
    }
  }

  // ============================================================
  // ORDENAR RESTAURANTES
  // ============================================================

  void ordenarRestaurantes(
    List<Map<String, dynamic>> lista,
  ) {
    if (lista.isEmpty) return;

    lista.sort(
      (a, b) {
        final destaqueA = restauranteDestaque(a) ? 1 : 0;

        final destaqueB = restauranteDestaque(b) ? 1 : 0;

        if (destaqueA != destaqueB) {
          return destaqueB.compareTo(
            destaqueA,
          );
        }

        final prioridadeA = _numeroInteiro(
          a['prioridade'],
        );

        final prioridadeB = _numeroInteiro(
          b['prioridade'],
        );

        if (prioridadeA != prioridadeB) {
          return prioridadeB.compareTo(
            prioridadeA,
          );
        }

        final abertoA = restauranteAberto(a) ? 1 : 0;

        final abertoB = restauranteAberto(b) ? 1 : 0;

        return abertoB.compareTo(
          abertoA,
        );
      },
    );
  }

  // ============================================================
  // DESTAQUE
  // ============================================================

  bool restauranteDestaque(
    Map<String, dynamic> restaurante,
  ) {
    if (restaurante['destaque'] == true ||
        restaurante['destaquePago'] == true ||
        restaurante['patrocinado'] == true) {
      return true;
    }

    final promocao = restaurante['promocao'];

    if (promocao is Map) {
      if (promocao['ativa'] == true) {
        final expiraEm = promocao['expiraEm'];

        if (expiraEm == null) {
          return true;
        }

        try {
          final validade = DateTime.parse(
            expiraEm.toString(),
          );

          return validade.isAfter(
            DateTime.now(),
          );
        } catch (_) {
          return false;
        }
      }
    }

    return false;
  }

  // ============================================================
  // RESTAURANTE ABERTO
  // ============================================================

  bool restauranteAberto(
    Map<String, dynamic> restaurante,
  ) {
    final status = restaurante['status']?.toString().trim().toUpperCase();

    if (status == 'ABERTO' || status == 'OPEN' || status == 'ONLINE') {
      return true;
    }

    if (status == 'FECHADO' || status == 'CLOSED' || status == 'OFFLINE') {
      return false;
    }

    if (restaurante['aberto'] == true) {
      return true;
    }

    if (restaurante['online'] == true) {
      return true;
    }

    return false;
  }

  // ============================================================
  // FILTRO
  // ============================================================

  List<Map<String, dynamic>> _aplicarFiltro(
    List<Map<String, dynamic>> lista,
    String texto,
  ) {
    if (lista.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final busca = texto.trim().toLowerCase();

    if (busca.isEmpty) {
      return List<Map<String, dynamic>>.from(
        lista,
      );
    }

    final resultado = <Map<String, dynamic>>[];

    for (final restaurante in lista) {
      final nome = restaurante['nome']?.toString().toLowerCase() ?? '';

      final categoria =
          restaurante['categoria']?.toString().toLowerCase() ?? '';

      final descricao =
          restaurante['descricao']?.toString().toLowerCase() ?? '';

      if (nome.contains(busca) ||
          categoria.contains(busca) ||
          descricao.contains(busca)) {
        resultado.add(restaurante);
      }
    }

    return resultado;
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  void selecionarPagina(
    int indice,
  ) {
    if (indice == 0) {
      if (!mounted) return;

      setState(() {
        indiceSelecionado = 0;
      });

      return;
    }

    if (indice == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderHistoryScreen(
            usuario: widget.usuario,
          ),
        ),
      );

      return;
    }

    if (indice == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const FavoritesScreen(),
        ),
      );

      return;
    }

    if (indice == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            usuario: widget.usuario,
          ),
        ),
      );
    }
  }

  // ============================================================
  // DADOS
  // ============================================================

  String nomeRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    final nome = restaurante['nome'] ??
        restaurante['nomeFantasia'] ??
        restaurante['nomeRestaurante'];

    if (nome == null || nome.toString().trim().isEmpty) {
      return 'Restaurante';
    }

    return nome.toString();
  }

  String categoriaRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    final categoria = restaurante['categoria'];

    if (categoria == null || categoria.toString().trim().isEmpty) {
      return 'Comida';
    }

    return categoria.toString();
  }

  String avaliacaoRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    final valor = restaurante['avaliacao'] ?? restaurante['nota'] ?? 5.0;

    final numero = _numero(valor);

    return numero.toStringAsFixed(1);
  }

  String tempoEntrega(
    Map<String, dynamic> restaurante,
  ) {
    final tempo = restaurante['tempoEntrega'];

    if (tempo == null || tempo.toString().trim().isEmpty) {
      return '30-45 min';
    }

    return tempo.toString();
  }

  String taxaEntrega(
    Map<String, dynamic> restaurante,
  ) {
    final taxa = restaurante['taxaEntrega'];

    if (taxa == null) {
      return 'Grátis';
    }

    final valor = _numero(taxa);

    if (valor <= 0) {
      return 'Grátis';
    }

    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String idRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    final id =
        restaurante['id'] ?? restaurante['_id'] ?? restaurante['restauranteId'];

    return id?.toString() ?? '';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final nomeUsuario =
        widget.usuario['nome']?.toString().trim().isNotEmpty == true
            ? widget.usuario['nome'].toString()
            : 'Usuário';

    return Scaffold(
      backgroundColor: fundo,

      appBar: AppBar(
        backgroundColor: laranja,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entregar em',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            Row(
              children: const [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  'Ipatinga - MG',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: laranja,
        onRefresh: () async {
          await Future.wait([
            carregarRestaurantes(),
            carregarPromocoes(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // SAUDAÇÃO
              // ==================================================

              Text(
                'Olá, $nomeUsuario 🏆',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'O que você quer pedir hoje?',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // BUSCA
              // ==================================================

              ValueListenableBuilder<TextEditingValue>(
                valueListenable: buscaController,
                builder: (
                  context,
                  value,
                  child,
                ) {
                  return TextField(
                    controller: buscaController,
                    decoration: InputDecoration(
                      hintText: 'Buscar restaurante ou prato',
                      prefixIcon: const Icon(
                        Icons.search,
                      ),
                      suffixIcon: value.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                buscaController.clear();
                              },
                              icon: const Icon(
                                Icons.close,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          16,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // BANNER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF97316),
                      Color(0xFFFF8C42),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔥 FoodJet Destaques',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Restaurantes parceiros com ofertas especiais para você',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

// ==================================================
// PROMOÇÕES
// ==================================================

              _listaPromocoes(),

              const SizedBox(height: 25),

// ==================================================
// CATEGORIAS
// ==================================================

              const Text(
                'Categorias',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                height: 105,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    categoria(
                      Icons.apps,
                      'Todos',
                    ),
                    categoria(
                      Icons.local_pizza,
                      'Pizza',
                    ),
                    categoria(
                      Icons.lunch_dining,
                      'Hambúrguer',
                    ),
                    categoria(
                      Icons.set_meal,
                      'Japonês',
                    ),
                    categoria(
                      Icons.fastfood,
                      'Lanches',
                    ),
                    categoria(
                      Icons.restaurant,
                      'Restaurante',
                    ),
                    categoria(
                      Icons.local_drink,
                      'Bebidas',
                    ),
                    categoria(
                      Icons.local_pizza_outlined,
                      'Massas',
                    ),
                    categoria(
                      Icons.local_fire_department,
                      'Carnes',
                    ),
                    categoria(
                      Icons.eco,
                      'Saudável',
                    ),
                    categoria(
                      Icons.cake,
                      'Doces',
                    ),
                    categoria(
                      Icons.local_cafe,
                      'Café',
                    ),
                    categoria(
                      Icons.ramen_dining,
                      'Brasileira',
                    ),
                    categoria(
                      Icons.public,
                      'Mexicana',
                    ),
                    categoria(
                      Icons.shopping_cart,
                      'Mercado',
                    ),
                    categoria(
                      Icons.local_pharmacy,
                      'Farmácia',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // RESTAURANTES
              // ==================================================

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Restaurantes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!carregando && restaurantesFiltrados.isNotEmpty)
                    Text(
                      '${restaurantesFiltrados.length} encontrados',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 15),

              if (carregando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(
                      color: laranja,
                    ),
                  ),
                )
              else if (erro != null && restaurantes.isEmpty)
                _erroCard()
              else if (restaurantesFiltrados.isEmpty)
                _nenhumRestaurante()
              else
                _listaRestaurantes(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // ==========================================================
      // MENU
      // ==========================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indiceSelecionado,
        onTap: selecionarPagina,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: laranja,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // ============================================================
// CARD DE PROMOÇÕES
// ============================================================

  Widget _listaPromocoes() {
    if (carregandoPromocoes) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: CircularProgressIndicator(
            color: laranja,
          ),
        ),
      );
    }

    if (promocoes.isEmpty) {
      return const SizedBox.shrink();
    }

    final promocoesAtivas = promocoes.where((promocao) {
      final ativa = promocao['ativa'];

      return ativa == true || ativa.toString().toLowerCase() == 'true';
    }).toList();

    if (promocoesAtivas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔥 Promoções para você',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: promocoesAtivas.length,
            itemBuilder: (
              context,
              index,
            ) {
              final promocao = promocoesAtivas[index];

              return _cardPromocao(
                promocao,
              );
            },
          ),
        ),
      ],
    );
  }

// ============================================================
// CARD INDIVIDUAL DA PROMOÇÃO
// ============================================================

  Widget _cardPromocao(
    Map<String, dynamic> promocao,
  ) {
    final titulo = promocao['titulo']?.toString().trim().isNotEmpty == true
        ? promocao['titulo'].toString()
        : 'Promoção especial';

    final descricao =
        promocao['descricao']?.toString().trim().isNotEmpty == true
            ? promocao['descricao'].toString()
            : 'Aproveite esta oferta especial do FoodJet.';

    final desconto = _numero(promocao['desconto']);

    final precoOriginal = _numero(promocao['precoOriginal']);

    final precoPromocional = _numero(promocao['precoPromocional']);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        _abrirPromocao(promocao);
      },
      child: Container(
        width: 310,
        margin: const EdgeInsets.only(
          right: 14,
        ),
        padding: const EdgeInsets.all(
          18,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF97316),
              Color(0xFFFFB347),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
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
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    desconto > 0
                        ? '${desconto.toStringAsFixed(0)}% OFF'
                        : 'OFERTA',
                    style: const TextStyle(
                      color: laranja,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.local_offer,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              descricao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                if (precoOriginal > 0 && precoPromocional > 0) ...[
                  Text(
                    'R\$ ${precoOriginal.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      color: Colors.white70,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    'R\$ ${precoPromocional.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else if (desconto > 0) ...[
                  Text(
                    '${desconto.toStringAsFixed(0)}% de desconto',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// ============================================================
// ABRIR PROMOÇÃO
// ============================================================

  void _abrirPromocao(
    Map<String, dynamic> promocao,
  ) {
    final restauranteId = promocao['restauranteId']?.toString().trim() ?? '';

    final produtoId = promocao['produtoId']?.toString().trim() ?? '';

    debugPrint(
      '========================================',
    );

    debugPrint(
      'FOODJET - ABRINDO PROMOÇÃO',
    );

    debugPrint(
      'RESTAURANTE ID: $restauranteId',
    );

    debugPrint(
      'PRODUTO ID: $produtoId',
    );

    debugPrint(
      '========================================',
    );

    if (restauranteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta promoção não possui um restaurante válido.',
          ),
        ),
      );

      return;
    }

    /*
   * IMPORTANTE:
   *
   * A sua promoção atual possui:
   *
   * restauranteId:
   * rest_1786542500158
   *
   * produtoId:
   * null
   *
   * Portanto, neste momento ela será direcionada
   * para o restaurante.
   */

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantScreen(
          restauranteId: restauranteId,
          nome: promocao['titulo']?.toString() ?? 'Restaurante',
          descricao: promocao['descricao']?.toString() ?? '',
          avaliacao: '5.0',
        ),
      ),
    );
  }

  // ============================================================
  // LISTA DE RESTAURANTES
  // ============================================================

  Widget _listaRestaurantes() {
    final widgets = <Widget>[];

    for (final restaurante in restaurantesFiltrados) {
      widgets.add(
        restauranteCard(
          restaurante,
        ),
      );
    }

    return Column(
      children: widgets,
    );
  }

// ============================================================
// FILTRAR POR CATEGORIA
// ============================================================

void _filtrarPorCategoria(
  String categoria,
) {
  final categoriaBusca =
      categoria.trim().toLowerCase();

  debugPrint(
    '========================================',
  );

  debugPrint(
    'FOODJET - FILTRO DE CATEGORIA',
  );

  debugPrint(
    'CATEGORIA: $categoriaBusca',
  );

  debugPrint(
    'RESTAURANTES: ${restaurantes.length}',
  );

  debugPrint(
    '========================================',
  );

  // ============================================================
  // RESTAURANTES / TODOS
  // ============================================================

  if (categoriaBusca == 'todos' ||
      categoriaBusca == 'restaurante' ||
      categoriaBusca == 'restaurantes') {
    setState(() {
      restaurantesFiltrados =
          List<Map<String, dynamic>>.from(
        restaurantes,
      );

      buscaController.clear();
    });

    debugPrint(
      'MOSTRANDO TODOS OS RESTAURANTES: ${restaurantes.length}',
    );

    return;
  }

  // ============================================================
  // FILTRO POR CATEGORIA
  // ============================================================

  final resultado = restaurantes.where(
    (restaurante) {
      final categoriaRestaurante =
          restaurante['categoria']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      final nome =
          restaurante['nome']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      final descricao =
          restaurante['descricao']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      return categoriaRestaurante.contains(
            categoriaBusca,
          ) ||
          nome.contains(
            categoriaBusca,
          ) ||
          descricao.contains(
            categoriaBusca,
          );
    },
  ).toList();

  if (!mounted) return;

  setState(() {
    restaurantesFiltrados =
        List<Map<String, dynamic>>.from(
      resultado,
    );

    buscaController.clear();
  });

  debugPrint(
    'RESULTADO: ${resultado.length}',
  );

  if (resultado.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Nenhum restaurante encontrado em $categoria.',
        ),
      ),
    );
  }
}

  





// ============================================================
// CATEGORIA
// ============================================================

  Widget categoria(
  IconData icone,
  String nome,
) {
  return GestureDetector(
    onTap: () {
      _filtrarPorCategoria(nome);
    },

    child: Container(
      width: 90,
      margin: const EdgeInsets.only(
        right: 12,
      ),

      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),

              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                ),
              ],
            ),

            child: Icon(
              icone,
              color: laranja,
              size: 30,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            nome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

  // ============================================================
  // CARD RESTAURANTE
  // ============================================================

  Widget restauranteCard(
    Map<String, dynamic> restaurante,
  ) {
    final destaque = restauranteDestaque(
      restaurante,
    );

    final aberto = restauranteAberto(
      restaurante,
    );

    final id = idRestaurante(
      restaurante,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          22,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          22,
        ),
        onTap: () {
          if (id.trim().isEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              const SnackBar(
                content: Text(
                  'Este restaurante não possui um ID válido.',
                ),
              ),
            );

            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantScreen(
                restauranteId: id,
                nome: nomeRestaurante(
                  restaurante,
                ),
                descricao: restaurante['descricao']?.toString() ??
                    categoriaRestaurante(
                      restaurante,
                    ),
                avaliacao: avaliacaoRestaurante(
                  restaurante,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(
            14,
          ),
          child: Row(
            children: [
              _imagemRestaurante(
                restaurante,
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nomeRestaurante(
                              restaurante,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (destaque)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: laranja,
                              borderRadius: BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: const Text(
                              'DESTAQUE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      categoriaRestaurante(
                        restaurante,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(
                          width: 3,
                        ),
                        Text(
                          avaliacaoRestaurante(
                            restaurante,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Icon(
                          aberto ? Icons.check_circle : Icons.schedule,
                          size: 16,
                          color: aberto ? Colors.green : Colors.red,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          aberto ? 'Aberto' : 'Fechado',
                          style: TextStyle(
                            color: aberto ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 15,
                        ),
                        const SizedBox(
                          width: 3,
                        ),
                        Flexible(
                          child: Text(
                            tempoEntrega(
                              restaurante,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        Text(
                          taxaEntrega(
                            restaurante,
                          ),
                          style: const TextStyle(
                            color: laranja,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGEM
  // ============================================================

  Widget _imagemRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    final imagem = restaurante['imagem'] ??
        restaurante['logo'] ??
        restaurante['foto'] ??
        restaurante['imagemUrl'] ??
        restaurante['logoUrl'];

    if (imagem != null && imagem.toString().trim().isNotEmpty) {
      final url = imagem.toString().trim();

      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            18,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (
            context,
            child,
            progress,
          ) {
            if (progress == null) {
              return child;
            }

            return _iconeRestaurante();
          },
          errorBuilder: (
            context,
            error,
            stack,
          ) {
            return _iconeRestaurante();
          },
        ),
      );
    }

    return _iconeRestaurante();
  }

  Widget _iconeRestaurante() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(
          0xFFFFEADB,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: const Icon(
        Icons.restaurant,
        color: laranja,
        size: 40,
      ),
    );
  }

  // ============================================================
  // NENHUM RESTAURANTE
  // ============================================================

  Widget _nenhumRestaurante() {
    final busca = buscaController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        children: [
          Icon(
            busca.isEmpty
                ? Icons.store_mall_directory_outlined
                : Icons.search_off,
            size: 55,
            color: Colors.grey,
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            busca.isEmpty
                ? 'Nenhum restaurante disponível no momento.'
                : 'Nenhum restaurante encontrado para "$busca".',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          if (busca.isEmpty)
            OutlinedButton.icon(
              onPressed: carregarRestaurantes,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Atualizar',
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () {
                buscaController.clear();
              },
              icon: const Icon(
                Icons.close,
              ),
              label: const Text(
                'Limpar busca',
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _erroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 50,
            color: Colors.grey,
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            'Não foi possível carregar os restaurantes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          ElevatedButton.icon(
            onPressed: carregarRestaurantes,
            style: ElevatedButton.styleFrom(
              backgroundColor: laranja,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Tentar novamente',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONVERSÕES
  // ============================================================

  double _numero(
    dynamic valor,
  ) {
    if (valor == null) {
      return 0;
    }

    if (valor is num) {
      return valor.toDouble();
    }

    return double.tryParse(
          valor.toString().replaceAll(',', '.'),
        ) ??
        0;
  }

  int _numeroInteiro(
    dynamic valor,
  ) {
    if (valor == null) {
      return 0;
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
        0;
  }
}
