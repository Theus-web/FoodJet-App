
import 'dart:convert';

import 'package:http/http.dart' as http;

class RestaurantService {
  // ============================================================
  // CONFIGURAÇÃO DA API
  // ============================================================

  // Android Emulator:
  static const String baseUrl =
      'http://10.0.2.2:3000/api';

  // Se estiver usando celular físico, troque pelo IP
  // do computador onde o backend está rodando.
  //
  // Exemplo:
  // static const String baseUrl =
  //     'http://192.168.1.100:3000/api';

  // ============================================================
  // LISTAR RESTAURANTES
  // ============================================================

  Future<List<Map<String, dynamic>>> buscarRestaurantes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print(
        '🏪 RESTAURANTES - STATUS: ${response.statusCode}',
      );

      print(
        '🏪 RESTAURANTES - RESPOSTA: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Falha ao buscar restaurantes: '
          '${response.statusCode}',
        );
      }

      final dynamic dados =
          jsonDecode(response.body);

      if (dados is! List) {
        throw Exception(
          'Resposta inválida da API de restaurantes.',
        );
      }

      final restaurantes = dados
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (restaurante) =>
                Map<String, dynamic>.from(
              restaurante,
            ),
          )
          .toList();

      return restaurantes;
    } catch (e) {
      print(
        '❌ ERRO AO BUSCAR RESTAURANTES: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // BUSCAR RESTAURANTE POR ID
  // ============================================================

  Future<Map<String, dynamic>?> buscarRestaurantePorId(
    dynamic restauranteId,
  ) async {
    try {
      if (restauranteId == null ||
          restauranteId.toString().trim().isEmpty) {
        return null;
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/restaurants/$restauranteId',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print(
        '🏪 RESTAURANTE $restauranteId - STATUS: '
        '${response.statusCode}',
      );

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Falha ao buscar restaurante: '
          '${response.statusCode}',
        );
      }

      final dynamic dados =
          jsonDecode(response.body);

      if (dados is! Map) {
        throw Exception(
          'Resposta inválida do restaurante.',
        );
      }

      return Map<String, dynamic>.from(
        dados,
      );
    } catch (e) {
      print(
        '❌ ERRO AO BUSCAR RESTAURANTE: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // ATUALIZAR RESTAURANTE
  // ============================================================

  Future<Map<String, dynamic>?> atualizarRestaurante(
    dynamic restauranteId,
    Map<String, dynamic> dados,
  ) async {
    try {
      if (restauranteId == null ||
          restauranteId.toString().trim().isEmpty) {
        throw Exception(
          'ID do restaurante é obrigatório.',
        );
      }

      final response = await http.put(
        Uri.parse(
          '$baseUrl/restaurants/$restauranteId',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(dados),
      );

      print(
        '⚙️ ATUALIZAR RESTAURANTE - STATUS: '
        '${response.statusCode}',
      );

      print(
        '⚙️ ATUALIZAR RESTAURANTE - RESPOSTA: '
        '${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Falha ao atualizar restaurante: '
          '${response.statusCode}',
        );
      }

      final dynamic resposta =
          jsonDecode(response.body);

      if (resposta is Map &&
          resposta['restaurante'] is Map) {
        return Map<String, dynamic>.from(
          resposta['restaurante'],
        );
      }

      if (resposta is Map) {
        return Map<String, dynamic>.from(
          resposta,
        );
      }

      return null;
    } catch (e) {
      print(
        '❌ ERRO AO ATUALIZAR RESTAURANTE: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // ALTERAR STATUS
  // ============================================================

  Future<Map<String, dynamic>?> atualizarStatus(
    dynamic restauranteId,
    String status,
  ) async {
    try {
      if (restauranteId == null ||
          restauranteId.toString().trim().isEmpty) {
        throw Exception(
          'ID do restaurante é obrigatório.',
        );
      }

      final response = await http.put(
        Uri.parse(
          '$baseUrl/restaurants/$restauranteId/status',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status.toUpperCase(),
        }),
      );

      print(
        '🔄 STATUS RESTAURANTE: '
        '${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Falha ao atualizar status: '
          '${response.statusCode}',
        );
      }

      final dynamic resposta =
          jsonDecode(response.body);

      if (resposta is Map &&
          resposta['restaurante'] is Map) {
        return Map<String, dynamic>.from(
          resposta['restaurante'],
        );
      }

      return null;
    } catch (e) {
      print(
        '❌ ERRO AO ATUALIZAR STATUS: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // PEGAR LOGO
  // ============================================================

  String obterLogo(
    Map<String, dynamic> restaurante,
  ) {
    final dynamic logo =
        restaurante['logo'];

    if (logo == null) {
      return '';
    }

    return logo.toString().trim();
  }

  // ============================================================
  // PEGAR NOME
  // ============================================================

  String obterNome(
    Map<String, dynamic> restaurante,
  ) {
    final dynamic nome =
        restaurante['nome'];

    if (nome == null ||
        nome.toString().trim().isEmpty) {
      return 'Restaurante';
    }

    return nome.toString();
  }

  // ============================================================
  // PEGAR CATEGORIA
  // ============================================================

  String obterCategoria(
    Map<String, dynamic> restaurante,
  ) {
    final dynamic categoria =
        restaurante['categoria'];

    if (categoria == null ||
        categoria.toString().trim().isEmpty) {
      return 'Restaurante';
    }

    return categoria.toString();
  }

  // ============================================================
  // PEGAR TAXA DE ENTREGA
  // ============================================================

  double obterTaxaEntrega(
    Map<String, dynamic> restaurante,
  ) {
    final dynamic taxa =
        restaurante['taxaEntrega'];

    if (taxa == null) {
      return 0;
    }

    if (taxa is num) {
      return taxa.toDouble();
    }

    return double.tryParse(
          taxa.toString(),
        ) ??
        0;
  }

  // ============================================================
  // PEGAR TEMPO DE ENTREGA
  // ============================================================

  String obterTempoEntrega(
    Map<String, dynamic> restaurante,
  ) {
    final dynamic tempo =
        restaurante['tempoEntrega'];

    if (tempo == null ||
        tempo.toString().trim().isEmpty) {
      return '30-50 min';
    }

    return tempo.toString();
  }

  // ============================================================
  // VERIFICAR SE ESTÁ ABERTO
  // ============================================================

  bool estaAberto(
    Map<String, dynamic> restaurante,
  ) {
    final status =
        restaurante['status']
            ?.toString()
            .toUpperCase();

    final online =
        restaurante['online'] == true;

    final aberto =
        restaurante['aberto'] == true;

    return status == 'ABERTO' &&
        online &&
        aberto;
  }

  // ============================================================
  // NORMALIZAR RESTAURANTE
  // ============================================================
  //
  // Garante que o App Cliente sempre tenha
  // os campos necessários para exibição.
  //
  // ============================================================

  Map<String, dynamic> normalizarRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    final copia =
        Map<String, dynamic>.from(
      restaurante,
    );

    copia['logo'] =
        obterLogo(copia);

    copia['nome'] =
        obterNome(copia);

    copia['categoria'] =
        obterCategoria(copia);

    copia['taxaEntrega'] =
        obterTaxaEntrega(copia);

    copia['tempoEntrega'] =
        obterTempoEntrega(copia);

    copia['aberto'] =
        estaAberto(copia);

    return copia;
  }

  // ============================================================
  // LISTAR RESTAURANTES NORMALIZADOS
  // ============================================================

  Future<List<Map<String, dynamic>>>
      buscarRestaurantesNormalizados() async {
    final restaurantes =
        await buscarRestaurantes();

    return restaurantes
        .map(
          normalizarRestaurante,
        )
        .toList();
  }
}

