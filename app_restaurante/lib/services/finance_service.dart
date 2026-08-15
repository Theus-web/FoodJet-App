import 'dart:convert';

import 'package:http/http.dart' as http;


class FinanceService {

  static const String baseUrl =
      "http://192.168.1.101:3000/api";


  // =====================================================
  // BUSCAR RESUMO FINANCEIRO
  // =====================================================

  Future<Map<String, dynamic>> buscarResumo(
    String restauranteId,
  ) async {

    final response = await http.get(

      Uri.parse(
        "$baseUrl/finance/$restauranteId",
      ),

      headers: {
        "Content-Type": "application/json",
      },

    );


    final data =
        jsonDecode(response.body);


    if (response.statusCode != 200) {

      throw Exception(
        data["erro"] ??
            "Erro ao carregar financeiro",
      );

    }


    return Map<String, dynamic>.from(
      data,
    );
  }


  // =====================================================
  // SOLICITAR SAQUE
  // =====================================================

  Future<Map<String, dynamic>> solicitarSaque({

    required String restauranteId,

    required double valor,

    required String metodo,

    required String chave,

  }) async {

    final response = await http.post(

      Uri.parse(
        "$baseUrl/finance/$restauranteId/saque",
      ),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({

        "valor": valor,

        "metodo": metodo,

        "chave": chave,

      }),

    );


    final data =
        jsonDecode(response.body);


    if (
      response.statusCode != 200 &&
      response.statusCode != 201
    ) {

      throw Exception(
        data["erro"] ??
            "Erro ao solicitar saque",
      );

    }


    return Map<String, dynamic>.from(
      data,
    );
  }
}