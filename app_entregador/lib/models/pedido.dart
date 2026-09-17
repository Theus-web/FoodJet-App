class Pedido {
  final dynamic id;
  final String restaurante;
  final String cliente;
  final String enderecoRetirada;
  final String enderecoEntrega;
  final double valorEntrega;
  final double valorPedido;
  final double distanciaKm;
  final String pagamento;
  final String status;

  const Pedido({
    this.id,
    required this.restaurante,
    required this.cliente,
    required this.enderecoRetirada,
    required this.enderecoEntrega,
    required this.valorEntrega,
    required this.valorPedido,
    required this.distanciaKm,
    required this.pagamento,
    required this.status,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(
            value.toString().replaceAll(',', '.'),
          ) ??
          0;
    }

    return Pedido(
      id: json['id'] ?? json['pedidoId'] ?? json['pedido_id'],
      restaurante: (json['restauranteNome'] ??
              json['restaurante_nome'] ??
              json['restaurante'] ??
              'Restaurante')
          .toString(),
      cliente: (json['clienteNome'] ??
              json['cliente_nome'] ??
              json['cliente'] ??
              'Cliente')
          .toString(),
      enderecoRetirada: (json['enderecoRetirada'] ??
              json['endereco_retirada'] ??
              json['enderecoRestaurante'] ??
              '')
          .toString(),
      enderecoEntrega: (json['enderecoEntrega'] ??
              json['endereco_entrega'] ??
              json['endereco'] ??
              '')
          .toString(),
      valorEntrega: number(
        json['valorEntrega'] ?? json['taxaEntrega'] ?? json['valor_entrega'],
      ),
      valorPedido: number(
        json['valor'] ?? json['total'] ?? json['valorPedido'],
      ),
      distanciaKm: number(
        json['distanciaKm'] ?? json['distancia_km'] ?? json['distancia'],
      ),
      pagamento: (json['formaPagamento'] ??
              json['forma_pagamento'] ??
              json['pagamento'] ??
              'Não informado')
          .toString(),
      status: (json['status'] ?? 'DISPONIVEL').toString(),
    );
  }
}
