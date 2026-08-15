import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api.dart';

class AuthService {
  static const String baseUrl = '${Api.baseUrl}/auth';

  static const String _tokenKey = 'foodjet_token';

  // ==================================================
  // LOGIN
  // ==================================================

  Future<Map<String, dynamic>> login(
    String email,
    String senha,
  ) async {
    final emailNormalizado = email.trim().toLowerCase();

    if (emailNormalizado.isEmpty) {
      throw Exception('Digite seu email.');
    }

    if (senha.isEmpty) {
      throw Exception('Digite sua senha.');
    }

    try {
      final resposta = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': emailNormalizado,
              'senha': senha,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      final resultado = _processarResposta(resposta);

      final token = resultado['token']?.toString();

      if (resposta.statusCode != 200) {
        throw Exception(
          resultado['erro']?.toString() ??
              resultado['message']?.toString() ??
              'Email ou senha incorretos.',
        );
      }

      if (token != null && token.isNotEmpty && token != 'null') {
        await salvarToken(token);

        print(
          '✅ TOKEN SALVO COM SUCESSO',
        );
      } else {
        print(
          '⚠️ LOGIN NÃO RETORNOU TOKEN',
        );
      }

      return resultado;
    } on http.ClientException {
      throw Exception(
        'Não foi possível conectar ao servidor.',
      );
    } on FormatException {
      throw Exception(
        'Resposta inválida do servidor.',
      );
    }
  }

  // ==================================================
  // SALVAR TOKEN
  // ==================================================

  Future<void> salvarToken(
    String token,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _tokenKey,
      token,
    );

    print(
      '🔐 TOKEN ARMAZENADO',
    );
  }

  // ==================================================
  // OBTER TOKEN
  // ==================================================

  Future<String?> obterToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) {
      print(
        '⚠️ NENHUM TOKEN ENCONTRADO',
      );

      return null;
    }

    print(
      '🔐 TOKEN ENCONTRADO',
    );

    return token;
  }

  // ==================================================
  // REMOVER TOKEN
  // ==================================================

  Future<void> removerToken() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      _tokenKey,
    );

    print(
      '🚪 TOKEN REMOVIDO',
    );
  }

  // ==================================================
  // LOGOUT
  // ==================================================

  Future<void> logout() async {
    await removerToken();
  }

  // ==================================================
  // CADASTRO
  // ==================================================

  Future<Map<String, dynamic>> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final emailNormalizado = email.trim().toLowerCase();

    if (nome.trim().isEmpty) {
      throw Exception(
        'Digite seu nome.',
      );
    }

    if (emailNormalizado.isEmpty) {
      throw Exception(
        'Digite seu email.',
      );
    }

    if (senha.length < 6) {
      throw Exception(
        'A senha deve ter pelo menos 6 caracteres.',
      );
    }

    try {
      final resposta = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'nome': nome.trim(),
              'email': emailNormalizado,
              'senha': senha,
              'tipo': 'CLIENTE',
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      final resultado = _processarResposta(resposta);

      if (resposta.statusCode != 200 && resposta.statusCode != 201) {
        throw Exception(
          resultado['erro']?.toString() ??
              resultado['message']?.toString() ??
              'Não foi possível realizar o cadastro.',
        );
      }

      return resultado;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Não foi possível realizar o cadastro.',
      );
    }
  }

  // ==================================================
  // SOLICITAR RECUPERAÇÃO DE SENHA
  // ==================================================

  Future<Map<String, dynamic>> forgotPassword(
    String email,
  ) async {
    final emailNormalizado = email.trim().toLowerCase();

    if (emailNormalizado.isEmpty) {
      throw Exception(
        'Digite seu email.',
      );
    }

    print('');
    print(
      '========================================',
    );
    print(
      '🔐 SOLICITANDO RECUPERAÇÃO',
    );
    print(
      '📧 Email: $emailNormalizado',
    );
    print(
      '========================================',
    );

    try {
      final resposta = await http
          .post(
            Uri.parse(
              '$baseUrl/solicitar-recuperacao',
            ),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': emailNormalizado,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      print(
        '📡 Status: ${resposta.statusCode}',
      );

      print(
        '📡 Resposta: ${resposta.body}',
      );

      final resultado = _processarResposta(resposta);

      if (resposta.statusCode != 200) {
        throw Exception(
          resultado['erro']?.toString() ??
              resultado['message']?.toString() ??
              'Não foi possível enviar o código.',
        );
      }

      return resultado;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Não foi possível conectar ao servidor.',
      );
    }
  }

  // ==================================================
  // COMPATIBILIDADE
  // ==================================================

  Future<Map<String, dynamic>> recuperarSenha(
    String email,
  ) async {
    return forgotPassword(email);
  }

  // ==================================================
  // VALIDAR CÓDIGO DE RECUPERAÇÃO
  // ==================================================

  Future<Map<String, dynamic>> validarCodigoRecuperacao({
    required String email,
    required String codigo,
  }) async {
    final emailNormalizado = email.trim().toLowerCase();

    final codigoNormalizado = codigo.trim();

    if (emailNormalizado.isEmpty) {
      throw Exception(
        'Email não informado.',
      );
    }

    if (codigoNormalizado.isEmpty) {
      throw Exception(
        'Digite o código recebido por email.',
      );
    }

    if (codigoNormalizado.length != 6) {
      throw Exception(
        'Digite o código de 6 números.',
      );
    }

    print('');
    print(
      '========================================',
    );
    print(
      '🔐 VALIDANDO CÓDIGO',
    );
    print(
      '📧 Email: $emailNormalizado',
    );
    print(
      '🔢 Código: $codigoNormalizado',
    );
    print(
      '========================================',
    );

    try {
      final resposta = await http
          .post(
            Uri.parse(
              '$baseUrl/validar-codigo',
            ),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': emailNormalizado,
              'codigo': codigoNormalizado,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      print(
        '📡 Status: ${resposta.statusCode}',
      );

      print(
        '📡 Resposta: ${resposta.body}',
      );

      final resultado = _processarResposta(resposta);

      if (resposta.statusCode != 200) {
        throw Exception(
          resultado['erro']?.toString() ??
              resultado['message']?.toString() ??
              'Código inválido ou expirado.',
        );
      }

      print(
        '✅ CÓDIGO VALIDADO',
      );

      return resultado;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Não foi possível validar o código.',
      );
    }
  }

  // ==================================================
  // REDEFINIR SENHA
  // ==================================================

  Future<Map<String, dynamic>> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    final emailNormalizado = email.trim().toLowerCase();

    final codigoNormalizado = codigo.trim();

    if (emailNormalizado.isEmpty) {
      throw Exception(
        'Email não informado.',
      );
    }

    if (codigoNormalizado.length != 6) {
      throw Exception(
        'Digite o código de 6 números.',
      );
    }

    if (novaSenha.length < 6) {
      throw Exception(
        'A nova senha deve ter pelo menos 6 caracteres.',
      );
    }

    print('');
    print(
      '========================================',
    );
    print(
      '🔑 REDEFININDO SENHA',
    );
    print(
      '📧 Email: $emailNormalizado',
    );
    print(
      '🔢 Código: $codigoNormalizado',
    );
    print(
      '========================================',
    );

    try {
      final resposta = await http
          .post(
            Uri.parse(
              '$baseUrl/redefinir-senha',
            ),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': emailNormalizado,
              'codigo': codigoNormalizado,
              'novaSenha': novaSenha,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      print(
        '📡 Status: ${resposta.statusCode}',
      );

      print(
        '📡 Resposta: ${resposta.body}',
      );

      final resultado = _processarResposta(resposta);

      if (resposta.statusCode != 200) {
        throw Exception(
          resultado['erro']?.toString() ??
              resultado['message']?.toString() ??
              'Não foi possível redefinir a senha.',
        );
      }

      print(
        '✅ SENHA REDEFINIDA COM SUCESSO',
      );

      return resultado;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Não foi possível redefinir a senha.',
      );
    }
  }

  // ==================================================
  // ATUALIZAR PERFIL
  // ==================================================

  Future<Map<String, dynamic>> atualizarPerfil({
    required String token,
    String? nome,
    String? email,
    String? telefone,
    String? cpf,
  }) async {
    final Map<String, dynamic> dados = {};

    if (nome != null) {
      dados['nome'] = nome.trim();
    }

    if (email != null) {
      dados['email'] = email.trim().toLowerCase();
    }

    if (telefone != null) {
      dados['telefone'] = telefone.trim();
    }

    if (cpf != null) {
      dados['cpf'] = cpf.trim();
    }

    final resposta = await http
        .put(
          Uri.parse(
            '$baseUrl/perfil',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(dados),
        )
        .timeout(
          const Duration(seconds: 15),
        );

    return _processarRespostaComErro(
      resposta,
      mensagemPadrao: 'Não foi possível atualizar o perfil.',
    );
  }

  // ==================================================
  // BUSCAR PERFIL
  // ==================================================

  Future<Map<String, dynamic>> buscarPerfil({
    required String token,
  }) async {
    final resposta = await http.get(
      Uri.parse(
        '$baseUrl/perfil',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 15),
    );

    return _processarRespostaComErro(
      resposta,
      mensagemPadrao: 'Não foi possível buscar o perfil.',
    );
  }

  // ==================================================
  // ALTERAR SENHA LOGADO
  // ==================================================

  Future<Map<String, dynamic>> alterarSenha({
    required String token,
    required String senhaAtual,
    required String novaSenha,
  }) async {
    if (senhaAtual.isEmpty) {
      throw Exception(
        'Digite sua senha atual.',
      );
    }

    if (novaSenha.length < 6) {
      throw Exception(
        'A nova senha deve ter pelo menos 6 caracteres.',
      );
    }

    final resposta = await http
        .put(
          Uri.parse(
            '$baseUrl/alterar-senha',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'senhaAtual': senhaAtual,
            'novaSenha': novaSenha,
          }),
        )
        .timeout(
          const Duration(seconds: 15),
        );

    return _processarRespostaComErro(
      resposta,
      mensagemPadrao: 'Não foi possível alterar a senha.',
    );
  }

  // ==================================================
  // ATUALIZAR ENDEREÇO
  // ==================================================

  Future<Map<String, dynamic>> atualizarEndereco({
    required String token,
    required Map<String, dynamic> endereco,
  }) async {
    final resposta = await http
        .put(
          Uri.parse(
            '$baseUrl/endereco',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(endereco),
        )
        .timeout(
          const Duration(seconds: 15),
        );

    return _processarRespostaComErro(
      resposta,
      mensagemPadrao: 'Não foi possível atualizar o endereço.',
    );
  }

  // ==================================================
  // PROCESSAR RESPOSTA
  // ==================================================

  Map<String, dynamic> _processarResposta(
    http.Response resposta,
  ) {
    Map<String, dynamic> dados = {};

    if (resposta.body.trim().isNotEmpty) {
      try {
        final resultado = jsonDecode(resposta.body);

        if (resultado is Map) {
          dados = Map<String, dynamic>.from(
            resultado,
          );
        }
      } catch (_) {
        throw Exception(
          'Resposta inválida do servidor.',
        );
      }
    }

    dados['statusCode'] = resposta.statusCode;

    return dados;
  }

  // ==================================================
  // PROCESSAR RESPOSTA + ERRO
  // ==================================================

  Map<String, dynamic> _processarRespostaComErro(
    http.Response resposta, {
    required String mensagemPadrao,
  }) {
    final dados = _processarResposta(resposta);

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw Exception(
        dados['erro']?.toString() ??
            dados['message']?.toString() ??
            mensagemPadrao,
      );
    }

    return dados;
  }
}
