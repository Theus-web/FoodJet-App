import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  // ============================================================
  // CORES
  // ============================================================

  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF5F5F5);

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  int indiceSelecionado = 0;

  // ============================================================
  // RESTAURANTES
  // ============================================================

  bool carregando = true;
  String? erro;

  List<Map<String, dynamic>> restaurantes = <Map<String, dynamic>>[];

  List<Map<String, dynamic>> restaurantesFiltrados = <Map<String, dynamic>>[];

  // ============================================================
  // PROMOÇÕES
  // ============================================================

  List<Map<String, dynamic>> promocoes = <Map<String, dynamic>>[];

  bool carregandoPromocoes = false;

  // ============================================================
  // BUSCA
  // ============================================================

  final TextEditingController buscaController = TextEditingController();

  bool mostrarSugestoesBusca = false;

  // ============================================================
  // HISTÓRICO
  // ============================================================

  List<Map<String, dynamic>> historicoRestaurantes = <Map<String, dynamic>>[];

  static const String _chaveHistoricoRestaurantes =
      'foodjet_historico_restaurantes';

  static const int _limiteHistorico = 8;

  // ============================================================
  // TIMERS
  // ============================================================

  Timer? _timer;
  Timer? _bannerTimer;

  // ============================================================
  // CARROSSEL
  // ============================================================

  final PageController _bannerController = PageController();

  int _bannerAtual = 0;

  // ============================================================
  // BANNERS
  // ============================================================

  final List<Map<String, dynamic>> banners = [
    {
      'titulo': 'Peça pelo FoodJet',
      'subtitulo': 'Os melhores restaurantes na palma da sua mão.',
      'imagem':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200',
      'cor1': Color(0xFFF97316),
      'cor2': Color(0xFFFFB347),
    },
    {
      'titulo': 'Ofertas imperdíveis',
      'subtitulo': 'Economize nos seus pedidos de hoje.',
      'imagem':
          'https://images.unsplash.com/photo-1600891964092-4316c288032e?w=1200',
      'cor1': Color(0xFFEA580C),
      'cor2': Color(0xFFFF8A4C),
    },
    {
      'titulo': 'Seu hambúrguer favorito',
      'subtitulo': 'Peça agora e receba onde estiver.',
      'imagem':
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1200',
      'cor1': Color(0xFFB91C1C),
      'cor2': Color(0xFFF97316),
    },
    {
      'titulo': 'Pizza quentinha',
      'subtitulo': 'Escolha sua pizza e aproveite.',
      'imagem':
          'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=1200',
      'cor1': Color(0xFFDC2626),
      'cor2': Color(0xFFF97316),
    },
    {
      'titulo': 'Comida japonesa',
      'subtitulo': 'Sushi, temaki e muito mais.',
      'imagem':
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=1200',
      'cor1': Color(0xFF7C3AED),
      'cor2': Color(0xFFEC4899),
    },
    {
      'titulo': 'Delivery rápido',
      'subtitulo': 'Seu pedido chegando até você.',
      'imagem':
          'https://images.unsplash.com/photo-1526367790999-0150786686a2?w=1200',
      'cor1': Color(0xFF2563EB),
      'cor2': Color(0xFF06B6D4),
    },
    {
      'titulo': 'Doces para você',
      'subtitulo': 'Deixe seu dia ainda mais gostoso.',
      'imagem':
          'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=1200',
      'cor1': Color(0xFFDB2777),
      'cor2': Color(0xFFF472B6),
    },
    {
      'titulo': 'Bebidas geladas',
      'subtitulo': 'Refresque seu pedido.',
      'imagem':
          'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=1200',
      'cor1': Color(0xFF0891B2),
      'cor2': Color(0xFF22D3EE),
    },
    {
      'titulo': 'FoodJet Premium',
      'subtitulo': 'Descubra novos sabores todos os dias.',
      'imagem':
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1200',
      'cor1': Color(0xFFEA580C),
      'cor2': Color(0xFFFBBF24),
    },
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    buscaController.addListener(_quandoBuscar);

    _carregarHistoricoRestaurantes();

    carregarRestaurantes();
    carregarPromocoes();

    _iniciarCarrossel();

    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) {
        if (!mounted) return;

        carregarRestaurantes(
          silencioso: true,
        );

        carregarPromocoes(
          silencioso: true,
        );
      },
    );
  }

  // ============================================================
  // HISTÓRICO
  // ============================================================

  Future<void> _carregarHistoricoRestaurantes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final dados = prefs.getStringList(
        _chaveHistoricoRestaurantes,
      );

      if (dados == null || dados.isEmpty) {
        return;
      }

      final resultado = <Map<String, dynamic>>[];

      for (final item in dados) {
        try {
          final restaurante = jsonDecode(item);

          if (restaurante is Map) {
            resultado.add(
              Map<String, dynamic>.from(
                restaurante,
              ),
            );
          }
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        historicoRestaurantes = resultado;
      });
    } catch (e) {
      debugPrint(
        'ERRO AO CARREGAR HISTÓRICO: $e',
      );
    }
  }

  Future<void> _salvarHistoricoRestaurante(
    Map<String, dynamic> restaurante,
  ) async {
    final id = idRestaurante(restaurante);

    if (id.trim().isEmpty) {
      return;
    }

    final novoRestaurante = Map<String, dynamic>.from(
      restaurante,
    );

    final historico = List<Map<String, dynamic>>.from(
      historicoRestaurantes,
    );

    historico.removeWhere(
      (item) => idRestaurante(item) == id,
    );

    historico.insert(
      0,
      novoRestaurante,
    );

    if (historico.length > _limiteHistorico) {
      historico.removeRange(
        _limiteHistorico,
        historico.length,
      );
    }

    if (!mounted) return;

    setState(() {
      historicoRestaurantes = historico;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final dados = historico
          .map(
            (item) => jsonEncode(item),
          )
          .toList();

      await prefs.setStringList(
        _chaveHistoricoRestaurantes,
        dados,
      );
    } catch (e) {
      debugPrint(
        'ERRO AO SALVAR HISTÓRICO: $e',
      );
    }
  }

  Future<void> _limparHistoricoRestaurantes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(
        _chaveHistoricoRestaurantes,
      );
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      historicoRestaurantes.clear();
    });
  }

  // ============================================================
  // PAINEL DE BUSCA
  // ============================================================

  Widget _painelBuscaRestaurantes() {
    final texto = buscaController.text.trim();

    final sugestoes = _restaurantesSugeridos();

    if (texto.isNotEmpty) {
      if (sugestoes.isEmpty) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_off,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nenhum restaurante encontrado para "$texto".',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                8,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: laranja,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Restaurantes encontrados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${sugestoes.length}',
                    style: const TextStyle(
                      color: laranja,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...sugestoes.map(
              (restaurante) => _itemSugestaoRestaurante(
                restaurante,
              ),
            ),
          ],
        ),
      );
    }

    if (historicoRestaurantes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              10,
              8,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history,
                  color: laranja,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Restaurantes recentes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _limparHistoricoRestaurantes,
                  child: const Text(
                    'Limpar',
                    style: TextStyle(
                      color: laranja,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...historicoRestaurantes.map(
            (restaurante) => _itemSugestaoRestaurante(
              restaurante,
              historico: true,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ITEM BUSCA
  // ============================================================

  Widget _itemSugestaoRestaurante(
    Map<String, dynamic> restaurante, {
    bool historico = false,
  }) {
    final aberto = restauranteAberto(restaurante);

    return InkWell(
      onTap: () {
        _abrirRestauranteBusca(
          restaurante,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        child: Row(
          children: [
            _imagemBuscaRestaurante(
              restaurante,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomeRestaurante(
                      restaurante,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          categoriaRestaurante(
                            restaurante,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (historico)
                        const Icon(
                          Icons.history,
                          size: 15,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              aberto ? Icons.check_circle : Icons.schedule,
              size: 16,
              color: aberto ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagemBuscaRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    final imagem = restaurante['imagem'] ??
        restaurante['logo'] ??
        restaurante['foto'] ??
        restaurante['imagemUrl'] ??
        restaurante['logoUrl'];

    if (imagem != null && imagem.toString().trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imagem.toString(),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconeBuscaRestaurante(),
        ),
      );
    }

    return _iconeBuscaRestaurante();
  }

  Widget _iconeBuscaRestaurante() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEADB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.restaurant,
        color: laranja,
        size: 25,
      ),
    );
  }

  List<Map<String, dynamic>> _restaurantesSugeridos() {
    final texto = buscaController.text.trim().toLowerCase();

    if (texto.isEmpty) {
      return [];
    }

    final resultados = <Map<String, dynamic>>[];

    for (final restaurante in restaurantes) {
      final nome = nomeRestaurante(
        restaurante,
      ).toLowerCase();

      final categoria = categoriaRestaurante(
        restaurante,
      ).toLowerCase();

      final descricao =
          restaurante['descricao']?.toString().toLowerCase() ?? '';

      if (nome.startsWith(texto)) {
        resultados.add(restaurante);
        continue;
      }

      if (nome.contains(texto) ||
          categoria.contains(texto) ||
          descricao.contains(texto)) {
        resultados.add(restaurante);
      }
    }

    resultados.sort(
      (a, b) {
        final nomeA = nomeRestaurante(
          a,
        ).toLowerCase();

        final nomeB = nomeRestaurante(
          b,
        ).toLowerCase();

        final inicioA = nomeA.startsWith(texto);

        final inicioB = nomeB.startsWith(texto);

        if (inicioA && !inicioB) {
          return -1;
        }

        if (!inicioA && inicioB) {
          return 1;
        }

        return nomeA.compareTo(nomeB);
      },
    );

    if (resultados.length > 6) {
      return resultados.sublist(0, 6);
    }

    return resultados;
  }

  // ============================================================
  // ABRIR RESTAURANTE DA BUSCA
  // ============================================================

  void _abrirRestauranteBusca(
    Map<String, dynamic> restaurante,
  ) {
    final id = idRestaurante(restaurante);

    if (id.trim().isEmpty) {
      return;
    }

    _salvarHistoricoRestaurante(
      restaurante,
    );

    buscaController.clear();

    FocusScope.of(context).unfocus();

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
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timer?.cancel();
    _bannerTimer?.cancel();

    buscaController.removeListener(
      _quandoBuscar,
    );

    buscaController.dispose();
    _bannerController.dispose();

    super.dispose();
  }

  // ============================================================
  // CARROSSEL
  // ============================================================

  void _iniciarCarrossel() {
    _bannerTimer?.cancel();

    _bannerTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (!mounted || !_bannerController.hasClients || banners.isEmpty) {
          return;
        }

        _proximoBanner(
          automatico: true,
        );
      },
    );
  }

  void _reiniciarCarrossel() {
    _bannerTimer?.cancel();
    _iniciarCarrossel();
  }

  void _proximoBanner({
    bool automatico = false,
  }) {
    if (!mounted || !_bannerController.hasClients || banners.isEmpty) {
      return;
    }

    int proximo = _bannerAtual + 1;

    if (proximo >= banners.length) {
      proximo = 0;
    }

    _bannerController.animateToPage(
      proximo,
      duration: Duration(
        milliseconds: automatico ? 700 : 450,
      ),
      curve: Curves.easeInOutCubic,
    );
  }


  // Clique no banner:
  // passa para o próximo banner.
  void _clicarBanner() {
    _reiniciarCarrossel();

    if (!mounted) return;

    _proximoBanner();
  }

  // ============================================================
  // BUSCA
  // ============================================================

  void _quandoBuscar() {
    if (!mounted) return;

    final texto = buscaController.text.trim();

    final filtrados = _aplicarFiltro(
      restaurantes,
      texto,
    );

    setState(() {
      restaurantesFiltrados = filtrados;

      mostrarSugestoesBusca = texto.isNotEmpty;
    });
  }

  // ============================================================
  // PROMOÇÕES
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

      final resposta = await http.get(
        url,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(
          seconds: 15,
        ),
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

      final dados = jsonDecode(body);

      final resultado = <Map<String, dynamic>>[];

      final lista = _extrairLista(dados);

      for (final item in lista) {
        if (item is Map) {
          resultado.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        promocoes = resultado;
        carregandoPromocoes = false;
      });
    } catch (e) {
      debugPrint(
        'ERRO PROMOÇÕES: $e',
      );

      if (!mounted) return;

      setState(() {
        carregandoPromocoes = false;
      });
    }
  }

  // ============================================================
  // RESTAURANTES
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

      debugPrint(
        'FOODJET - BUSCANDO RESTAURANTES: $url',
      );

      final resposta = await http.get(
        url,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(
          seconds: 15,
        ),
      );

      if (resposta.statusCode != 200) {
        throw Exception(
          'HTTP ${resposta.statusCode}',
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
          'Resposta inválida.',
        );
      }

      final lista = _extrairLista(dados);

      final resultado = <Map<String, dynamic>>[];

      for (final item in lista) {
        if (item is Map) {
          final restaurante = Map<String, dynamic>.from(
            item,
          );

          _normalizarRestaurante(
            restaurante,
          );

          resultado.add(
            restaurante,
          );
        }
      }

      ordenarRestaurantes(
        resultado,
      );

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
    } catch (e) {
      debugPrint(
        'ERRO RESTAURANTES: $e',
      );

      if (!mounted) return;

      if (restaurantes.isNotEmpty) {
        setState(() {
          carregando = false;
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
  // EXTRAIR LISTA
  // ============================================================

  List<dynamic> _extrairLista(
    dynamic dados,
  ) {
    if (dados is List) {
      return List<dynamic>.from(
        dados,
      );
    }

    if (dados is! Map) {
      return <dynamic>[];
    }

    final mapa = Map<String, dynamic>.from(
      dados,
    );

    final possiveis = [
      mapa['restaurantes'],
      mapa['restaurants'],
      mapa['data'],
      mapa['resultado'],
      mapa['items'],
      mapa['results'],
      mapa['promocoes'],
      mapa['promotions'],
    ];

    for (final item in possiveis) {
      if (item is List) {
        return List<dynamic>.from(
          item,
        );
      }
    }

    if (mapa['id'] != null ||
        mapa['_id'] != null ||
        mapa['restauranteId'] != null ||
        mapa['nome'] != null ||
        mapa['nomeFantasia'] != null) {
      return [mapa];
    }

    return <dynamic>[];
  }

  // ============================================================
  // NORMALIZAÇÃO
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

    restaurante['categoria'] = restaurante['categoria'] ?? 'Restaurante';

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
  // ORDENAÇÃO
  // ============================================================

  void ordenarRestaurantes(
    List<Map<String, dynamic>> lista,
  ) {
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

    if (promocao is Map && promocao['ativa'] == true) {
      final expira = promocao['expiraEm'];

      if (expira == null) {
        return true;
      }

      try {
        return DateTime.parse(
          expira.toString(),
        ).isAfter(
          DateTime.now(),
        );
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  // ============================================================
  // ABERTO
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

    return restaurante['aberto'] == true || restaurante['online'] == true;
  }

  // ============================================================
  // FILTRO
  // ============================================================

  List<Map<String, dynamic>> _aplicarFiltro(
    List<Map<String, dynamic>> lista,
    String texto,
  ) {
    final busca = texto.trim().toLowerCase();

    if (busca.isEmpty) {
      return List<Map<String, dynamic>>.from(
        lista,
      );
    }

    return lista.where(
      (restaurante) {
        final nome = nomeRestaurante(
          restaurante,
        ).toLowerCase();

        final categoria = categoriaRestaurante(
          restaurante,
        ).toLowerCase();

        final descricao =
            restaurante['descricao']?.toString().toLowerCase() ?? '';

        return nome.contains(busca) ||
            categoria.contains(busca) ||
            descricao.contains(busca);
      },
    ).toList();
  }

  // ============================================================
  // FILTRO CATEGORIA
  // ============================================================

  void _filtrarPorCategoria(
    String categoria,
  ) {
    final busca = categoria.trim().toLowerCase();

    if (busca == 'todos') {
      buscaController.clear();

      if (!mounted) return;

      setState(() {
        restaurantesFiltrados = List<Map<String, dynamic>>.from(
          restaurantes,
        );
      });

      return;
    }

    final resultado = restaurantes.where(
      (restaurante) {
        final categoriaRestaurante =
            restaurante['categoria']?.toString().trim().toLowerCase() ?? '';

        final nome = nomeRestaurante(
          restaurante,
        ).toLowerCase();

        final descricao =
            restaurante['descricao']?.toString().toLowerCase() ?? '';

        // ======================================================
        // NORMALIZAÇÃO DA CATEGORIA
        // ======================================================

        final categoriaNormalizada = _normalizarTexto(
          categoriaRestaurante,
        );

        final buscaNormalizada = _normalizarTexto(
          busca,
        );

        // ======================================================
        // COMPARAÇÃO
        // ======================================================

        return categoriaNormalizada.contains(
              buscaNormalizada,
            ) ||
            nome.contains(busca) ||
            descricao.contains(busca);
      },
    ).toList();

    buscaController.clear();

    if (!mounted) return;

    setState(() {
      restaurantesFiltrados = List<Map<String, dynamic>>.from(
        resultado,
      );
    });

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
  // NORMALIZAR TEXTO
  // ============================================================

  String _normalizarTexto(
    String texto,
  ) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll(
          'á',
          'a',
        )
        .replaceAll(
          'à',
          'a',
        )
        .replaceAll(
          'ã',
          'a',
        )
        .replaceAll(
          'â',
          'a',
        )
        .replaceAll(
          'é',
          'e',
        )
        .replaceAll(
          'ê',
          'e',
        )
        .replaceAll(
          'í',
          'i',
        )
        .replaceAll(
          'ó',
          'o',
        )
        .replaceAll(
          'ô',
          'o',
        )
        .replaceAll(
          'õ',
          'o',
        )
        .replaceAll(
          'ú',
          'u',
        )
        .replaceAll(
          'ç',
          'c',
        );
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  void selecionarPagina(
    int indice,
  ) {
    if (indice == 0) {
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
  // HELPERS
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
      return 'Restaurante';
    }

    return categoria.toString();
  }

  String avaliacaoRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    final valor = restaurante['avaliacao'] ?? restaurante['nota'] ?? 5.0;

    return _numero(valor).toStringAsFixed(1);
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
    final valor = _numero(
      restaurante['taxaEntrega'],
    );

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

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: laranja,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entregar em',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  'Ipatinga - MG',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

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
              Text(
                'Olá, $nomeUsuario 🏆',
                style: const TextStyle(
                  color: Color(0xFF1F1F1F),
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              const Text(
                'O que você quer pedir hoje?',
                style: TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

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
                  return Column(
                    children: [
                      TextField(
                        controller: buscaController,
                        decoration: InputDecoration(
                          hintText: 'Buscar restaurante ou prato',
                          hintStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
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
                      ),
                      if (mostrarSugestoesBusca) _painelBuscaRestaurantes(),
                    ],
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // CARROSSEL
              // ==================================================

              _carrosselBanners(),

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // PROMOÇÕES
              // ==================================================

              _listaPromocoes(),

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // CATEGORIAS
              // ==================================================

              const Text(
                'Categorias',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

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

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // RESTAURANTES
              // ==================================================

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Restaurantes',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!carregando && restaurantesFiltrados.isNotEmpty)
                    Text(
                      '${restaurantesFiltrados.length} encontrados',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 3, 2, 2),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),

              const SizedBox(
                height: 15,
              ),

              if (carregando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(
                      30,
                    ),
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

              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),

      // ========================================================
      // MENU
      // ========================================================

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
            icon: Icon(
              Icons.favorite_border,
            ),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARROSSEL
  // ============================================================

  Widget _carrosselBanners() {
    return Column(
      children: [
        SizedBox(
          height: 185,
          child: Stack(
            children: [
              PageView.builder(
                controller: _bannerController,
                itemCount: banners.length,
                onPageChanged: (index) {
                  if (!mounted) return;

                  setState(() {
                    _bannerAtual = index;
                  });

                  _reiniciarCarrossel();
                },
                itemBuilder: (
                  context,
                  index,
                ) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _clicarBanner,
                    child: _bannerCard(
                      banners[index],
                      index,
                    ),
                  );
                },
              ),

            

    
              // ==================================================
              // AVANÇAR
              // ==================================================

              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _botaoCarrossel(
                    icone: Icons.chevron_right,
                    onPressed: () {
                      _proximoBanner();
                      _reiniciarCarrossel();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        // ========================================================
        // INDICADORES
        // ========================================================

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) {
              final ativo = index == _bannerAtual;

              return AnimatedContainer(
                duration: const Duration(
                  milliseconds: 250,
                ),
                width: ativo ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(
                  horizontal: 3,
                ),
                decoration: BoxDecoration(
                  color: ativo ? laranja : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTÃO CARROSSEL
  // ============================================================

  Widget _botaoCarrossel({
    required IconData icone,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.black.withOpacity(
        0.35,
      ),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icone,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BANNER
  // ============================================================

  Widget _bannerCard(
    Map<String, dynamic> banner,
    int index,
  ) {
    final titulo = banner['titulo']?.toString() ?? 'FoodJet';

    final subtitulo = banner['subtitulo']?.toString() ?? '';

    final imagem = banner['imagem']?.toString() ?? '';

    final cor1 = banner['cor1'] as Color? ?? laranja;

    final cor2 = banner['cor2'] as Color? ??
        const Color(
          0xFFFFB347,
        );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          22,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imagem,
            fit: BoxFit.cover,
            loadingBuilder: (
              context,
              child,
              progress,
            ) {
              if (progress == null) {
                return child;
              }

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cor1,
                      cor2,
                    ],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cor1,
                      cor2,
                    ],
                  ),
                ),
              );
            },
          ),

          // ======================================================
          // SOMBRA
          // ======================================================

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(
                    0.72,
                  ),
                  Colors.black.withOpacity(
                    0.25,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ======================================================
          // TEXTO
          // ======================================================

          Padding(
            padding: const EdgeInsets.all(
              18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                SizedBox(
                  width: 260,
                  child: Text(
                    subtitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: laranja,
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pedir agora',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // CONTADOR
          // ======================================================

          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(
                  0.35,
                ),
                borderRadius: BorderRadius.circular(
                  15,
                ),
              ),
              child: Text(
                '${index + 1}/${banners.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROMOÇÕES
  // ============================================================

  Widget _listaPromocoes() {
    if (carregandoPromocoes) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 10,
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: laranja,
          ),
        ),
      );
    }

    final ativas = promocoes.where(
      (promocao) {
        final ativa = promocao['ativa'];

        return ativa == true || ativa?.toString().toLowerCase() == 'true';
      },
    ).toList();

    if (ativas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔥 Promoções para você',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 14,
        ),
        SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ativas.length,
            itemBuilder: (
              context,
              index,
            ) {
              return _cardPromocao(
                ativas[index],
              );
            },
          ),
        ),
      ],
    );
  }

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

    final desconto = _numero(
      promocao['desconto'],
    );

    final precoOriginal = _numero(
      promocao['precoOriginal'],
    );

    final precoPromocional = _numero(
      promocao['precoPromocional'],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(
        22,
      ),
      onTap: () {
        _abrirPromocao(
          promocao,
        );
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
              Color(
                0xFFF97316,
              ),
              Color(
                0xFFFFB347,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(
            22,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(
                0,
                5,
              ),
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
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
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
                  padding: const EdgeInsets.all(
                    8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
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

    if (restauranteId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta promoção não possui restaurante válido.',
          ),
        ),
      );
      return;
    }

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
  // LISTA RESTAURANTES
  // ============================================================

  Widget _listaRestaurantes() {
    return Column(
      children: restaurantesFiltrados
          .map(
            (restaurante) => restauranteCard(
              restaurante,
            ),
          )
          .toList(),
    );
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
        _filtrarPorCategoria(
          nome,
        );
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
                borderRadius: BorderRadius.circular(
                  35,
                ),
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
            const SizedBox(
              height: 8,
            ),
            Text(
              nome,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black,
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
            offset: Offset(
              0,
              4,
            ),
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

          _salvarHistoricoRestaurante(
            restaurante,
          );

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
                              color: Colors.black,
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
                        color: const Color.fromARGB(255, 7, 1, 1),
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
                            color: Colors.black,
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
                            tempoEntrega(restaurante),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              
                              fontWeight: FontWeight.w500,
                            ),
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
  // IMAGEM RESTAURANTE
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
          imagem.toString(),
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
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
          OutlinedButton.icon(
            onPressed: () {
              if (busca.isEmpty) {
                carregarRestaurantes();
              } else {
                buscaController.clear();
              }
            },
            icon: Icon(
              busca.isEmpty ? Icons.refresh : Icons.close,
            ),
            label: Text(
              busca.isEmpty ? 'Atualizar' : 'Limpar busca',
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
          valor.toString().replaceAll(
                ',',
                '.',
              ),
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
