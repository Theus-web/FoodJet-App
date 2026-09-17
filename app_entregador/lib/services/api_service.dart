import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';
import 'auth_service.dart';

class ApiService {
  static const Duration httpTimeout = Duration(seconds: 30);

  static Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('${Api.baseUrl}$path');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await AuthService.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    late http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(
                uri,
                headers: headers,
              )
              .timeout(httpTimeout);
          break;

        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: jsonEncode(body ?? {}),
              )
              .timeout(httpTimeout);
          break;

        case 'PUT':
          response = await http
              .put(
                uri,
                headers: headers,
                body: jsonEncode(body ?? {}),
              )
              .timeout(httpTimeout);
          break;

        case 'PATCH':
          response = await http
              .patch(
                uri,
                headers: headers,
                body: jsonEncode(body ?? {}),
              )
              .timeout(httpTimeout);
          break;

        case 'DELETE':
          response = await http
              .delete(
                uri,
                headers: headers,
                body: jsonEncode(body ?? {}),
              )
              .timeout(httpTimeout);
          break;

        default:
          throw Exception(
            'Método HTTP não suportado: $method',
          );
      }
    } on http.ClientException catch (e) {
      throw Exception(
        'Erro de conexão com o servidor: ${e.message}',
      );
    } on FormatException {
      throw Exception(
        'Endereço da API inválido.',
      );
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'O servidor demorou muito para responder.',
        );
      }

      rethrow;
    }

    dynamic decoded;

    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      decoded = {
        'raw': response.body,
      };
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String? message;

      if (decoded is Map) {
        message = (
          decoded['erro'] ??
          decoded['error'] ??
          decoded['mensagem'] ??
          decoded['message'] ??
          decoded['detalhe']
        )?.toString();
      }

      throw Exception(
        message != null && message.isNotEmpty
            ? message
            : 'Erro HTTP ${response.statusCode}',
      );
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {
      'data': decoded,
    };
  }
}