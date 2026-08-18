import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api.dart';


class PromotionService {


  // ======================================================
  // BUSCAR PROMOÇÕES DO RESTAURANTE
  // ======================================================

  Future<List<Map<String, dynamic>>> buscarPromocoes(
    String restauranteId,
  ) async {


    final url = Uri.parse(
      '${ApiConfig.baseUrl}/promocoes/restaurante/$restauranteId',
    );


    final resposta = await http.get(
      url,
      headers: const {

        'Content-Type':
            'application/json',

        'Accept':
            'application/json',

      },
    );



    if(resposta.statusCode != 200){

      throw Exception(
        'Erro ao buscar promoções',
      );

    }



    final dados =
        jsonDecode(
          resposta.body,
        );



    if(dados is! List){

      return [];

    }



    return dados
        .whereType<Map>()
        .map(
          (item){

            return Map<String,dynamic>.from(
              item,
            );

          },
        )
        .toList();

  }





  // ======================================================
  // CRIAR PROMOÇÃO
  // ======================================================


  Future<Map<String,dynamic>> criarPromocao(
    Map<String,dynamic> promocao,
  ) async {


    final url = Uri.parse(
      '${ApiConfig.baseUrl}/promocoes',
    );



    final resposta =
        await http.post(
      url,

      headers: const {

        'Content-Type':
            'application/json',

        'Accept':
            'application/json',

      },


      body:
          jsonEncode(
            promocao,
          ),

    );




    if(resposta.statusCode != 201){

      throw Exception(
        'Erro ao criar promoção',
      );

    }



    return Map<String,dynamic>.from(
      jsonDecode(
        resposta.body,
      ),
    );


  }





  // ======================================================
  // ALTERAR STATUS
  // ======================================================


  Future<void> alterarStatus(
    String id,
    bool ativa,
  ) async {


    final url = Uri.parse(
      '${ApiConfig.baseUrl}/promocoes/$id/status',
    );



    final resposta =
        await http.put(
      url,


      headers: const {

        'Content-Type':
            'application/json',

        'Accept':
            'application/json',

      },


      body:
          jsonEncode({

            'ativa':
                ativa,

          }),

    );




    if(resposta.statusCode != 200){

      throw Exception(
        'Erro ao alterar status',
      );

    }


  }





  // ======================================================
  // EXCLUIR PROMOÇÃO
  // ======================================================


  Future<void> excluirPromocao(
    String id,
  ) async {


    final url = Uri.parse(
      '${ApiConfig.baseUrl}/promocoes/$id',
    );



    final resposta =
        await http.delete(
      url,
    );



    if(resposta.statusCode != 200){

      throw Exception(
        'Erro ao excluir promoção',
      );

    }


  }



}