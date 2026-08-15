import 'dart:convert';

import 'package:http/http.dart' as http;

class OrderService {
  final String baseUrl =
      'http://192.168.1.101:3000/api';

  // ============================================================
  // BUSCAR PEDIDOS DO RESTAURANTE
  // ============================================================

  Future<List> buscarPedidosRestaurante(
    String restauranteId,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/orders/restaurante/$restauranteId',
      );

      print('==========================================');
      print('BUSCANDO PEDIDOS');
      print('URL: $url');
      print('RESTAURANTE: $restauranteId');
      print('==========================================');

      final response = await http.get(url);

      print('STATUS: ${response.statusCode}');
      print('RESPOSTA: ${response.body}');

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);

        if (dados is List) {
          return dados;
        }

        if (dados is Map && dados['pedidos'] is List) {
          return List.from(dados['pedidos']);
        }

        print('Resposta da API não é uma lista de pedidos.');
        return [];
      }

      print(
        'Erro HTTP ao buscar pedidos: '
        '${response.statusCode}',
      );

      return [];
    } catch (e) {
      print('==========================================');
      print('ERRO AO BUSCAR PEDIDOS');
      print(e);
      print('==========================================');

      return [];
    }
  }

  // ============================================================
  // ATUALIZAR STATUS
  // ============================================================

  Future<bool> atualizarStatusPedido(
    String pedidoId,
    String status,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/orders/$pedidoId/status',
      );

      print('ATUALIZANDO PEDIDO');
      print('URL: $url');
      print('STATUS: $status');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      print('STATUS HTTP: ${response.statusCode}');
      print('RESPOSTA: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('ERRO AO ATUALIZAR PEDIDO: $e');
      return false;
    }
  }
}