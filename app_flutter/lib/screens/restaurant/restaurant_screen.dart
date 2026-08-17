import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api.dart';
import '../cart/cart_screen.dart';
import 'restaurant_orders_screen.dart';

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

  bool favorito = false;
  bool carregandoProdutos = true;
  bool restauranteOnline = false;
  bool carregandoStatus = true;

  Timer? _timerStatus;

  String? erroProdutos;

  List<Map<String, dynamic>> produtos = [];

  String categoriaSelecionada = 'Todos';

  @override
  void initState() {
    super.initState();

    _salvarRestauranteSelecionado();
    _carregarProdutos();
    _verificarStatusRestaurante();

    _timerStatus = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _verificarStatusRestaurante(),
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
    } catch (e) {
      debugPrint('Erro ao salvar restaurante: $e');
    }
  }

  // ============================================================
  // BOOLEANO
  // ============================================================

  bool _converterBooleano(
    dynamic valor, {
    bool padrao = false,
  }) {
    if (valor == null) return padrao;

    if (valor is bool) return valor;

    final texto = valor.toString().trim().toLowerCase();

    if ([
      'true',
      '1',
      'sim',
      'aberto',
      'online',
    ].contains(texto)) {
      return true;
    }

    if ([
      'false',
      '0',
      'nao',
      'não',
      'fechado',
      'offline',
    ].contains(texto)) {
      return false;
    }

    return padrao;
  }

  // ============================================================
  // STATUS
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
      final resposta = await http
          .get(
            Uri.parse(
              '${Api.baseUrl}/restaurants/$restauranteId',
            ),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (resposta.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          restauranteOnline = false;
          carregandoStatus = false;
        });

        return;
      }

      final dados = jsonDecode(resposta.body);

      if (dados is! Map) return;

      final restaurante =
          dados['restaurante'] is Map
              ? Map<String, dynamic>.from(
                  dados['restaurante'],
                )
              : Map<String, dynamic>.from(dados);

      final status =
          restaurante['status']
                  ?.toString()
                  .trim()
                  .toUpperCase() ??
              '';

      final online = _converterBooleano(
        restaurante['online'],
      );

      final aberto = _converterBooleano(
        restaurante['aberto'],
      );

      final disponivel =
          status == 'ABERTO' &&
          online &&
          aberto;

      if (!mounted) return;

      final estavaOnline = restauranteOnline;

      setState(() {
        restauranteOnline = disponivel;
        carregandoStatus = false;
      });

      if (estavaOnline &&
          !disponivel &&
          carrinho.isNotEmpty) {
        setState(() {
          carrinho.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O restaurante ficou fechado. O carrinho foi atualizado.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Erro ao verificar restaurante: $e',
      );

      if (!mounted) return;

      setState(() {
        restauranteOnline = false;
        carregandoStatus = false;
      });
    }
  }

  // ============================================================
  // PRODUTOS
  // ============================================================

  Future<void> _carregarProdutos() async {
    if (mounted) {
      setState(() {
        carregandoProdutos = true;
        erroProdutos = null;
      });
    }

    try {
      final restauranteId =
          widget.restauranteId.trim();

      if (restauranteId.isEmpty) {
        throw Exception(
          'ID do restaurante não informado.',
        );
      }

      final resposta = await http
          .get(
            Uri.parse(
              '${Api.baseUrl}/products',
            ),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      if (resposta.statusCode < 200 ||
          resposta.statusCode >= 300) {
        throw Exception(
          'Erro ${resposta.statusCode}',
        );
      }

      final resultado = jsonDecode(
        resposta.body,
      );

      if (resultado is! List) {
        throw Exception(
          'Resposta inválida da API.',
        );
      }

      final produtosApi = resultado
          .whereType<Map>()
          .map(
            (produto) =>
                Map<String, dynamic>.from(
              produto,
            ),
          )
          .where(
            (produto) =>
                produto['restauranteId']
                    ?.toString() ==
                restauranteId,
          )
          .where(
            (produto) =>
                produto['disponivel'] != false,
          )
          .toList();

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
      final categoria =
          produto['categoria']
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
                  .toLowerCase() ==
              categoriaSelecionada
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          favorito
              ? '${widget.nome} adicionado aos favoritos ❤️'
              : '${widget.nome} removido dos favoritos',
        ),
        backgroundColor: laranja,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 1),
      ),
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
            restauranteId:
                widget.restauranteId,
          ),
        );
      }
    });

    _mensagem(
      '$nome adicionado ao carrinho!',
    );
  }

  void _mensagem(
    String texto, {
    bool vermelho = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor:
            vermelho
                ? Colors.redAccent
                : laranja,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        duration: const Duration(seconds: 1),
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

  double _precoProduto(
    dynamic valor,
  ) {
    if (valor is num) {
      return valor.toDouble();
    }

    return double.tryParse(
          valor
                  ?.toString()
                  .replaceAll(',', '.') ??
              '',
        ) ??
        0;
  }

  String _formatarPreco(
    double preco,
  ) {
    return 'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // IMAGEM
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,

      body: RefreshIndicator(
        color: laranja,

        onRefresh: () async {
          await _carregarProdutos();
          await _verificarStatusRestaurante();
        },

        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          slivers: [
            // ==================================================
            // HEADER CORRIGIDO
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
                onPressed: () =>
                    Navigator.pop(context),
              ),

              actions: [
                _botaoHeader(
                  icon: favorito
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  onPressed:
                      alternarFavorito,
                ),

                const SizedBox(width: 4),

                _botaoHeader(
                  icon:
                      Icons.receipt_long_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const RestaurantOrdersScreen(),
                      ),
                    );
                  },
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
            // TÍTULO CARDÁPIO
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
      // CARRINHO FLUTUANTE
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
  // HEADER RESTAURANTE — CORRIGIDO
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
          // Círculo decorativo superior
          Positioned(
            right: -70,
            top: 40,
            child: Container(
              width: 210,
              height: 210,
              decoration:
                  BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.08,
                ),
                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          // Círculo decorativo inferior
          Positioned(
            left: -90,
            bottom: -70,
            child: Container(
              width: 230,
              height: 230,
              decoration:
                  BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.07,
                ),
                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          // ==================================================
          // CONTEÚDO ADAPTÁVEL
          // ==================================================

          Align(
            alignment:
                Alignment.bottomCenter,

            child: SingleChildScrollView(
              physics:
                  const NeverScrollableScrollPhysics(),

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

                  mainAxisAlignment:
                      MainAxisAlignment.end,

                  children: [
                    // ==================================================
                    // LOGO
                    // ==================================================

                    Container(
                      width: 100,
                      height: 100,

                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(
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

                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: laranja,
                        size: 48,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

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

                    const SizedBox(
                      height: 7,
                    ),

                    // ==================================================
                    // STATUS
                    // ==================================================

                    _statusPremium(),

                    const SizedBox(
                      height: 8,
                    ),

                    // ==================================================
                    // DESCRIÇÃO
                    // ==================================================

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
                          color: Colors.white
                              .withValues(
                            alpha: 0.88,
                          ),
                          fontSize: 12,
                        ),
                      ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==================================================
                    // INFORMAÇÕES
                    // ==================================================

                    Wrap(
                      alignment:
                          WrapAlignment.center,

                      spacing: 7,
                      runSpacing: 6,

                      children: [
                        _informacaoHeader(
                          Icons.star_rounded,
                          widget.avaliacao,
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
          ),
        ],
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

          const SizedBox(
            width: 7,
          ),

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
  // INFORMAÇÃO HEADER
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
        color: Colors.white.withValues(
          alpha: 0.14,
        ),

        borderRadius:
            BorderRadius.circular(20),

        border:
            Border.all(
          color: Colors.white.withValues(
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

          const SizedBox(
            width: 4,
          ),

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
        color: Colors.black.withValues(
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
        '${produtos.length} itens',

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
                const SizedBox(
          width: 9,
        ),

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
                    BorderRadius.circular(30),

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
          color: Colors.red.withValues(
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
              color: Colors.red.withValues(
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

          const SizedBox(
            width: 12,
          ),

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

                SizedBox(
                  height: 3,
                ),

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
        produto['id']?.toString();

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
          color: Colors.black.withValues(
            alpha: 0.035,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
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
            // ==================================================
            // IMAGEM
            // ==================================================

            SizedBox(
              width: 105,
              height: 105,

              child: Hero(
                tag:
                    'produto_${produtoId ?? nome}',

                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),

                  child:
                      _imagemProduto(
                    imagem,
                    tamanho: 105,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // ==================================================
            // INFORMAÇÕES
            // ==================================================

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
                    const SizedBox(
                      height: 7,
                    ),

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

                  const SizedBox(
                    height: 10,
                  ),

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

                      const SizedBox(
                        width: 8,
                      ),

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
              color: laranja.withValues(
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
                color: Colors.white.withValues(
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

            const SizedBox(
              width: 11,
            ),

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
                      color: Colors.white
                          .withValues(
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

            const SizedBox(
              width: 6,
            ),

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

            const SizedBox(
              width: 7,
            ),

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
            color: Colors.black.withValues(
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
              color: laranja.withValues(
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

          const SizedBox(
            height: 17,
          ),

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
            const SizedBox(
              height: 8,
            ),

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
            const SizedBox(
              height: 20,
            ),
            botao,
          ],
        ],
      ),
    );
  }
}