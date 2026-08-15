import 'dart:convert';

import 'package:http/http.dart' as http;


class DashboardService {


  static const String baseUrl =
      "http://192.168.1.101:3000/api";



  Future<Map<String, dynamic>> buscarDashboard(
    String restauranteId,
  ) async {


    try {


      final response = await http.get(

        Uri.parse(
          "$baseUrl/dashboard/$restauranteId",
        ),

      );



      if (response.statusCode == 200) {


        return jsonDecode(
          response.body,
        );


      }



      throw Exception(
        "Erro API Dashboard: ${response.statusCode}",
      );



    } catch (e) {


      throw Exception(
        "Falha ao conectar Dashboard: $e",
      );


    }


  }


}