import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api.dart';

class FavoriteService {
  // ============================================================
  // TOKEN
  // ============================================================

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null || token.trim().isEmpty) {
      debugPrint('⚠️ FOODJET FAVORITOS: TOKEN NÃO ENCONTRADO');
      return null;
    }

    return token.trim();
  }

  // ============================================================
  // LISTAR FAVORITOS
  // ============================================================

  static Future<List<Map<String, dynamic>>> listar() async {
    final token = await _token();

    if (token == null) {
      return [];
    }

    final url = '${Api.baseUrl}/favoritos';

    debugPrint('========================================');
    debugPrint('FOODJET FAVORITOS - GET');
    debugPrint('URL: $url');
    debugPrint('========================================');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'FAVORITOS GET STATUS: ${response.statusCode}',
      );

      debugPrint(
        'FAVORITOS GET RESPOSTA: ${response.body}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return [];
      }

      if (response.body.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(response.body);

      // --------------------------------------------------------
      // Backend pode retornar diretamente uma lista
      // --------------------------------------------------------

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      }

      // --------------------------------------------------------
      // Backend pode retornar:
      //
      // {
      //   "favoritos": [...]
      // }
      // --------------------------------------------------------

      if (decoded is Map) {
        final dados = Map<String, dynamic>.from(decoded);

        final possiveisListas = [
          dados['favoritos'],
          dados['favorites'],
          dados['data'],
          dados['dados'],
        ];

        for (final valor in possiveisListas) {
          if (valor is List) {
            return valor
                .whereType<Map>()
                .map(
                  (item) =>
                      Map<String, dynamic>.from(item),
                )
                .toList();
          }
        }
      }

      return [];
    } catch (e) {
      debugPrint(
        '❌ ERRO AO LISTAR FAVORITOS: $e',
      );

      return [];
    }
  }

  // ============================================================
  // VERIFICAR SE É FAVORITO
  // ============================================================

  static Future<bool> estaFavorito(
    String restauranteId,
  ) async {
    final id = restauranteId.trim();

    if (id.isEmpty) {
      return false;
    }

    try {
      final lista = await listar();

      debugPrint('========================================');
      debugPrint('VERIFICANDO FAVORITO');
      debugPrint('ID PROCURADO: $id');
      debugPrint('TOTAL FAVORITOS: ${lista.length}');
      debugPrint('========================================');

      for (final favorito in lista) {
        final idFavorito =
            favorito['restauranteId'] ??
            favorito['restaurantId'] ??
            favorito['restaurante_id'] ??
            favorito['restaurant_id'] ??
            favorito['id'] ??
            favorito['_id'];

        if (idFavorito == null) {
          continue;
        }

        final idNormalizado =
            idFavorito.toString().trim();

        debugPrint(
          'FAVORITO NO BANCO: $idNormalizado',
        );

        if (idNormalizado == id) {
          debugPrint(
            '❤️ RESTAURANTE É FAVORITO',
          );

          return true;
        }
      }

      debugPrint(
        '🤍 RESTAURANTE NÃO É FAVORITO',
      );

      return false;
    } catch (e) {
      debugPrint(
        '❌ ERRO AO VERIFICAR FAVORITO: $e',
      );

      return false;
    }
  }

  // ============================================================
  // ALTERNAR FAVORITO
  // ============================================================

  static Future<bool> alternar(
    Map<String, dynamic> restaurante,
  ) async {
    final token = await _token();

    if (token == null) {
      throw Exception(
        'Usuário não está autenticado.',
      );
    }

    final idBruto =
        restaurante['restauranteId'] ??
        restaurante['restaurantId'] ??
        restaurante['id'] ??
        restaurante['_id'];

    if (idBruto == null ||
        idBruto.toString().trim().isEmpty) {
      throw Exception(
        'ID do restaurante não informado.',
      );
    }

    final id = idBruto.toString().trim();

    debugPrint('========================================');
    debugPrint('FOODJET - ALTERNAR FAVORITO');
    debugPrint('RESTAURANTE ID: $id');
    debugPrint('NOME: ${restaurante['nome']}');
    debugPrint('========================================');

    final jaFavorito =
        await estaFavorito(id);

    debugPrint(
      'JÁ É FAVORITO: $jaFavorito',
    );

    // ==========================================================
    // REMOVER
    // ==========================================================

    if (jaFavorito) {
      final removido =
          await remover(id);

      if (!removido) {
        throw Exception(
          'Não foi possível remover o favorito.',
        );
      }

      return false;
    }

    // ==========================================================
    // ADICIONAR
    // ==========================================================

    final url =
        '${Api.baseUrl}/favoritos';

    final dadosEnviar =
        Map<String, dynamic>.from(
      restaurante,
    );

    // Garantir que o backend receba o ID principal
    dadosEnviar['id'] = id;
    dadosEnviar['restauranteId'] = id;

    debugPrint('========================================');
    debugPrint('FOODJET FAVORITO - POST');
    debugPrint('URL: $url');
    debugPrint(
      'DADOS: ${jsonEncode(dadosEnviar)}',
    );
    debugPrint('========================================');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(dadosEnviar),
      );

      debugPrint(
        'FAVORITO POST STATUS: ${response.statusCode}',
      );

      debugPrint(
        'FAVORITO POST RESPOSTA: ${response.body}',
      );

      // ========================================================
      // IMPORTANTE:
      //
      // Aceita 200, 201 e qualquer outro 2xx.
      // ========================================================

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        debugPrint(
          '❤️ FAVORITO SALVO COM SUCESSO',
        );

        return true;
      }

      // ========================================================
      // ERRO DO BACKEND
      // ========================================================

      String mensagem =
          'Erro ao salvar favorito.';

      if (response.body.trim().isNotEmpty) {
        try {
          final decoded =
              jsonDecode(response.body);

          if (decoded is Map) {
            mensagem =
                decoded['erro']?.toString() ??
                decoded['mensagem']?.toString() ??
                decoded['message']?.toString() ??
                mensagem;
          }
        } catch (_) {}
      }

      throw Exception(mensagem);
    } catch (e) {
      debugPrint(
        '❌ ERRO AO SALVAR FAVORITO NO BACKEND: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // REMOVER FAVORITO
  // ============================================================

  static Future<bool> remover(
    String restauranteId,
  ) async {
    final token = await _token();

    if (token == null) {
      throw Exception(
        'Usuário não está autenticado.',
      );
    }

    final id = restauranteId.trim();

    if (id.isEmpty) {
      throw Exception(
        'ID do restaurante não informado.',
      );
    }

    final url =
        '${Api.baseUrl}/favoritos/$id';

    debugPrint('========================================');
    debugPrint('FOODJET FAVORITO - DELETE');
    debugPrint('URL: $url');
    debugPrint('========================================');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'FAVORITO DELETE STATUS: ${response.statusCode}',
      );

      debugPrint(
        'FAVORITO DELETE RESPOSTA: ${response.body}',
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        debugPrint(
          '🤍 FAVORITO REMOVIDO COM SUCESSO',
        );

        return true;
      }

      String mensagem =
          'Não foi possível remover o favorito.';

      if (response.body.trim().isNotEmpty) {
        try {
          final decoded =
              jsonDecode(response.body);

          if (decoded is Map) {
            mensagem =
                decoded['erro']?.toString() ??
                decoded['mensagem']?.toString() ??
                decoded['message']?.toString() ??
                mensagem;
          }
        } catch (_) {}
      }

      throw Exception(mensagem);
    } catch (e) {
      debugPrint(
        '❌ ERRO AO REMOVER FAVORITO: $e',
      );

      rethrow;
    }
  }
}