import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      "http://192.168.1.101:3000/api";

  static const String _tokenKey = "token";
  static const String _userKey = "usuario";
  static const String _restaurantKey = "restaurante";
  static const String _restaurantIdKey = "restauranteId";

  // ============================================================
  // SOLICITAR RECUPERAÇÃO DE SENHA
  // ============================================================

  Future<Map<String, dynamic>> solicitarRecuperacao({
    required String email,
  }) async {
    final emailNormalizado = email.trim().toLowerCase();

    if (emailNormalizado.isEmpty) {
      throw Exception("Digite seu email.");
    }

    try {
      final response = await http.post(
        Uri.parse(
          "$baseUrl/auth/solicitar-recuperacao",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": emailNormalizado,
        }),
      );

      final data = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(
          data["erro"] ??
              data["message"] ??
              "Não foi possível enviar o código.",
        );
      }

      return data;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Não foi possível conectar ao servidor.",
      );
    }
  }

  // ============================================================
  // VALIDAR CÓDIGO
  // ============================================================

  Future<Map<String, dynamic>> validarCodigoRecuperacao({
    required String email,
    required String codigo,
  }) async {
    final emailNormalizado = email.trim().toLowerCase();
    final codigoNormalizado = codigo.trim();

    if (emailNormalizado.isEmpty) {
      throw Exception("Email não informado.");
    }

    if (codigoNormalizado.length != 6) {
      throw Exception(
        "Digite o código de 6 números.",
      );
    }

    try {
      final response = await http.post(
        Uri.parse(
          "$baseUrl/auth/validar-codigo",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": emailNormalizado,
          "codigo": codigoNormalizado,
        }),
      );

      final data = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(
          data["erro"] ??
              data["message"] ??
              "Código inválido ou expirado.",
        );
      }

      return data;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Não foi possível validar o código.",
      );
    }
  }

  // ============================================================
  // REDEFINIR SENHA
  // ============================================================

  Future<Map<String, dynamic>> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    final emailNormalizado = email.trim().toLowerCase();
    final codigoNormalizado = codigo.trim();

    if (emailNormalizado.isEmpty) {
      throw Exception("Email não informado.");
    }

    if (codigoNormalizado.length != 6) {
      throw Exception(
        "Digite o código de 6 números.",
      );
    }

    if (novaSenha.length < 6) {
      throw Exception(
        "A nova senha deve ter pelo menos 6 caracteres.",
      );
    }

    try {
      final response = await http.post(
        Uri.parse(
          "$baseUrl/auth/redefinir-senha",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": emailNormalizado,
          "codigo": codigoNormalizado,
          "novaSenha": novaSenha,
        }),
      );

      final data = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(
          data["erro"] ??
              data["message"] ??
              "Não foi possível redefinir a senha.",
        );
      }

      return data;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Não foi possível redefinir a senha.",
      );
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    await _limparSessao();

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email.trim().toLowerCase(),
          "senha": senha,
        }),
      );

      final data = _decodeResponse(response);

      if (response.statusCode != 200) {
        throw Exception(
          data["erro"] ??
              data["message"] ??
              "Falha no login.",
        );
      }

      final usuario = data["usuario"] is Map
          ? Map<String, dynamic>.from(
              data["usuario"],
            )
          : <String, dynamic>{};

      final token = data["token"]?.toString() ?? "";

      Map<String, dynamic>? restaurante;

      if (data["restaurante"] is Map) {
        restaurante = Map<String, dynamic>.from(
          data["restaurante"],
        );
      }

      final idUsuario =
          _extrairRestauranteId(usuario);

      if (restaurante == null && idUsuario != null) {
        restaurante = {
          "id": idUsuario,
        };
      }

      if (restaurante != null) {
        final idRestaurante =
            _extrairIdRestaurante(restaurante);

        if (idRestaurante == null && idUsuario != null) {
          restaurante["id"] = idUsuario;
        }
      }

      await salvarSessao(
        token: token,
        usuario: usuario,
        restaurante: restaurante,
      );

      final restauranteId =
          _extrairIdRestaurante(restaurante ?? {});

      if (restauranteId != null) {
        await _buscarEAtualizarRestaurante(
          restauranteId,
          token,
        );
      }

      return data;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Não foi possível conectar ao servidor.",
      );
    }
  }

  // ============================================================
  // CADASTRO
  // ============================================================

  Future<Map<String, dynamic>?> register(
    String nome,
    String email,
    String senha,
    String telefone, {
    String tipo = "CLIENTE",
    String cpf = "",
    Map<String, dynamic>? restaurante,
  }) async {
    final body = <String, dynamic>{
      "nome": nome.trim(),
      "email": email.trim().toLowerCase(),
      "senha": senha,
      "telefone": telefone.trim(),
      "tipo": tipo,
      "cpf": cpf.trim(),
    };

    if (tipo == "RESTAURANTE" && restaurante != null) {
      body["cnpj"] =
          restaurante["cnpj"]?.toString().trim() ?? "";

      body["categoria"] =
          restaurante["categoria"]?.toString().trim() ??
              "Restaurante";

      body["responsavel"] =
          restaurante["responsavel"]?.toString().trim() ??
              "";

      body["cep"] =
          restaurante["endereco"]?["cep"]
                  ?.toString()
                  .trim() ??
              "";

      body["rua"] =
          restaurante["endereco"]?["rua"]
                  ?.toString()
                  .trim() ??
              "";

      body["numero"] =
          restaurante["endereco"]?["numero"]
                  ?.toString()
                  .trim() ??
              "";

      body["complemento"] =
          restaurante["endereco"]?["complemento"]
                  ?.toString()
                  .trim() ??
              "";

      body["bairro"] =
          restaurante["endereco"]?["bairro"]
                  ?.toString()
                  .trim() ??
              "";

      body["cidade"] =
          restaurante["endereco"]?["cidade"]
                  ?.toString()
                  .trim() ??
              "";

      body["estado"] =
          restaurante["endereco"]?["estado"]
                  ?.toString()
                  .trim() ??
              "";

      body["banco"] =
          restaurante["pagamento"]?["banco"]
                  ?.toString()
                  .trim() ??
              "";

      body["agencia"] =
          restaurante["pagamento"]?["agencia"]
                  ?.toString()
                  .trim() ??
              "";

      body["conta"] =
          restaurante["pagamento"]?["conta"]
                  ?.toString()
                  .trim() ??
              "";

      body["pix"] =
          restaurante["pagamento"]?["pix"]
                  ?.toString()
                  .trim() ??
              "";

      body["nome"] =
          restaurante["nome"]?.toString().trim() ??
              nome.trim();
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      final data = _decodeResponse(response);

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception(
          data["erro"] ??
              data["message"] ??
              "Não foi possível realizar o cadastro.",
        );
      }

      return data;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Não foi possível conectar ao servidor.",
      );
    }
  }

  // ============================================================
  // EXCLUIR CONTA
  // ============================================================

  Future<Map<String, dynamic>> excluirConta({
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(
          "$baseUrl/auth/excluir-conta",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      Map<String, dynamic> body = {};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          body = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}

      return {
        "statusCode": response.statusCode,
        ...body,
      };
    } catch (_) {
      return {
        "statusCode": 0,
        "erro": "Não foi possível conectar ao servidor.",
      };
    }
  }

  // ============================================================
  // SALVAR SESSÃO
  // ============================================================

  Future<void> salvarSessao({
    required String token,
    required Map<String, dynamic> usuario,
    Map<String, dynamic>? restaurante,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _tokenKey,
      token,
    );

    await prefs.setString(
      _userKey,
      jsonEncode(usuario),
    );

    String? restauranteId;

    if (restaurante != null) {
      restauranteId =
          _extrairIdRestaurante(restaurante);
    }

    restauranteId ??=
        _extrairRestauranteId(usuario);

    if (restaurante != null) {
      if (restauranteId != null) {
        restaurante["id"] = restauranteId;
      }

      await prefs.setString(
        _restaurantKey,
        jsonEncode(restaurante),
      );
    }

    if (restauranteId != null &&
        restauranteId.isNotEmpty) {
      await prefs.setString(
        _restaurantIdKey,
        restauranteId,
      );
    } else {
      await prefs.remove(_restaurantIdKey);
    }
  }

  // ============================================================
  // VERIFICAR LOGIN
  // ============================================================

  Future<bool> estaLogado() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);

    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // BUSCAR USUÁRIO
  // ============================================================

  Future<Map<String, dynamic>?>
      buscarUsuarioSessao() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final usuario =
          prefs.getString(_userKey);

      if (usuario == null || usuario.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(usuario);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?>
      obterUsuario() async {
    return await buscarUsuarioSessao();
  }

  // ============================================================
  // BUSCAR RESTAURANTE DA SESSÃO
  // ============================================================

  Future<Map<String, dynamic>?>
      buscarRestauranteSessao() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final restaurante =
          prefs.getString(_restaurantKey);

      if (restaurante == null ||
          restaurante.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(restaurante);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // BUSCAR RESTAURANTE
  // ============================================================

  Future<Map<String, dynamic>?>
      buscarRestaurante() async {
    final restaurante =
        await buscarRestauranteSessao();

    if (restaurante != null) {
      return restaurante;
    }

    return await buscarDadosRestaurante();
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> obterToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  // ============================================================
  // ID RESTAURANTE
  // ============================================================

  Future<String?> obterRestauranteId() async {
    final prefs =
        await SharedPreferences.getInstance();

    final idSalvo =
        prefs.getString(_restaurantIdKey);

    if (idSalvo != null &&
        idSalvo.trim().isNotEmpty) {
      return idSalvo.trim();
    }

    final restaurante =
        await buscarRestauranteSessao();

    if (restaurante != null) {
      final id =
          _extrairIdRestaurante(restaurante);

      if (id != null) {
        await prefs.setString(
          _restaurantIdKey,
          id,
        );

        return id;
      }
    }

    final usuario =
        await buscarUsuarioSessao();

    if (usuario != null) {
      final id =
          _extrairRestauranteId(usuario);

      if (id != null) {
        await prefs.setString(
          _restaurantIdKey,
          id,
        );

        return id;
      }
    }

    return null;
  }

  // ============================================================
  // BUSCAR DADOS RESTAURANTE
  // ============================================================

  Future<Map<String, dynamic>?>
      buscarDadosRestaurante() async {
    try {
      final restauranteId =
          await obterRestauranteId();

      if (restauranteId == null ||
          restauranteId.isEmpty) {
        return null;
      }

      final token =
          await obterToken();

      return await _buscarEAtualizarRestaurante(
        restauranteId,
        token,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // BUSCAR RESTAURANTE POR ID
  // ============================================================

  Future<Map<String, dynamic>?>
      _buscarEAtualizarRestaurante(
    String restauranteId,
    String? token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/restaurants/$restauranteId",
        ),
        headers: {
          "Content-Type": "application/json",
          if (token != null &&
              token.isNotEmpty &&
              token != "logado")
            "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);

      Map<String, dynamic>? restaurante;

      if (decoded is Map) {
        final data =
            Map<String, dynamic>.from(decoded);

        if (data["restaurante"] is Map) {
          restaurante =
              Map<String, dynamic>.from(
            data["restaurante"],
          );
        } else {
          restaurante = data;
        }
      }

      if (restaurante == null) {
        return null;
      }

      restaurante["id"] =
          _extrairIdRestaurante(restaurante) ??
              restauranteId;

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        _restaurantKey,
        jsonEncode(restaurante),
      );

      await prefs.setString(
        _restaurantIdKey,
        restauranteId,
      );

      return restaurante;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // ATUALIZAR STATUS
  // ============================================================

  Future<bool> atualizarStatusRestaurante(
    bool online,
  ) async {
    try {
      final restauranteId =
          await obterRestauranteId();

      if (restauranteId == null ||
          restauranteId.isEmpty) {
        return false;
      }

      final token =
          await obterToken();

      final status =
          online ? "ABERTO" : "FECHADO";

      final response = await http.put(
        Uri.parse(
          "$baseUrl/restaurants/$restauranteId/status",
        ),
        headers: {
          "Content-Type": "application/json",
          if (token != null &&
              token.isNotEmpty &&
              token != "logado")
            "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "status": status,
        }),
      );

      if (response.statusCode != 200) {
        return false;
      }

      final restaurante =
          await buscarRestauranteSessao();

      if (restaurante != null) {
        restaurante["status"] = status;
        restaurante["online"] = online;

        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
          _restaurantKey,
          jsonEncode(restaurante),
        );
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // VERIFICAR STATUS
  // ============================================================

  Future<bool?> restauranteEstaOnline() async {
    try {
      final restaurante =
          await buscarDadosRestaurante();

      if (restaurante == null) {
        return null;
      }

      final status =
          restaurante["status"]
              ?.toString()
              .toUpperCase();

      if (status == "ABERTO") {
        return true;
      }

      if (status == "FECHADO") {
        return false;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _limparSessao();
  }

  // ============================================================
  // LIMPAR SESSÃO
  // ============================================================

  Future<void> _limparSessao() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_restaurantKey);
    await prefs.remove(_restaurantIdKey);
  }

  // ============================================================
  // EXTRAIR ID DO RESTAURANTE DO USUÁRIO
  // ============================================================

  String? _extrairRestauranteId(
    Map<String, dynamic> usuario,
  ) {
    dynamic valor;

    valor = usuario["restauranteId"];
    valor ??= usuario["restaurante_id"];
    valor ??= usuario["restaurantId"];
    valor ??= usuario["restaurant_id"];

    if (valor == null &&
        usuario["restaurante"] is Map) {
      final restaurante =
          Map<String, dynamic>.from(
        usuario["restaurante"],
      );

      valor = restaurante["id"];
      valor ??= restaurante["restauranteId"];
      valor ??= restaurante["_id"];
    }

    if (valor == null &&
        usuario["restaurant"] is Map) {
      final restaurante =
          Map<String, dynamic>.from(
        usuario["restaurant"],
      );

      valor = restaurante["id"];
      valor ??= restaurante["restaurantId"];
      valor ??= restaurante["_id"];
    }

    if (valor == null) {
      return null;
    }

    final id = valor.toString().trim();

    if (id.isEmpty || id == "null") {
      return null;
    }

    return id;
  }

  // ============================================================
  // EXTRAIR ID RESTAURANTE
  // ============================================================

  String? _extrairIdRestaurante(
    Map<String, dynamic> restaurante,
  ) {
    dynamic valor;

    valor = restaurante["id"];
    valor ??= restaurante["restauranteId"];
    valor ??= restaurante["restaurante_id"];
    valor ??= restaurante["restaurantId"];
    valor ??= restaurante["restaurant_id"];
    valor ??= restaurante["_id"];

    if (valor == null) {
      return null;
    }

    final id = valor.toString().trim();

    if (id.isEmpty || id == "null") {
      return null;
    }

    return id;
  }

  // ============================================================
  // DECODIFICAR RESPOSTA
  // ============================================================

  Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    try {
      final decoded =
          jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      return {};
    } catch (_) {
      throw Exception(
        "Resposta inválida do servidor.",
      );
    }
  }
}