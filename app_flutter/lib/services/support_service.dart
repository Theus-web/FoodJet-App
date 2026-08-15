import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SupportService {
  static const String baseUrl =
      "http://10.0.2.2:3000/api/support";

  // ============================================================
  // PEGAR TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("token");
  }

  // ============================================================
  // HEADERS
  // ============================================================

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    return {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty)
        "Authorization": "Bearer $token",
    };
  }

  // ============================================================
  // CRIAR CHAMADO
  // ============================================================

  Future<Map<String, dynamic>> criarChamado({
    required dynamic pedidoId,
    required dynamic clienteId,
    required dynamic restauranteId,
    required String assunto,
    required String descricao,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode({
        "pedidoId": pedidoId,
        "clienteId": clienteId,
        "restauranteId": restauranteId,
        "assunto": assunto,
        "descricao": descricao,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data["erro"] ??
            "Não foi possível abrir o chamado.",
      );
    }

    return Map<String, dynamic>.from(
      data["chamado"],
    );
  }

  // ============================================================
  // BUSCAR SUPORTES DO CLIENTE
  // ============================================================

  Future<List<Map<String, dynamic>>> buscarPorCliente(
    dynamic clienteId,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/cliente/$clienteId",
      ),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Não foi possível carregar seus chamados.",
      );
    }

    final data = jsonDecode(response.body);

    return List<Map<String, dynamic>>.from(
      data.map(
        (item) =>
            Map<String, dynamic>.from(item),
      ),
    );
  }

  // ============================================================
  // BUSCAR SUPORTE DO PEDIDO
  // ============================================================

  Future<List<Map<String, dynamic>>> buscarPorPedido(
    dynamic pedidoId,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/pedido/$pedidoId",
      ),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Não foi possível carregar o suporte.",
      );
    }

    final data = jsonDecode(response.body);

    return List<Map<String, dynamic>>.from(
      data.map(
        (item) =>
            Map<String, dynamic>.from(item),
      ),
    );
  }

  // ============================================================
  // BUSCAR CHAMADO
  // ============================================================

  Future<Map<String, dynamic>> buscarChamado(
    dynamic chamadoId,
  ) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/$chamadoId",
      ),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data["erro"] ??
            "Não foi possível carregar o chamado.",
      );
    }

    return Map<String, dynamic>.from(data);
  }

  // ============================================================
  // ENVIAR MENSAGEM
  // ============================================================

  Future<Map<String, dynamic>> enviarMensagem({
    required dynamic chamadoId,
    required dynamic remetenteId,
    required String mensagem,
  }) async {
    final response = await http.post(
      Uri.parse(
        "$baseUrl/$chamadoId/mensagem",
      ),
      headers: await _headers(),
      body: jsonEncode({
        "remetenteId": remetenteId,
        "remetenteTipo": "CLIENTE",
        "mensagem": mensagem,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data["erro"] ??
            "Não foi possível enviar a mensagem.",
      );
    }

    return Map<String, dynamic>.from(
      data["chamado"],
    );
  }
}