import 'dart:convert';

import 'package:http/http.dart' as http;

class OrderService {
  static const String baseUrl =
      'http://192.168.1.101:3000/api';

  // ============================================================
  // BUSCAR PEDIDOS DO RESTAURANTE
  // ============================================================

  Future<List<dynamic>> buscarPedidosRestaurante(
    String restauranteId,
  ) async {
    if (restauranteId.trim().isEmpty) {
      throw Exception(
        'ID do restaurante não informado.',
      );
    }

    final url = Uri.parse(
      '$baseUrl/orders/restaurante/${Uri.encodeComponent(restauranteId)}',
    );

    print('==========================================');
    print('BUSCANDO PEDIDOS DO RESTAURANTE');
    print('URL: $url');
    print('RESTAURANTE: $restauranteId');
    print('==========================================');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      print('STATUS HTTP: ${response.statusCode}');
      print('RESPOSTA: ${response.body}');

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Erro HTTP ${response.statusCode}',
        );
      }

      if (response.body.trim().isEmpty) {
        return [];
      }

      final dados = jsonDecode(response.body);

      // API retornando diretamente:
      // [
      //   {...},
      //   {...}
      // ]

      if (dados is List) {
        return List<dynamic>.from(dados);
      }

      // API retornando:
      // {
      //   "pedidos": [...]
      // }

      if (dados is Map &&
          dados['pedidos'] is List) {
        return List<dynamic>.from(
          dados['pedidos'],
        );
      }

      // Alguns backends podem retornar:
      // {
      //   "data": [...]
      // }

      if (dados is Map &&
          dados['data'] is List) {
        return List<dynamic>.from(
          dados['data'],
        );
      }

      print(
        'Resposta da API não contém uma lista de pedidos.',
      );

      return [];
    } catch (e) {
      print('==========================================');
      print('ERRO AO BUSCAR PEDIDOS');
      print(e);
      print('==========================================');

      rethrow;
    }
  }

  // ============================================================
  // ATUALIZAR STATUS DO PEDIDO
  // ============================================================

  Future<bool> atualizarStatusPedido(
    String pedidoId,
    String status,
  ) async {
    if (pedidoId.trim().isEmpty) {
      throw Exception(
        'ID do pedido não informado.',
      );
    }

    if (status.trim().isEmpty) {
      throw Exception(
        'Status não informado.',
      );
    }

    final url = Uri.parse(
      '$baseUrl/orders/${Uri.encodeComponent(pedidoId)}/status',
    );

    print('==========================================');
    print('ATUALIZANDO PEDIDO');
    print('URL: $url');
    print('PEDIDO: $pedidoId');
    print('NOVO STATUS: $status');
    print('==========================================');

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type':
                  'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'status': status,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      print(
        'STATUS HTTP ATUALIZAÇÃO: ${response.statusCode}',
      );
      print(
        'RESPOSTA ATUALIZAÇÃO: ${response.body}',
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return true;
      }

      throw Exception(
        'Erro HTTP ${response.statusCode}: '
        '${response.body}',
      );
    } catch (e) {
      print(
        'ERRO AO ATUALIZAR PEDIDO: $e',
      );

      rethrow;
    }
  }
}