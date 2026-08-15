
import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String restauranteId;

  const ProductsScreen({
    super.key,
    required this.restauranteId,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService service = ProductService();

  final TextEditingController pesquisaController =
      TextEditingController();

  List<ProductModel> produtos = [];
  List<ProductModel> filtro = [];

  bool carregando = true;
  String categoriaSelecionada = 'Todos';

  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    carregarProdutos();
  }

  // ============================================================
  // CARREGAR PRODUTOS
  // ============================================================

  Future<void> carregarProdutos() async {
    if (produtos.isEmpty && mounted) {
      setState(() {
        carregando = true;
      });
    }

    try {
      final lista = await service.buscarProdutos(
        widget.restauranteId,
      );

      final produtosConvertidos = lista.map<ProductModel>((e) {
        return ProductModel.fromJson(
          Map<String, dynamic>.from(e as Map),
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        produtos = produtosConvertidos;
        carregando = false;
      });

      aplicarFiltros();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar os produtos.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // CATEGORIAS
  // ============================================================

  List<String> get categorias {
    final lista = produtos
        .map(
          (produto) => produto.categoria.trim(),
        )
        .where((categoria) => categoria.isNotEmpty)
        .toSet()
        .toList();

    lista.sort();

    return ['Todos', ...lista];
  }

  // ============================================================
  // FILTROS
  // ============================================================

  void pesquisar(String texto) {
    aplicarFiltros();
  }

  void selecionarCategoria(String categoria) {
    setState(() {
      categoriaSelecionada = categoria;
    });

    aplicarFiltros();
  }

  void aplicarFiltros() {
    final texto = pesquisaController.text.trim().toLowerCase();

    final resultado = produtos.where((produto) {
      final nome = produto.nome.toLowerCase();
      final categoria = produto.categoria.toLowerCase();

      final correspondePesquisa =
          texto.isEmpty ||
          nome.contains(texto) ||
          categoria.contains(texto);

      final correspondeCategoria =
          categoriaSelecionada == 'Todos' ||
          produto.categoria.toLowerCase() ==
              categoriaSelecionada.toLowerCase();

      return correspondePesquisa && correspondeCategoria;
    }).toList();

    if (!mounted) return;

    setState(() {
      filtro = resultado;
    });
  }

  // ============================================================
  // DISPONIBILIDADE
  // ============================================================

  Future<void> alterarDisponibilidade(
    ProductModel produto,
  ) async {
    try {
      await service.alterarDisponibilidade(
        produto.id,
        !produto.disponivel,
      );

      await carregarProdutos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            produto.disponivel
                ? '${produto.nome} ficou indisponível.'
                : '${produto.nome} está disponível.',
          ),
          backgroundColor: produto.disponivel
              ? Colors.orange
              : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível alterar a disponibilidade.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<void> excluirProduto(
    ProductModel produto,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text(
                'Excluir produto',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Deseja realmente excluir "${produto.nome}"?\n\n'
            'Essa ação não poderá ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Excluir',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await service.excluirProduto(
        produto.id,
      );

      await carregarProdutos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Produto excluído com sucesso.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível excluir o produto.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ADICIONAR
  // ============================================================

  Future<void> adicionarProduto() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(
          restauranteId: widget.restauranteId,
        ),
      ),
    );

    if (resultado == true || resultado == null) {
      await carregarProdutos();
    }
  }

  // ============================================================
  // EDITAR
  // ============================================================

  Future<void> editarProduto(
    ProductModel produto,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(
          produto: produto,
        ),
      ),
    );

    await carregarProdutos();
  }

  // ============================================================
  // URL DA IMAGEM
  // ============================================================

  String _urlImagem(String imagem) {
    if (imagem.startsWith('http://') ||
        imagem.startsWith('https://')) {
      return imagem;
    }

    return 'http://192.168.1.101:3000$imagem';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,

        titleSpacing: 18,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meu cardápio',
              style: TextStyle(
                color: Colors.black,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Gerencie seus produtos',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: carregando
                ? null
                : carregarProdutos,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.black87,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: carregando
            ? null
            : adicionarProduto,
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 5,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Novo produto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: carregando
          ? const Center(
              child: CircularProgressIndicator(
                color: laranja,
              ),
            )
          : RefreshIndicator(
              color: laranja,
              onRefresh: carregarProdutos,
              child: CustomScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _cabecalho(),
                  ),

                  SliverToBoxAdapter(
                    child: _pesquisa(),
                  ),

                  SliverToBoxAdapter(
                    child: _categorias(),
                  ),

                  if (filtro.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _estadoVazio(),
                    )
                  else
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        110,
                      ),
                      sliver: SliverList(
                        delegate:
                            SliverChildBuilderDelegate(
                          (context, index) {
                            final produto =
                                filtro[index];

                            return _produtoCard(
                              produto,
                            );
                          },
                          childCount: filtro.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // CABEÇALHO
  // ============================================================

  Widget _cabecalho() {
    final disponiveis = produtos
        .where((produto) => produto.disponivel)
        .length;

    final destaques = produtos
        .where((produto) => produto.destaque)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        8,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFEDD5),
              Color(0xFFFFF7ED),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: laranja,
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seu cardápio',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Controle seus produtos e preços',
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

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _estatistica(
                    valor: produtos.length
                        .toString(),
                    titulo: 'Produtos',
                    icone:
                        Icons.inventory_2_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _estatistica(
                    valor:
                        disponiveis.toString(),
                    titulo: 'Disponíveis',
                    icone:
                        Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _estatistica(
                    valor:
                        destaques.toString(),
                    titulo: 'Destaques',
                    icone: Icons.star_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _estatistica({
    required String valor,
    required String titulo,
    required IconData icone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.75,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            icone,
            color: laranja,
            size: 20,
          ),
          const SizedBox(height: 5),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PESQUISA
  // ============================================================

  Widget _pesquisa() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        6,
      ),
      child: TextField(
        controller: pesquisaController,
        onChanged: pesquisar,
        textInputAction:
            TextInputAction.search,
        decoration: InputDecoration(
          hintText:
              'Buscar produto ou categoria...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: laranja,
          ),
          suffixIcon:
              pesquisaController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        pesquisaController.clear();
                        aplicarFiltros();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    )
                  : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(17),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(17),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(17),
            borderSide: const BorderSide(
              color: laranja,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORIAS
  // ============================================================

  Widget _categorias() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final categoria =
              categorias[index];

          final selecionada =
              categoria == categoriaSelecionada;

          return ChoiceChip(
            label: Text(
              categoria,
              style: TextStyle(
                color: selecionada
                    ? Colors.white
                    : Colors.black87,
                fontWeight:
                    FontWeight.w600,
                fontSize: 12,
              ),
            ),
            selected: selecionada,
            onSelected: (_) {
              selecionarCategoria(
                categoria,
              );
            },
            selectedColor: laranja,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selecionada
                  ? laranja
                  : Colors.grey.shade200,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),
            showCheckmark: false,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 7,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CARD PRODUTO
  // ============================================================

  Widget _produtoCard(
    ProductModel produto,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 5),
            color: Colors.black.withValues(
              alpha: 0.055,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _imagemProduto(produto),

              const SizedBox(width: 14),

              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 13,
                    right: 5,
                    bottom: 8,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              produto.nome,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                          ),
                          PopupMenuButton<int>(
                            padding:
                                EdgeInsets.zero,
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Colors.black54,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                            ),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 1,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .edit_outlined,
                                      size: 20,
                                    ),
                                    SizedBox(
                                        width: 10),
                                    Text(
                                      'Editar',
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 2,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .delete_outline_rounded,
                                      color:
                                          Colors.red,
                                      size: 20,
                                    ),
                                    SizedBox(
                                        width: 10),
                                    Text(
                                      'Excluir',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 1) {
                                editarProduto(
                                  produto,
                                );
                              }

                              if (value == 2) {
                                excluirProduto(
                                  produto,
                                );
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      _categoriaBadge(
                        produto.categoria,
                      ),

                      const SizedBox(height: 7),

                      Text(
                        'R\$ ${produto.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                        style:
                            const TextStyle(
                          color: laranja,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _statusBadge(
                            produto.disponivel,
                          ),

                          if (produto.destaque) ...[
                            const SizedBox(width: 6),
                            _destaqueBadge(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  produto.disponivel
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 18,
                  color: produto.disponivel
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    produto.disponivel
                        ? 'Produto visível para os clientes'
                        : 'Produto oculto do cardápio',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: produto.disponivel,
                  onChanged: (_) {
                    alterarDisponibilidade(
                      produto,
                    );
                  },
                  activeThumbColor:
                      Colors.green,
                ),
              ],
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
    ProductModel produto,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(18),
            child: SizedBox(
              width: 105,
              height: 125,
              child: produto.imagem == null ||
                      produto.imagem!.trim().isEmpty
                  ? Container(
                      color:
                          const Color(0xFFFFF7ED),
                      child: const Icon(
                        Icons
                            .restaurant_rounded,
                        color: laranja,
                        size: 38,
                      ),
                    )
                  : Image.network(
                      _urlImagem(
                        produto.imagem!,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stack) {
                        return Container(
                          color:
                              const Color(
                            0xFFFFF7ED,
                          ),
                          child:
                              const Icon(
                            Icons
                                .broken_image_outlined,
                            color: laranja,
                            size: 35,
                          ),
                        );
                      },
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
                          color:
                              const Color(
                            0xFFF5F5F5,
                          ),
                          child:
                              const Center(
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: laranja,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          if (produto.destaque)
            Positioned(
              left: 7,
              top: 7,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Destaque',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.bold,
                      ),
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
  // CATEGORIA BADGE
  // ============================================================

  Widget _categoriaBadge(
    String categoria,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Text(
        categoria,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusBadge(
    bool disponivel,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: disponivel
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFF3F4F6),
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: disponivel
                  ? Colors.green
                  : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            disponivel
                ? 'Disponível'
                : 'Indisponível',
            style: TextStyle(
              color: disponivel
                  ? Colors.green.shade700
                  : Colors.grey.shade700,
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
  // DESTAQUE
  // ============================================================

  Widget _destaqueBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            'Destaque',
            style: TextStyle(
              color: Color(0xFF9A6700),
              fontSize: 10,
              fontWeight: FontWeight.w700,
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
    final pesquisando =
        pesquisaController.text.trim().isNotEmpty ||
            categoriaSelecionada != 'Todos';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEDD5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                pesquisando
                    ? Icons.search_off_rounded
                    : Icons.restaurant_menu_rounded,
                color: laranja,
                size: 42,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              pesquisando
                  ? 'Nenhum produto encontrado'
                  : 'Seu cardápio está vazio',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              pesquisando
                  ? 'Tente buscar outro produto ou categoria.'
                  : 'Cadastre seu primeiro produto para começar.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            if (!pesquisando) ...[
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: adicionarProduto,
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label: const Text(
                  'Cadastrar produto',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: laranja,
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
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }
}

