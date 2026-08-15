import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ProductService {
static const String baseUrl =
'http://10.0.2.2:3000/api/products';

// ============================================================
// LISTAR PRODUTOS DO RESTAURANTE
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
} catch (_) {
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


  return response.statusCode == 200 ||
      response.statusCode == 201;
} catch (_) {
  return false;
}


}

// ============================================================
// CRIAR PRODUTO E RETORNAR DADOS
// ============================================================

Future<Map<String, dynamic>?> criarProdutoComRetorno(
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


  if (response.statusCode == 200 ||
      response.statusCode == 201) {
    final dados = jsonDecode(response.body);

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
} catch (_) {
  return null;
}


}

// ============================================================
// ATUALIZAR PRODUTO
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
} catch (_) {
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
} catch (_) {
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
final response = await http.delete(
Uri.parse('$baseUrl/$id'),
);


  return response.statusCode == 200;
} catch (_) {
  return false;
}


}

// ============================================================
// UPLOAD DA IMAGEM
// ============================================================

Future<Map<String, dynamic>?> uploadImagem(
String produtoId,
File imagem,
) async {
try {
final request = http.MultipartRequest(
'POST',
Uri.parse(
'$baseUrl/$produtoId/imagem',
),
);


  request.files.add(
    await http.MultipartFile.fromPath(
      'imagem',
      imagem.path,
    ),
  );

  final streamedResponse =
      await request.send();

  final response =
      await http.Response.fromStream(
    streamedResponse,
  );

  if (response.statusCode == 200) {
    final dados = jsonDecode(
      response.body,
    );

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
} catch (_) {
  return null;
}


}
}
