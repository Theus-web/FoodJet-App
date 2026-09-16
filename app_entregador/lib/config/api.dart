class Api {
  // ============================================================
  // BACKEND FOODJET
  // ============================================================

  static const String baseUrl =
      'http://192.168.1.101:3000/api';

  // ============================================================
  // AUTH
  // ============================================================

  static String login =
      '$baseUrl/auth/login';

  static String register =
      '$baseUrl/auth/register';

  static String perfil =
      '$baseUrl/auth/perfil';

  // ============================================================
  // ENTREGADOR
  // ============================================================

  static String entregadores =
      '$baseUrl/delivery';

  static String statusEntregador(String id) =>
      '$baseUrl/delivery/$id/status';

  static String pedidosEntregador(String id) =>
      '$baseUrl/delivery/$id/orders';
}