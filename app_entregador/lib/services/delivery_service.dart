
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../models/entregador.dart';
import 'auth_service.dart';

class DeliveryService {
  static Future<Entregador> buscarEntregador() async {
    final usuario = await AuthService.getUsuario();

    if (usuario == null) {
      throw Exception('Usuário não encontrado.');
    }

    final id = usuario['id']?.toString();

    if (id == null || id.isEmpty) {
      throw Exception('ID do entregador não encontrado.');
    }

    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${Api.entregadores}/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Entregador.fromJson(
        jsonDecode(response.body),
      );
    }

    final perfil = await AuthService.perfil();

    final dados =
        perfil['entregador'] ??
        perfil['usuario'] ??
        perfil;

    if (dados is Map<String, dynamic>) {
      return Entregador.fromJson({
        ...dados,
        'id': dados['id'] ?? id,
      });
    }

    throw Exception(
      'Não foi possível carregar o entregador.',
    );
  }

  static Future<Entregador> alterarStatus({
    required dynamic id,
    required bool online,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.put(
      Uri.parse(
        Api.statusEntregador(id.toString()),
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'online': online,
      }),
    );

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data['mensagem']?.toString() ??
            data['erro']?.toString() ??
            'Não foi possível alterar o status.',
      );
    }

    final entregador = data['entregador'];

    if (entregador is Map<String, dynamic>) {
      return Entregador.fromJson(entregador);
    }

    return buscarEntregador();
  }

  static Future<List<Map<String, dynamic>>> meusPedidos() async {
    final usuario = await AuthService.getUsuario();

    if (usuario == null) {
      return [];
    }

    final id = usuario['id']?.toString();

    if (id == null || id.isEmpty) {
      return [];
    }

    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse(
        Api.pedidosEntregador(id),
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      return [];
    }

    try {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) =>
                  Map<String, dynamic>.from(item),
            )
            .toList();
      }

      if (data is Map<String, dynamic>) {
        final pedidos =
            data['pedidos'] ??
            data['orders'] ??
            data['data'];

        if (pedidos is List) {
          return pedidos
              .whereType<Map>()
              .map(
                (item) =>
                    Map<String, dynamic>.from(item),
              )
              .toList();
        }
      }
    } catch (_) {}

    return [];
  }

  static Future<void> aceitarEntrega({
    required dynamic entregadorId,
    required dynamic pedidoId,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.put(
      Uri.parse(
        '${Api.baseUrl}/delivery/'
        '$entregadorId/orders/$pedidoId/accept',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String mensagem =
          'Não foi possível aceitar a entrega.';

      try {
        final data = jsonDecode(response.body);

        if (data is Map) {
          mensagem =
              data['erro']?.toString() ??
              data['mensagem']?.toString() ??
              data['message']?.toString() ??
              mensagem;
        }
      } catch (_) {}

      throw Exception(mensagem);
    }
  }

  /// Atualiza o andamento da entrega.
  ///
  /// CHEGUEI_RESTAURANTE:
  /// PUT /delivery/orders/:pedidoId/arrived
  ///
  /// EM_ENTREGA:
  /// PUT /delivery/orders/:pedidoId/start
  ///
  /// ENTREGUE / FINALIZADO:
  /// PUT /delivery/orders/:pedidoId/finish
  static Future<void> updateStatus(
    dynamic pedidoId,
    String status,
  ) async {
    if (pedidoId == null ||
        pedidoId.toString().trim().isEmpty) {
      throw Exception(
        'ID do pedido não informado.',
      );
    }

    final token = await AuthService.getToken();

    String endpoint;

    switch (status.toUpperCase()) {
      case 'CHEGUEI_RESTAURANTE':
        endpoint =
            '${Api.baseUrl}/delivery/orders/'
            '${pedidoId.toString()}/arrived';
        break;

      case 'EM_ENTREGA':
        endpoint =
            '${Api.baseUrl}/delivery/orders/'
            '${pedidoId.toString()}/start';
        break;

      case 'ENTREGUE':
      case 'FINALIZADO':
        endpoint =
            '${Api.baseUrl}/delivery/orders/'
            '${pedidoId.toString()}/finish';
        break;

      default:
        throw Exception(
          'Status de entrega inválido: $status',
        );
    }

    final response = await http.put(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    String mensagem =
        'Não foi possível atualizar a entrega.';

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        mensagem =
            decoded['erro']?.toString() ??
            decoded['mensagem']?.toString() ??
            decoded['message']?.toString() ??
            decoded['detalhe']?.toString() ??
            mensagem;
      }
    } catch (_) {}

    throw Exception(
      '$mensagem (HTTP ${response.statusCode})',
    );
  }
}

