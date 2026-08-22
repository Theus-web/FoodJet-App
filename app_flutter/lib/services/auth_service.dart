import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get baseUrl {
    // Flutter Web - Edge/Chrome
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    // Android Emulator
    return 'http://10.0.2.2:3000/api';
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'senha': senha,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final token = data['token']?.toString();

      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
      }

      return data;
    }

    throw Exception(
      data['erro']?.toString() ??
          data['mensagem']?.toString() ??
          'Erro ao realizar login.',
    );
  }

  // ==========================================================
  // TOKEN
  // ==========================================================

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> obterToken() async {
    return getToken();
  }

  // ==========================================================
  // SESSÃO
  // ==========================================================

  Future<Map<String, dynamic>?> obterSessao() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      return null;
    }

    final usuarioJson = prefs.getString('usuario');

    if (usuarioJson == null || usuarioJson.isEmpty) {
      return {
        'token': token,
      };
    }

    try {
      final usuario = jsonDecode(usuarioJson);

      if (usuario is Map<String, dynamic>) {
        return {
          ...usuario,
          'token': token,
        };
      }
    } catch (_) {}

    return {
      'token': token,
    };
  }

  // ==========================================================
  // RECUPERAR SENHA
  // ==========================================================

  Future<Map<String, dynamic>> recuperarSenha(
  String email,
) async {
  final url = '$baseUrl/auth/recuperar-senha';

  print('========================================');
  print('FOODJET - RECUPERAÇÃO DE SENHA');
  print('URL: $url');
  print('EMAIL: $email');
  print('========================================');

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
      }),
    );

    print('STATUS HTTP: ${response.statusCode}');
    print('RESPOSTA: ${response.body}');

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['erro']?.toString() ??
          data['mensagem']?.toString() ??
          'Não foi possível solicitar a recuperação da senha.',
    );
  } catch (e) {
    print('========================================');
    print('ERRO RECUPERAÇÃO DE SENHA');
    print(e);
    print('========================================');

    rethrow;
  }
}

  // ==========================================================
  // VALIDAR CÓDIGO DE RECUPERAÇÃO
  // ==========================================================

  Future<Map<String, dynamic>> validarCodigoRecuperacao({
    required String email,
    required String codigo,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/validar-codigo-recuperacao'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'codigo': codigo,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['erro']?.toString() ??
          data['mensagem']?.toString() ??
          'Código inválido ou expirado.',
    );
  }

  // ==========================================================
  // REDEFINIR SENHA
  // ==========================================================

  Future<Map<String, dynamic>> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/redefinir-senha'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'codigo': codigo,
        'novaSenha': novaSenha,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['erro']?.toString() ??
          data['mensagem']?.toString() ??
          'Não foi possível redefinir a senha.',
    );
  }

  // ==========================================================
  // ALTERAR SENHA LOGADO
  // ==========================================================

  Future<Map<String, dynamic>> alterarSenha({
    required String token,
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/alterar-senha'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'senhaAtual': senhaAtual,
        'novaSenha': novaSenha,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['erro']?.toString() ??
          data['mensagem']?.toString() ??
          'Não foi possível alterar a senha.',
    );
  }

  // ==========================================================
  // ATUALIZAR PERFIL
  // ==========================================================

  Future<Map<String, dynamic>> atualizarPerfil({
    required String token,
    String? nome,
    String? email,
    String? telefone,
    String? foto,
  }) async {
    final Map<String, dynamic> body = {};

    if (nome != null) {
      body['nome'] = nome;
    }

    if (email != null) {
      body['email'] = email;
    }

    if (telefone != null) {
      body['telefone'] = telefone;
    }

    if (foto != null) {
      body['foto'] = foto;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/auth/perfil'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final usuario = data['usuario'];

      if (usuario is Map<String, dynamic>) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString(
          'usuario',
          jsonEncode(usuario),
        );
      }

      return data;
    }

    throw Exception(
      data['erro']?.toString() ??
          data['mensagem']?.toString() ??
          'Não foi possível atualizar o perfil.',
    );
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('usuario');
  }

  // ==========================================================
  // DECODIFICAR RESPOSTA
  // ==========================================================

  Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'dados': decoded,
      };
    } catch (_) {
      return {
        'mensagem': response.body,
      };
    }
  }
}