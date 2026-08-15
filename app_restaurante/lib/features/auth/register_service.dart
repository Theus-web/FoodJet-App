import 'dart:convert';

import 'package:http/http.dart' as http;

class RegisterService {

  // ALTERE PARA O IP DO SEU BACKEND
  static const String baseUrl =
      "http://192.168.1.101:3000/api";

  Future<Map<String, dynamic>> register({

    required String restaurantName,
    required String ownerName,
    required String email,
    required String phone,
    required String password,

  }) async {

    final response = await http.post(

      Uri.parse("$baseUrl/restaurants/register"),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({

        "restaurantName": restaurantName,

        "ownerName": ownerName,

        "email": email,

        "phone": phone,

        "password": password,

      }),

    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {

      return data;

    }

    throw Exception(
      data["erro"] ??
      data["message"] ??
      "Erro ao criar conta.",
    );

  }

}