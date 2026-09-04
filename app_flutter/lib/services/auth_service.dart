
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api.dart';

class AuthService {
  // ==========================================================
  // URL DA API
  // ==========================================================
  //
  // IMPORTANTE:
  // O FoodJet agora utiliza o backend hospedado no Render.
  //
  // Não usar:
  //   localhost
  //   10.0.2.2
  //   IP local da rede
  //
  // O Api.baseUrl já contém:
  // https://foodjet-backend.onrender.com/api
  // ==========================================================

  static String get baseUrl {
    return Api.baseUrl;
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<Map<String, dynamic>> login(
    String email,
    String senha,
  ) async {
    final emailNormalizado = email.trim().toLowerCase();

    debugPrint('========================================');
    debugPrint('🔐 FOODJET - LOGIN');
    debugPrint('📧 E-MAIL: $emailNormalizado');
    debugPrint('🌐 API: $baseUrl');
    debugPrint('========================================');

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': emailNormalizado,
              'senha': senha,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      debugPrint(
        '📡 STATUS LOGIN: ${response.statusCode}',
      );

      debugPrint(
        '📡 RESPOSTA LOGIN: ${response.body}',
      );

      final data = _decodeResponse(response);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final prefs =
            await SharedPreferences.getInstance();

        // ======================================================
        // TOKEN
        // ======================================================

        final token = data['token']?.toString();

        if (token != null && token.isNotEmpty) {
          await prefs.setString(
            'token',
            token,
          );

          debugPrint(
            '✅ TOKEN SALVO',
          );
        } else {
          debugPrint(
            '⚠️ LOGIN NÃO RETORNOU TOKEN',
          );
        }

        // ======================================================
        // USUÁRIO
        // ======================================================

        dynamic usuario = data['usuario'];

        // Caso o backend utilize "user"
        if (usuario == null) {
          usuario = data['user'];
        }

        // Caso o backend retorne o usuário
        // diretamente na resposta
        if (usuario == null &&
            (data['id'] != null ||
                data['email'] != null ||
                data['nome'] != null)) {
          usuario = data;
        }

        Map<String, dynamic> usuarioFinal;

        if (usuario is Map) {
          usuarioFinal =
              Map<String, dynamic>.from(
            usuario,
          );
        } else {
          usuarioFinal = {};
        }

        // ======================================================
        // GARANTIR E-MAIL
        // ======================================================

        final emailUsuario =
            usuarioFinal['email']
                ?.toString()
                .trim()
                .toLowerCase();

        if (emailUsuario == null ||
            emailUsuario.isEmpty) {
          usuarioFinal['email'] =
              emailNormalizado;
        }

        // ======================================================
        // SALVAR USUÁRIO
        // ======================================================

        await prefs.setString(
          'usuario',
          jsonEncode(usuarioFinal),
        );

        // ======================================================
        // SALVAR E-MAIL SEPARADAMENTE
        // ======================================================

        await prefs.setString(
          'email',
          emailNormalizado,
        );

        debugPrint(
          '========================================',
        );

        debugPrint(
          '✅ LOGIN CONCLUÍDO',
        );

        debugPrint(
          '📧 E-MAIL SALVO: $emailNormalizado',
        );

        debugPrint(
          '👤 USUÁRIO SALVO: $usuarioFinal',
        );

        debugPrint(
          '🔐 TOKEN SALVO: '
          '${token != null && token.isNotEmpty}',
        );

        debugPrint(
          '========================================',
        );

        return data;
      }

      throw Exception(
        data['erro']?.toString() ??
            data['mensagem']?.toString() ??
            data['error']?.toString() ??
            'Erro ao realizar login.',
      );
    } catch (e) {
      debugPrint(
        '❌ ERRO LOGIN: $e',
      );

      rethrow;
    }
  }

  // ==========================================================
  // TOKEN
  // ==========================================================

  Future<String?> getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  Future<String?> obterToken() async {
    return getToken();
  }

  // ==========================================================
  // E-MAIL DO USUÁRIO LOGADO
  // ==========================================================

  Future<String?> obterEmail() async {
    final prefs =
        await SharedPreferences.getInstance();

    // Primeiro tenta o campo separado
    final email =
        prefs.getString('email');

    if (email != null &&
        email.trim().isNotEmpty) {
      return email.trim().toLowerCase();
    }

    // Depois tenta dentro do usuário
    final usuarioJson =
        prefs.getString('usuario');

    if (usuarioJson != null &&
        usuarioJson.isNotEmpty) {
      try {
        final decoded =
            jsonDecode(usuarioJson);

        if (decoded is Map) {
          final emailUsuario =
              decoded['email']
                  ?.toString()
                  .trim()
                  .toLowerCase();

          if (emailUsuario != null &&
              emailUsuario.isNotEmpty) {
            return emailUsuario;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  // ==========================================================
  // SESSÃO
  // ==========================================================

  Future<Map<String, dynamic>?> obterSessao() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString('token');

    if (token == null ||
        token.isEmpty) {
      return null;
    }

    Map<String, dynamic> usuario = {};

    final usuarioJson =
        prefs.getString('usuario');

    if (usuarioJson != null &&
        usuarioJson.isNotEmpty) {
      try {
        final decoded =
            jsonDecode(usuarioJson);

        if (decoded is Map) {
          usuario =
              Map<String, dynamic>.from(
            decoded,
          );
        }
      } catch (e) {
        debugPrint(
          '⚠️ Erro ao ler usuário salvo: $e',
        );
      }
    }

    // ========================================================
    // RECUPERAR E-MAIL
    // ========================================================

    if (usuario['email'] == null ||
        usuario['email']
            .toString()
            .trim()
            .isEmpty) {
      final email =
          prefs.getString('email');

      if (email != null &&
          email.trim().isNotEmpty) {
        usuario['email'] =
            email.trim().toLowerCase();
      }
    }

    return {
      ...usuario,
      'token': token,
    };
  }

  // ==========================================================
  // RECUPERAR SENHA
  // ==========================================================

  Future<Map<String, dynamic>> recuperarSenha(
    String email,
  ) async {
    final url =
        '$baseUrl/auth/recuperar-senha';

    debugPrint('========================================');
    debugPrint(
      'FOODJET - RECUPERAÇÃO DE SENHA',
    );
    debugPrint('URL: $url');
    debugPrint('EMAIL: $email');
    debugPrint('========================================');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email
                  .trim()
                  .toLowerCase(),
            }),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      debugPrint(
        'STATUS HTTP: ${response.statusCode}',
      );

      debugPrint(
        'RESPOSTA: ${response.body}',
      );

      final data =
          _decodeResponse(response);

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
      debugPrint(
        '❌ ERRO RECUPERAÇÃO DE SENHA: $e',
      );

      rethrow;
    }
  }

  // ==========================================================
  // VALIDAR CÓDIGO DE RECUPERAÇÃO
  // ==========================================================

  Future<Map<String, dynamic>>
      validarCodigoRecuperacao({
    required String email,
    required String codigo,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/auth/validar-codigo-recuperacao',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email
                .trim()
                .toLowerCase(),
            'codigo': codigo.trim(),
          }),
        )
        .timeout(
          const Duration(seconds: 20),
        );

    final data =
        _decodeResponse(response);

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

  Future<Map<String, dynamic>>
      redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/auth/redefinir-senha',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email
                .trim()
                .toLowerCase(),
            'codigo': codigo.trim(),
            'novaSenha': novaSenha,
          }),
        )
        .timeout(
          const Duration(seconds: 20),
        );

    final data =
        _decodeResponse(response);

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

  Future<Map<String, dynamic>>
      alterarSenha({
    required String token,
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final response = await http
        .put(
          Uri.parse(
            '$baseUrl/auth/alterar-senha',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization':
                'Bearer $token',
          },
          body: jsonEncode({
            'senhaAtual': senhaAtual,
            'novaSenha': novaSenha,
          }),
        )
        .timeout(
          const Duration(seconds: 20),
        );

    final data =
        _decodeResponse(response);

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

  Future<Map<String, dynamic>>
      atualizarPerfil({
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
      body['email'] = email
          .trim()
          .toLowerCase();
    }

    if (telefone != null) {
      body['telefone'] = telefone;
    }

    if (foto != null) {
      body['foto'] = foto;
    }

    final response = await http
        .put(
          Uri.parse(
            '$baseUrl/auth/perfil',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization':
                'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 20),
        );

    final data =
        _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final usuario =
          data['usuario'];

      if (usuario is Map) {
        final usuarioMap =
            Map<String, dynamic>.from(
          usuario,
        );

        final prefs =
            await SharedPreferences
                .getInstance();

        await prefs.setString(
          'usuario',
          jsonEncode(usuarioMap),
        );

        final emailUsuario =
            usuarioMap['email']
                ?.toString()
                .trim()
                .toLowerCase();

        if (emailUsuario != null &&
            emailUsuario.isNotEmpty) {
          await prefs.setString(
            'email',
            emailUsuario,
          );
        }
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
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('usuario');
    await prefs.remove('email');

    debugPrint(
      '🚪 FOODJET: sessão encerrada.',
    );
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
      final decoded =
          jsonDecode(response.body);

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

