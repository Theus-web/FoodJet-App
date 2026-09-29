import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../models/entregador.dart';
import 'auth_service.dart';

class DeliveryService {
  // ==========================================================
  // HEADERS
  // ==========================================================

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ==========================================================
  // BUSCAR DADOS DO ENTREGADOR
  // ==========================================================

  static Future<Entregador> buscarEntregador() async {
    final usuario = await AuthService.getUsuario();

    if (usuario == null) {
      throw Exception('Usuário não encontrado.');
    }

    final id = usuario['id']?.toString();

    if (id == null || id.isEmpty) {
      throw Exception('ID do entregador não encontrado.');
    }

    final headers = await _headers();

    try {
      final response = await http.get(
        Uri.parse('${Api.entregadores}/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final dados =
              decoded['entregador'] ??
              decoded['usuario'] ??
              decoded['data'] ??
              decoded;

          if (dados is Map) {
            return Entregador.fromJson({
              ...Map<String, dynamic>.from(dados),
              'id': dados['id'] ?? id,
            });
          }
        }
      }
    } catch (_) {
      // Continua para o fallback abaixo.
    }

    // ========================================================
    // FALLBACK
    // ========================================================

    try {
      final perfil = await AuthService.perfil();

      final dados =
          perfil['entregador'] ??
          perfil['usuario'] ??
          perfil['data'] ??
          perfil;

      if (dados is Map) {
        return Entregador.fromJson({
          ...Map<String, dynamic>.from(dados),
          'id': dados['id'] ?? id,
        });
      }
    } catch (_) {
      // Continua para a mensagem final.
    }

    throw Exception(
      'Não foi possível carregar os dados do entregador.',
    );
  }

  // ==========================================================
  // ALTERAR STATUS ONLINE/OFFLINE
  // ==========================================================

  static Future<Entregador> alterarStatus({
    required dynamic id,
    required bool online,
  }) async {
    if (id == null || id.toString().trim().isEmpty) {
      throw Exception('ID do entregador não informado.');
    }

    final headers = await _headers();

    final response = await http.put(
      Uri.parse(
        Api.statusEntregador(id.toString()),
      ),
      headers: headers,
      body: jsonEncode({
        'online': online,
      }),
    );

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    // ========================================================
    // ERRO
    // ========================================================

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data['mensagem']?.toString() ??
            data['erro']?.toString() ??
            data['message']?.toString() ??
            'Não foi possível alterar o status.',
      );
    }

    // ========================================================
    // ENTREGADOR RETORNADO PELO BACKEND
    // ========================================================

    final entregador = data['entregador'];

    if (entregador is Map) {
      return Entregador.fromJson(
        Map<String, dynamic>.from(entregador),
      );
    }

    // ========================================================
    // SE O BACKEND NÃO RETORNAR O ENTREGADOR
    // ========================================================

    return buscarEntregador();
  }

  // ==========================================================
  // BUSCAR PEDIDOS DISPONÍVEIS
  // ==========================================================

  static Future<List<Map<String, dynamic>>>
      buscarPedidosDisponiveis() async {
    final headers = await _headers();

    try {
      final response = await http.get(
        Uri.parse(
          '${Api.baseUrl}/delivery/available/orders',
        ),
        headers: headers,
      );

      if (response.statusCode != 200) {
        return [];
      }

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

      if (data is Map) {
        final pedidos =
            data['pedidos'] ??
            data['orders'] ??
            data['data'] ??
            data['result'];

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

  // ==========================================================
  // PEDIDOS DO ENTREGADOR
  // ==========================================================

  static Future<List<Map<String, dynamic>>>
      meusPedidos() async {
    final usuario = await AuthService.getUsuario();

    if (usuario == null) {
      return [];
    }

    final id = usuario['id']?.toString();

    if (id == null || id.isEmpty) {
      return [];
    }

    final headers = await _headers();

    try {
      final response = await http.get(
        Uri.parse(
          Api.pedidosEntregador(id),
        ),
        headers: headers,
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);

      // Backend retornando diretamente uma lista
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) =>
                  Map<String, dynamic>.from(item),
            )
            .toList();
      }

      // Backend retornando objeto
      if (data is Map) {
        final pedidos =
            data['pedidos'] ??
            data['orders'] ??
            data['data'] ??
            data['result'];

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

  // ==========================================================
  // ACEITAR ENTREGA
  // ==========================================================

  static Future<void> aceitarEntrega({
    required dynamic entregadorId,
    required dynamic pedidoId,
  }) async {
    if (entregadorId == null ||
        entregadorId.toString().trim().isEmpty) {
      throw Exception(
        'ID do entregador não informado.',
      );
    }

    if (pedidoId == null ||
        pedidoId.toString().trim().isEmpty) {
      throw Exception(
        'ID do pedido não informado.',
      );
    }

    final headers = await _headers();

    final response = await http.put(
      Uri.parse(
        '${Api.baseUrl}/delivery/'
        '$entregadorId/orders/'
        '$pedidoId/accept',
      ),
      headers: headers,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

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

    throw Exception(
      '$mensagem (HTTP ${response.statusCode})',
    );
  }

  // ==========================================================
  // ATUALIZAR STATUS DA ENTREGA
  // ==========================================================

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

    final statusNormalizado =
        status.trim().toUpperCase();

    final headers = await _headers();

    String endpoint;

    switch (statusNormalizado) {
      // ======================================================
      // CHEGUEI NO RESTAURANTE
      // ======================================================

      case 'CHEGUEI_RESTAURANTE':
      case 'CHEGUEI':
        endpoint =
            '${Api.baseUrl}/delivery/orders/'
            '$pedidoId/arrived';
        break;

      // ======================================================
      // INICIAR ENTREGA
      // ======================================================

      case 'EM_ENTREGA':
      case 'SAIU_RESTAURANTE':
      case 'INICIAR_ENTREGA':
        endpoint =
            '${Api.baseUrl}/delivery/orders/'
            '$pedidoId/start';
        break;

      // ======================================================
      // FINALIZAR ENTREGA
      // ======================================================

      case 'ENTREGUE':
      case 'FINALIZADO':
      case 'FINALIZADA':
        endpoint =
            '${Api.baseUrl}/delivery/orders/'
            '$pedidoId/finish';
        break;

      default:
        throw Exception(
          'Status inválido: $status',
        );
    }

    final response = await http.put(
      Uri.parse(endpoint),
      headers: headers,
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
            mensagem;
      }
    } catch (_) {}

    throw Exception(
      '$mensagem (HTTP ${response.statusCode})',
    );
  }
}