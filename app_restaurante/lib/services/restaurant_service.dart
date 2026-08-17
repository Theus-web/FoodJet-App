import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RestaurantService {
  static const String baseUrl =
      'http://192.168.1.101:3000/api';

  static const String _restaurantIdKey = 'restauranteId';
  static const String _restaurantKey = 'restaurante';

  // ============================================================
  // BUSCAR RESTAURANTE
  // ============================================================

  Future<Map<String, dynamic>> buscarRestaurante(
    String id,
  ) async {
    final restauranteId = id.trim();

    if (restauranteId.isEmpty) {
      throw Exception(
        'Restaurante não identificado.',
      );
    }

    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/restaurants/$restauranteId',
          ),
          headers: {
            'Content-Type': 'application/json',
          },
        )
        .timeout(
          const Duration(seconds: 10),
        );

    Map<String, dynamic> data = {};

    try {
      if (response.body.trim().isNotEmpty) {
        final decoded =
            jsonDecode(response.body);

        if (decoded is Map) {
          data =
              Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}

    if (response.statusCode == 200) {
      Map<String, dynamic> restaurante;

      if (data['restaurante'] is Map) {
        restaurante =
            Map<String, dynamic>.from(
          data['restaurante'],
        );
      } else {
        restaurante = data;
      }

      // Salva a versão mais recente localmente.
      await _salvarRestauranteLocal(
        restaurante,
      );

      return restaurante;
    }

    throw Exception(
      data['erro'] ??
          data['message'] ??
          'Erro ao buscar restaurante.',
    );
  }

  // ============================================================
  // ALTERAR STATUS
  //
  // ABERTO  = ONLINE
  // FECHADO = OFFLINE
  // ============================================================

  Future<Map<String, dynamic>> alterarStatus(
    String restauranteId,
    String status,
  ) async {
    final id = restauranteId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Restaurante não identificado.',
      );
    }

    final statusNormalizado =
        status.trim().toUpperCase();

    if (statusNormalizado != 'ABERTO' &&
        statusNormalizado != 'FECHADO') {
      throw Exception(
        'Status inválido.',
      );
    }

    // ==========================================================
    // SINCRONIZA STATUS E ONLINE
    // ==========================================================

    final bool online =
        statusNormalizado == 'ABERTO';

    print('');
    print(
      '==========================================',
    );
    print(
      '🔄 FOODJET - ALTERANDO STATUS',
    );
    print(
      '🏪 Restaurante: $id',
    );
    print(
      '📌 Status: $statusNormalizado',
    );
    print(
      '🟢 Online: $online',
    );
    print(
      '==========================================',
    );

    final response = await http
        .put(
          Uri.parse(
            '$baseUrl/restaurants/$id/status',
          ),
          headers: {
            'Content-Type':
                'application/json',
          },
          body: jsonEncode({
            'status':
                statusNormalizado,
            'online': online,
            'aberto': online,
          }),
        )
        .timeout(
          const Duration(seconds: 10),
        );

    Map<String, dynamic> data = {};

    try {
      if (response.body.trim().isNotEmpty) {
        final decoded =
            jsonDecode(response.body);

        if (decoded is Map) {
          data =
              Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}

    print(
      '📡 HTTP: ${response.statusCode}',
    );

    print(
      '📦 RESPOSTA: ${response.body}',
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> restaurante;

      if (data['restaurante'] is Map) {
        restaurante =
            Map<String, dynamic>.from(
          data['restaurante'],
        );
      } else {
        restaurante = {
          ...data,
          'id': id,
          'status':
              statusNormalizado,
          'online': online,
          'aberto': online,
        };
      }

      // Garante os valores mesmo se o backend
      // não devolver algum campo.
      restaurante['status'] =
          restaurante['status'] ??
              statusNormalizado;

      restaurante['online'] =
          restaurante['online'] ??
              online;

      restaurante['aberto'] =
          restaurante['aberto'] ??
              online;

      await _salvarRestauranteLocal(
        restaurante,
      );

      return restaurante;
    }

    throw Exception(
      data['erro'] ??
          data['message'] ??
          'Erro ao alterar status do restaurante.',
    );
  }

  // ============================================================
  // ATUALIZAR RESTAURANTE
  // ============================================================

  Future<bool> atualizarRestaurante(
    String restauranteId,
    Map<String, dynamic> dados,
  ) async {
    final id = restauranteId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Restaurante não identificado.',
      );
    }

    final response = await http
        .put(
          Uri.parse(
            '$baseUrl/restaurants/$id',
          ),
          headers: {
            'Content-Type':
                'application/json',
          },
          body: jsonEncode(dados),
        )
        .timeout(
          const Duration(seconds: 10),
        );

    Map<String, dynamic> data = {};

    try {
      if (response.body.trim().isNotEmpty) {
        final decoded =
            jsonDecode(response.body);

        if (decoded is Map) {
          data =
              Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}

    if (response.statusCode == 200) {
      if (data['restaurante'] is Map) {
        await _salvarRestauranteLocal(
          Map<String, dynamic>.from(
            data['restaurante'],
          ),
        );
      }

      return true;
    }

    throw Exception(
      data['erro'] ??
          data['message'] ??
          'Erro ao atualizar restaurante.',
    );
  }

  // ============================================================
  // OBTER ID DO RESTAURANTE
  // ============================================================

  Future<String?> obterRestauranteId() async {
    final prefs =
        await SharedPreferences.getInstance();

    final idSalvo =
        prefs.getString(_restaurantIdKey);

    if (idSalvo != null &&
        idSalvo.trim().isNotEmpty) {
      return idSalvo.trim();
    }

    final restauranteJson =
        prefs.getString(_restaurantKey);

    if (restauranteJson != null &&
        restauranteJson.trim().isNotEmpty) {
      try {
        final decoded =
            jsonDecode(restauranteJson);

        if (decoded is Map) {
          final restaurante =
              Map<String, dynamic>.from(decoded);

          final id =
              restaurante['id'] ??
                  restaurante['_id'] ??
                  restaurante['restauranteId'];

          if (id != null &&
              id.toString().trim().isNotEmpty) {
            final restauranteId =
                id.toString().trim();

            await prefs.setString(
              _restaurantIdKey,
              restauranteId,
            );

            return restauranteId;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  // ============================================================
  // SALVAR RESTAURANTE LOCALMENTE
  // ============================================================

  Future<void> _salvarRestauranteLocal(
    Map<String, dynamic> restaurante,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final id =
        restaurante['id'] ??
            restaurante['_id'] ??
            restaurante['restauranteId'];

    if (id != null &&
        id.toString().trim().isNotEmpty) {
      await prefs.setString(
        _restaurantIdKey,
        id.toString().trim(),
      );
    }

    await prefs.setString(
      _restaurantKey,
      jsonEncode(restaurante),
    );
  }

  // ============================================================
  // EXCLUIR CONTA
  // ============================================================

  Future<bool> excluirConta([
    String? restauranteId,
  ]) async {
    String? id = restauranteId?.trim();

    if (id == null || id.isEmpty) {
      id = await obterRestauranteId();
    }

    if (id == null || id.trim().isEmpty) {
      throw Exception(
        'Restaurante não identificado. Faça login novamente.',
      );
    }

    id = id.trim();

    print('');
    print(
      '==========================================',
    );
    print(
      '🗑️ FOODJET - EXCLUSÃO DE CONTA',
    );
    print(
      '🏪 Restaurante ID: $id',
    );
    print(
      '📡 DELETE /restaurants/$id',
    );
    print(
      '==========================================',
    );

    final response = await http.delete(
      Uri.parse(
        '$baseUrl/restaurants/$id',
      ),
      headers: {
        'Content-Type':
            'application/json',
      },
    );

    Map<String, dynamic> data = {};

    try {
      if (response.body.trim().isNotEmpty) {
        final decoded =
            jsonDecode(response.body);

        if (decoded is Map) {
          data =
              Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}

    print(
      '📡 Status HTTP: ${response.statusCode}',
    );

    print(
      '📡 Resposta: ${response.body}',
    );

    if (response.statusCode == 200 ||
        response.statusCode == 204) {
      await _limparSessaoLocal();
      return true;
    }

    if (response.statusCode == 404) {
      await _limparSessaoLocal();
      return true;
    }

    final mensagem =
        data['erro'] ??
            data['message'] ??
            'Não foi possível excluir a conta do restaurante.';

    throw Exception(
      mensagem.toString(),
    );
  }

  // ============================================================
  // LIMPAR SESSÃO LOCAL
  // ============================================================

  Future<void> _limparSessaoLocal() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _restaurantIdKey,
    );

    await prefs.remove(
      _restaurantKey,
    );

    await prefs.remove('token');
    await prefs.remove('usuario');
    await prefs.remove('user');
    await prefs.remove('access_token');
    await prefs.remove('auth_token');

    await prefs.remove('restaurantId');
    await prefs.remove('restaurant');

    await prefs.remove('usuarioLogado');
    await prefs.remove('userData');
    await prefs.remove('restauranteAtual');
  }
}