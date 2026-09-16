import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api.dart';

class AuthService {
  // ============================================================
  // TOKEN
  // ============================================================

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token') ??
        prefs.getString('jwt') ??
        prefs.getString('access_token') ??
        prefs.getString('auth_token');
  }

  // ============================================================
  // USUÁRIO
  // ============================================================

  static Future<Map<String, dynamic>?> getUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getString('usuario');

    if (dados == null || dados.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(dados);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final response = await http.post(
      Uri.parse(Api.login),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'senha': senha,
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
            data['erro']?.toString() ??
            'Erro ao fazer login.',
      );
    }

    final tipo =
        data['tipo']?.toString() ??
        data['usuario']?['tipo']?.toString();

    if (tipo != 'ENTREGADOR') {
      throw Exception(
        'Este acesso não pertence a um entregador.',
      );
    }

    final token =
        data['token']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception(
        'O servidor não retornou o token.',
      );
    }

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString('token', token);

    final usuario =
        data['usuario'] ??
        data['user'];

    if (usuario is Map) {
      await prefs.setString(
        'usuario',
        jsonEncode(usuario),
      );
    } else {
      await prefs.setString(
        'usuario',
        jsonEncode({
          'id': data['id'],
          'nome': data['nome'],
          'email': data['email'],
          'tipo': tipo,
        }),
      );
    }

    return data;
  }

  // ============================================================
  // PERFIL
  // ============================================================

  static Future<Map<String, dynamic>> perfil() async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Usuário não autenticado.');
    }

    final response = await http.get(
      Uri.parse(Api.perfil),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    Map<String, dynamic> data = {};

    try {
      data = jsonDecode(response.body);
    } catch (_) {}

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data['mensagem']?.toString() ??
            'Não foi possível carregar o perfil.',
      );
    }

    return data;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('jwt');
    await prefs.remove('access_token');
    await prefs.remove('auth_token');
    await prefs.remove('usuario');
  }
}