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

  int _indiceSelecionado = 0;

  bool carregandoRestaurantes = true;

  String? erroRestaurantes;

  List<Map<String, dynamic>> restaurantes = [];

  @override
  void initState() {
    super.initState();

    carregarRestaurantes();
  }

  // ============================================================
  // CARREGAR RESTAURANTES DA API
  // ============================================================

  Future<void> carregarRestaurantes() async {
    if (mounted) {
      setState(() {
        carregandoRestaurantes = true;
        erroRestaurantes = null;
      });
    }

    try {
      final url = Uri.parse(
        '${Api.baseUrl}/restaurants',
      );

      debugPrint('======================================');
      debugPrint('FOODJET - BUSCANDO RESTAURANTES');
      debugPrint('URL: $url');
      debugPrint('======================================');

      final resposta = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      debugPrint(
        'STATUS RESTAURANTES: ${resposta.statusCode}',
      );

      debugPrint(
        'RESPOSTA RESTAURANTES: ${resposta.body}',
      );

      if (resposta.statusCode < 200 ||
          resposta.statusCode >= 300) {
        throw Exception(
          'Erro ${resposta.statusCode} ao buscar restaurantes.',
        );
      }

      final resultado = jsonDecode(
        resposta.body,
      );

      List<dynamic> lista;

      // Caso a API retorne diretamente:
      //
      // [
      //   {...},
      //   {...}
      // ]
      //
      if (resultado is List) {
        lista = resultado;
      }

      // Caso a API retorne:
      //
      // {
      //   "restaurantes": [...]
      // }
      //
      else if (resultado is Map &&
          resultado['restaurantes'] is List) {
        lista = resultado['restaurantes'];
      }

      // Caso a API retorne:
      //
      // {
      //   "restaurants": [...]
      // }
      //
      else if (resultado is Map &&
          resultado['restaurants'] is List) {
        lista = resultado['restaurants'];
      } else {
        throw Exception(
          'Formato de restaurantes inválido.',
        );
      }

      final listaFinal = lista
          .whereType<Map>()
          .map(
            (restaurante) =>
                Map<String, dynamic>.from(
              restaurante,
            ),
          )
          .where(
            (restaurante) {
              final id =
                  restaurante['id'] ??
                  restaurante['_id'] ??
                  restaurante['restauranteId'];

              final nome =
                  restaurante['nome'] ??
                  restaurante['name'] ??
                  restaurante['restauranteNome'];

              return id != null &&
                  id.toString().trim().isNotEmpty &&
                  nome != null &&
                  nome.toString().trim().isNotEmpty;
            },
          )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        restaurantes = listaFinal;
        carregandoRestaurantes = false;
      });

      debugPrint(
        'RESTAURANTES ENCONTRADOS: ${restaurantes.length}',
      );
    } catch (e) {
      debugPrint(
        'ERRO AO CARREGAR RESTAURANTES: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        carregandoRestaurantes = false;

        erroRestaurantes =
            'Não foi possível carregar os restaurantes.';
      });
    }
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  void _selecionarPagina(int indice) {
    if (indice == 0) {
      setState(() {
        _indiceSelecionado = 0;
      });

      return;
    }

    if (indice == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const OrderHistoryScreen(),
        ),
      );

      return;
    }

    if (indice == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const FavoritesScreen(),
        ),
      );

      return;
    }

    if (indice == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            usuario: widget.usuario,
          ),
        ),
      );

      return;
    }
  }

  // ============================================================
  // NOME RESTAURANTE
  // ============================================================

  String nomeRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    return (
      restaurante['nome'] ??
      restaurante['name'] ??
      restaurante['restauranteNome'] ??
      'Restaurante'
    ).toString();
  }

  // ============================================================
  // DESCRIÇÃO
  // ============================================================

  String descricaoRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    final descricao =
        restaurante['descricao'] ??
        restaurante['description'] ??
        restaurante['categoria'] ??
        restaurante['tipo'];

    if (descricao == null ||
        descricao.toString().trim().isEmpty) {
      return 'Delícias preparadas especialmente para você';
    }

    return descricao.toString();
  }

  // ============================================================
  // AVALIAÇÃO
  // ============================================================

  String avaliacaoRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    final avaliacao =
        restaurante['avaliacao'] ??
        restaurante['rating'] ??
        restaurante['nota'];

    if (avaliacao == null) {
      return '5.0';
    }

    return avaliacao.toString();
  }

  // ============================================================
  // ID RESTAURANTE
  // ============================================================

  String idRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    return (
      restaurante['id'] ??
      restaurante['_id'] ??
      restaurante['restauranteId']
    ).toString();
  }

  // ============================================================
  // STATUS
  // ============================================================

  bool restauranteAberto(
    Map<String, dynamic> restaurante,
  ) {
    final aberto =
        restaurante['aberto'] ??
        restaurante['online'] ??
        restaurante['ativo'] ??
        restaurante['abertoAgora'];

    if (aberto == null) {
      return true;
    }

    if (aberto is bool) {
      return aberto;
    }

    return aberto.toString().toLowerCase() !=
        'false';
  }

  // ============================================================
  // ABRIR RESTAURANTE
  // ============================================================

  void abrirRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    final id =
        idRestaurante(restaurante);

    if (id.isEmpty || id == 'null') {
      ScaffoldMessenger.of(context)
          .showSnackBar(
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
        builder: (context) =>
            RestaurantScreen(
          nome: nomeRestaurante(
            restaurante,
          ),
          descricao:
              descricaoRestaurante(
            restaurante,
          ),
          avaliacao:
              avaliacaoRestaurante(
            restaurante,
          ),
          restauranteId: id,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String nomeUsuario =
        widget.usuario['nome']?.toString() ??
            'Usuário';

    return Scaffold(
      backgroundColor: fundo,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Entregar em',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Ipatinga, MG',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
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
              Icons.notifications_outlined,
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        color: laranja,
        onRefresh:
            carregarRestaurantes,

        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ==================================================
              // SAUDAÇÃO
              // ==================================================

              Text(
                'Olá, $nomeUsuario! 👋',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
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

              TextField(
                decoration:
                    InputDecoration(
                  hintText:
                      'Buscar restaurantes ou pratos',

                  prefixIcon:
                      const Icon(
                    Icons.search,
                  ),

                  suffixIcon:
                      const Icon(
                    Icons.tune,
                  ),

                  filled: true,

                  fillColor:
                      Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // CATEGORIAS
              // ==================================================

              const Text(
                'Categorias',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                height: 105,

                child: ListView(
                  scrollDirection:
                      Axis.horizontal,

                  children: [
                    categoria(
                      Icons.local_pizza,
                      'Pizza',
                    ),
                    categoria(
                      Icons.lunch_dining,
                      'Hambúrguer',
                    ),
                    categoria(
                      Icons.icecream,
                      'Sobremesas',
                    ),
                    categoria(
                      Icons.local_drink,
                      'Bebidas',
                    ),
                    categoria(
                      Icons.restaurant,
                      'Comida',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // TÍTULO
              // ==================================================

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Restaurantes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  if (!carregandoRestaurantes &&
                      restaurantes.isNotEmpty)
                    Text(
                      '${restaurantes.length}',
                      style:
                          const TextStyle(
                        color: laranja,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 15),

              // ==================================================
              // CARREGANDO
              // ==================================================

              if (carregandoRestaurantes)
                const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.all(40),
                    child:
                        CircularProgressIndicator(
                      color: laranja,
                    ),
                  ),
                )

              // ==================================================
              // ERRO
              // ==================================================

              else if (
                  erroRestaurantes != null)
                _estadoErro()

              // ==================================================
              // NENHUM RESTAURANTE
              // ==================================================

              else if (
                  restaurantes.isEmpty)
                _estadoVazio()

              // ==================================================
              // RESTAURANTES DA API
              // ==================================================

              else
                ...restaurantes.map(
                  (restaurante) =>
                      restauranteCard(
                    restaurante,
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),

      // ========================================================
      // CARRINHO
      // ========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor: laranja,

        onPressed: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Seu carrinho está vazio.',
              ),
            ),
          );
        },

        icon: const Icon(
          Icons.shopping_cart,
          color: Colors.white,
        ),

        label: const Text(
          'Carrinho',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex:
            _indiceSelecionado,

        onTap:
            _selecionarPagina,

        type:
            BottomNavigationBarType.fixed,

        selectedItemColor:
            laranja,

        unselectedItemColor:
            Colors.grey,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
            ),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.receipt_long,
            ),
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
  // CATEGORIA
  // ============================================================

  Widget categoria(
    IconData icone,
    String nome,
  ) {
    return Container(
      width: 90,

      margin:
          const EdgeInsets.only(
        right: 12,
      ),

      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,

            decoration:
                BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(
                35,
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(
                    alpha: 0.05,
                  ),
                  blurRadius: 5,
                  offset:
                      const Offset(0, 2),
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
            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD RESTAURANTE
  // ============================================================

  Widget restauranteCard(
    Map<String, dynamic> restaurante,
  ) {
    final nome =
        nomeRestaurante(
      restaurante,
    );

    final descricao =
        descricaoRestaurante(
      restaurante,
    );

    final avaliacao =
        avaliacaoRestaurante(
      restaurante,
    );

    final aberto =
        restauranteAberto(
      restaurante,
    );

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          18,
        ),

        onTap: () {
          abrirRestaurante(
            restaurante,
          );
        },

        child: Padding(
          padding:
              const EdgeInsets.all(
            12,
          ),

          child: Row(
            children: [
              // ==================================================
              // LOGO
              // ==================================================

              Container(
                width: 82,
                height: 82,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFFFE5D3,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child:
                    const Icon(
                  Icons.restaurant,
                  color: laranja,
                  size: 40,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              // ==================================================
              // INFORMAÇÕES
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      nome,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          const TextStyle(
                        color:
                            Colors.black,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      descricao,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,

                      style: TextStyle(
                        color:
                            Colors.grey
                                .shade600,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(
                      height: 9,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color:
                              Colors.orange,
                          size: 17,
                        ),

                        const SizedBox(
                          width: 3,
                        ),

                        Text(
                          avaliacao,
                          style:
                              const TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Icon(
                          aberto
                              ? Icons
                                  .check_circle
                              : Icons
                                  .schedule,
                          color: aberto
                              ? Colors.green
                              : Colors.orange,
                          size: 16,
                        ),

                        const SizedBox(
                          width: 3,
                        ),

                        Text(
                          aberto
                              ? 'Aberto'
                              : 'Fechado',
                          style:
                              TextStyle(
                            color: aberto
                                ? Colors.green
                                : Colors.orange,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 5,
              ),

              const Icon(
                Icons
                    .arrow_forward_ios,
                color:
                    Colors.black38,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ESTADO DE ERRO
  // ============================================================

  Widget _estadoErro() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(
        30,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.cloud_off,
            color: laranja,
            size: 55,
          ),

          const SizedBox(height: 12),

          const Text(
            'Não foi possível carregar os restaurantes.',
            textAlign:
                TextAlign.center,

            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          ElevatedButton.icon(
            onPressed:
                carregarRestaurantes,

            icon: const Icon(
              Icons.refresh,
            ),

            label: const Text(
              'Tentar novamente',
            ),

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  laranja,

              foregroundColor:
                  Colors.white,

              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _estadoVazio() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(
        30,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.storefront_outlined,
            color: laranja,
            size: 60,
          ),

          const SizedBox(height: 15),

          const Text(
            'Nenhum restaurante disponível',
            textAlign:
                TextAlign.center,

            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Quando um novo restaurante for cadastrado no FoodJet, ele aparecerá aqui automaticamente.',
            textAlign:
                TextAlign.center,

            style: TextStyle(
              color:
                  Colors.grey.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}