import 'package:flutter/material.dart';

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
  static const Color fundo = Color(0xFFF7F7F8);

  int _indiceSelecionado = 0;

  final TextEditingController _buscaController =
      TextEditingController();

  String _termoBusca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // ==========================================================
  // NAVEGAÇÃO
  // ==========================================================

  void _selecionarPagina(int indice) {
    if (indice == 0) {
      setState(() {
        _indiceSelecionado = 0;
      });
      return;
    }

    if (indice == 1) {
      _abrirBusca();
      return;
    }

    if (indice == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const OrderHistoryScreen(),
        ),
      );
      return;
    }

    if (indice == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const FavoritesScreen(),
        ),
      );
      return;
    }

    if (indice == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            usuario: widget.usuario,
          ),
        ),
      );
    }
  }

  // ==========================================================
  // BUSCA
  // ==========================================================

  void _abrirBusca() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height:
                  MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: fundo,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        22,
                        20,
                        10,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Buscar no FoodJet',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: TextField(
                        autofocus: true,
                        controller: _buscaController,
                        onChanged: (valor) {
                          setModalState(() {
                            _termoBusca =
                                valor.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Buscar restaurante ou prato',
                          prefixIcon: const Icon(
                            Icons.search,
                          ),
                          suffixIcon:
                              _buscaController
                                      .text
                                      .isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _buscaController
                                            .clear();

                                        setModalState(() {
                                          _termoBusca = '';
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                      ),
                                    )
                                  : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                            borderSide:
                                BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Expanded(
                      child: ListView(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        children: [
                          const Text(
                            'Sugestões',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 15),

                          _buscaItem(
                            'Burger House',
                            'Hambúrguer • Lanches',
                            Icons.lunch_dining,
                            _termoBusca,
                          ),

                          _buscaItem(
                            'Pizzaria do Chef',
                            'Pizza • Italiana',
                            Icons.local_pizza,
                            _termoBusca,
                          ),

                          _buscaItem(
                            'Açaí Point',
                            'Açaí • Sorvetes',
                            Icons.icecream,
                            _termoBusca,
                          ),

                          _buscaItem(
                            'Pizza Minas',
                            'Pizza • Massas • Bebidas',
                            Icons.local_pizza,
                            _termoBusca,
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
      },
    );
  }

  Widget _buscaItem(
    String nome,
    String descricao,
    IconData icone,
    String termo,
  ) {
    final texto =
        '$nome $descricao'.toLowerCase();

    if (termo.isNotEmpty &&
        !texto.contains(termo)) {
      return const SizedBox.shrink();
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantScreen(
              nome: nome,
              descricao: descricao,
              avaliacao: '4.8',
            ),
          ),
        );
      },
      child: Container(
        margin:
            const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            _iconeRestaurante(icone),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // RESTAURANTE
  // ==========================================================

  void _abrirRestaurante({
    required String nome,
    required String descricao,
    required String avaliacao,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantScreen(
          nome: nome,
          descricao: descricao,
          avaliacao: avaliacao,
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final String nomeUsuario =
        widget.usuario['nome']?.toString() ??
            'Usuário';

    return Scaffold(
      backgroundColor: fundo,

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,

        toolbarHeight: 76,

        titleSpacing: 18,

        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Entregar em',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 3),

            Row(
              children: const [
                Icon(
                  Icons.location_on,
                  size: 17,
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
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
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
              size: 27,
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),

      // ======================================================
      // HOME
      // ======================================================

      body: SafeArea(
        child: RefreshIndicator(
          color: laranja,
          onRefresh: () async {
            await Future.delayed(
              const Duration(milliseconds: 500),
            );
          },
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ============================================
                // ÁREA LARANJA
                // ============================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    22,
                  ),
                  color: laranja,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, $nomeUsuario 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'O que você quer pedir hoje?',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // BUSCA
                      GestureDetector(
                        onTap: _abrirBusca,
                        child: Container(
                          height: 56,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              17,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color:
                                    Colors.grey.shade600,
                                size: 25,
                              ),

                              const SizedBox(width: 11),

                              Expanded(
                                child: Text(
                                  'O que você está procurando?',
                                  style: TextStyle(
                                    color: Colors
                                        .grey.shade600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),

                              Container(
                                padding:
                                    const EdgeInsets.all(
                                  8,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: const Color(
                                    0xFFFFF1E8,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    11,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  color: laranja,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    20,
                    16,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ========================================
                      // CATEGORIAS
                      // ========================================

                      _tituloSecao(
                        'Categorias',
                        'Ver todas',
                        () {},
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: 104,
                        child: ListView(
                          scrollDirection:
                              Axis.horizontal,
                          children: [
                            _categoria(
                              Icons.fastfood,
                              'Lanches',
                            ),
                            _categoria(
                              Icons.local_pizza,
                              'Pizza',
                            ),
                            _categoria(
                              Icons.ramen_dining,
                              'Japonesa',
                            ),
                            _categoria(
                              Icons.local_drink,
                              'Bebidas',
                            ),
                            _categoria(
                              Icons.cake,
                              'Doces',
                            ),
                            _categoria(
                              Icons.icecream,
                              'Açaí',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ========================================
                      // BANNER
                      // ========================================

                      _bannerOferta(),

                      const SizedBox(height: 30),

                      // ========================================
                      // NOVAS LOJAS
                      // ========================================

                      _tituloSecao(
                        'Novas lojas',
                        'Ver todas',
                        () {},
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: 205,
                        child: ListView(
                          scrollDirection:
                              Axis.horizontal,
                          children: [
                            _cardNovaLoja(
                              'Pizzaria do Chef',
                              'Pizza • Italiana',
                              '4.8',
                              '25–35 min',
                              Icons.local_pizza,
                              () {
                                _abrirRestaurante(
                                  nome:
                                      'Pizzaria do Chef',
                                  descricao:
                                      'Pizza • Italiana',
                                  avaliacao: '4.8',
                                );
                              },
                            ),
                            _cardNovaLoja(
                              'Burger House',
                              'Hambúrguer • Lanches',
                              '4.7',
                              '20–30 min',
                              Icons.lunch_dining,
                              () {
                                _abrirRestaurante(
                                  nome:
                                      'Burger House',
                                  descricao:
                                      'Hambúrguer • Lanches',
                                  avaliacao: '4.7',
                                );
                              },
                            ),
                            _cardNovaLoja(
                              'Açaí Point',
                              'Açaí • Sorvetes',
                              '4.9',
                              '15–25 min',
                              Icons.icecream,
                              () {
                                _abrirRestaurante(
                                  nome: 'Açaí Point',
                                  descricao:
                                      'Açaí • Sorvetes',
                                  avaliacao: '4.9',
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ========================================
                      // RESTAURANTES PRÓXIMOS
                      // ========================================

                      _tituloSecao(
                        'Restaurantes próximos',
                        'Ver todos',
                        () {},
                      ),

                      const SizedBox(height: 15),

                      _cardRestaurante(
                        'Restaurante FoodJet',
                        'Hambúrguer • Pizza • Lanches',
                        '4.8',
                        '30–45 min',
                        Icons.restaurant,
                      ),

                      _cardRestaurante(
                        'Pizza Minas',
                        'Pizza • Massas • Bebidas',
                        '4.7',
                        '30–45 min',
                        Icons.local_pizza,
                      ),

                      _cardRestaurante(
                        'Burger Vale',
                        'Hambúrguer • Batata • Milkshake',
                        '4.9',
                        '30–45 min',
                        Icons.lunch_dining,
                      ),

                      const SizedBox(height: 18),

                      // ========================================
                      // OFERTAS ESPECIAIS
                      // ========================================

                      _tituloSecao(
                        'Ofertas especiais',
                        'Ver todas',
                        () {},
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: 230,
                        child: ListView(
                          scrollDirection:
                              Axis.horizontal,
                          children: [
                            _cardOferta(
                              'Combo Burger',
                              'Burger + Batata + Refri',
                              'R\$ 29,90',
                              '25% OFF',
                              Icons.lunch_dining,
                            ),
                            _cardOferta(
                              '2 Pizzas Grandes',
                              'Escolha os sabores',
                              'R\$ 59,90',
                              '25% OFF',
                              Icons.local_pizza,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ========================================
                      // MAIS PEDIDOS
                      // ========================================

                      _tituloSecao(
                        'Mais pedidos',
                        'Ver todos',
                        () {},
                      ),

                      const SizedBox(height: 15),

                      _cardRestaurante(
                        'Açaí do Vale',
                        'Açaí • Sorvetes • Sobremesas',
                        '4.9',
                        '15–25 min',
                        Icons.icecream,
                      ),

                      _cardRestaurante(
                        'Burger Vale',
                        'Hambúrguer • Batata • Milkshake',
                        '4.9',
                        '20–30 min',
                        Icons.lunch_dining,
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ======================================================
      // CARRINHO
      // ======================================================

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor: laranja,
        elevation: 5,
        onPressed: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content:
                  Text('Seu carrinho está vazio.'),
              backgroundColor: laranja,
            ),
          );
        },
        icon: const Icon(
          Icons.shopping_bag_outlined,
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

      // ======================================================
      // NAVEGAÇÃO INFERIOR
      // ======================================================

      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            _indiceSelecionado,
        onDestinationSelected:
            _selecionarPagina,
        backgroundColor:
            Colors.white,
        elevation: 10,
        height: 72,

        indicatorColor:
            const Color(0xFFFFE7D7),

        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home,
            ),
            label: 'Início',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.search_outlined,
            ),
            selectedIcon: Icon(
              Icons.search,
            ),
            label: 'Busca',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.receipt_long_outlined,
            ),
            selectedIcon: Icon(
              Icons.receipt_long,
            ),
            label: 'Pedidos',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.favorite_border,
            ),
            selectedIcon: Icon(
              Icons.favorite,
            ),
            label: 'Favoritos',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // COMPONENTES
  // ==========================================================

  Widget _tituloSecao(
    String titulo,
    String acao,
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Ver todos',
            style: TextStyle(
              color: laranja,
              fontWeight:
                  FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoria(
    IconData icone,
    String nome,
  ) {
    return Container(
      width: 82,
      margin:
          const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset:
                      const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icone,
              color: laranja,
              size: 29,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            nome,
            textAlign:
                TextAlign.center,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerOferta() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF97316),
            Color(0xFFFF9A5A),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.18,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Text(
                    'OFERTA EXCLUSIVA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Até 30% OFF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Peça agora e aproveite ofertas especiais.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 15),

                ElevatedButton(
                  onPressed: () {},
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.white,
                    foregroundColor:
                        laranja,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 11,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Ver ofertas',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          const Icon(
            Icons.local_offer_rounded,
            color: Colors.white,
            size: 78,
          ),
        ],
      ),
    );
  }

  Widget _cardNovaLoja(
    String nome,
    String descricao,
    String avaliacao,
    String tempo,
    IconData icone,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 175,
        margin:
            const EdgeInsets.only(right: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.05),
              blurRadius: 8,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 105,
                  width: double.infinity,
                  decoration:
                      const BoxDecoration(
                    color: Color(0xFFFFE2CF),
                    borderRadius:
                        BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Icon(
                    icone,
                    size: 52,
                    color: laranja,
                  ),
                ),

                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color: laranja,
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                    child: const Text(
                      'NOVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding:
                  const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    descricao,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color:
                            Colors.amber,
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        avaliacao,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          tempo,
                          style: TextStyle(
                            color: Colors
                                .grey.shade600,
                            fontSize: 10,
                          ),
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
    );
  }

  Widget _cardRestaurante(
    String nome,
    String descricao,
    String avaliacao,
    String tempo,
    IconData icone,
  ) {
    return GestureDetector(
      onTap: () {
        _abrirRestaurante(
          nome: nome,
          descricao: descricao,
          avaliacao: avaliacao,
        );
      },
      child: Container(
        margin:
            const EdgeInsets.only(bottom: 13),
        padding:
            const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.04),
              blurRadius: 8,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFFFFE2CF),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Icon(
                    icone,
                    color: laranja,
                    size: 38,
                  ),
                ),

                Positioned(
                  bottom: 5,
                  left: 5,
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        7,
                      ),
                    ),
                    child: const Text(
                      'FoodJet',
                      style: TextStyle(
                        color: laranja,
                        fontSize: 8,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    descricao,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color:
                            Colors.amber,
                        size: 16,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        avaliacao,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(width: 7),

                      Text(
                        '• $tempo',
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.favorite_border,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardOferta(
    String titulo,
    String descricao,
    String preco,
    String desconto,
    IconData icone,
  ) {
    return Container(
      width: 220,
      margin:
          const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.05),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            height: 105,
            width: double.infinity,
            decoration:
                const BoxDecoration(
              color: Color(0xFFFFE2CF),
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icone,
                    color: laranja,
                    size: 55,
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color: laranja,
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                    child: Text(
                      desconto,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  descricao,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  preco,
                  style: const TextStyle(
                    color: laranja,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconeRestaurante(
    IconData icone,
  ) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE2CF),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Icon(
        icone,
        color: laranja,
        size: 29,
      ),
    );
  }
}