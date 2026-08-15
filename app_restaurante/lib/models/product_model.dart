class ProductModel {
  final String id;
  final String restauranteId;
  final String nome;
  final String descricao;
  final double preco;
  final String categoria;
  final String? imagem;
  final bool disponivel;
  final bool destaque;

  ProductModel({
    required this.id,
    required this.restauranteId,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.categoria,
    this.imagem,
    required this.disponivel,
    required this.destaque,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json["id"].toString(),
      restauranteId: json["restauranteId"].toString(),
      nome: json["nome"] ?? "",
      descricao: json["descricao"] ?? "",
      preco: (json["preco"] as num).toDouble(),
      categoria: json["categoria"] ?? "",
      imagem: json["imagem"],
      disponivel: json["disponivel"] ?? true,
      destaque: json["destaque"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "restauranteId": restauranteId,
      "nome": nome,
      "descricao": descricao,
      "preco": preco,
      "categoria": categoria,
      "imagem": imagem,
      "disponivel": disponivel,
      "destaque": destaque,
    };
  }

  ProductModel copyWith({
    String? id,
    String? restauranteId,
    String? nome,
    String? descricao,
    double? preco,
    String? categoria,
    String? imagem,
    bool? disponivel,
    bool? destaque,
  }) {
    return ProductModel(
      id: id ?? this.id,
      restauranteId: restauranteId ?? this.restauranteId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      categoria: categoria ?? this.categoria,
      imagem: imagem ?? this.imagem,
      disponivel: disponivel ?? this.disponivel,
      destaque: destaque ?? this.destaque,
    );
  }
}