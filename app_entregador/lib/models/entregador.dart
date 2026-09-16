class Entregador {
  final dynamic id;
  final String nome;
  final String email;
  final String telefone;
  final String? cpf;
  final String? veiculo;
  final String? placa;
  final String status;
  final bool online;

  Entregador({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.cpf,
    this.veiculo,
    this.placa,
    required this.status,
    required this.online,
  });

  factory Entregador.fromJson(Map<String, dynamic> json) {
    return Entregador(
      id: json['id'],
      nome: json['nome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      telefone: json['telefone']?.toString() ?? '',
      cpf: json['cpf']?.toString(),
      veiculo: json['veiculo']?.toString(),
      placa: json['placa']?.toString(),
      status: json['status']?.toString() ?? 'DISPONIVEL',
      online: json['online'] == true,
    );
  }

  Entregador copyWith({
    bool? online,
    String? status,
  }) {
    return Entregador(
      id: id,
      nome: nome,
      email: email,
      telefone: telefone,
      cpf: cpf,
      veiculo: veiculo,
      placa: placa,
      status: status ?? this.status,
      online: online ?? this.online,
    );
  }
}