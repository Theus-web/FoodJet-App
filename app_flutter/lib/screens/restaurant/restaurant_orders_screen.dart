import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RestaurantOrdersScreen extends StatefulWidget {
const RestaurantOrdersScreen({
super.key,
});

@override
State<RestaurantOrdersScreen> createState() =>
_RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState
extends State<RestaurantOrdersScreen> {
Timer? timer;

bool carregando = true;

List pedidos = [];

// ID da Pizzaria do João
final int restauranteId = 1784400784535;

final String apiUrl =
'http://192.168.1.101:3000';

@override
void initState() {
super.initState();


buscarPedidos();

// Atualiza os pedidos automaticamente
timer = Timer.periodic(
  const Duration(seconds: 5),
  (_) {
    buscarPedidos();
  },
);


}

@override
void dispose() {
timer?.cancel();
super.dispose();
}

// =========================================================
// BUSCAR PEDIDOS DO RESTAURANTE
// =========================================================

Future<void> buscarPedidos() async {
try {
final resposta = await http.get(
Uri.parse(
'$apiUrl/api/orders/restaurante/$restauranteId',
),
);


  if (resposta.statusCode != 200) {
    return;
  }

  final dados = jsonDecode(resposta.body);

  if (!mounted) {
    return;
  }

  setState(() {
    pedidos = dados;
    carregando = false;
  });
} catch (erro) {
  print(
    'ERRO AO BUSCAR PEDIDOS: $erro',
  );

  if (!mounted) {
    return;
  }

  setState(() {
    carregando = false;
  });
}


}

// =========================================================
// ATUALIZAR STATUS DO PEDIDO
// =========================================================

Future<void> atualizarStatus(
int pedidoId,
String novoStatus,
) async {
try {
final resposta = await http.put(
Uri.parse(
'$apiUrl/api/orders/$pedidoId/status',
),
headers: {
'Content-Type': 'application/json',
},
body: jsonEncode({
'status': novoStatus,
}),
);


  print(
    'STATUS ATUALIZADO: ${resposta.statusCode}',
  );

  print(
    'RESPOSTA: ${resposta.body}',
  );

  if (!mounted) {
    return;
  }

  if (resposta.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pedido atualizado para $novoStatus',
        ),
        backgroundColor:
            const Color(0xFFF97316),
      ),
    );

    await buscarPedidos();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Erro ao atualizar pedido: ${resposta.body}',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
} catch (erro) {
  print(
    'ERRO AO ATUALIZAR STATUS: $erro',
  );

  if (!mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Erro de conexão: $erro',
      ),
      backgroundColor: Colors.red,
    ),
  );
}


}

// =========================================================
// TÍTULO DO STATUS
// =========================================================

String nomeStatus(String status) {
switch (status) {
case 'AGUARDANDO':
case 'AGUARDANDO_RESTAURANTE':
return 'Aguardando confirmação';


  case 'ACEITO':
    return 'Pedido aceito';

  case 'PREPARANDO':
    return 'Preparando pedido';

  case 'PRONTO':
    return 'Pedido pronto';

  case 'EM_ENTREGA':
    return 'Em entrega';

  case 'ENTREGUE':
    return 'Entregue';

  default:
    return status;
}


}

// =========================================================
// COR DO STATUS
// =========================================================

Color corStatus(String status) {
switch (status) {
case 'AGUARDANDO':
case 'AGUARDANDO_RESTAURANTE':
return Colors.orange;


  case 'ACEITO':
    return Colors.blue;

  case 'PREPARANDO':
    return Colors.deepOrange;

  case 'PRONTO':
    return Colors.green;

  case 'EM_ENTREGA':
    return Colors.purple;

  case 'ENTREGUE':
    return Colors.grey;

  default:
    return Colors.grey;
}


}

// =========================================================
// BOTÃO DE AÇÃO
// =========================================================

Widget botaoAcao(
Map pedido,
) {
final int pedidoId =
int.parse(
pedido['id'].toString(),
);


final String status =
    pedido['status'] ?? '';

if (status == 'AGUARDANDO_RESTAURANTE' ||
    status == 'AGUARDANDO') {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {
        atualizarStatus(
          pedidoId,
          'ACEITO',
        );
      },
      icon: const Icon(
        Icons.check,
      ),
      label: const Text(
        'ACEITAR PEDIDO',
      ),
      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            const Color(0xFFF97316),
        foregroundColor:
            Colors.white,
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),
      ),
    ),
  );
}

if (status == 'ACEITO') {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {
        atualizarStatus(
          pedidoId,
          'PREPARANDO',
        );
      },
      icon: const Icon(
        Icons.restaurant,
      ),
      label: const Text(
        'INICIAR PREPARO',
      ),
      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            Colors.blue,
        foregroundColor:
            Colors.white,
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),
      ),
    ),
  );
}

if (status == 'PREPARANDO') {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {
        atualizarStatus(
          pedidoId,
          'PRONTO',
        );
      },
      icon: const Icon(
        Icons.check_circle,
      ),
      label: const Text(
        'PEDIDO PRONTO',
      ),
      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            Colors.green,
        foregroundColor:
            Colors.white,
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),
      ),
    ),
  );
}

if (status == 'PRONTO') {
  return Container(
    width: double.infinity,
    padding:
        const EdgeInsets.all(14),
    decoration:
        BoxDecoration(
      color:
          Colors.green.withValues(
        alpha: 0.1,
      ),
      borderRadius:
          BorderRadius.circular(10),
    ),
    child: const Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(
          Icons.delivery_dining,
          color:
              Colors.green,
        ),
        SizedBox(
          width: 8,
        ),
        Text(
          'Aguardando entregador',
          style:
              TextStyle(
            color:
                Colors.green,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

return const SizedBox();


}

// =========================================================
// CARD DO PEDIDO
// =========================================================

Widget cardPedido(
Map pedido,
) {
final int pedidoId =
int.parse(
pedido['id'].toString(),
);


final String status =
    pedido['status'] ?? '';

final List itens =
    pedido['itens'] ?? [];

final double total =
    double.tryParse(
          pedido['total']
              .toString(),
        ) ??
        0;

return Card(
  color: Colors.white,
  margin:
      const EdgeInsets.only(
    bottom: 16,
  ),
  elevation: 3,
  shape:
      RoundedRectangleBorder(
    borderRadius:
        BorderRadius.circular(
      16,
    ),
  ),
  child: Padding(
    padding:
        const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // CABEÇALHO
        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
          children: [
            Text(
              'Pedido #$pedidoId',
              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration:
                  BoxDecoration(
                color:
                    corStatus(status)
                        .withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                nomeStatus(status),
                style:
                    TextStyle(
                  color:
                      corStatus(
                    status,
                  ),
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),

        const Divider(
          height: 25,
        ),

        // ITENS
        const Text(
          'Itens do pedido',
          style:
              TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        ...itens.map(
          (item) {
            final nome =
                item['nome'] ??
                    'Produto';

            final quantidade =
                item['quantidade'] ??
                    1;

            final preco =
                double.tryParse(
                      item['preco']
                          .toString(),
                    ) ??
                    0;

            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 8,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${quantidade}x $nome',
                    ),
                  ),
                  Text(
                    'R\$ ${(preco * quantidade).toStringAsFixed(2).replaceAll('.', ',')}',
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

        const Divider(
          height: 25,
        ),

        // TOTAL
        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
          children: [
            const Text(
              'Total',
              style:
                  TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Text(
              'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
              style:
                  const TextStyle(
                fontSize: 18,
                color:
                    Color(0xFFF97316),
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 15,
        ),

        // PAGAMENTO
        Row(
          children: [
            const Icon(
              Icons.payment,
              size: 20,
              color:
                  Colors.grey,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              'Pagamento: ${pedido['pagamento'] ?? 'Não informado'}',
              style:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 18,
        ),

        // BOTÃO
        botaoAcao(
          pedido,
        ),
      ],
    ),
  ),
);


}

// =========================================================
// TELA
// =========================================================

@override
Widget build(
BuildContext context,
) {
const laranja =
Color(0xFFF97316);


return Scaffold(
  backgroundColor:
      const Color(0xFFF5F5F5),

  appBar: AppBar(
    backgroundColor:
        laranja,
    foregroundColor:
        Colors.white,
    title: const Text(
      'Pedidos do Restaurante',
      style:
          TextStyle(
        fontWeight:
            FontWeight.bold,
      ),
    ),
    actions: [
      IconButton(
        onPressed:
            buscarPedidos,
        icon:
            const Icon(
          Icons.refresh,
        ),
      ),
    ],
  ),

  body: carregando
      ? const Center(
          child:
              CircularProgressIndicator(),
        )
      : RefreshIndicator(
          onRefresh:
              buscarPedidos,
          child:
              pedidos.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(
                          height: 250,
                        ),
                        Center(
                          child: Text(
                            'Nenhum pedido encontrado',
                            style:
                                TextStyle(
                              fontSize:
                                  18,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      itemCount:
                          pedidos.length,
                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        return cardPedido(
                          pedidos[index],
                        );
                      },
                    ),
        ),
);


}
}
