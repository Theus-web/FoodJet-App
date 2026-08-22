import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/favorite_service.dart';
import '../restaurant/restaurant_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
  });

  @override
  State<FavoritesScreen> createState() =>
      _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with WidgetsBindingObserver {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF6F7F9);

  bool carregando = true;
  bool removendo = false;

  List<Map<String, dynamic>> favoritos = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    carregarFavoritos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ============================================================
  // ATUALIZAR QUANDO A TELA VOLTAR A FICAR ATIVA
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      carregarFavoritos();
    }
  }

  // ============================================================
  // CARREGAR FAVORITOS
  // ============================================================

  Future<void> carregarFavoritos() async {
    if (!mounted) return;

    setState(() {
      carregando = true;
    });

    try {
      final lista = await FavoriteService.listar();

      debugPrint('');
      debugPrint('========================================');
      debugPrint('FOODJET - MEUS FAVORITOS');
      debugPrint('TOTAL: ${lista.length}');
      debugPrint('========================================');

      for (final favorito in lista) {
        debugPrint(
          'NOME: ${_obterNome(favorito)}',
        );

        debugPrint(
          'ID: ${_obterId(favorito)}',
        );

        debugPrint(
          'IMAGEM: ${_obterImagem(favorito) != null}',
        );
      }

      debugPrint('========================================');
      debugPrint('');

      if (!mounted) return;

      setState(() {
        favoritos = List<Map<String, dynamic>>.from(
          lista.map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );

        carregando = false;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'ERRO AO CARREGAR FAVORITOS: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) return;

      setState(() {
        favoritos = [];
        carregando = false;
      });
    }
  }

  // ============================================================
  // ID
  // ============================================================

  String _obterId(
    Map<String, dynamic> restaurante,
  ) {
    final valores = [
      restaurante['id'],
      restaurante['_id'],
      restaurante['restauranteId'],
      restaurante['restaurantId'],
      restaurante['restaurante_id'],
      restaurante['restaurant_id'],
    ];

    for (final valor in valores) {
      if (valor == null) continue;

      final id = valor.toString().trim();

      if (id.isNotEmpty &&
          id.toLowerCase() != 'null' &&
          id.toLowerCase() != 'undefined') {
        return id;
      }
    }

    return '';
  }

  // ============================================================
  // NOME
  // ============================================================

  String _obterNome(
    Map<String, dynamic> restaurante,
  ) {
    final valores = [
      restaurante['nome'],
      restaurante['name'],
      restaurante['nomeRestaurante'],
      restaurante['restaurantName'],
    ];

    for (final valor in valores) {
      if (valor == null) continue;

      final nome = valor.toString().trim();

      if (nome.isNotEmpty &&
          nome.toLowerCase() != 'null') {
        return nome;
      }
    }

    return 'Restaurante';
  }

  // ============================================================
  // DESCRIÇÃO
  // ============================================================

  String _obterDescricao(
    Map<String, dynamic> restaurante,
  ) {
    final valores = [
      restaurante['descricao'],
      restaurante['description'],
    ];

    for (final valor in valores) {
      if (valor == null) continue;

      final descricao = valor.toString().trim();

      if (descricao.isNotEmpty &&
          descricao.toLowerCase() != 'null') {
        return descricao;
      }
    }

    return '';
  }

  // ============================================================
  // AVALIAÇÃO
  // ============================================================

  String _obterAvaliacao(
    Map<String, dynamic> restaurante,
  ) {
    final valores = [
      restaurante['avaliacao'],
      restaurante['rating'],
      restaurante['nota'],
      restaurante['score'],
    ];

    for (final valor in valores) {
      if (valor == null) continue;

      final avaliacao = valor.toString().trim();

      if (avaliacao.isNotEmpty &&
          avaliacao.toLowerCase() != 'null') {
        return avaliacao;
      }
    }

    return '5,0';
  }

  // ============================================================
  // IMAGEM
  // ============================================================

  String? _obterImagem(
    Map<String, dynamic> restaurante,
  ) {
    final valores = [
      restaurante['logo'],
      restaurante['logoUrl'],
      restaurante['imagem'],
      restaurante['imagemUrl'],
      restaurante['foto'],
      restaurante['fotoUrl'],
      restaurante['logoBase64'],
      restaurante['imagemBase64'],
      restaurante['fotoBase64'],
    ];

    for (final valor in valores) {
      if (valor == null) continue;

      final imagem = valor.toString().trim();

      if (imagem.isEmpty) continue;

      if (imagem.toLowerCase() == 'null') continue;

      return imagem;
    }

    return null;
  }

  // ============================================================
  // REMOVER FAVORITO
  // ============================================================

  Future<void> removerFavorito(
    Map<String, dynamic> restaurante,
  ) async {
    if (removendo) return;

    final id = _obterId(restaurante);

    if (id.isEmpty) {
      _mensagem(
        'Não foi possível identificar o restaurante.',
        vermelho: true,
      );

      return;
    }

    final nome = _obterNome(restaurante);

    setState(() {
      removendo = true;
    });

    try {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('REMOVENDO FAVORITO');
      debugPrint('ID: $id');
      debugPrint('NOME: $nome');
      debugPrint('========================================');

      await FavoriteService.remover(id);

      // Remove imediatamente da interface.
      if (mounted) {
        setState(() {
          favoritos.removeWhere(
            (item) => _obterId(item) == id,
          );
        });
      }

      _mensagem(
        '$nome removido dos favoritos.',
      );
    } catch (e) {
      debugPrint(
        'ERRO AO REMOVER FAVORITO: $e',
      );

      _mensagem(
        'Não foi possível remover dos favoritos.',
        vermelho: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          removendo = false;
        });
      }
    }
  }

  // ============================================================
  // ABRIR RESTAURANTE
  // ============================================================

  Future<void> abrirRestaurante(
    Map<String, dynamic> restaurante,
  ) async {
    final id = _obterId(restaurante);

    if (id.isEmpty) {
      _mensagem(
        'Não foi possível identificar o restaurante.',
        vermelho: true,
      );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantScreen(
          restauranteId: id,
          nome: _obterNome(restaurante),
          descricao: _obterDescricao(restaurante),
          avaliacao: _obterAvaliacao(restaurante),
        ),
      ),
    );

    // O usuário pode ter alterado o favorito
    // dentro do RestaurantScreen.
    await carregarFavoritos();
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mensagem(
    String texto, {
    bool vermelho = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          backgroundColor:
              vermelho ? Colors.redAccent : laranja,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: fundo,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,

        title: const Text(
          'Meus favoritos',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Atualizar favoritos',
            onPressed: carregando
                ? null
                : carregarFavoritos,
            icon: const Icon(
              Icons.refresh_rounded,
              color: laranja,
            ),
          ),

          const SizedBox(width: 6),
        ],

        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
      ),

      body: RefreshIndicator(
        color: laranja,
        onRefresh: carregarFavoritos,
        child: _conteudo(),
      ),
    );
  }

  // ============================================================
  // CONTEÚDO
  // ============================================================

  Widget _conteudo() {
    if (carregando) {
      return const Center(
        child: CircularProgressIndicator(
          color: laranja,
        ),
      );
    }

    if (favoritos.isEmpty) {
      return _estadoVazio();
    }

    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        30,
      ),

      itemCount: favoritos.length,

      itemBuilder: (
        context,
        index,
      ) {
        final restaurante = favoritos[index];

        return _cardFavorito(
          restaurante,
        );
      },
    );
  }

  // ============================================================
  // CARD FAVORITO
  // ============================================================

  Widget _cardFavorito(
    Map<String, dynamic> restaurante,
  ) {
    final nome = _obterNome(
      restaurante,
    );

    final avaliacao = _obterAvaliacao(
      restaurante,
    );

    final imagem = _obterImagem(
      restaurante,
    );

    final id = _obterId(
      restaurante,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(
              0,
              7,
            ),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        borderRadius:
            BorderRadius.circular(24),

        child: InkWell(
          borderRadius:
              BorderRadius.circular(24),

          onTap: () {
            abrirRestaurante(
              restaurante,
            );
          },

          child: Padding(
            padding:
                const EdgeInsets.all(12),

            child: Row(
              children: [
                // ==================================================
                // IMAGEM
                // ==================================================

                _imagemRestaurante(
                  imagem,
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
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        nome,

                        maxLines: 1,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color:
                                Color(0xFFF59E0B),
                            size: 18,
                          ),

                          const SizedBox(
                            width: 4,
                          ),

                          Text(
                            avaliacao,

                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 9,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),

                        decoration:
                            BoxDecoration(
                          color: laranja
                              .withValues(
                            alpha: 0.10,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),

                        child:
                            const Text(
                          'Favorito ❤️',

                          style:
                              TextStyle(
                            color: laranja,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),

                      if (id.isNotEmpty) ...[
                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          id,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Colors.transparent,
                            fontSize: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(
                  width: 5,
                ),

                // ==================================================
                // CORAÇÃO
                // ==================================================

                IconButton(
                  tooltip:
                      'Remover dos favoritos',

                  onPressed: () {
                    removerFavorito(
                      restaurante,
                    );
                  },

                  icon:
                      const Icon(
                    Icons.favorite_rounded,
                    color:
                        Colors.redAccent,
                    size: 27,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGEM RESTAURANTE
  // ============================================================

  Widget _imagemRestaurante(
    String? imagem,
  ) {
    if (imagem == null ||
        imagem.trim().isEmpty) {
      return _imagemPadrao();
    }

    final valor = imagem.trim();

    // ----------------------------------------------------------
    // BASE64 DATA URI
    // ----------------------------------------------------------

    if (valor.startsWith(
      'data:image',
    )) {
      return _imagemBase64(
        valor,
      );
    }

    // ----------------------------------------------------------
    // BASE64 PURO
    // ----------------------------------------------------------

    if (_pareceBase64(valor)) {
      return _imagemBase64Puro(
        valor,
      );
    }

    // ----------------------------------------------------------
    // URL
    // ----------------------------------------------------------

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(18),

      child: Image.network(
        valor,

        width: 82,
        height: 82,

        fit: BoxFit.cover,

        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return _imagemCarregando();
        },

        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          debugPrint(
            'ERRO IMAGEM FAVORITO: $error',
          );

          return _imagemPadrao();
        },
      ),
    );
  }

  // ============================================================
  // VERIFICAR BASE64
  // ============================================================

  bool _pareceBase64(
    String valor,
  ) {
    if (valor.length < 100) {
      return false;
    }

    final regex = RegExp(
      r'^[A-Za-z0-9+/=\r\n]+$',
    );

    return regex.hasMatch(valor);
  }

  // ============================================================
  // BASE64 DATA URI
  // ============================================================

  Widget _imagemBase64(
    String imagem,
  ) {
    try {
      final bytes =
          UriData.parse(
        imagem,
      ).contentAsBytes();

      return ClipRRect(
        borderRadius:
            BorderRadius.circular(18),

        child: Image.memory(
          bytes,

          width: 82,
          height: 82,

          fit: BoxFit.cover,

          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _imagemPadrao();
          },
        ),
      );
    } catch (e) {
      debugPrint(
        'ERRO BASE64 FAVORITO: $e',
      );

      return _imagemPadrao();
    }
  }

  // ============================================================
  // BASE64 PURO
  // ============================================================

  Widget _imagemBase64Puro(
    String imagem,
  ) {
    try {
      final bytes =
          base64Decode(
        imagem,
      );

      return ClipRRect(
        borderRadius:
            BorderRadius.circular(18),

        child: Image.memory(
          bytes,

          width: 82,
          height: 82,

          fit: BoxFit.cover,

          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _imagemPadrao();
          },
        ),
      );
    } catch (e) {
      debugPrint(
        'ERRO BASE64 PURO FAVORITO: $e',
      );

      return _imagemPadrao();
    }
  }

  // ============================================================
  // IMAGEM CARREGANDO
  // ============================================================

  Widget _imagemCarregando() {
    return Container(
      width: 82,
      height: 82,

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
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
  // IMAGEM PADRÃO
  // ============================================================

  Widget _imagemPadrao() {
    return Container(
      width: 82,
      height: 82,

      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFFFFE5D3),
            Color(0xFFFFD2B2),
          ],
        ),

        borderRadius:
            BorderRadius.circular(18),
      ),

      child: const Icon(
        Icons.restaurant_rounded,
        color: laranja,
        size: 38,
      ),
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _estadoVazio() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      children: [
        SizedBox(
          height:
              MediaQuery.of(context)
                      .size
                      .height *
                  0.65,

          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(30),

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
                          laranja.withValues(
                        alpha: 0.10,
                      ),
                      shape:
                          BoxShape.circle,
                    ),

                    child:
                        const Icon(
                      Icons
                          .favorite_border_rounded,
                      color: laranja,
                      size: 52,
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  const Text(
                    'Você ainda não tem favoritos',

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'Toque no coração dos restaurantes que você gosta para encontrá-los aqui.',

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      color:
                          Colors.black54,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  ElevatedButton.icon(
                    onPressed:
                        carregarFavoritos,

                    icon:
                        const Icon(
                      Icons.refresh_rounded,
                    ),

                    label:
                        const Text(
                      'Atualizar favoritos',
                    ),

                    style:
                        ElevatedButton.styleFrom(
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
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}