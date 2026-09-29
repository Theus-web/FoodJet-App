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

  // ==========================================================
  // CONVERTER NÚMERO
  // ==========================================================

  static double _number(dynamic value) {
  if (value == null) {
    return 0.0;
  }

  if (value is num) {
    return value.toDouble();
  }

  String texto = value.toString().trim();

  if (texto.isEmpty) {
    return 0.0;
  }

  // Remove símbolo da moeda
  texto = texto.replaceAll('R\$', '');
  texto = texto.trim();

  // ==========================================================
  // FORMATO BRASILEIRO
  // Exemplo:
  // 50,00
  // 1.250,50
  // ==========================================================

  if (texto.contains(',')) {
    texto = texto.replaceAll('.', '');
    texto = texto.replaceAll(',', '.');

    return double.tryParse(texto) ?? 0.0;
  }

  // ==========================================================
  // FORMATO DECIMAL NORMAL
  // Exemplo:
  // 50.00
  // 5.01
  // 12.50
  // ==========================================================

  return double.tryParse(texto) ?? 0.0;
}

  // ==========================================================
  // PEGAR TEXTO
  // ==========================================================

  static String _text(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    if (value is String) {
      final texto = value.trim();

      if (texto.isEmpty) {
        return fallback;
      }

      return texto;
    }

    return value.toString();
  }

  // ==========================================================
  // PEGAR VALOR DE MAPA
  // ==========================================================

  static dynamic _mapValue(
    dynamic value,
    List<String> keys,
  ) {
    if (value is! Map) {
      return null;
    }

    for (final key in keys) {
      if (value.containsKey(key) &&
          value[key] != null) {
        return value[key];
      }
    }

    return null;
  }

  // ==========================================================
  // NOME DO RESTAURANTE
  // ==========================================================

  static String _restauranteNome(
    Map<String, dynamic> json,
  ) {
    // --------------------------------------------------------
    // Campos diretos
    // --------------------------------------------------------

    final direto =
        json['restauranteNome'] ??
        json['restaurante_nome'] ??
        json['nome_restaurante'];

    if (direto != null &&
        direto.toString().trim().isNotEmpty) {
      return direto.toString().trim();
    }

    // --------------------------------------------------------
    // Restaurante como objeto
    // --------------------------------------------------------

    final restaurante =
        json['restaurante'];

    final nomeObjeto = _mapValue(
      restaurante,
      [
        'nome',
        'name',
        'nome_restaurante',
      ],
    );

    if (nomeObjeto != null &&
        nomeObjeto.toString().trim().isNotEmpty) {
      return nomeObjeto.toString().trim();
    }

    return 'Restaurante';
  }

  // ==========================================================
  // NOME DO CLIENTE
  // ==========================================================

  static String _clienteNome(
    Map<String, dynamic> json,
  ) {
    // --------------------------------------------------------
    // Campos diretos
    // --------------------------------------------------------

    final direto =
        json['clienteNome'] ??
        json['cliente_nome'] ??
        json['nome_cliente'];

    if (direto != null &&
        direto.toString().trim().isNotEmpty) {
      return direto.toString().trim();
    }

    // --------------------------------------------------------
    // Cliente como objeto
    // --------------------------------------------------------

    final cliente =
        json['cliente'];

    final nomeObjeto = _mapValue(
      cliente,
      [
        'nome',
        'name',
        'nome_cliente',
      ],
    );

    if (nomeObjeto != null &&
        nomeObjeto.toString().trim().isNotEmpty) {
      return nomeObjeto.toString().trim();
    }

    return 'Cliente';
  }

  // ==========================================================
  // ENDEREÇO DO RESTAURANTE
  // ==========================================================

  static String _enderecoRetirada(
    Map<String, dynamic> json,
  ) {
    // --------------------------------------------------------
    // Campos diretos
    // --------------------------------------------------------

    final direto =
        json['enderecoRetirada'] ??
        json['endereco_retirada'] ??
        json['enderecoRestaurante'] ??
        json['endereco_restaurante'] ??
        json['endereco_coleta'] ??
        json['enderecoOrigem'] ??
        json['endereco_origem'];

    final enderecoDireto =
        _formatarEndereco(direto);

    if (enderecoDireto.isNotEmpty) {
      return enderecoDireto;
    }

    // --------------------------------------------------------
    // Restaurante como objeto
    // --------------------------------------------------------

    final restaurante =
        json['restaurante'];

    final enderecoObjeto =
        _mapValue(
          restaurante,
          [
            'endereco',
            'endereco_completo',
            'enderecoCompleto',
            'address',
            'logradouro',
          ],
        );

    final resultado =
        _formatarEndereco(enderecoObjeto);

    if (resultado.isNotEmpty) {
      return resultado;
    }

    return 'Endereço de retirada não informado';
  }

  // ==========================================================
  // ENDEREÇO DO CLIENTE
  // ==========================================================

  static String _enderecoEntrega(
    Map<String, dynamic> json,
  ) {
    // --------------------------------------------------------
    // Campos diretos
    // --------------------------------------------------------

    final direto =
        json['enderecoEntrega'] ??
        json['endereco_entrega'] ??
        json['enderecoDestino'] ??
        json['endereco_destino'];

    final enderecoDireto =
        _formatarEndereco(direto);

    if (enderecoDireto.isNotEmpty) {
      return enderecoDireto;
    }

    // --------------------------------------------------------
    // Campo genérico "endereco"
    // --------------------------------------------------------

    final endereco =
        json['endereco'];

    final resultado =
        _formatarEndereco(endereco);

    if (resultado.isNotEmpty) {
      return resultado;
    }

    return 'Endereço de entrega não informado';
  }

  // ==========================================================
  // FORMATAR ENDEREÇO
  // ==========================================================

  static String _formatarEndereco(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    // --------------------------------------------------------
    // String
    // --------------------------------------------------------

    if (value is String) {
      return value.trim();
    }

    // --------------------------------------------------------
    // Objeto / Map
    // --------------------------------------------------------

    if (value is Map) {
      final partes = <String>[];

      final logradouro =
          _mapValue(
            value,
            [
              'logradouro',
              'rua',
              'endereco',
              'address',
            ],
          );

      final numero =
          _mapValue(
            value,
            [
              'numero',
              'número',
            ],
          );

      final complemento =
          _mapValue(
            value,
            [
              'complemento',
              'complement',
            ],
          );

      final bairro =
          _mapValue(
            value,
            [
              'bairro',
              'neighborhood',
            ],
          );

      final cidade =
          _mapValue(
            value,
            [
              'cidade',
              'city',
            ],
          );

      final estado =
          _mapValue(
            value,
            [
              'estado',
              'uf',
              'state',
            ],
          );

      final cep =
          _mapValue(
            value,
            [
              'cep',
              'CEP',
              'zipCode',
            ],
          );

      if (logradouro != null &&
          logradouro.toString().trim().isNotEmpty) {
        partes.add(
          logradouro.toString().trim(),
        );
      }

      if (numero != null &&
          numero.toString().trim().isNotEmpty) {
        partes.add(
          numero.toString().trim(),
        );
      }

      if (complemento != null &&
          complemento.toString().trim().isNotEmpty) {
        partes.add(
          complemento.toString().trim(),
        );
      }

      if (bairro != null &&
          bairro.toString().trim().isNotEmpty) {
        partes.add(
          bairro.toString().trim(),
        );
      }

      if (cidade != null &&
          cidade.toString().trim().isNotEmpty) {
        partes.add(
          cidade.toString().trim(),
        );
      }

      if (estado != null &&
          estado.toString().trim().isNotEmpty) {
        partes.add(
          estado.toString().trim(),
        );
      }

      if (cep != null &&
          cep.toString().trim().isNotEmpty) {
        partes.add(
          'CEP ${cep.toString().trim()}',
        );
      }

      return partes.join(', ');
    }

    return value.toString().trim();
  }

  // ==========================================================
  // FORMA DE PAGAMENTO
  // ==========================================================

  static String _pagamento(
    Map<String, dynamic> json,
  ) {
    final pagamento =
        json['formaPagamento'] ??
        json['forma_pagamento'] ??
        json['pagamento'] ??
        json['metodoPagamento'] ??
        json['metodo_pagamento'];

    if (pagamento is Map) {
      final tipo = _mapValue(
        pagamento,
        [
          'tipo',
          'forma',
          'nome',
          'name',
        ],
      );

      if (tipo != null) {
        return tipo.toString();
      }
    }

    final resultado =
        _text(
          pagamento,
          fallback: 'Não informado',
        );

    return resultado;
  }

  // ==========================================================
  // FACTORY
  // ==========================================================

  factory Pedido.fromJson(
    Map<String, dynamic> json,
  ) {
    return Pedido(
      // ------------------------------------------------------
      // ID
      // ------------------------------------------------------

      id:
          json['id'] ??
          json['pedidoId'] ??
          json['pedido_id'],

      // ------------------------------------------------------
      // RESTAURANTE
      // ------------------------------------------------------

      restaurante:
          _restauranteNome(json),

      // ------------------------------------------------------
      // CLIENTE
      // ------------------------------------------------------

      cliente:
          _clienteNome(json),

      // ------------------------------------------------------
      // RETIRADA
      // ------------------------------------------------------

      enderecoRetirada:
          _enderecoRetirada(json),

      // ------------------------------------------------------
      // ENTREGA
      // ------------------------------------------------------

      enderecoEntrega:
          _enderecoEntrega(json),

      // ------------------------------------------------------
      // VALOR DA ENTREGA
      // ------------------------------------------------------

      valorEntrega:
          _number(
            json['valorEntrega'] ??
            json['valor_entrega'] ??
            json['taxaEntrega'] ??
            json['taxa_entrega'] ??
            json['taxa'] ??
            json['valor_entregador'] ??
            json['valor_entregador_total'],
          ),

      // ------------------------------------------------------
      // VALOR DO PEDIDO
      // ------------------------------------------------------

      valorPedido:
          _number(
            json['valorPedido'] ??
            json['valor_pedido'] ??
            json['total'] ??
            json['valor'] ??
            json['valor_total'],
          ),

      // ------------------------------------------------------
      // DISTÂNCIA
      // ------------------------------------------------------

      distanciaKm:
          _number(
            json['distanciaKm'] ??
            json['distancia_km'] ??
            json['distancia'] ??
            json['distanciaEntrega'] ??
            json['distancia_entrega'],
          ),

      // ------------------------------------------------------
      // PAGAMENTO
      // ------------------------------------------------------

      pagamento:
          _pagamento(json),

      // ------------------------------------------------------
      // STATUS
      // ------------------------------------------------------

      status:
          _text(
            json['status'],
            fallback: 'PRONTO',
          ).toUpperCase(),
    );
  }
}