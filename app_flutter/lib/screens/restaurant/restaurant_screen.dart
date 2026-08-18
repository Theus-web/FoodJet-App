import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api.dart';
import '../cart/cart_screen.dart';

class RestaurantScreen extends StatefulWidget {
  final String restauranteId;
  final String nome;
  final String descricao;
  final String avaliacao;

  const RestaurantScreen({
    super.key,
    required this.restauranteId,
    required this.nome,
    required this.descricao,
    required this.avaliacao,
  });

  @override
  State<RestaurantScreen> createState() =>
      _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color laranjaEscuro = Color(0xFFEA580C);
  static const Color fundo = Color(0xFFF6F7F9);
  static const Color fundoImagem = Color(0xFFFFE5D3);

  final List<CartItem> carrinho = [];

  Timer? _timerStatus;

  bool favorito = false;
  bool carregandoProdutos = true;
  bool restauranteOnline = false;
  bool carregandoStatus = true;

  String? erroProdutos;

  List<Map<String, dynamic>> produtos = [];

  String categoriaSelecionada = 'Todos';

  // ============================================================
  // LOGO DO RESTAURANTE
  // ============================================================

  String? logoRestaurante;

  String? logoBase64;

  // ============================================================
  // INICIALIZAÇÃO
  // ============================================================

  @override
  void initState() {
    super.initState();

    _inicializar();
  }

  Future<void> _inicializar() async {
    await _salvarRestauranteSelecionado();

    await Future.wait([
      _carregarProdutos(),
      _verificarStatusRestaurante(),
    ]);

    if (!mounted) return;

    _timerStatus = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        _verificarStatusRestaurante();
      },
    );
  }

  @override
  void dispose() {
    _timerStatus?.cancel();
    super.dispose();
  }

  // ============================================================
  // RESTAURANTE SELECIONADO
  // ============================================================

  Future<void> _salvarRestauranteSelecionado() async {
    final id = widget.restauranteId.trim();

    if (id.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'restauranteSelecionadoId',
        id,
      );

      await prefs.setString(
        'restauranteId',
        id,
      );
    } catch (e) {
      debugPrint(
        'Erro ao salvar restaurante selecionado: $e',
      );
    }
  }

  // ============================================================
  // BOOLEANO
  // ============================================================

  bool _converterBooleano(
    dynamic valor, {
    bool padrao = false,
  }) {
    if (valor == null) {
      return padrao;
    }

    if (valor is bool) {
      return valor;
    }

    if (valor is num) {
      return valor != 0;
    }

    final texto = valor
        .toString()
        .trim()
        .toLowerCase();

    if ([
      'true',
      '1',
      'sim',
      'yes',
      'aberto',
      'online',
      'ativo',
      'disponivel',
      'disponível',
    ].contains(texto)) {
      return true;
    }

    if ([
      'false',
      '0',
      'nao',
      'não',
      'no',
      'fechado',
      'offline',
      'inativo',
      'indisponivel',
      'indisponível',
    ].contains(texto)) {
      return false;
    }

    return padrao;
  }

  // ============================================================
  // STATUS + DADOS DO RESTAURANTE
  // ============================================================

  Future<void> _verificarStatusRestaurante() async {
    final restauranteId = widget.restauranteId.trim();

    if (restauranteId.isEmpty) {
      if (!mounted) return;

      setState(() {
        restauranteOnline = false;
        carregandoStatus = false;
      });

      return;
    }

    try {
      final uri = Uri.parse(
        '${Api.baseUrl}/restaurants/$restauranteId',
      );

      final resposta = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 10),
          );

      debugPrint(
        'STATUS RESTAURANTE: ${resposta.statusCode}',
      );

      debugPrint(
        'RESPOSTA RESTAURANTE: ${resposta.body}',
      );

      if (resposta.statusCode < 200 ||
          resposta.statusCode >= 300) {
        if (!mounted) return;

        setState(() {
          carregandoStatus = false;
        });

        return;
      }

      final dados = jsonDecode(resposta.body);

      if (dados is! Map) {
        if (!mounted) return;

        setState(() {
          restauranteOnline = false;
          carregandoStatus = false;
        });

        return;
      }

      Map<String, dynamic> restaurante;

      if (dados['restaurante'] is Map) {
        restaurante = Map<String, dynamic>.from(
          dados['restaurante'] as Map,
        );
      } else if (dados['restaurant'] is Map) {
        restaurante = Map<String, dynamic>.from(
          dados['restaurant'] as Map,
        );
      } else {
        restaurante = Map<String, dynamic>.from(
          dados,
        );
      }

      // ========================================================
      // BUSCAR LOGO REAL DO RESTAURANTE
      // ========================================================

      String? logo;

      final possiveisLogos = [
        restaurante['logo'],
        restaurante['logoUrl'],
        restaurante['imagem'],
        restaurante['imagemUrl'],
        restaurante['foto'],
        restaurante['fotoUrl'],
      ];

      for (final valor in possiveisLogos) {
        if (valor != null &&
            valor.toString().trim().isNotEmpty) {
          logo = valor.toString().trim();
          break;
        }
      }

      String? base64Logo;

      final possiveisBase64 = [
        restaurante['logoBase64'],
        restaurante['imagemBase64'],
        restaurante['fotoBase64'],
      ];

      for (final valor in possiveisBase64) {
        if (valor != null &&
            valor.toString().trim().isNotEmpty) {
          base64Logo = valor.toString().trim();
          break;
        }
      }

      final status = restaurante['status']
              ?.toString()
              .trim()
              .toUpperCase() ??
          '';

      final online = _converterBooleano(
        restaurante['online'],
        padrao: true,
      );

      final aberto = _converterBooleano(
        restaurante['aberto'],
        padrao: true,
      );

      final ativo = _converterBooleano(
        restaurante['ativo'],
        padrao: true,
      );

      bool disponivel;

      if (status.isNotEmpty) {
        final statusAberto = [
          'ABERTO',
          'ONLINE',
          'ATIVO',
          'DISPONIVEL',
          'DISPONÍVEL',
        ].contains(status);

        final statusFechado = [
          'FECHADO',
          'OFFLINE',
          'INATIVO',
          'INDISPONIVEL',
          'INDISPONÍVEL',
        ].contains(status);

        if (statusFechado) {
          disponivel = false;
        } else {
          disponivel =
              statusAberto &&
              online &&
              aberto &&
              ativo;
        }
      } else {
        disponivel =
            online &&
            aberto &&
            ativo;
      }

      if (!mounted) return;

      final estavaOnline = restauranteOnline;

      setState(() {
        restauranteOnline = disponivel;
        carregandoStatus = false;

        if (logo != null) {
          logoRestaurante = logo;
        }

        if (base64Logo != null) {
          logoBase64 = base64Logo;
        }
      });

      // ========================================================
      // LIMPAR CARRINHO SOMENTE SE REALMENTE FICOU OFFLINE
      // ========================================================

      if (estavaOnline &&
          !disponivel &&
          carrinho.isNotEmpty) {
        setState(() {
          carrinho.clear();
        });

        _mensagem(
          'O restaurante ficou fechado. O carrinho foi atualizado.',
          vermelho: true,
          duracao: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint(
        'Erro ao verificar status do restaurante: $e',
      );

      if (!mounted) return;

      setState(() {
        carregandoStatus = false;
      });
    }
  }

  // ============================================================
  // PRODUTOS
  // ============================================================

  Future<void> _carregarProdutos() async {
    if (!mounted) return;

    setState(() {
      carregandoProdutos = true;
      erroProdutos = null;
    });

    try {
      final restauranteId =
          widget.restauranteId.trim();

      if (restauranteId.isEmpty) {
        throw Exception(
          'ID do restaurante não informado.',
        );
      }

      final uri = Uri.parse(
        '${Api.baseUrl}/products',
      );

      final resposta = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        'PRODUTOS STATUS: ${resposta.statusCode}',
      );

      debugPrint(
        'PRODUTOS RESPOSTA: ${resposta.body}',
      );

      if (resposta.statusCode < 200 ||
          resposta.statusCode >= 300) {
        throw Exception(
          'Erro HTTP ${resposta.statusCode}',
        );
      }

      final resultado = jsonDecode(
        resposta.body,
      );

      List<dynamic> listaProdutos;

      if (resultado is List) {
        listaProdutos = resultado;
      } else if (resultado is Map &&
          resultado['produtos'] is List) {
        listaProdutos =
            resultado['produtos'] as List;
      } else if (resultado is Map &&
          resultado['products'] is List) {
        listaProdutos =
            resultado['products'] as List;
      } else if (resultado is Map &&
          resultado['data'] is List) {
        listaProdutos =
            resultado['data'] as List;
      } else {
        throw Exception(
          'Formato de resposta inválido.',
        );
      }

      final produtosApi =
          <Map<String, dynamic>>[];

      for (final item in listaProdutos) {
        if (item is! Map) continue;

        final produto =
            Map<String, dynamic>.from(item);

        final idProduto =
            produto['restauranteId'] ??
            produto['restaurantId'] ??
            produto['restaurante_id'];

        if (idProduto == null) {
          continue;
        }

        if (idProduto.toString().trim() !=
            restauranteId) {
          continue;
        }

        final disponivel =
            _converterBooleano(
          produto['disponivel'],
          padrao: true,
        );

        if (!disponivel) {
          continue;
        }

        produto['restauranteId'] =
            idProduto.toString();

        produtosApi.add(produto);
      }

      if (!mounted) return;

      setState(() {
        produtos = produtosApi;
        carregandoProdutos = false;

        if (!categorias.contains(
          categoriaSelecionada,
        )) {
          categoriaSelecionada = 'Todos';
        }
      });

      debugPrint(
        'PRODUTOS DO RESTAURANTE: ${produtos.length}',
      );
    } catch (e) {
      debugPrint(
        'Erro ao buscar produtos: $e',
      );

      if (!mounted) return;

      setState(() {
        carregandoProdutos = false;
        erroProdutos =
            'Não foi possível carregar o cardápio.';
      });
    }
  }

  // ============================================================
  // CATEGORIAS
  // ============================================================

  List<String> get categorias {
    final conjunto = <String>{};

    for (final produto in produtos) {
      final categoria = produto['categoria']
          ?.toString()
          .trim();

      if (categoria != null &&
          categoria.isNotEmpty) {
        conjunto.add(categoria);
      }
    }

    final lista = conjunto.toList();

    lista.sort(
      (a, b) => a
          .toLowerCase()
          .compareTo(
            b.toLowerCase(),
          ),
    );

    return [
      'Todos',
      ...lista,
    ];
  }

  List<Map<String, dynamic>>
      get produtosFiltrados {
    if (categoriaSelecionada == 'Todos') {
      return produtos;
    }

    return produtos
        .where(
          (produto) =>
              produto['categoria']
                  ?.toString()
                  .trim()
                  .toLowerCase() ==
              categoriaSelecionada
                  .trim()
                  .toLowerCase(),
        )
        .toList();
  }

  // ============================================================
  // FAVORITO
  // ============================================================

  void alternarFavorito() {
    setState(() {
      favorito = !favorito;
    });

    _mensagem(
      favorito
          ? '${widget.nome} adicionado aos favoritos ❤️'
          : '${widget.nome} removido dos favoritos',
    );
  }

  // ============================================================
  // ADICIONAR PRODUTO
  // ============================================================

  void adicionarProduto({
    required String nome,
    required double preco,
    String? imagem,
    String? produtoId,
  }) {
    if (!restauranteOnline) {
      _mensagem(
        'Este restaurante está fechado e não está aceitando pedidos.',
        vermelho: true,
      );
      return;
    }

    final restauranteId =
        widget.restauranteId.trim();

    if (restauranteId.isEmpty) {
      _mensagem(
        'Não foi possível identificar o restaurante.',
        vermelho: true,
      );
      return;
    }

    setState(() {
      final index = carrinho.indexWhere(
        (item) =>
            item.produtoId == produtoId &&
            produtoId != null,
      );

      if (index >= 0) {
        carrinho[index].quantidade++;
      } else {
        carrinho.add(
          CartItem(
            produtoId: produtoId,
            nome: nome,
            preco: preco,
            imagem: imagem,
            restauranteId: restauranteId,
          ),
        );
      }
    });

    _mensagem(
      '$nome adicionado ao carrinho!',
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mensagem(
    String texto, {
    bool vermelho = false,
    Duration duracao =
        const Duration(seconds: 1),
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
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          duration: duracao,
        ),
      );
  }

  // ============================================================
  // CARRINHO
  // ============================================================

  double get totalCarrinho {
    return carrinho.fold(
      0,
      (total, item) =>
          total +
          item.preco *
              item.quantidade,
    );
  }

  int get quantidadeItens {
    return carrinho.fold(
      0,
      (total, item) =>
          total +
          item.quantidade,
    );
  }

  void abrirCarrinho() {
    if (!restauranteOnline) {
      _mensagem(
        'Este restaurante está fechado e não está aceitando pedidos.',
        vermelho: true,
      );
      return;
    }

    final restauranteId =
        widget.restauranteId.trim();

    if (restauranteId.isEmpty) {
      _mensagem(
        'Não foi possível identificar o restaurante.',
        vermelho: true,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          itens: carrinho,
          restauranteId: restauranteId,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ============================================================
  // PREÇO
  // ============================================================

  double _precoProduto(dynamic valor) {
    if (valor is num) {
      return valor.toDouble();
    }

    final texto =
        valor?.toString().trim() ?? '';

    if (texto.isEmpty) {
      return 0;
    }

    String normalizado;

    if (texto.contains(',')) {
      normalizado = texto
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
    } else {
      normalizado = texto
          .replaceAll('R\$', '')
          .replaceAll(' ', '');
    }

    return double.tryParse(
          normalizado,
        ) ??
        0;
  }

  String _formatarPreco(double preco) {
    return 'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // URL IMAGEM
  // ============================================================

  String _urlImagemProduto(
    String imagem,
  ) {
    if (imagem.startsWith('http://') ||
        imagem.startsWith('https://')) {
      return imagem;
    }

    final baseUrl =
        Api.baseUrl.replaceFirst(
      RegExp(r'/api/?$'),
      '',
    );

    if (imagem.startsWith('/')) {
      return '$baseUrl$imagem';
    }

    return '$baseUrl/$imagem';
  }

  // ============================================================
  // URL LOGO
  // ============================================================

  String _urlLogo(
    String imagem,
  ) {
    final valor = imagem.trim();

    if (valor.startsWith('http://') ||
        valor.startsWith('https://')) {
      return valor;
    }

    final baseUrl =
        Api.baseUrl.replaceFirst(
      RegExp(r'/api/?$'),
      '',
    );

    if (valor.startsWith('/')) {
      return '$baseUrl$valor';
    }

    return '$baseUrl/$valor';
  }

  // ============================================================
  // LOGO BASE64
  // ============================================================

  Widget? _logoBase64Widget() {
    if (logoBase64 == null ||
        logoBase64!.trim().isEmpty) {
      return null;
    }

    try {
      String base64String =
          logoBase64!.trim();

      if (base64String.contains(',')) {
        base64String =
            base64String.split(',').last;
      }

      final bytes =
          base64Decode(base64String);

      return Image.memory(
        bytes,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) {
          return _iconeLogo();
        },
      );
    } catch (e) {
      debugPrint(
        'Erro ao carregar logoBase64: $e',
      );

      return null;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: RefreshIndicator(
        color: laranja,
        onRefresh: () async {
          await Future.wait([
            _carregarProdutos(),
            _verificarStatusRestaurante(),
          ]);
        },
        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ==================================================
            // HEADER
            // ==================================================

            SliverAppBar(
              expandedHeight: 410,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: laranja,
              foregroundColor: Colors.white,
              leading: _botaoHeader(
                icon:
                    Icons.arrow_back_ios_new_rounded,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              actions: [
                _botaoHeader(
                  icon: favorito
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  onPressed:
                      alternarFavorito,
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace:
                  FlexibleSpaceBar(
                collapseMode:
                    CollapseMode.parallax,
                background:
                    _cabecalhoRestaurante(),
              ),
            ),

            // ==================================================
            // AVISO OFFLINE
            // ==================================================

            if (!carregandoStatus &&
                !restauranteOnline)
              SliverToBoxAdapter(
                child:
                    _avisoRestauranteOffline(),
              ),

            // ==================================================
            // CARDÁPIO
            // ==================================================

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  24,
                  18,
                  12,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Cardápio',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (produtos.isNotEmpty)
                      _contadorProdutos(),
                  ],
                ),
              ),
            ),

            // ==================================================
            // CATEGORIAS
            // ==================================================

            if (!carregandoProdutos &&
                produtos.isNotEmpty)
              SliverToBoxAdapter(
                child: _categorias(),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 10),
            ),

            // ==================================================
            // PRODUTOS
            // ==================================================

            if (carregandoProdutos)
              const SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.all(70),
                  child: Center(
                    child:
                        CircularProgressIndicator(
                      color: laranja,
                    ),
                  ),
                ),
              )
            else if (erroProdutos != null)
              SliverToBoxAdapter(
                child:
                    _estadoErroProdutos(),
              )
            else if (produtos.isEmpty)
              SliverToBoxAdapter(
                child:
                    _estadoVazioProdutos(),
              )
            else if (produtosFiltrados.isEmpty)
              SliverToBoxAdapter(
                child:
                    _estadoVazioCategoria(),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  140,
                ),
                sliver: SliverList(
                  delegate:
                      SliverChildBuilderDelegate(
                    (
                      context,
                      index,
                    ) {
                      return produtoCard(
                        produto:
                            produtosFiltrados[index],
                      );
                    },
                    childCount:
                        produtosFiltrados.length,
                  ),
                ),
              ),
          ],
        ),
      ),

      // ========================================================
      // CARRINHO
      // ========================================================

      floatingActionButton:
          quantidadeItens > 0 &&
                  restauranteOnline
              ? _botaoCarrinho()
              : null,

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  // ============================================================
  // HEADER DO RESTAURANTE
  // ============================================================

  Widget _cabecalhoRestaurante() {
    return Container(
      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF97316),
            Color(0xFFEA580C),
            Color(0xFFC2410C),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: 40,
            child: Container(
              width: 210,
              height: 210,
              decoration:
                  BoxDecoration(
                color:
                    Colors.white.withValues(
                  alpha: 0.08,
                ),
                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            left: -90,
            bottom: -70,
            child: Container(
              width: 230,
              height: 230,
              decoration:
                  BoxDecoration(
                color:
                    Colors.black.withValues(
                  alpha: 0.07,
                ),
                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          Align(
            alignment:
                Alignment.bottomCenter,
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                78,
                20,
                22,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  // ==================================================
                  // LOGO REAL DO RESTAURANTE
                  // ==================================================

                  _logoRestaurante(),

                  const SizedBox(height: 12),

                  // ==================================================
                  // NOME
                  // ==================================================

                  Text(
                    widget.nome,
                    textAlign:
                        TextAlign.center,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 7),

                  // STATUS

                  _statusPremium(),

                  const SizedBox(height: 8),

                  // DESCRIÇÃO

                  if (widget.descricao
                      .trim()
                      .isNotEmpty)
                    Text(
                      widget.descricao,
                      textAlign:
                          TextAlign.center,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            Colors.white.withValues(
                          alpha: 0.88,
                        ),
                        fontSize: 12,
                      ),
                    ),

                  const SizedBox(height: 10),

                  // INFORMAÇÕES

                  Wrap(
                    alignment:
                        WrapAlignment.center,
                    spacing: 7,
                    runSpacing: 6,
                    children: [
                      _informacaoHeader(
                        Icons.star_rounded,
                        widget.avaliacao.isEmpty
                            ? '5,0'
                            : widget.avaliacao,
                      ),
                      _informacaoHeader(
                        Icons.access_time_rounded,
                        '30–45 min',
                      ),
                      _informacaoHeader(
                        Icons.delivery_dining_rounded,
                        'Entrega',
                      ),
                    ],
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
  // LOGO RESTAURANTE
  // ============================================================

  Widget _logoRestaurante() {
    final logoBase64Widget =
        _logoBase64Widget();

    return Container(
      width: 100,
      height: 100,
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.20,
            ),
            blurRadius: 28,
            offset:
                const Offset(
              0,
              12,
            ),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(30),
        child:
            // ==================================================
            // PRIORIDADE 1: BASE64
            // ==================================================
            logoBase64Widget ??
                // ==================================================
                // PRIORIDADE 2: URL DA LOGO
                // ==================================================
                (logoRestaurante != null &&
                        logoRestaurante!
                            .trim()
                            .isNotEmpty
                    ? Image.network(
                        _urlLogo(
                          logoRestaurante!,
                        ),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        loadingBuilder:
                            (
                          context,
                          child,
                          progress,
                        ) {
                          if (progress ==
                              null) {
                            return child;
                          }

                          return _iconeLogo();
                        },
                        errorBuilder:
                            (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return _iconeLogo();
                        },
                      )
                    : _iconeLogo()),
      ),
    );
  }

  // ============================================================
  // ÍCONE PADRÃO DA LOGO
  // ============================================================

  Widget _iconeLogo() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.white,
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: laranja,
          size: 48,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS PREMIUM
  // ============================================================

  Widget _statusPremium() {
    return Container(
      constraints:
          const BoxConstraints(
        maxWidth: 280,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color: restauranteOnline
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626),
        borderRadius:
            BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                const BoxDecoration(
              color: Colors.white,
              shape:
                  BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              restauranteOnline
                  ? 'ONLINE • ACEITANDO PEDIDOS'
                  : 'OFFLINE • PEDIDOS INDISPONÍVEIS',
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMAÇÃO
  // ============================================================

  Widget _informacaoHeader(
    IconData icon,
    String texto,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white.withValues(
          alpha: 0.14,
        ),
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(
          color:
              Colors.white.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            texto,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTÃO HEADER
  // ============================================================

  Widget _botaoHeader({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.black.withValues(
          alpha: 0.18,
        ),
        shape:
            BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // ============================================================
  // CONTADOR
  // ============================================================

  Widget _contadorProdutos() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(30),
      ),
      child: Text(
        '${produtos.length} ${produtos.length == 1 ? 'item' : 'itens'}',
        style:
            const TextStyle(
          color: laranja,
          fontSize: 11,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORIAS
  // ============================================================

  Widget _categorias() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        scrollDirection:
            Axis.horizontal,
        itemCount:
            categorias.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 9),
        itemBuilder:
            (_, index) {
          final categoria =
              categorias[index];

          final selecionada =
              categoria ==
                  categoriaSelecionada;

          return GestureDetector(
            onTap: () {
              setState(() {
                categoriaSelecionada =
                    categoria;
              });
            },
            child:
                AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 200,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 11,
              ),
              decoration:
                  BoxDecoration(
                gradient: selecionada
                    ? const LinearGradient(
                        colors: [
                          laranja,
                          laranjaEscuro,
                        ],
                      )
                    : null,
                color: selecionada
                    ? null
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  30,
                ),
                border:
                    Border.all(
                  color: selecionada
                      ? Colors.transparent
                      : Colors.black12,
                ),
              ),
              child: Text(
                categoria,
                style: TextStyle(
                  color: selecionada
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // OFFLINE
  // ============================================================

  Widget _avisoRestauranteOffline() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        15,
        16,
        0,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(
          color:
              Colors.red.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
                BoxDecoration(
              color:
                  Colors.red.withValues(
                alpha: 0.10,
              ),
              shape:
                  BoxShape.circle,
            ),
            child:
                const Icon(
              Icons.storefront_rounded,
              color:
                  Colors.redAccent,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Restaurante fechado',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 15,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Este restaurante não está aceitando pedidos agora.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
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
  // PRODUTO CARD
  // ============================================================

  Widget produtoCard({
    required Map<String, dynamic> produto,
  }) {
    final nome =
        produto['nome']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? produto['nome'].toString()
            : 'Produto';

    final descricao =
        produto['descricao']
                ?.toString() ??
            '';

    final preco =
        _precoProduto(
      produto['preco'],
    );

    final imagem =
        produto['imagem']?.toString();

    final produtoId =
        (produto['id'] ??
                produto['_id'] ??
                produto['produtoId'])
            ?.toString();

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        border:
            Border.all(
          color:
              Colors.black.withValues(
            alpha: 0.035,
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
                const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 105,
              height: 105,
              child: Hero(
                tag:
                    'produto_${produtoId ?? nome}',
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  child:
                      _imagemProduto(
                    imagem,
                    tamanho: 105,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      height: 1.15,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  if (descricao
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      descricao,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _formatarPreco(
                            preco,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color: laranja,
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _botaoAdicionar(
                        nome: nome,
                        preco: preco,
                        imagem: imagem,
                        produtoId:
                            produtoId,
                      ),
                    ],
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
  // BOTÃO ADICIONAR
  // ============================================================

  Widget _botaoAdicionar({
    required String nome,
    required double preco,
    String? imagem,
    String? produtoId,
  }) {
    return GestureDetector(
      behavior:
          HitTestBehavior.opaque,
      onTap: () {
        adicionarProduto(
          nome: nome,
          preco: preco,
          imagem: imagem,
          produtoId: produtoId,
        );
      },
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 180,
        ),
        width: 44,
        height: 44,
        decoration:
            BoxDecoration(
          gradient: restauranteOnline
              ? const LinearGradient(
                  colors: [
                    laranja,
                    laranjaEscuro,
                  ],
                )
              : null,
          color: restauranteOnline
              ? null
              : Colors.grey.shade400,
          shape:
              BoxShape.circle,
          boxShadow:
              restauranteOnline
                  ? [
                      BoxShadow(
                        color:
                            laranja.withValues(
                          alpha: 0.30,
                        ),
                        blurRadius: 12,
                        offset:
                            const Offset(
                          0,
                          5,
                        ),
                      ),
                    ]
                  : null,
        ),
        child: Icon(
          restauranteOnline
              ? Icons.add_rounded
              : Icons.lock_outline_rounded,
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }

  // ============================================================
  // IMAGEM PRODUTO
  // ============================================================

  Widget _imagemProduto(
    String? imagem, {
    double tamanho = 105,
  }) {
    if (imagem == null ||
        imagem.trim().isEmpty) {
      return _placeholderImagem(
        tamanho,
      );
    }

    return Image.network(
      _urlImagemProduto(
        imagem.trim(),
      ),
      width: tamanho,
      height: tamanho,
      fit: BoxFit.cover,
      loadingBuilder:
          (
        context,
        child,
        progress,
      ) {
        if (progress == null) {
          return child;
        }

        return _loadingImagem(
          tamanho,
        );
      },
      errorBuilder:
          (
        context,
        error,
        stackTrace,
      ) {
        return _placeholderImagem(
          tamanho,
        );
      },
    );
  }

  Widget _placeholderImagem(
    double tamanho,
  ) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFFFFEAD9),
            Color(0xFFFFD5B5),
          ],
        ),
      ),
      child: const Icon(
        Icons.fastfood_rounded,
        color: laranja,
        size: 42,
      ),
    );
  }

  Widget _loadingImagem(
    double tamanho,
  ) {
    return Container(
      width: tamanho,
      height: tamanho,
      color: fundoImagem,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child:
              CircularProgressIndicator(
            strokeWidth: 2,
            color: laranja,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARRINHO FLUTUANTE
  // ============================================================

  Widget _botaoCarrinho() {
    return GestureDetector(
      onTap: abrirCarrinho,
      child: Container(
        height: 64,
        margin:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration:
            BoxDecoration(
          gradient:
              const LinearGradient(
            begin:
                Alignment.centerLeft,
            end:
                Alignment.centerRight,
            colors: [
              Color(0xFFF97316),
              Color(0xFFEA580C),
            ],
          ),
          borderRadius:
              BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color:
                  laranja.withValues(
                alpha: 0.38,
              ),
              blurRadius: 24,
              offset:
                  const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration:
                  BoxDecoration(
                color:
                    Colors.white.withValues(
                  alpha: 0.18,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '$quantidadeItens ${quantidadeItens == 1 ? 'item' : 'itens'}',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          Colors.white.withValues(
                        alpha: 0.85,
                      ),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    _formatarPreco(
                      totalCarrinho,
                    ),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            const Text(
              'Ver carrinho',
              style:
                  TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(width: 7),

            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ESTADOS
  // ============================================================

  Widget _estadoErroProdutos() {
    return _estadoBase(
      icon:
          Icons.cloud_off_rounded,
      titulo:
          'Não foi possível carregar o cardápio',
      descricao:
          'Verifique a conexão com o servidor e tente novamente.',
      botao:
          ElevatedButton.icon(
        onPressed:
            _carregarProdutos,
        icon:
            const Icon(
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
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _estadoVazioProdutos() {
    return _estadoBase(
      icon:
          Icons.restaurant_menu_rounded,
      titulo:
          'Nenhum produto disponível',
      descricao:
          'Este restaurante ainda não possui produtos disponíveis.',
    );
  }

  Widget _estadoVazioCategoria() {
    return _estadoBase(
      icon:
          Icons.search_off_rounded,
      titulo:
          'Nenhum produto nesta categoria',
    );
  }

  Widget _estadoBase({
    required IconData icon,
    required String titulo,
    String? descricao,
    Widget? botao,
  }) {
    return Container(
      margin:
          const EdgeInsets.all(16),
      padding:
          const EdgeInsets.all(30),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration:
                BoxDecoration(
              color:
                  laranja.withValues(
                alpha: 0.10,
              ),
              shape:
                  BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: laranja,
              size: 36,
            ),
          ),

          const SizedBox(height: 17),

          Text(
            titulo,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          if (descricao != null) ...[
            const SizedBox(height: 8),
            Text(
              descricao,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],

          if (botao != null) ...[
            const SizedBox(height: 20),
            botao,
          ],
        ],
      ),
    );
  }
}