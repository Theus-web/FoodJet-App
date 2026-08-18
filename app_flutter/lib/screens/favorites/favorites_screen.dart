import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() =>
      _FavoritesScreenState();
}

class _FavoritesScreenState
    extends State<FavoritesScreen> {
  static const Color laranja =
      Color(0xFFF97316);

  // ============================================================
  // FAVORITOS
  // ============================================================
  //
  // IMPORTANTE:
  // Não existem mais restaurantes fixos aqui.
  //
  // A lista começa vazia e deverá receber somente os restaurantes
  // que o usuário realmente adicionar aos favoritos.
  //
  final List<Map<String, String>> favoritos = [];

  // ============================================================
  // REMOVER FAVORITO
  // ============================================================

  void removerFavorito(int index) {
    if (index < 0 ||
        index >= favoritos.length) {
      return;
    }

    final nome =
        favoritos[index]['nome'] ??
            'Restaurante';

    setState(() {
      favoritos.removeAt(index);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$nome removido dos favoritos.',
          ),
          backgroundColor: laranja,
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

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

  // ============================================================
  // TELA SEM FAVORITOS
  // ============================================================

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
              width: 110,
              height: 110,
              decoration:
                  BoxDecoration(
                color:
                    laranja.withValues(
                  alpha: 0.10,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 58,
                color: laranja,
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            const Text(
              'Nenhum favorito ainda',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.w800,
                color:
                    Colors.black87,
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
                height: 1.4,
                color:
                    Colors.grey,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },

              icon: const Icon(
                Icons.restaurant_rounded,
              ),

              label: const Text(
                'Explorar restaurantes',
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
                  horizontal: 25,
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
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD DO FAVORITO
  // ============================================================

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
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // ====================================================
          // ÍCONE
          // ====================================================

          Container(
            width: 75,
            height: 75,

            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE5D3),
                  Color(0xFFFFC58F),
                ],
              ),

              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),

            child: const Icon(
              Icons.restaurant_rounded,
              color: laranja,
              size: 38,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          // ====================================================
          // INFORMAÇÕES
          // ====================================================

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
                      TextOverflow.ellipsis,

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
                      Icons.star_rounded,
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

          // ====================================================
          // BOTÃO REMOVER
          // ====================================================

          IconButton(
            onPressed: () {
              removerFavorito(
                index,
              );
            },

            icon: const Icon(
              Icons.favorite_rounded,
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