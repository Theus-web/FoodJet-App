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
  static const Color fundo = Color(0xFFF7F7F8);
  static const Color fundoImagem = Color(0xFFFFE5D3);

  final List<CartItem> carrinho = [];

  bool favorito = false;
  bool carregandoProdutos = true;

  String? erroProdutos;

  List<Map<String, dynamic>> produtos = [];

  String categoriaSelecionada = 'Todos';

  @override
  void initState() {
    super.initState();

    _salvarRestauranteSelecionado();
    _carregarProdutos();
  }

  // ==========================================================
  // SALVAR RESTAURANTE SELECIONADO
  // ==========================================================

  Future<void> _salvarRestauranteSelecionado() async {
    final restauranteId =
        widget.restauranteId.trim();

    if (restauranteId.isEmpty) {
      debugPrint(
        '⚠️ RESTAURANTE SEM ID.',
      );
      return;
    }

    try {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'restauranteSelecionadoId',
        restauranteId,
      );

      debugPrint(
        '🏪 RESTAURANTE SELECIONADO: $restauranteId',
      );
    } catch (e) {
      debugPrint(
        '❌ ERRO AO SALVAR RESTAURANTE: $e',
      );
    }
  }

  // ==========================================================
  // BUSCAR PRODUTOS
  // ==========================================================

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

      final url = Uri.parse(
        '${Api.baseUrl}/products',
      );

      debugPrint(
        '================================',
      );

      debugPrint(
        '🍔 BUSCANDO PRODUTOS',
      );

      debugPrint(
        '🏪 RESTAURANTE ID: $restauranteId',
      );

      debugPrint(
        '🌐 URL: $url',
      );

      debugPrint(
        '================================',
      );

      final resposta = await http
          .get(
            url,
            headers: {
              'Content-Type':
                  'application/json',
            },
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      debugPrint(
        '📡 STATUS PRODUTOS: ${resposta.statusCode}',
      );

      debugPrint(
        '📡 RESPOSTA PRODUTOS: ${resposta.body}',
      );

      if (resposta.statusCode < 200 ||
          resposta.statusCode >= 300) {
        throw Exception(
          'Erro ${resposta.statusCode} ao buscar produtos.',
        );
      }

      final resultado =
          jsonDecode(resposta.body);

      if (resultado is! List) {
        throw Exception(
          'A API não retornou uma lista de produtos.',
        );
      }

      final produtosApi = resultado
          .whereType<Map<String, dynamic>>()
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

      if (!mounted) {
        return;
      }

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
        '❌ ERRO AO BUSCAR PRODUTOS: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        carregandoProdutos = false;

        erroProdutos =
            'Não foi possível carregar o cardápio.';
      });
    }
  }

  // ==========================================================
  // CATEGORIAS
  // ==========================================================

  List<String> get categorias {
    final categoriasSet = <String>{};

    for (final produto in produtos) {
      final categoria =
          produto['categoria']
              ?.toString()
              .trim();

      if (categoria != null &&
          categoria.isNotEmpty) {
        categoriasSet.add(categoria);
      }
    }

    final lista =
        categoriasSet.toList();

    lista.sort(
      (a, b) =>
          a.toLowerCase().compareTo(
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
    if (categoriaSelecionada ==
        'Todos') {
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

  // ==========================================================
  // FAVORITO
  // ==========================================================

  void alternarFavorito() {
    setState(() {
      favorito = !favorito;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          favorito
              ? '${widget.nome} adicionado aos favoritos ❤️'
              : '${widget.nome} removido dos favoritos',
        ),
        backgroundColor: laranja,
        duration:
            const Duration(seconds: 1),
      ),
    );
  }

  // ==========================================================
  // ADICIONAR PRODUTO
  // ==========================================================

  void adicionarProduto({
    required String nome,
    required double preco,
    String? imagem,
    String? produtoId,
  }) {
    setState(() {
      final index =
          carrinho.indexWhere(
        (item) =>
            item.produtoId ==
                produtoId &&
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
            restauranteId: widget.restauranteId,
          ),
        );
      }
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$nome adicionado ao carrinho!',
        ),
        backgroundColor: laranja,
        duration:
            const Duration(seconds: 1),
      ),
    );
  }

  // ==========================================================
  // TOTAL
  // ==========================================================

  double get totalCarrinho {
    return carrinho.fold(
      0,
      (total, item) =>
          total +
          (item.preco *
              item.quantidade),
    );
  }

  int get quantidadeItens {
    return carrinho.fold(
      0,
      (total, item) =>
          total + item.quantidade,
    );
  }

  // ==========================================================
  // ABRIR CARRINHO
  // ==========================================================

  void abrirCarrinho() {
  final restauranteId = widget.restauranteId.trim();

  if (restauranteId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível identificar o restaurante.',
        ),
        backgroundColor: Colors.redAccent,
      ),
    );

    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CartScreen(
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

  // ==========================================================
  // PREÇO
  // ==========================================================

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

  // ==========================================================
  // URL IMAGEM
  // ==========================================================

  String _urlImagemProduto(
    String imagem,
  ) {
    if (imagem.startsWith(
          'http://',
        ) ||
        imagem.startsWith(
          'https://',
        )) {
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

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: fundo,

      body: RefreshIndicator(
        color: laranja,

        onRefresh:
            _carregarProdutos,

        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          slivers: [
            // ==================================================
            // HEADER
            // ==================================================

            SliverAppBar(
              expandedHeight: 285,

              pinned: true,

              elevation: 0,

              backgroundColor:
                  laranja,

              foregroundColor:
                  Colors.white,

              leading: Padding(
                padding:
                    const EdgeInsets.all(8),

                child: _botaoHeader(
                  icon:
                      Icons.arrow_back,

                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                ),
              ),

              actions: [
                _botaoHeader(
                  icon: favorito
                      ? Icons.favorite
                      : Icons.favorite_border,

                  onPressed:
                      alternarFavorito,
                ),

                const SizedBox(
                  width: 5,
                ),

                _botaoHeader(
                  icon:
                      Icons.receipt_long,

                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const RestaurantOrdersScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(
                  width: 8,
                ),
              ],

              flexibleSpace:
                  FlexibleSpaceBar(
                background:
                    _cabecalhoRestaurante(),
              ),
            ),

            // ==================================================
            // TÍTULO
            // ==================================================

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  25,
                  16,
                  10,
                ),

                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Cardápio',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    if (produtos.isNotEmpty)
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFFFE8D8,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),

                        child: Text(
                          '${produtos.length} itens',
                          style:
                              const TextStyle(
                            color:
                                laranja,
                            fontSize: 11,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
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
                child: SizedBox(
                  height: 55,

                  child:
                      ListView.separated(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 16,
                    ),

                    scrollDirection:
                        Axis.horizontal,

                    itemCount:
                        categorias.length,

                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      width: 8,
                    ),

                    itemBuilder:
                        (context, index) {
                      final categoria =
                          categorias[
                              index];

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
                            milliseconds:
                                180,
                          ),

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 17,
                            vertical: 10,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                selecionada
                                    ? laranja
                                    : Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              25,
                            ),

                            border:
                                Border.all(
                              color:
                                  selecionada
                                      ? laranja
                                      : Colors
                                          .grey
                                          .shade200,
                            ),
                          ),

                          child: Center(
                            child: Text(
                              categoria,

                              style:
                                  TextStyle(
                                color:
                                    selecionada
                                        ? Colors
                                            .white
                                        : Colors
                                            .black87,

                                fontWeight:
                                    FontWeight
                                        .w600,

                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child:
                  SizedBox(height: 10),
            ),

            // ==================================================
            // PRODUTOS
            // ==================================================

            if (carregandoProdutos)
              const SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.all(60),

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
            else if (produtosFiltrados
                .isEmpty)
              SliverToBoxAdapter(
                child:
                    _estadoVazioCategoria(),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  16,
                  5,
                  16,
                  130,
                ),

                sliver: SliverList(
                  delegate:
                      SliverChildBuilderDelegate(
                    (context, index) {
                      return produtoCard(
                        produto:
                            produtosFiltrados[
                                index],
                      );
                    },

                    childCount:
                        produtosFiltrados
                            .length,
                  ),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton:
          quantidadeItens > 0
              ? _botaoCarrinho()
              : null,

      floatingActionButtonLocation:
          FloatingActionButtonLocation
              .centerFloat,
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _cabecalhoRestaurante() {
    return Container(
      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topCenter,
          end:
              Alignment.bottomCenter,
          colors: [
            laranja,
            Color(0xFFFF9A5A),
          ],
        ),
      ),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.end,

        children: [
          Container(
            width: 105,
            height: 105,

            margin:
                const EdgeInsets.only(
              bottom: 13,
            ),

            decoration:
                BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(
                28,
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(
                    alpha: 0.15,
                  ),

                  blurRadius: 15,

                  offset:
                      const Offset(
                    0,
                    7,
                  ),
                ),
              ],
            ),

            child: const Icon(
              Icons.restaurant,
              color: laranja,
              size: 52,
            ),
          ),

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
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 25,
            ),

            child: Text(
              widget.descricao,

              textAlign:
                  TextAlign.center,

              maxLines: 1,

              overflow:
                  TextOverflow.ellipsis,

              style: TextStyle(
                color: Colors.white
                    .withValues(
                  alpha: 0.9,
                ),

                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(
            height: 13,
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              _informacaoHeader(
                Icons.star_rounded,
                widget.avaliacao,
              ),

              const SizedBox(
                width: 12,
              ),

              _informacaoHeader(
                Icons
                    .access_time_rounded,
                '30–45 min',
              ),

              const SizedBox(
                width: 12,
              ),

              _informacaoHeader(
                Icons.delivery_dining,
                'Entrega',
              ),
            ],
          ),

          const SizedBox(
            height: 22,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFORMAÇÃO HEADER
  // ==========================================================

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
        color: Colors.white
            .withValues(
          alpha: 0.16,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 15,
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            texto,

            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTÃO HEADER
  // ==========================================================

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
        color: Colors.black
            .withValues(
          alpha: 0.18,
        ),

        shape: BoxShape.circle,
      ),

      child: IconButton(
        onPressed: onPressed,

        icon: Icon(
          icon,
          color: Colors.white,
          size: 21,
        ),
      ),
    );
  }

  // ==========================================================
  // CARD PRODUTO
  // ==========================================================

  Widget produtoCard({
    required Map<String, dynamic>
        produto,
  }) {
    final nome =
        produto['nome']
                ?.toString() ??
            'Produto';

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
      margin:
          const EdgeInsets.only(
        bottom: 13,
      ),

      padding:
          const EdgeInsets.all(12),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: Colors.black
              .withValues(
            alpha: 0.04,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.045,
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
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              16,
            ),

            child:
                _imagemProduto(
              imagem,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(
                top: 2,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    nome,

                    maxLines: 2,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (descricao
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      descricao,

                      maxLines: 2,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade600,

                        fontSize: 12,

                        height: 1.3,
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    _formatarPreco(
                      preco,
                    ),

                    style:
                        const TextStyle(
                      color: laranja,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.only(
              top: 38,
            ),

            child: GestureDetector(
              onTap: () {
                adicionarProduto(
                  nome: nome,
                  preco: preco,
                  imagem: imagem,
                  produtoId:
                      produtoId,
                );
              },

              child: Container(
                width: 40,
                height: 40,

                decoration:
                    const BoxDecoration(
                  color: laranja,
                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons.add,
                  color:
                      Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // IMAGEM
  // ==========================================================

  Widget _imagemProduto(
    String? imagem,
  ) {
    if (imagem == null ||
        imagem.isEmpty) {
      return _placeholderImagem();
    }

    final url =
        _urlImagemProduto(
      imagem,
    );

    return Image.network(
      url,

      width: 105,
      height: 105,

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

        return _loadingImagem();
      },

      errorBuilder:
          (
        context,
        error,
        stackTrace,
      ) {
        return _placeholderImagem();
      },
    );
  }

  Widget _placeholderImagem() {
    return Container(
      width: 105,
      height: 105,

      decoration:
          BoxDecoration(
        color: fundoImagem,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child: const Icon(
        Icons.fastfood_rounded,
        color: laranja,
        size: 40,
      ),
    );
  }

  Widget _loadingImagem() {
    return Container(
      width: 105,
      height: 105,

      color: fundoImagem,

      child: const Center(
        child:
            CircularProgressIndicator(
          strokeWidth: 2,
          color: laranja,
        ),
      ),
    );
  }

  // ==========================================================
  // BOTÃO CARRINHO
  // ==========================================================

  Widget _botaoCarrinho() {
    return GestureDetector(
      onTap: abrirCarrinho,

      child: Container(
        height: 58,

        margin:
            const EdgeInsets
                .symmetric(
          horizontal: 18,
        ),

        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 18,
        ),

        decoration:
            BoxDecoration(
          color: laranja,

          borderRadius:
              BorderRadius.circular(
            18,
          ),

          boxShadow: [
            BoxShadow(
              color: laranja
                  .withValues(
                alpha: 0.35,
              ),

              blurRadius: 15,

              offset:
                  const Offset(
                0,
                6,
              ),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,

              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withValues(
                  alpha: 0.18,
                ),

                shape:
                    BoxShape.circle,
              ),

              child: const Icon(
                Icons
                    .shopping_bag_outlined,
                color:
                    Colors.white,
                size: 21,
              ),
            ),

            const SizedBox(
              width: 11,
            ),

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    '$quantidadeItens ${quantidadeItens == 1 ? 'item' : 'itens'}',

                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 11,
                    ),
                  ),

                  Text(
                    _formatarPreco(
                      totalCarrinho,
                    ),

                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Text(
              'Ver carrinho',

              style:
                  TextStyle(
                color:
                    Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              width: 5,
            ),

            const Icon(
              Icons
                  .arrow_forward_ios,
              color:
                  Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ERRO
  // ==========================================================

  Widget _estadoErroProdutos() {
    return Container(
      margin:
          const EdgeInsets.all(16),

      padding:
          const EdgeInsets.all(30),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,

            decoration:
                const BoxDecoration(
              color: fundoImagem,
              shape:
                  BoxShape.circle,
            ),

            child: const Icon(
              Icons
                  .cloud_off_rounded,
              color: laranja,
              size: 34,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          const Text(
            'Não foi possível carregar o cardápio',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          const Text(
            'Verifique a conexão com o servidor e tente novamente.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          ElevatedButton.icon(
            onPressed:
                _carregarProdutos,

            icon:
                const Icon(
              Icons.refresh,
            ),

            label:
                const Text(
              'Tentar novamente',
            ),

            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  laranja,

              foregroundColor:
                  Colors.white,

              elevation: 0,

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 20,
                vertical: 13,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // VAZIO
  // ==========================================================

  Widget _estadoVazioProdutos() {
    return Container(
      margin:
          const EdgeInsets.all(16),

      padding:
          const EdgeInsets.all(30),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,

            decoration:
                const BoxDecoration(
              color: fundoImagem,
              shape:
                  BoxShape.circle,
            ),

            child: const Icon(
              Icons
                  .restaurant_menu_outlined,
              color: laranja,
              size: 34,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          const Text(
            'Nenhum produto disponível',

            style:
                TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          const Text(
            'Este restaurante ainda não possui produtos disponíveis.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // VAZIO CATEGORIA
  // ==========================================================

  Widget _estadoVazioCategoria() {
    return Container(
      margin:
          const EdgeInsets.all(16),

      padding:
          const EdgeInsets.all(30),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,

            decoration:
                const BoxDecoration(
              color: fundoImagem,
              shape:
                  BoxShape.circle,
            ),

            child: const Icon(
              Icons.search_off_rounded,
              color: laranja,
              size: 34,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          const Text(
            'Nenhum produto nesta categoria',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}