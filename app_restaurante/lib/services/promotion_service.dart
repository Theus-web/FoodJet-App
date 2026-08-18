import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';

class PromotionService {
  // ======================================================
  // BUSCAR PROMOÇÕES DO RESTAURANTE
  // ======================================================

  Future<List<Map<String, dynamic>>> buscarPromocoes(
    String restauranteId,
  ) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/promocoes/restaurante/$restauranteId',
    );

    final resposta = await http.get(
      url,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (resposta.statusCode != 200) {
      throw Exception(
        'Erro ao buscar promoções: ${resposta.body}',
      );
    }

    final dados = jsonDecode(resposta.body);

    if (dados is! List) {
      return [];
    }

    return dados
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  // ======================================================
  // CRIAR PROMOÇÃO
  // POST /api/promocoes
  // ======================================================

  Future<Map<String, dynamic>> criarPromocao(
    Map<String, dynamic> promocao,
  ) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/promocoes',
    );

    print('======================================');
    print('CRIANDO PROMOÇÃO');
    print('URL: $url');
    print('DADOS: ${jsonEncode(promocao)}');
    print('======================================');

    final resposta = await http.post(
      url,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(promocao),
    );

    print('STATUS PROMOÇÃO: ${resposta.statusCode}');
    print('RESPOSTA API: ${resposta.body}');

    if (resposta.statusCode != 201) {
      throw Exception(
        'Erro ao criar promoção: ${resposta.body}',
      );
    }

    final dados = jsonDecode(resposta.body);

    return Map<String, dynamic>.from(dados);
  }

  // ======================================================
  // ALTERAR STATUS
  // PUT /api/promocoes/:id/status
  // ======================================================

  Future<void> alterarStatus(
    String id,
    bool ativa,
  ) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/promocoes/$id/status',
    );

    final resposta = await http.put(
      url,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'ativa': ativa,
      }),
    );

    if (resposta.statusCode != 200) {
      throw Exception(
        'Erro ao alterar status: ${resposta.body}',
      );
    }
  }

  // ======================================================
  // EXCLUIR PROMOÇÃO
  // DELETE /api/promocoes/:id
  // ======================================================

  Future<void> excluirPromocao(
    String id,
  ) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/promocoes/$id',
    );

    final resposta = await http.delete(
      url,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (resposta.statusCode != 200) {
      throw Exception(
        'Erro ao excluir promoção: ${resposta.body}',
      );
    }
  }
}