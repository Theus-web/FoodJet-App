
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

    Map<String, dynamic>? usuario;

    if (dados != null && dados.isNotEmpty) {
      try {
        final decoded = jsonDecode(dados);

        if (decoded is Map) {
          usuario = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        print('❌ Erro ao ler usuário salvo: $e');
      }
    }

    // ==========================================================
    // SE JÁ TEM ID, RETORNA DIRETAMENTE
    // ==========================================================

    if (usuario != null && _temId(usuario)) {
      return usuario;
    }

    // ==========================================================
    // TENTA RECUPERAR O PERFIL DO BACKEND
    // ==========================================================

    final token = await getToken();

    if (token == null || token.isEmpty) {
      return usuario;
    }

    try {
      print('🔄 Usuário sem ID. Buscando perfil no backend...');

      final response = await http.get(
        Uri.parse(Api.perfil),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print(
        '📡 GET ${Api.perfil} → HTTP ${response.statusCode}',
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          final perfil = Map<String, dynamic>.from(decoded);

          final dadosPerfil = _extrairUsuario(perfil);

          if (dadosPerfil != null) {
            final usuarioFinal = {
              ...?usuario,
              ...dadosPerfil,
            };

            await prefs.setString(
              'usuario',
              jsonEncode(usuarioFinal),
            );

            print(
              '✅ Usuário atualizado pelo perfil: '
              '$usuarioFinal',
            );

            return usuarioFinal;
          }
        }
      }
    } catch (e) {
      print(
        '❌ Erro ao recuperar perfil automaticamente: $e',
      );
    }

    return usuario;
  }

  // ============================================================
  // VERIFICAR SE POSSUI ID
  // ============================================================

  static bool _temId(Map<String, dynamic> usuario) {
    final possiveisIds = [
      usuario['id'],
      usuario['usuario_id'],
      usuario['id_usuario'],
      usuario['entregador_id'],
      usuario['id_entregador'],
      usuario['user_id'],
    ];

    for (final valor in possiveisIds) {
      if (valor != null &&
          valor.toString().trim().isNotEmpty &&
          valor.toString() != 'null') {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // EXTRAIR USUÁRIO DE DIFERENTES FORMATOS
  // ============================================================

  static Map<String, dynamic>? _extrairUsuario(
    Map<String, dynamic> data,
  ) {
    final usuario = data['usuario'];

    if (usuario is Map) {
      return Map<String, dynamic>.from(usuario);
    }

    final user = data['user'];

    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }

    final entregador = data['entregador'];

    if (entregador is Map) {
      return Map<String, dynamic>.from(entregador);
    }

    // Caso o próprio objeto já seja o usuário
    if (_temId(data)) {
      return data;
    }

    return null;
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
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'senha': senha,
      }),
    );

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      print('❌ Erro ao interpretar resposta do login: $e');
    }

    print('📡 LOGIN → HTTP ${response.statusCode}');
    print('📦 RESPOSTA LOGIN: $data');

    // ==========================================================
    // ERRO
    // ==========================================================

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data['mensagem']?.toString() ??
            data['erro']?.toString() ??
            data['message']?.toString() ??
            'Erro ao fazer login.',
      );
    }

    // ==========================================================
    // USUÁRIO
    // ==========================================================

    final usuario = _extrairUsuario(data);

    // ==========================================================
    // TIPO
    // ==========================================================

    final tipo =
        data['tipo']?.toString() ??
        usuario?['tipo']?.toString() ??
        usuario?['role']?.toString();

    if (tipo == null ||
        tipo.trim().toUpperCase() != 'ENTREGADOR') {
      throw Exception(
        'Este acesso não pertence a um entregador.',
      );
    }

    // ==========================================================
    // TOKEN
    // ==========================================================

    final token =
        data['token']?.toString() ??
        data['access_token']?.toString() ??
        data['jwt']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception(
        'O servidor não retornou o token.',
      );
    }

    // ==========================================================
    // MONTAR USUÁRIO FINAL
    // ==========================================================

    final usuarioFinal = <String, dynamic>{
      ...?usuario,

      // Dados que podem vir fora de "usuario"
      if (data['id'] != null)
        'id': data['id'],

      if (data['usuario_id'] != null)
        'usuario_id': data['usuario_id'],

      if (data['entregador_id'] != null)
        'entregador_id': data['entregador_id'],

      if (data['id_entregador'] != null)
        'id_entregador': data['id_entregador'],

      if (data['nome'] != null)
        'nome': data['nome'],

      if (data['email'] != null)
        'email': data['email'],

      'tipo': tipo.toUpperCase(),

      if (data['online'] != null)
        'online': data['online'],

      if (usuario?['online'] != null)
        'online': usuario!['online'],
    };

    // ==========================================================
    // VERIFICAR ID
    // ==========================================================

    print('👤 USUÁRIO FINAL DO LOGIN: $usuarioFinal');

    final idEncontrado =
        usuarioFinal['id'] ??
        usuarioFinal['usuario_id'] ??
        usuarioFinal['entregador_id'] ??
        usuarioFinal['id_entregador'] ??
        usuarioFinal['user_id'];

    print('🆔 ID DO ENTREGADOR: $idEncontrado');

    // ==========================================================
    // SALVAR
    // ==========================================================

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'token',
      token,
    );

    await prefs.setString(
      'usuario',
      jsonEncode(usuarioFinal),
    );

    print('✅ Token salvo.');
    print('✅ Usuário salvo.');
    print('════════════════════════════════════');

    return data;
  }

  // ============================================================
  // PERFIL
  // ============================================================

  static Future<Map<String, dynamic>> perfil() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Usuário não autenticado.',
      );
    }

    final response = await http.get(
      Uri.parse(Api.perfil),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data['mensagem']?.toString() ??
            data['erro']?.toString() ??
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

    print('👋 Logout realizado.');
  }
}

