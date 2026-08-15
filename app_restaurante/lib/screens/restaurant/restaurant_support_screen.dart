import 'package:flutter/material.dart';

class RestaurantSupportScreen extends StatefulWidget {
  final String restauranteId;
  final String nomeRestaurante;
  final String email;

  const RestaurantSupportScreen({
    super.key,
    required this.restauranteId,
    required this.nomeRestaurante,
    required this.email,
  });

  @override
  State<RestaurantSupportScreen> createState() =>
      _RestaurantSupportScreenState();
}

class _RestaurantSupportScreenState
    extends State<RestaurantSupportScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF7F7F8);

  final TextEditingController _mensagemController =
      TextEditingController();

  String categoriaSelecionada = 'Selecione uma categoria';

  bool enviandoChamado = false;

  final List<String> categorias = [
    'Problema com pedido',
    'Ganhos e saques',
    'Restaurante e cardápio',
    'Minha conta',
    'Problema no aplicativo',
    'Outro assunto',
  ];

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  // ============================================================
  // ABRIR CHAMADO
  // ============================================================

  Future<void> _abrirChamado() async {
    if (categoriaSelecionada ==
        'Selecione uma categoria') {
      _mensagem(
        'Selecione o motivo do atendimento.',
      );
      return;
    }

    if (_mensagemController.text.trim().isEmpty) {
      _mensagem(
        'Digite uma mensagem para o suporte.',
      );
      return;
    }

    setState(() {
      enviandoChamado = true;
    });

    // ==========================================================
    // FUTURA INTEGRAÇÃO COM A API
    // ==========================================================
    //
    // Aqui futuramente vamos enviar:
    //
    // restauranteId
    // nomeRestaurante
    // email
    // categoria
    // mensagem
    //
    // para o backend FoodJet.
    //
    // ==========================================================

    await Future.delayed(
      const Duration(
        milliseconds: 800,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      enviandoChamado = false;
    });

    _mensagem(
      'Chamado enviado com sucesso! O suporte FoodJet responderá em breve.',
    );

    _mensagemController.clear();

    setState(() {
      categoriaSelecionada =
          'Selecione uma categoria';
    });
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mensagem(String texto) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
        duration:
            const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // ITEM DE SUPORTE
  // ============================================================

  Widget _itemSuporte({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color cor = laranja,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(18),
      child: Container(
        padding:
            const EdgeInsets.all(16),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.04),
              blurRadius: 10,
              offset:
                  const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration:
                  BoxDecoration(
                color: cor.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                icone,
                color: cor,
                size: 24,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    subtitulo,
                    style:
                        const TextStyle(
                      color:
                          Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .arrow_forward_ios_rounded,
              size: 15,
              color:
                  Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FAQ
  // ============================================================

  Widget _faqItem({
    required String pergunta,
    required String resposta,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(
          pergunta,
          style:
              const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        iconColor: laranja,
        collapsedIconColor:
            Colors.black54,
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16,
            ),
            child: Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                resposta,
                style:
                    const TextStyle(
                  color:
                      Colors.black54,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ABRIR CHAMADO
  // ============================================================

  void _mostrarFormularioChamado() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setModalState) {
            return Container(
              padding:
                  EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom:
                    MediaQuery.of(context)
                            .viewInsets
                            .bottom +
                        20,
              ),
              decoration:
                  const BoxDecoration(
                color: fundo,
                borderRadius:
                    BorderRadius.vertical(
                  top:
                      Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.black26,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      'Abrir chamado',
                      style:
                          TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    const Text(
                      'Descreva o problema para nossa equipe de suporte.',
                      style:
                          TextStyle(
                        color:
                            Colors.black54,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                          categorias.contains(
                        categoriaSelecionada,
                      )
                              ? categoriaSelecionada
                              : null,
                      decoration:
                          InputDecoration(
                        labelText:
                            'Categoria',
                        prefixIcon:
                            const Icon(
                          Icons
                              .category_outlined,
                          color:
                              laranja,
                        ),
                        filled: true,
                        fillColor:
                            Colors.white,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                      items:
                          categorias.map(
                        (categoria) {
                          return DropdownMenuItem<
                              String>(
                            value:
                                categoria,
                            child:
                                Text(
                              categoria,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged:
                          (valor) {
                        if (valor == null) {
                          return;
                        }

                        setModalState(() {
                          categoriaSelecionada =
                              valor;
                        });

                        setState(() {});
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextField(
                      controller:
                          _mensagemController,
                      maxLines: 5,
                      decoration:
                          InputDecoration(
                        labelText:
                            'Descreva seu problema',
                        alignLabelWithHint:
                            true,
                        prefixIcon:
                            const Padding(
                          padding:
                              EdgeInsets.only(
                            bottom: 75,
                          ),
                          child:
                              Icon(
                            Icons
                                .message_outlined,
                            color:
                                laranja,
                          ),
                        ),
                        filled: true,
                        fillColor:
                            Colors.white,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child:
                          ElevatedButton(
                        onPressed:
                            enviandoChamado
                                ? null
                                : () async {
                                    Navigator.pop(
                                      context,
                                    );

                                    await _abrirChamado();
                                  },
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              laranja,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        child:
                            enviandoChamado
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.5,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'ENVIAR CHAMADO',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor:
            Colors.black87,
        elevation: 0,
        title: const Text(
          'Suporte FoodJet',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          30,
        ),
        children: [
          // ======================================================
          // CABEÇALHO
          // ======================================================

          Container(
            padding:
                const EdgeInsets.all(22),
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
                colors: [
                  Color(0xFFF97316),
                  Color(0xFFEA580C),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(
                22,
              ),
              boxShadow: [
                BoxShadow(
                  color: laranja
                      .withValues(
                    alpha: 0.25,
                  ),
                  blurRadius: 15,
                  offset:
                      const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.18,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      17,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .support_agent_rounded,
                    color:
                        Colors.white,
                    size: 32,
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
                      const Text(
                        'Olá, ${''}',
                        style:
                            TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 13,
                        ),
                      ),

                      Text(
                        widget.nomeRestaurante,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      const Text(
                        'Estamos aqui para ajudar.',
                        style:
                            TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          const Text(
            'Como podemos ajudar?',
            style:
                TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          _itemSuporte(
            icone:
                Icons.receipt_long_rounded,
            titulo:
                'Problema com pedido',
            subtitulo:
                'Ajuda com pedidos, cancelamentos ou entregas.',
            onTap: () {
              setState(() {
                categoriaSelecionada =
                    'Problema com pedido';
              });

              _mostrarFormularioChamado();
            },
          ),

          const SizedBox(
            height: 10,
          ),

          _itemSuporte(
            icone:
                Icons.account_balance_wallet_rounded,
            titulo:
                'Ganhos e saques',
            subtitulo:
                'Dúvidas sobre saldo, pagamentos ou saques.',
            onTap: () {
              setState(() {
                categoriaSelecionada =
                    'Ganhos e saques';
              });

              _mostrarFormularioChamado();
            },
            cor:
                Colors.green,
          ),

          const SizedBox(
            height: 10,
          ),

          _itemSuporte(
            icone:
                Icons.storefront_rounded,
            titulo:
                'Restaurante e cardápio',
            subtitulo:
                'Ajuda com produtos, preços e informações da loja.',
            onTap: () {
              setState(() {
                categoriaSelecionada =
                    'Restaurante e cardápio';
              });

              _mostrarFormularioChamado();
            },
          ),

          const SizedBox(
            height: 10,
          ),

          _itemSuporte(
            icone:
                Icons.person_outline_rounded,
            titulo:
                'Minha conta',
            subtitulo:
                'Problemas com acesso ou dados da conta.',
            onTap: () {
              setState(() {
                categoriaSelecionada =
                    'Minha conta';
              });

              _mostrarFormularioChamado();
            },
            cor:
                Colors.blue,
          ),

          const SizedBox(
            height: 10,
          ),

          _itemSuporte(
            icone:
                Icons.phone_android_rounded,
            titulo:
                'Problema no aplicativo',
            subtitulo:
                'Encontrou algum erro ou problema no app?',
            onTap: () {
              setState(() {
                categoriaSelecionada =
                    'Problema no aplicativo';
              });

              _mostrarFormularioChamado();
            },
            cor:
                Colors.purple,
          ),

          const SizedBox(
            height: 25,
          ),

          // ======================================================
          // CHAMADO
          // ======================================================

          Container(
            padding:
                const EdgeInsets.all(18),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border:
                  Border.all(
                color:
                    laranja.withValues(
                  alpha: 0.15,
                ),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons
                      .support_agent_rounded,
                  color:
                      laranja,
                  size: 40,
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'Precisa de ajuda personalizada?',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                const Text(
                  'Abra um chamado e nossa equipe poderá analisar seu problema.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.black54,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _mostrarFormularioChamado,
                    icon:
                        const Icon(
                      Icons
                          .add_comment_outlined,
                    ),
                    label:
                        const Text(
                      'Abrir chamado',
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          laranja,
                      foregroundColor:
                          Colors.white,
                      padding:
                          const EdgeInsets
                              .symmetric(
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
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          // ======================================================
          // PERGUNTAS FREQUENTES
          // ======================================================

          const Text(
            'Perguntas frequentes',
            style:
                TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          _faqItem(
            pergunta:
                'Como faço para ficar online?',
            resposta:
                'Na tela inicial do restaurante, utilize o botão de status para ficar online. Quando estiver online, seu restaurante poderá receber novos pedidos.',
          ),

          _faqItem(
            pergunta:
                'Como acompanho meus ganhos?',
            resposta:
                'Acesse a área de Ganhos no menu do restaurante para consultar seu saldo, histórico de movimentações e valores disponíveis para saque.',
          ),

          _faqItem(
            pergunta:
                'Como faço um saque?',
            resposta:
                'Acesse Ganhos, confira o saldo disponível e selecione a opção de saque. O sistema mostrará as informações necessárias antes da confirmação.',
          ),

          _faqItem(
            pergunta:
                'O que faço se um pedido estiver com problema?',
            resposta:
                'Abra um chamado na categoria Problema com pedido e informe o número do pedido e todos os detalhes do problema.',
          ),

          _faqItem(
            pergunta:
                'Como alterar os produtos do restaurante?',
            resposta:
                'Acesse a área Produtos do aplicativo para gerenciar o cardápio. Caso encontre algum problema, abra um chamado para nossa equipe.',
          ),

          const SizedBox(
            height: 25,
          ),

          // ======================================================
          // DADOS DA CONTA
          // ======================================================

          Center(
            child: Text(
              'ID do restaurante: ${widget.restauranteId}',
              style:
                  const TextStyle(
                color:
                    Colors.black38,
                fontSize: 11,
              ),
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Center(
            child: Text(
              widget.email,
              style:
                  const TextStyle(
                color:
                    Colors.black38,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}