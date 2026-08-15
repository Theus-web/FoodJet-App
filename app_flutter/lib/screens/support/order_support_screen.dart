import 'package:flutter/material.dart';

import '../../services/support_service.dart';

class OrderSupportScreen extends StatefulWidget {
  final dynamic pedidoId;
  final dynamic clienteId;
  final dynamic restauranteId;

  const OrderSupportScreen({
    super.key,
    required this.pedidoId,
    required this.clienteId,
    required this.restauranteId,
  });

  @override
  State<OrderSupportScreen> createState() =>
      _OrderSupportScreenState();
}

class _OrderSupportScreenState
    extends State<OrderSupportScreen> {

  final SupportService service =
      SupportService();

  final TextEditingController descricaoController =
      TextEditingController();

  bool enviando = false;

  String assuntoSelecionado =
      "Problema com o pedido";

  final List<String> assuntos = [
    "Problema com o pedido",
    "Pedido não chegou",
    "Item faltando",
    "Item errado",
    "Problema com pagamento",
    "Pedido atrasado",
    "Outro problema",
  ];

  // ============================================================
  // ABRIR CHAMADO
  // ============================================================

  Future<void> abrirChamado() async {
    final descricao =
        descricaoController.text.trim();

    if (descricao.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Explique o que aconteceu.",
          ),
        ),
      );

      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      await service.criarChamado(
        pedidoId: widget.pedidoId,
        clienteId: widget.clienteId,
        restauranteId: widget.restauranteId,
        assunto: assuntoSelecionado,
        descricao: descricao,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Suporte solicitado com sucesso!",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erro: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF97316);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7F9),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),

        title: const Text(
          "Ajuda com o pedido",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ==================================================
            // CABEÇALHO
            // ==================================================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(22),
              ),

              child: Row(
                children: [

                  Container(
                    width: 52,
                    height: 52,

                    decoration:
                        BoxDecoration(
                      color:
                          orange.withOpacity(
                        .12,
                      ),
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: orange,
                      size: 28,
                    ),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Como podemos ajudar?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          "Informe o problema e nossa equipe poderá acompanhar sua solicitação.",
                          style: TextStyle(
                            color:
                                Colors.grey,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // PEDIDO
            // ==================================================

            const Text(
              "Pedido",
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.receipt_long_rounded,
                    color: orange,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Text(
                      "Pedido #${widget.pedidoId}",
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // ASSUNTO
            // ==================================================

            const Text(
              "Qual é o problema?",
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),

              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value:
                      assuntoSelecionado,

                  isExpanded: true,

                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                  ),

                  items:
                      assuntos.map(
                    (assunto) {
                      return DropdownMenuItem(
                        value: assunto,
                        child: Text(
                          assunto,
                        ),
                      );
                    },
                  ).toList(),

                  onChanged: (valor) {
                    if (valor == null) {
                      return;
                    }

                    setState(() {
                      assuntoSelecionado =
                          valor;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // DESCRIÇÃO
            // ==================================================

            const Text(
              "Conte o que aconteceu",
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            TextField(
              controller:
                  descricaoController,

              maxLines: 6,

              decoration:
                  InputDecoration(
                hintText:
                    "Explique o problema com o máximo de detalhes possível...",

                filled: true,

                fillColor:
                    Colors.white,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  borderSide:
                      BorderSide.none,
                ),

                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  borderSide:
                      const BorderSide(
                    color: orange,
                    width: 1.5,
                  ),
                ),

                contentPadding:
                    const EdgeInsets.all(
                  18,
                ),
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            // ==================================================
            // AVISO
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color:
                    orange.withOpacity(.08),
                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Icon(
                    Icons.info_outline_rounded,
                    color: orange,
                  ),

                  SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      "Seu chamado ficará vinculado a este pedido. O restaurante poderá acompanhar a ocorrência e responder pelo sistema.",
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // BOTÃO
            // ==================================================

            SizedBox(
              width:
                  double.infinity,

              height: 56,

              child: ElevatedButton.icon(
                onPressed:
                    enviando
                        ? null
                        : abrirChamado,

                icon: enviando
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                      ),

                label: Text(
                  enviando
                      ? "Enviando..."
                      : "Enviar solicitação",
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      orange,

                  foregroundColor:
                      Colors.white,

                  elevation: 0,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      17,
                    ),
                  ),

                  textStyle:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    descricaoController.dispose();
    super.dispose();
  }
}