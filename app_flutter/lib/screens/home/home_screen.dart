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
int _indiceSelecionado = 0;

final Color laranja = const Color(0xFFF97316);

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

@override
Widget build(BuildContext context) {
final String nomeUsuario =
widget.usuario['nome']?.toString() ??
'Usuário';


return Scaffold(
  backgroundColor:
      const Color(0xFFF5F5F5),

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

  body: SingleChildScrollView(
    padding:
        const EdgeInsets.all(16),

    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
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
                  BorderRadius.circular(
                15,
              ),

              borderSide:
                  BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.all(
            20,
          ),

          decoration:
              BoxDecoration(
            color: laranja,

            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Text(
                      'Fome de desconto? 🔥',

                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Peça agora e aproveite ofertas especiais.',

                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    ElevatedButton(
                      onPressed: () {},

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            Colors.white,

                        foregroundColor:
                            laranja,
                      ),

                      child:
                          const Text(
                        'Ver ofertas',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              const Icon(
                Icons.fastfood,
                size: 70,
                color:
                    Colors.white,
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 25,
        ),

        const Text(
          'Categorias',

          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        SizedBox(
          height: 105,

          child: ListView(
            scrollDirection:
                Axis.horizontal,

            children: [
              categoria(
                Icons.fastfood,
                'Lanches',
              ),

              categoria(
                Icons.local_pizza,
                'Pizza',
              ),

              categoria(
                Icons.ramen_dining,
                'Japonesa',
              ),

              categoria(
                Icons.local_drink,
                'Bebidas',
              ),

              categoria(
                Icons.cake,
                'Doces',
              ),

              categoria(
                Icons.local_dining,
                'Brasileira',
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 25,
        ),

        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,

          children: [
            const Text(
              'Restaurantes próximos',

              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            TextButton(
              onPressed: () {},

              child: Text(
                'Ver todos',

                style: TextStyle(
                  color: laranja,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 5,
        ),

        restaurante(
          'Restaurante FoodJet',
          'Hambúrguer • Pizza • Lanches',
          '4.8',
        ),

        restaurante(
          'Pizza Minas',
          'Pizza • Massas • Bebidas',
          '4.7',
        ),

        restaurante(
          'Burger Vale',
          'Hambúrguer • Batata • Milkshake',
          '4.9',
        ),

        restaurante(
          'Açaí do Vale',
          'Açaí • Sorvetes • Sobremesas',
          '4.9',
        ),

        const SizedBox(
          height: 30,
        ),
      ],
    ),
  ),

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

  bottomNavigationBar:
      BottomNavigationBar(
    currentIndex:
        _indiceSelecionado,

    onTap:
        _selecionarPagina,

    type:
        BottomNavigationBarType.fixed,

    selectedItemColor:
        Color(0xFFF97316),

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
              color:
                  Colors.black
                      .withValues(
                alpha: 0.05,
              ),

              blurRadius: 5,

              offset:
                  const Offset(
                0,
                2,
              ),
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

Widget restaurante(
String nome,
String descricao,
String avaliacao,
) {
return InkWell(
borderRadius:
BorderRadius.circular(
18,
),


  onTap: () {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) =>
            RestaurantScreen(
          nome: nome,
          descricao: descricao,
          avaliacao: avaliacao,
        ),
      ),
    );
  },

  child: Container(
    margin:
        const EdgeInsets.only(
      bottom: 15,
    ),

    padding:
        const EdgeInsets.all(
      12,
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
              Colors.black
                  .withValues(
            alpha: 0.05,
          ),

          blurRadius: 6,

          offset:
              const Offset(
            0,
            2,
          ),
        ),
      ],
    ),

    child: Row(
      children: [
        Container(
          width: 75,
          height: 75,

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFFFB36B,
            ),

            borderRadius:
                BorderRadius.circular(
              15,
            ),
          ),

          child: Icon(
            Icons.restaurant,
            color: laranja,
            size: 38,
          ),
        ),

        const SizedBox(
          width: 15,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              Text(
                nome,

                style:
                    const TextStyle(
                  color:
                      Colors.black,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                descricao,

                style:
                    const TextStyle(
                  color:
                      Colors.black,
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
                    size: 18,
                    color:
                        Colors.orange,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Text(
                    avaliacao,

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  const Text(
                    '• 30-45 min',

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

        const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.grey,
        ),
      ],
    ),
  ),
);

}
}
