import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../models/entregador.dart';
import 'auth_service.dart';

class DeliveryService {
  // ============================================================
  // BUSCAR ENTREGADOR
  // ============================================================

  static Future<Entregador> buscarEntregador() async {
    final usuario =
        await AuthService.getUsuario();

    if (usuario == null) {
      throw Exception(
        'Usuário não encontrado.',
      );
    }

    final id =
        usuario['id']?.toString();

    if (id == null || id.isEmpty) {
      throw Exception(
        'ID do entregador não encontrado.',
      );
    }

    final token =
        await AuthService.getToken();

    final response = await http.get(
      Uri.parse(
        '${Api.entregadores}/$id',
      ),
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

    // ----------------------------------------------------------
    // FALLBACK
    // ----------------------------------------------------------

    final perfil =
        await AuthService.perfil();

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

  // ============================================================
  // ALTERAR ONLINE/OFFLINE
  // ============================================================

  static Future<Entregador> alterarStatus({
    required dynamic id,
    required bool online,
  }) async {
    final token =
        await AuthService.getToken();

    final response = await http.put(
      Uri.parse(
        Api.statusEntregador(
          id.toString(),
        ),
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
      data = jsonDecode(response.body);
    } catch (_) {}

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data['mensagem']?.toString() ??
            'Não foi possível alterar o status.',
      );
    }

    final entregador =
        data['entregador'];

    if (entregador is Map<String, dynamic>) {
      return Entregador.fromJson(
        entregador,
      );
    }

    return await buscarEntregador();
  }

  // ============================================================
  // PEDIDOS DO ENTREGADOR
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      meusPedidos() async {
    final usuario =
        await AuthService.getUsuario();

    if (usuario == null) {
      return [];
    }

    final id =
        usuario['id']?.toString();

    if (id == null || id.isEmpty) {
      return [];
    }

    final token =
        await AuthService.getToken();

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

    final data =
        jsonDecode(response.body);

    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (e) => Map<String, dynamic>.from(e),
          )
          .toList();
    }

    return [];
  }
}