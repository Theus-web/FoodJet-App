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
      throw Exception('Restaurante não identificado.');
    }

    final response = await http.get(
      Uri.parse(
        '$baseUrl/restaurants/$restauranteId',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    if (response.statusCode == 200) {
      if (data['restaurante'] is Map) {
        return Map<String, dynamic>.from(
          data['restaurante'],
        );
      }

      return data;
    }

    throw Exception(
      data['erro'] ??
          data['message'] ??
          'Erro ao buscar restaurante.',
    );
  }

  // ============================================================
  // ALTERAR STATUS
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

    final response = await http.put(
      Uri.parse(
        '$baseUrl/restaurants/$id/status',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    if (response.statusCode == 200) {
      if (data['restaurante'] is Map) {
        return Map<String, dynamic>.from(
          data['restaurante'],
        );
      }

      return data;
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

    final response = await http.put(
      Uri.parse(
        '$baseUrl/restaurants/$id',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(dados),
    );

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    if (response.statusCode == 200) {
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

    // ----------------------------------------------------------
    // 1. ID SALVO DIRETAMENTE
    // ----------------------------------------------------------

    final idSalvo =
        prefs.getString(_restaurantIdKey);

    if (idSalvo != null &&
        idSalvo.trim().isNotEmpty) {
      return idSalvo.trim();
    }

    // ----------------------------------------------------------
    // 2. OBJETO RESTAURANTE SALVO
    // ----------------------------------------------------------

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
  // EXCLUIR CONTA
  // ============================================================

  Future<bool> excluirConta([
    String? restauranteId,
  ]) async {
    String? id = restauranteId?.trim();

    // ----------------------------------------------------------
    // 1. TENTAR ID RECEBIDO
    // ----------------------------------------------------------

    if (id == null || id.isEmpty) {
      id = await obterRestauranteId();
    }

    // ----------------------------------------------------------
    // 2. VALIDAR ID
    // ----------------------------------------------------------

    if (id == null || id.trim().isEmpty) {
      throw Exception(
        'Restaurante não identificado. Faça login novamente.',
      );
    }

    id = id.trim();

    print('');
    print('==========================================');
    print('🗑️ FOODJET - EXCLUSÃO DE CONTA');
    print('==========================================');
    print('🏪 Restaurante ID: $id');
    print('📡 DELETE /restaurants/$id');
    print('==========================================');

    // ----------------------------------------------------------
    // 3. CHAMAR BACKEND
    // ----------------------------------------------------------

    final response = await http.delete(
      Uri.parse(
        '$baseUrl/restaurants/$id',
      ),
      headers: {
        'Content-Type': 'application/json',
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

    // ----------------------------------------------------------
    // 4. SUCESSO
    // ----------------------------------------------------------

    if (response.statusCode == 200 ||
        response.statusCode == 204) {
      print(
        '✅ Servidor confirmou exclusão.',
      );

      await _limparSessaoLocal();

      print(
        '✅ Sessão local removida.',
      );

      return true;
    }

    // ----------------------------------------------------------
    // 5. CONTA JÁ NÃO EXISTE
    // ----------------------------------------------------------

    if (response.statusCode == 404) {
      print(
        '⚠️ Restaurante já não existe no servidor.',
      );

      await _limparSessaoLocal();

      return true;
    }

    // ----------------------------------------------------------
    // 6. ERRO
    // ----------------------------------------------------------

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

    print(
      '🧹 Limpando sessão local...',
    );

    // Restaurante
    await prefs.remove(
      _restaurantIdKey,
    );

    await prefs.remove(
      _restaurantKey,
    );

    // Autenticação
    await prefs.remove('token');
    await prefs.remove('usuario');

    // Possíveis nomes antigos
    await prefs.remove('user');
    await prefs.remove('access_token');
    await prefs.remove('auth_token');

    await prefs.remove('restaurantId');
    await prefs.remove('restaurant');

    // Outros dados
    await prefs.remove('usuarioLogado');
    await prefs.remove('userData');
    await prefs.remove('restauranteAtual');

    print(
      '✅ Sessão local limpa.',
    );
  }
}