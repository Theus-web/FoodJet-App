import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() =>
      _FavoritesScreenState();
}

class _FavoritesScreenState
    extends State<FavoritesScreen> {
  final Color laranja =
      const Color(0xFFF97316);

  // Favoritos de teste
  final List<Map<String, String>> favoritos = [
    {
      'nome': 'Restaurante FoodJet',
      'descricao': 'Hambúrguer • Pizza • Lanches',
      'avaliacao': '4.8',
    },
    {
      'nome': 'Pizza Minas',
      'descricao': 'Pizza • Massas • Bebidas',
      'avaliacao': '4.7',
    },
  ];

  void removerFavorito(int index) {
    final nome =
        favoritos[index]['nome'] ?? 'Restaurante';

    setState(() {
      favoritos.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$nome removido dos favoritos.',
        ),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Meus Favoritos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: favoritos.isEmpty
          ? _telaVazia()
          : ListView.builder(
              padding:
                  const EdgeInsets.all(16),

              itemCount:
                  favoritos.length,

              itemBuilder:
                  (context, index) {
                final favorito =
                    favoritos[index];

                return _cardFavorito(
                  index,
                  favorito,
                );
              },
            ),
    );
  }

  // ==========================================
  // TELA SEM FAVORITOS
  // ==========================================

  Widget _telaVazia() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 100,
              height: 100,

              decoration:
                  BoxDecoration(
                color:
                    Colors.orange.shade50,
                shape:
                    BoxShape.circle,
              ),

              child: Icon(
                Icons.favorite_border,
                size: 55,
                color: laranja,
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            const Text(
              'Nenhum favorito ainda',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
                color:
                    Colors.black,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'Quando você favoritar um restaurante,\nele aparecerá aqui.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color:
                    Colors.grey,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    laranja,
                foregroundColor:
                    Colors.white,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),

              child: const Text(
                'Explorar restaurantes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CARD DO FAVORITO
  // ==========================================

  Widget _cardFavorito(
    int index,
    Map<String, String> favorito,
  ) {
    final String nome =
        favorito['nome'] ?? '';

    final String descricao =
        favorito['descricao'] ?? '';

    final String avaliacao =
        favorito['avaliacao'] ?? '';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),

      padding:
          const EdgeInsets.all(12),

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

            blurRadius: 6,

            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          // ÍCONE
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

          // INFORMAÇÕES
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  nome,

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

                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
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
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // BOTÃO REMOVER
          IconButton(
            onPressed: () {
              removerFavorito(
                index,
              );
            },

            icon: const Icon(
              Icons.favorite,
              color: Colors.red,
            ),

            tooltip:
                'Remover dos favoritos',
          ),
        ],
      ),
    );
  }
}