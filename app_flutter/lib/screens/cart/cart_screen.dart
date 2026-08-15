import 'package:flutter/material.dart';

import '../../config/api.dart';
import 'delivery_address_screen.dart';

class CartItem {
  final String nome;
  final double preco;
  final String? imagem;
  final String? produtoId;

  // Mantido opcional para não quebrar a estrutura atual.
  final String? restauranteId;

  int quantidade;

  CartItem({
    required this.nome,
    required this.preco,
    this.imagem,
    this.produtoId,
    this.restauranteId,
    this.quantidade = 1,
  });
}

class CartScreen extends StatefulWidget {
  final List<CartItem> itens;

  const CartScreen({
    super.key,
    required this.itens,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF7F7F8);

  double get subtotal {
    return widget.itens.fold(
      0,
      (total, item) => total + (item.preco * item.quantidade),
    );
  }

  int get quantidadeTotal {
    return widget.itens.fold(
      0,
      (total, item) => total + item.quantidade,
    );
  }

  void aumentar(CartItem item) {
    setState(() {
      item.quantidade++;
    });
  }

  void diminuir(CartItem item) {
    setState(() {
      if (item.quantidade > 1) {
        item.quantidade--;
      } else {
        widget.itens.remove(item);
      }
    });
  }

  void removerProduto(CartItem item) {
    setState(() {
      widget.itens.remove(item);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${item.nome} removido do carrinho.',
        ),
        backgroundColor: laranja,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void limparCarrinho() {
    if (widget.itens.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Limpar carrinho?',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Todos os produtos serão removidos do carrinho.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          side: const BorderSide(
                            color: Colors.black12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            widget.itens.clear();
                          });

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Limpar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void continuarPedido() {
    if (widget.itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Adicione pelo menos um produto para continuar.',
          ),
          backgroundColor: laranja,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryAddressScreen(
          itens: widget.itens,
          subtotal: subtotal,
        ),
      ),
    );
  }

  String formatarPreco(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,

      appBar: _appBar(),

      body: widget.itens.isEmpty
          ? _carrinhoVazio()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      24,
                    ),
                    children: [
                      _cabecalhoCarrinho(),

                      const SizedBox(height: 14),

                      ...widget.itens.map(
                        (item) => _itemCarrinho(item),
                      ),
                    ],
                  ),
                ),

                _resumoCarrinho(),
              ],
            ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _appBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,

      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 21,
          color: Colors.black87,
        ),
      ),

      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meu carrinho',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (widget.itens.isNotEmpty)
            Text(
              '$quantidadeTotal ${quantidadeTotal == 1 ? 'item' : 'itens'}',
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),

      actions: [
        if (widget.itens.isNotEmpty)
          IconButton(
            tooltip: 'Limpar carrinho',
            onPressed: limparCarrinho,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.black54,
            ),
          ),

        const SizedBox(width: 6),
      ],
    );
  }

  // ============================================================
  // CABEÇALHO
  // ============================================================

  Widget _cabecalhoCarrinho() {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF1E7),
            Colors.white,
          ],
        ),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: laranja.withValues(alpha: 0.08),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: laranja.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.shopping_bag_outlined,
              color: laranja,
              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seu pedido',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '$quantidadeTotal ${quantidadeTotal == 1 ? 'produto selecionado' : 'produtos selecionados'}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Text(
            formatarPreco(subtotal),
            style: const TextStyle(
              color: laranja,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARRINHO VAZIO
  // ============================================================

  Widget _carrinhoVazio() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,

              decoration: BoxDecoration(
                color: laranja.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 58,
                color: laranja,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Seu carrinho está vazio',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Escolha seus pratos favoritos e adicione ao carrinho para fazer seu pedido.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },

                icon: const Icon(
                  Icons.restaurant_menu_rounded,
                ),

                label: const Text(
                  'EXPLORAR RESTAURANTES',
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: laranja,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
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
  // ITEM
  // ============================================================

  Widget _itemCarrinho(CartItem item) {
    final totalItem = item.preco * item.quantidade;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: Colors.black.withValues(alpha: 0.035),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imagemProduto(item.imagem),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    InkWell(
                      onTap: () {
                        removerProduto(item);
                      },

                      borderRadius: BorderRadius.circular(20),

                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.black38,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  formatarPreco(item.preco),
                  style: const TextStyle(
                    color: laranja,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _botaoQuantidade(
                      icone: Icons.remove_rounded,
                      onPressed: () {
                        diminuir(item);
                      },
                    ),

                    SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          item.quantidade.toString(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    _botaoQuantidade(
                      icone: Icons.add_rounded,
                      onPressed: () {
                        aumentar(item);
                      },
                    ),

                    const Spacer(),

                    Text(
                      formatarPreco(totalItem),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUANTIDADE
  // ============================================================

  Widget _botaoQuantidade({
    required IconData icone,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: laranja.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(11),

      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(11),

        child: SizedBox(
          width: 36,
          height: 36,

          child: Icon(
            icone,
            color: laranja,
            size: 19,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGEM
  // ============================================================

  Widget _imagemProduto(String? imagem) {
    Widget fallback() {
      return Container(
        width: 78,
        height: 78,

        decoration: BoxDecoration(
          color: const Color(0xFFFFE8D5),
          borderRadius: BorderRadius.circular(16),
        ),

        child: const Icon(
          Icons.fastfood_rounded,
          color: laranja,
          size: 34,
        ),
      );
    }

    if (imagem == null || imagem.trim().isEmpty) {
      return fallback();
    }

    String url = imagem.trim();

    if (!url.startsWith('http://') &&
        !url.startsWith('https://')) {
      final baseUrl = Api.baseUrl.replaceFirst(
        RegExp(r'/api/?$'),
        '',
      );

      if (url.startsWith('/')) {
        url = '$baseUrl$url';
      } else {
        url = '$baseUrl/$url';
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),

      child: Image.network(
        url,
        width: 78,
        height: 78,
        fit: BoxFit.cover,

        loadingBuilder: (
          context,
          child,
          progress,
        ) {
          if (progress == null) {
            return child;
          }

          return Container(
            width: 78,
            height: 78,
            color: const Color(0xFFFFE8D5),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: laranja,
                ),
              ),
            ),
          );
        },

        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return fallback();
        },
      ),
    );
  }

  // ============================================================
  // RESUMO
  // ============================================================

  Widget _resumoCarrinho() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        17,
        20,
        18,
      ),

      decoration: const BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, -4),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,

              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),

                Text(
                  formatarPreco(subtotal),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Produtos',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),

                Text(
                  quantidadeTotal.toString(),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            const Divider(
              height: 1,
              color: Color(0xFFEDEDED),
            ),

            const SizedBox(height: 13),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  formatarPreco(subtotal),
                  style: const TextStyle(
                    color: laranja,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton(
                onPressed: continuarPedido,

                style: ElevatedButton.styleFrom(
                  backgroundColor: laranja,
                  foregroundColor: Colors.white,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    const Text(
                      'Continuar pedido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Container(
                      width: 30,
                      height: 30,

                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.18,
                        ),
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}