import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProductService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/products';
    }

    return 'http://10.0.2.2:3000/api/products';
  }

  // ============================================================
  // LISTAR PRODUTOS
  // ============================================================

  Future<List<dynamic>> buscarProdutosRestaurante(
    String restauranteId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/restaurante/$restauranteId',
        ),
      );

      debugPrint(
        'LISTAR PRODUTOS: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);

        if (dados is List) {
          return dados;
        }

        if (dados is Map &&
            dados['produtos'] != null) {
          return dados['produtos'];
        }
      }

      return [];
    } catch (e) {
      debugPrint(
        'ERRO AO LISTAR PRODUTOS: $e',
      );

      return [];
    }
  }

  // ============================================================
  // COMPATIBILIDADE
  // ============================================================

  Future<List<dynamic>> buscarProdutos(
    String restauranteId,
  ) async {
    return buscarProdutosRestaurante(
      restauranteId,
    );
  }

  // ============================================================
  // CRIAR PRODUTO
  // ============================================================

  Future<bool> criarProduto(
    Map<String, dynamic> produto,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(produto),
      );

      debugPrint(
        'CRIAR PRODUTO: ${response.statusCode}',
      );

      debugPrint(
        'RESPOSTA: ${response.body}',
      );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      debugPrint(
        'ERRO CRIAR PRODUTO: $e',
      );

      return false;
    }
  }

  // ============================================================
  // CRIAR E RETORNAR
  // ============================================================

  Future<Map<String, dynamic>?>
      criarProdutoComRetorno(
    Map<String, dynamic> produto,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(produto),
      );

      debugPrint(
        'CRIAR PRODUTO STATUS: ${response.statusCode}',
      );

      debugPrint(
        'CRIAR PRODUTO RESPOSTA: ${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final dados =
            jsonDecode(response.body);

        if (dados is Map<String, dynamic>) {
          if (dados['produto'] is Map) {
            return Map<String, dynamic>.from(
              dados['produto'],
            );
          }

          return dados;
        }
      }

      return null;
    } catch (e) {
      debugPrint(
        'ERRO CRIAR PRODUTO: $e',
      );

      return null;
    }
  }

  // ============================================================
  // ATUALIZAR
  // ============================================================

  Future<bool> atualizarProduto(
    String id,
    Map<String, dynamic> produto,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(produto),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'ERRO ATUALIZAR PRODUTO: $e',
      );

      return false;
    }
  }

  // ============================================================
  // DISPONIBILIDADE
  // ============================================================

  Future<bool> alterarDisponibilidade(
    String id,
    bool disponivel,
  ) async {
    return atualizarProduto(
      id,
      {
        'disponivel': disponivel,
      },
    );
  }

  // ============================================================
  // DESTAQUE
  // ============================================================

  Future<bool> alterarDestaque(
    String id,
    bool destaque,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$baseUrl/$id/destaque',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'destaque': destaque,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'ERRO DESTAQUE: $e',
      );

      return false;
    }
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<bool> excluirProduto(
    String id,
  ) async {
    try {
      final response =
          await http.delete(
        Uri.parse('$baseUrl/$id'),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'ERRO EXCLUIR PRODUTO: $e',
      );

      return false;
    }
  }

  // ============================================================
  // UPLOAD DA IMAGEM
  // WEB + ANDROID
  // ============================================================

  Future<Map<String, dynamic>?>
      uploadImagem(
    String produtoId,
    XFile imagem,
    Uint8List bytes,
  ) async {
    try {
      debugPrint(
        'UPLOAD IMAGEM: $produtoId',
      );

      final request =
          http.MultipartRequest(
        'POST',
        Uri.parse(
          '$baseUrl/$produtoId/imagem',
        ),
      );

      final String nomeArquivo =
          imagem.name.isNotEmpty
              ? imagem.name
              : 'produto.jpg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'imagem',
          bytes,
          filename: nomeArquivo,
        ),
      );

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        'UPLOAD STATUS: ${response.statusCode}',
      );

      debugPrint(
        'UPLOAD RESPOSTA: ${response.body}',
      );

      if (response.statusCode == 200) {
        final dados =
            jsonDecode(response.body);

        if (dados is Map<String, dynamic>) {
          if (dados['produto'] is Map) {
            return Map<String, dynamic>.from(
              dados['produto'],
            );
          }

          return dados;
        }
      }

      return null;
    } catch (e) {
      debugPrint(
        'ERRO UPLOAD IMAGEM: $e',
      );

      return null;
    }
  }
}