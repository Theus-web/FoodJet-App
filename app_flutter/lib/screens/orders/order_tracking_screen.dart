
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrderTrackingScreen extends StatefulWidget {
  final dynamic pedidoId;

  const OrderTrackingScreen({
    super.key,
    required this.pedidoId,
  });

  @override
  State<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const String baseUrl =
      'http://192.168.1.101:3000/api';

  static const Color primaryColor =
      Color(0xFFF97316);

  Map<String, dynamic>? pedido;

  bool carregando = true;
  bool erro = false;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    buscarPedido();

    timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => buscarPedido(silencioso: true),
    );
  }

  // ============================================================
  // BUSCAR PEDIDO
  // ============================================================

  Future<void> buscarPedido({
    bool silencioso = false,
  }) async {
    try {
      if (!silencioso && mounted) {
        setState(() {
          carregando = true;
          erro = false;
        });
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/orders/${widget.pedidoId}',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Pedido não encontrado');
      }

      final dados = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        pedido = Map<String, dynamic>.from(dados);
        carregando = false;
        erro = false;
      });
    } catch (e) {
      if (!mounted) return;

      if (!silencioso) {
        setState(() {
          carregando = false;
          erro = true;
        });
      }
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  String get status {
    return pedido?['status']?.toString().toUpperCase() ??
        'AGUARDANDO_RESTAURANTE';
  }

  String get tituloStatus {
    switch (status) {
      case 'AGUARDANDO_RESTAURANTE':
        return 'Pedido recebido';

      case 'ACEITO':
        return 'Pedido aceito';

      case 'PREPARANDO':
      case 'EM_PREPARO':
        return 'Preparando seu pedido';

      case 'PRONTO':
        return 'Pedido pronto';

      case 'EM_ENTREGA':
        return 'Pedido a caminho';

      case 'ENTREGUE':
        return 'Pedido entregue';

      case 'CANCELADO':
        return 'Pedido cancelado';

      default:
        return 'Acompanhando pedido';
    }
  }

  String get descricaoStatus {
    switch (status) {
      case 'AGUARDANDO_RESTAURANTE':
        return 'O restaurante recebeu seu pedido e irá analisá-lo.';

      case 'ACEITO':
        return 'O restaurante aceitou seu pedido.';

      case 'PREPARANDO':
      case 'EM_PREPARO':
        return 'Seu pedido está sendo preparado.';

      case 'PRONTO':
        return 'Seu pedido está pronto e aguardando o entregador.';

      case 'EM_ENTREGA':
        return 'O entregador está levando seu pedido até você.';

      case 'ENTREGUE':
        return 'Seu pedido foi entregue. Bom apetite!';

      case 'CANCELADO':
        return 'Este pedido foi cancelado.';

      default:
        return 'Estamos atualizando as informações do seu pedido.';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'AGUARDANDO_RESTAURANTE':
        return Icons.hourglass_top_rounded;

      case 'ACEITO':
        return Icons.check_circle_outline_rounded;

      case 'PREPARANDO':
      case 'EM_PREPARO':
        return Icons.restaurant_rounded;

      case 'PRONTO':
        return Icons.inventory_2_rounded;

      case 'EM_ENTREGA':
        return Icons.delivery_dining_rounded;

      case 'ENTREGUE':
        return Icons.check_circle_rounded;

      case 'CANCELADO':
        return Icons.cancel_rounded;

      default:
        return Icons.receipt_long_rounded;
    }
  }

  // ============================================================
  // ETAPAS
  // ============================================================

  bool etapaConcluida(String etapa) {
    const ordem = [
      'AGUARDANDO_RESTAURANTE',
      'ACEITO',
      'EM_PREPARO',
      'PRONTO',
      'EM_ENTREGA',
      'ENTREGUE',
    ];

    int atual = ordem.indexOf(status);

    if (status == 'PREPARANDO') {
      atual = ordem.indexOf('EM_PREPARO');
    }

    final indice = ordem.indexOf(etapa);

    if (indice == -1) return false;

    return atual >= indice;
  }

  // ============================================================
  // TOTAL
  // ============================================================

  double get total {
    return double.tryParse(
          pedido?['total']?.toString() ?? '0',
        ) ??
        0;
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // SUPORTE
  // ============================================================

  void abrirSuporte() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Precisa de ajuda?',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const Text(
                  'Se aconteceu algum problema com seu pedido, entre em contato e informe o que aconteceu.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                _suporteOpcao(
                  icon: Icons.report_problem_outlined,
                  titulo: 'Problema com o pedido',
                  descricao:
                      'Informar um problema com os produtos ou pedido.',
                  onTap: () {
                    Navigator.pop(context);
                    abrirFormularioSuporte(
                      'Problema com o pedido',
                    );
                  },
                ),

                _suporteOpcao(
                  icon: Icons.restaurant_outlined,
                  titulo: 'Problema com o restaurante',
                  descricao:
                      'Relatar um problema com o estabelecimento.',
                  onTap: () {
                    Navigator.pop(context);
                    abrirFormularioSuporte(
                      'Problema com o restaurante',
                    );
                  },
                ),

                _suporteOpcao(
                  icon: Icons.delivery_dining_outlined,
                  titulo: 'Problema com a entrega',
                  descricao:
                      'Relatar um problema com a entrega.',
                  onTap: () {
                    Navigator.pop(context);
                    abrirFormularioSuporte(
                      'Problema com a entrega',
                    );
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FORMULÁRIO DE SUPORTE
  // ============================================================

  void abrirFormularioSuporte(String tipo) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tipo,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Pedido #${widget.pedidoId}',
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                      'Descreva o que aconteceu...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Descreva o problema antes de enviar.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Solicitação enviada. O suporte analisará seu pedido.',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Enviar solicitação',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      backgroundColor: const Color(0xFFF6F6F6),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Acompanhar pedido',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Suporte',
            onPressed: abrirSuporte,
            icon: const Icon(
              Icons.support_agent_rounded,
            ),
          ),
        ],
      ),

      body: carregando
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : erro
              ? _telaErro()
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: buscarPedido,
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _cabecalhoStatus(),

                        const SizedBox(height: 16),

                        _progressoPedido(),

                        const SizedBox(height: 16),

                        _resumoPedido(),

                        const SizedBox(height: 16),

                        _informacaoEntrega(),

                        const SizedBox(height: 16),

                        _botaoSuporte(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ============================================================
  // CABEÇALHO STATUS
  // ============================================================

  Widget _cabecalhoStatus() {
    final cancelado = status == 'CANCELADO';
    final entregue = status == 'ENTREGUE';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cancelado
                  ? Colors.red.withOpacity(.1)
                  : primaryColor.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              size: 38,
              color: cancelado
                  ? Colors.red
                  : entregue
                      ? Colors.green
                      : primaryColor,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            tituloStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            descricaoStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: cancelado
                  ? Colors.red.withOpacity(.1)
                  : entregue
                      ? Colors.green.withOpacity(.1)
                      : primaryColor.withOpacity(.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              status.replaceAll('_', ' '),
              style: TextStyle(
                color: cancelado
                    ? Colors.red
                    : entregue
                        ? Colors.green
                        : primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESSO
  // ============================================================

  Widget _progressoPedido() {
    if (status == 'CANCELADO') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(.06),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Colors.red,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Entre em contato com o suporte caso precise de ajuda com este pedido.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Status do pedido',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 22),

          _etapa(
            'AGUARDANDO_RESTAURANTE',
            'Pedido recebido',
            Icons.receipt_long_rounded,
          ),

          _etapa(
            'ACEITO',
            'Pedido aceito',
            Icons.check_circle_outline_rounded,
          ),

          _etapa(
            'EM_PREPARO',
            'Em preparação',
            Icons.restaurant_rounded,
          ),

          _etapa(
            'PRONTO',
            'Pedido pronto',
            Icons.inventory_2_rounded,
          ),

          _etapa(
            'EM_ENTREGA',
            'Saiu para entrega',
            Icons.delivery_dining_rounded,
          ),

          _etapa(
            'ENTREGUE',
            'Entregue',
            Icons.check_circle_rounded,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ETAPA
  // ============================================================

  Widget _etapa(
    String etapa,
    String titulo,
    IconData icon, {
    bool isLast = false,
  }) {
    final concluida = etapaConcluida(etapa);

    final atual =
        status == etapa ||
        (status == 'PREPARANDO' &&
            etapa == 'EM_PREPARO');

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 250),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: concluida || atual
                    ? primaryColor
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                concluida
                    ? Icons.check
                    : icon,
                size: 21,
                color: concluida || atual
                    ? Colors.white
                    : Colors.grey.shade500,
              ),
            ),

            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: concluida
                    ? primaryColor
                    : Colors.grey.shade200,
              ),
          ],
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 9,
              bottom: 25,
            ),
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    atual || concluida
                        ? FontWeight.bold
                        : FontWeight.w500,
                color:
                    atual || concluida
                        ? Colors.black87
                        : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RESUMO
  // ============================================================

  Widget _resumoPedido() {
    final itens =
        pedido?['itens'] is List
            ? List.from(pedido!['itens'])
            : <dynamic>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do pedido',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          if (itens.isEmpty)
            const Text(
              'Nenhum item encontrado.',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),

          ...itens.map(
            (item) {
              final nome =
                  item['nome']?.toString() ??
                      'Produto';

              final quantidade =
                  int.tryParse(
                        item['quantidade']
                                ?.toString() ??
                            '1',
                      ) ??
                      1;

              final preco =
                  double.tryParse(
                        item['preco']
                                ?.toString() ??
                            '0',
                      ) ??
                      0;

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment:
                          Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            primaryColor.withOpacity(.1),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$quantidade',
                        style:
                            const TextStyle(
                          color: primaryColor,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        nome,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),

                    Text(
                      dinheiro(
                        preco * quantidade,
                      ),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 24),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                dinheiro(total),
                style: const TextStyle(
                  fontSize: 19,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ENTREGA
  // ============================================================

  Widget _informacaoEntrega() {
    final endereco = pedido?['endereco'];

    String enderecoTexto;

    if (endereco is Map) {
      final rua =
          endereco['rua']?.toString() ?? '';

      final numero =
          endereco['numero']?.toString() ?? '';

      final bairro =
          endereco['bairro']?.toString() ?? '';

      enderecoTexto =
          '$rua, $numero'
          '${bairro.isNotEmpty ? ' • $bairro' : ''}';
    } else {
      enderecoTexto =
          endereco?.toString() ??
              'Endereço não informado';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Entrega',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      primaryColor.withOpacity(.1),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: primaryColor,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Endereço de entrega',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enderecoTexto,
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTÃO SUPORTE
  // ============================================================

  Widget _botaoSuporte() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton.icon(
        onPressed: abrirSuporte,
        icon: const Icon(
          Icons.support_agent_rounded,
        ),
        label: const Text(
          'Preciso de ajuda com este pedido',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(
            color: primaryColor,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OPÇÃO SUPORTE
  // ============================================================

  Widget _suporteOpcao({
    required IconData icon,
    required String titulo,
    required String descricao,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    primaryColor.withOpacity(.1),
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: primaryColor,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descricao,
                    style:
                        const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _telaErro() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color:
                    Colors.red.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Colors.red,
                size: 40,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Não foi possível carregar o pedido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Verifique sua conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 22),

            ElevatedButton.icon(
              onPressed: buscarPedido,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Tentar novamente',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryColor,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
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
    timer?.cancel();

    super.dispose();
  }
}

