class Ganho {
  final double hoje;
  final double semana;
  final double mes;
  final double saldo;

  const Ganho({
    required this.hoje,
    required this.semana,
    required this.mes,
    required this.saldo,
  });

  factory Ganho.fromJson(Map<String, dynamic> json) {
    double n(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
    }

    return Ganho(
      hoje: n(json['hoje'] ?? json['today']),
      semana: n(json['semana'] ?? json['week']),
      mes: n(json['mes'] ?? json['month']),
      saldo: n(json['saldo'] ?? json['balance']),
    );
  }

  static const empty = Ganho(
    hoje: 0,
    semana: 0,
    mes: 0,
    saldo: 0,
  );
}
