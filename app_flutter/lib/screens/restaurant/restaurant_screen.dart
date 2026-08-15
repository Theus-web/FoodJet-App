
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api.dart';
import '../cart/cart_screen.dart';
import 'restaurant_orders_screen.dart';

class RestaurantScreen extends StatefulWidget {
  final String nome;
  final String descricao;
  final String avaliacao;
  final String restauranteId;

  const RestaurantScreen({
    super.key,
    required this.nome,
    required this.descricao,
    required this.avaliacao,
    this.restauranteId = '1784400784535',
  });

  @override
  State<RestaurantScreen> createState() =>
      _RestaurantScreenState();
}

class _RestaurantScreenState
    extends State<RestaurantScreen> {
  static const Color laranja =
      Color(0xFFF97316);

  static const Color fundo =
      Color(0xFFF5F5F5);

  final List<CartItem> carrinho = [];

  bool favorito = false;

  bool carregandoProdutos = true;

  String? erroProdutos;

  List<Map<String, dynamic>> produtos = [];

  String categoriaSelecionada = 'Todos';

  @override
  void initState() {
    super.initState();

    _carregarProdutos();
  }

  // ============================================================
  // BUSCAR PRODUTOS
  // ============================================================

  Future<void> _carregarProdutos() async {
    if (mounted) {
      setState(() {
        carregandoProdutos = true;
        erroProdutos = null;
      });
    }

    try {
      final url = Uri.parse(
        '${Api.baseUrl}/products',
      );

      print('================================');
      print('BUSCANDO PRODUTOS');
      print('RESTAURANTE ID: ${widget.restauranteId}');
      print('URL: $url');
      print('================================');

      final resposta = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      print(
        'STATUS PRODUTOS: ${resposta.statusCode}',
      );

      print(
        'RESPOSTA PRODUTOS: ${resposta.body}',
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
                widget.restauranteId,
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
          categoriaSelecionada =
              'Todos';
        }
      });
    } catch (e) {
      print(
        'ERRO AO BUSCAR PRODUTOS: $e',
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

  // ============================================================
  // CATEGORIAS
  // ============================================================

  List<String> get categorias {
    final categoriasSet =
        <String>{};

    for (final produto in produtos) {
      final categoria =
          produto['categoria']
              ?.toString()
              .trim();

      if (categoria != null &&
          categoria.isNotEmpty) {
        categoriasSet.add(
          categoria,
        );
      }
    }

    final lista =
        categoriasSet.toList();

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

  // ============================================================
  // FAVORITO
  // ============================================================

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
        backgroundColor:
            laranja,
        duration:
            const Duration(
          seconds: 1,
        ),
      ),
    );
  }

  // ============================================================
  // ADICIONAR PRODUTO REAL AO CARRINHO
  // ============================================================

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
            produtoId:
                produtoId,
            nome:
                nome,
            preco:
                preco,
            imagem:
                imagem,
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
        backgroundColor:
            laranja,
        duration:
            const Duration(
          seconds: 1,
        ),
      ),
    );
  }

  // ============================================================
  // TOTAL CARRINHO
  // ============================================================

  double get totalCarrinho {
    return carrinho.fold(
      0,
      (total, item) =>
          total +
          (
            item.preco *
            item.quantidade
          ),
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

  // ============================================================
  // ABRIR CARRINHO
  // ============================================================

  void abrirCarrinho() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CartScreen(
          itens: carrinho,
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
                  .replaceAll(
                ',',
                '.',
              ) ??
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
  // URL DA IMAGEM
  // ============================================================

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
      RegExp(
        r'/api/?$',
      ),
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          fundo,

      appBar: AppBar(
        backgroundColor:
            laranja,

        foregroundColor:
            Colors.white,

        title: Text(
          widget.nome,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                favorito
                    ? 'Remover dos favoritos'
                    : 'Adicionar aos favoritos',

            icon:
                Icon(
              favorito
                  ? Icons.favorite
                  : Icons.favorite_border,
              color:
                  Colors.white,
              size:
                  28,
            ),

            onPressed:
                alternarFavorito,
          ),

          IconButton(
            tooltip:
                'Pedidos',

            icon:
                const Icon(
              Icons.receipt_long,
            ),

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
        ],
      ),

      body:
          RefreshIndicator(
        color:
            laranja,

        onRefresh:
            _carregarProdutos,

        child:
            SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.only(
            bottom:
                100,
          ),

          child:
              Column(
            children: [
              // ==================================================
              // CABEÇALHO
              // ==================================================

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  20,
                ),

                color:
                    Colors.white,

                child:
                    Column(
                  children: [
                    Container(
                      width:
                          100,

                      height:
                          100,

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFFFB36B,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),

                      child:
                          const Icon(
                        Icons.restaurant,
                        size:
                            55,
                        color:
                            laranja,
                      ),
                    ),

                    const SizedBox(
                      height:
                          15,
                    ),

                    Text(
                      widget.nome,

                      textAlign:
                          TextAlign.center,

                      style:
                          const TextStyle(
                        fontSize:
                            24,
                        color:
                            Colors.black,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height:
                          8,
                    ),

                    Text(
                      widget.descricao,

                      textAlign:
                          TextAlign.center,

                      style:
                          const TextStyle(
                        color:
                            Colors.grey,
                        fontSize:
                            14,
                      ),
                    ),

                    const SizedBox(
                      height:
                          12,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [
                        const Icon(
                          Icons.star,
                          color:
                              Colors.orange,
                          size:
                              20,
                        ),

                        const SizedBox(
                          width:
                              5,
                        ),

                        Text(
                          widget.avaliacao,

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          width:
                              15,
                        ),

                        const Icon(
                          Icons.access_time,
                          size:
                              20,
                          color:
                              Colors.grey,
                        ),

                        const SizedBox(
                          width:
                              5,
                        ),

                        const Text(
                          '30-45 min',

                          style:
                              TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height:
                    20,
              ),

              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal:
                      16,
                ),

                child:
                    Align(
                  alignment:
                      Alignment.centerLeft,

                  child:
                      Text(
                    'Cardápio',

                    style:
                        TextStyle(
                      color:
                          Colors.black,
                      fontSize:
                          21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height:
                    10,
              ),

              // ==================================================
              // CATEGORIAS
              // ==================================================

              if (!carregandoProdutos &&
                  produtos.isNotEmpty)
                SizedBox(
                  height:
                      44,

                  child:
                      ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          16,
                    ),

                    scrollDirection:
                        Axis.horizontal,

                    itemCount:
                        categorias.length,

                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      width:
                          8,
                    ),

                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      final categoria =
                          categorias[index];

                      final selecionada =
                          categoriaSelecionada ==
                              categoria;

                      return ChoiceChip(
                        label:
                            Text(
                          categoria,
                        ),

                        selected:
                            selecionada,

                        onSelected:
                            (_) {
                          setState(() {
                            categoriaSelecionada =
                                categoria;
                          });
                        },

                        selectedColor:
                            laranja,

                        backgroundColor:
                            Colors.white,

                        labelStyle:
                            TextStyle(
                          color:
                              selecionada
                                  ? Colors.white
                                  : Colors.black87,

                          fontWeight:
                              FontWeight.w600,
                        ),

                        side:
                            BorderSide(
                          color:
                              selecionada
                                  ? laranja
                                  : Colors.black12,
                        ),
                      );
                    },
                  ),
                ),

              if (!carregandoProdutos)
                const SizedBox(
                  height:
                      10,
                ),

              // ==================================================
              // PRODUTOS
              // ==================================================

              if (carregandoProdutos)
                const Padding(
                  padding:
                      EdgeInsets.all(
                    50,
                  ),

                  child:
                      Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          laranja,
                    ),
                  ),
                )
              else if (erroProdutos !=
                  null)
                _estadoErroProdutos()
              else if (produtos.isEmpty)
                _estadoVazioProdutos()
              else if (produtosFiltrados.isEmpty)
                _estadoVazioCategoria()
              else
                ...produtosFiltrados.map(
                  (produto) =>
                      produtoCard(
                    produto:
                        produto,
                  ),
                ),

              const SizedBox(
                height:
                    20,
              ),
            ],
          ),
        ),
      ),

      // ============================================================
      // CARRINHO
      // ============================================================

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            laranja,

        onPressed:
            abrirCarrinho,

        icon:
            const Icon(
          Icons.shopping_cart,
          color:
              Colors.white,
        ),

        label:
            Text(
          quantidadeItens == 0
              ? 'Carrinho'
              : '$quantidadeItens itens • ${_formatarPreco(totalCarrinho)}',

          style:
              const TextStyle(
            color:
                Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD PRODUTO
  // ============================================================

  Widget produtoCard({
    required Map<String, dynamic> produto,
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
        produto['imagem']
            ?.toString();

    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal:
            16,
        vertical:
            7,
      ),

      padding:
          const EdgeInsets.all(
        15,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFFFF7F0,
        ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha:
                  0.08,
            ),

            blurRadius:
                6,

            offset:
                const Offset(
              0,
              2,
            ),
          ),
        ],
      ),

      child:
          Row(
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              12,
            ),

            child:
                _imagemProduto(
              imagem,
            ),
          ),

          const SizedBox(
            width:
                15,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  nome,

                  maxLines:
                      2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    color:
                        Colors.black,
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height:
                      5,
                ),

                if (descricao.isNotEmpty)
                  Text(
                    descricao,

                    maxLines:
                        2,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      color:
                          Colors.black,
                      fontSize:
                          12,
                    ),
                  ),

                const SizedBox(
                  height:
                      8,
                ),

                Text(
                  _formatarPreco(
                    preco,
                  ),

                  style:
                      const TextStyle(
                    color:
                        laranja,
                    fontSize:
                        16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              adicionarProduto(
                nome:
                    nome,
                preco:
                    preco,
                imagem:
                    imagem,
                produtoId:
                    produto['id']
                        ?.toString(),
              );
            },

            icon:
                const Icon(
              Icons.add_circle,
              color:
                  laranja,
              size:
                  34,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGEM
  // ============================================================

  Widget _imagemProduto(
    String? imagem,
  ) {
    if (imagem == null ||
        imagem.isEmpty) {
      return Container(
        width:
            80,

        height:
            80,

        color:
            const Color(
          0xFFFFB36B,
        ),

        child:
            const Icon(
          Icons.fastfood,

          color:
              laranja,

          size:
              35,
        ),
      );
    }

    final url =
        _urlImagemProduto(
      imagem,
    );

    return Image.network(
      url,

      width:
          80,

      height:
          80,

      fit:
          BoxFit.cover,

      loadingBuilder:
          (
        context,
        child,
        progress,
      ) {
        if (progress == null) {
          return child;
        }

        return Container(
          width:
              80,

          height:
              80,

          color:
              const Color(
            0xFFFFB36B,
          ),

          child:
              const Center(
            child:
                CircularProgressIndicator(
              strokeWidth:
                  2,

              color:
                  laranja,
            ),
          ),
        );
      },

      errorBuilder:
          (
        context,
        error,
        stackTrace,
      ) {
        return Container(
          width:
              80,

          height:
              80,

          color:
              const Color(
            0xFFFFB36B,
          ),

          child:
              const Icon(
            Icons.fastfood,

            color:
                laranja,

            size:
                35,
          ),
        );
      },
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _estadoErroProdutos() {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal:
            16,
      ),

      padding:
          const EdgeInsets.all(
        30,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child:
          Column(
        children: [
          const Icon(
            Icons
                .cloud_off_rounded,

            size:
                55,

            color:
                Colors.black26,
          ),

          const SizedBox(
            height:
                12,
          ),

          const Text(
            'Não foi possível carregar o cardápio',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              fontSize:
                  17,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
                6,
          ),

          const Text(
            'Verifique a conexão com o servidor e tente novamente.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Colors.black54,
            ),
          ),

          const SizedBox(
            height:
                16,
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
                ElevatedButton.styleFrom(
              backgroundColor:
                  laranja,

              foregroundColor:
                  Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VAZIO
  // ============================================================

  Widget _estadoVazioProdutos() {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal:
            16,
      ),

      padding:
          const EdgeInsets.all(
        30,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child:
          const Column(
        children: [
          Icon(
            Icons
                .restaurant_menu_outlined,

            size:
                55,

            color:
                Colors.black26,
          ),

          SizedBox(
            height:
                12,
          ),

          Text(
            'Nenhum produto disponível',

            style:
                TextStyle(
              fontSize:
                  17,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          SizedBox(
            height:
                6,
          ),

          Text(
            'Este restaurante ainda não possui produtos disponíveis.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VAZIO CATEGORIA
  // ============================================================

  Widget _estadoVazioCategoria() {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal:
            16,
      ),

      padding:
          const EdgeInsets.all(
        30,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child:
          const Column(
        children: [
          Icon(
            Icons.search_off_rounded,

            size:
                55,

            color:
                Colors.black26,
          ),

          SizedBox(
            height:
                12,
          ),

          Text(
            'Nenhum produto nesta categoria',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              fontSize:
                  17,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

