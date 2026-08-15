
import 'package:flutter/material.dart';

import 'delivery_address_screen.dart';

class CartItem {
  final String nome;
  final double preco;
  final String? imagem;
  final String? produtoId;
  int quantidade;

  CartItem({
    required this.nome,
    required this.preco,
    this.imagem,
    this.produtoId,
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
  State<CartScreen> createState() =>
      _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color laranja =
      Color(0xFFF97316);

  static const Color fundo =
      Color(0xFFF5F5F5);

  double get subtotal {
    return widget.itens.fold(
      0,
      (total, item) =>
          total +
          (item.preco *
              item.quantidade),
    );
  }

  int get quantidadeTotal {
    return widget.itens.fold(
      0,
      (total, item) =>
          total +
          item.quantidade,
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

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '${item.nome} removido do carrinho.',
        ),
        backgroundColor: laranja,
        duration:
            const Duration(seconds: 1),
      ),
    );
  }

  void continuarPedido() {
    if (widget.itens.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Adicione pelo menos um produto para continuar.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DeliveryAddressScreen(
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

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,

        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Meu Carrinho',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            if (widget.itens.isNotEmpty)
              Text(
                '$quantidadeTotal ${quantidadeTotal == 1 ? 'item' : 'itens'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),

      body: widget.itens.isEmpty
          ? _carrinhoVazio()
          : Column(
              children: [
                Expanded(
                  child:
                      ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      20,
                    ),

                    itemCount:
                        widget.itens.length,

                    itemBuilder:
                        (context, index) {
                      final item =
                          widget.itens[index];

                      return _itemCarrinho(
                        item,
                      );
                    },
                  ),
                ),

                _resumoCarrinho(),
              ],
            ),
    );
  }

  // ============================================================
  // CARRINHO VAZIO
  // ============================================================

  Widget _carrinhoVazio() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
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

              child:
                  const Icon(
                Icons
                    .shopping_cart_outlined,
                size: 58,
                color: laranja,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'Seu carrinho está vazio',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Adicione produtos do restaurante para continuar seu pedido.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            ElevatedButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                );
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    laranja,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 24,
                  vertical: 14,
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
                'VOLTAR AO CARDÁPIO',
                style: TextStyle(
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

  // ============================================================
  // ITEM DO CARRINHO
  // ============================================================

  Widget _itemCarrinho(
    CartItem item,
  ) {
    final totalItem =
        item.preco *
            item.quantidade;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(15),

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
              alpha: 0.04,
            ),
            blurRadius: 6,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _imagemProduto(
            item.imagem,
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Expanded(
                      child: Text(
                        item.nome,

                        maxLines: 2,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          color:
                              Colors.black87,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed:
                          () {
                        removerProduto(
                          item,
                        );
                      },

                      padding:
                          EdgeInsets.zero,

                      constraints:
                          const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),

                      icon:
                          const Icon(
                        Icons
                            .delete_outline_rounded,
                        color:
                            Colors.redAccent,
                        size: 21,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  formatarPreco(
                    item.preco,
                  ),

                  style:
                      const TextStyle(
                    color: laranja,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Row(
                  children: [
                    _botaoQuantidade(
                      icone:
                          Icons
                              .remove_rounded,
                      onPressed:
                          () {
                        diminuir(
                          item,
                        );
                      },
                    ),

                    Container(
                      width: 42,
                      alignment:
                          Alignment.center,

                      child:
                          Text(
                        item.quantidade
                            .toString(),

                        style:
                            const TextStyle(
                          color:
                              Colors.black87,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    _botaoQuantidade(
                      icone:
                          Icons
                              .add_rounded,
                      onPressed:
                          () {
                        aumentar(
                          item,
                        );
                      },
                    ),

                    const Spacer(),

                    Text(
                      formatarPreco(
                        totalItem,
                      ),

                      style:
                          const TextStyle(
                        color:
                            Colors.black87,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
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
  // BOTÃO QUANTIDADE
  // ============================================================

  Widget _botaoQuantidade({
    required IconData icone,
    required VoidCallback onPressed,
  }) {
    return Material(
      color:
          laranja.withValues(
        alpha: 0.10,
      ),

      borderRadius:
          BorderRadius.circular(
        10,
      ),

      child: InkWell(
        onTap:
            onPressed,

        borderRadius:
            BorderRadius.circular(
          10,
        ),

        child:
            SizedBox(
          width: 38,
          height: 38,

          child:
              Icon(
            icone,
            color: laranja,
            size: 20,
          ),
        ),
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
        imagem.trim().isEmpty) {
      return Container(
        width: 72,
        height: 72,

        decoration:
            BoxDecoration(
          color:
              const Color(0xFFFFB36B),

          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),

        child:
            const Icon(
          Icons.fastfood_rounded,
          color: laranja,
          size: 34,
        ),
      );
    }

    String url = imagem;

    if (!imagem.startsWith(
          'http://',
        ) &&
        !imagem.startsWith(
          'https://',
        )) {
      final baseUrl =
          'http://192.168.1.101:3000';

      if (imagem.startsWith('/')) {
        url =
            '$baseUrl$imagem';
      } else {
        url =
            '$baseUrl/$imagem';
      }
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        14,
      ),

      child:
          Image.network(
        url,

        width: 72,
        height: 72,

        fit:
            BoxFit.cover,

        errorBuilder:
            (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            width: 72,
            height: 72,

            color:
                const Color(
              0xFFFFB36B,
            ),

            child:
                const Icon(
              Icons.fastfood_rounded,
              color:
                  laranja,
              size: 34,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // RESUMO DO CARRINHO
  // ============================================================

  Widget _resumoCarrinho() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20,
      ),

      decoration:
          const BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            25,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black12,
            blurRadius: 10,
            offset:
                Offset(0, -3),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                const Text(
                  'Subtotal',

                  style:
                      TextStyle(
                    color:
                        Colors.black54,
                    fontSize:
                        15,
                  ),
                ),

                Text(
                  formatarPreco(
                    subtotal,
                  ),

                  style:
                      const TextStyle(
                    color:
                        Colors.black87,
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height:
                  6,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                const Text(
                  'Quantidade',

                  style:
                      TextStyle(
                    color:
                        Colors.black54,
                    fontSize:
                        15,
                  ),
                ),

                Text(
                  quantidadeTotal
                      .toString(),

                  style:
                      const TextStyle(
                    color:
                        Colors.black87,
                    fontSize:
                        15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height:
                  15,
            ),

            const Divider(
              height:
                  1,
            ),

            const SizedBox(
              height:
                  15,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                const Text(
                  'Total',

                  style:
                      TextStyle(
                    color:
                        Colors.black87,
                    fontSize:
                        20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                Text(
                  formatarPreco(
                    subtotal,
                  ),

                  style:
                      const TextStyle(
                    color:
                        laranja,
                    fontSize:
                        21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height:
                  16,
            ),

            SizedBox(
              width:
                  double.infinity,

              child:
                  ElevatedButton.icon(
                onPressed:
                    continuarPedido,

                icon:
                    const Icon(
                  Icons
                      .arrow_forward_rounded,
                ),

                label:
                    const Text(
                  'CONTINUAR PEDIDO',
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      laranja,

                  foregroundColor:
                      Colors.white,

                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical:
                        16,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

