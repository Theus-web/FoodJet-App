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

  // Base das rotas de entregadores
  static String entregadores =
      '$baseUrl/delivery';

  // ============================================================
  // ONLINE / OFFLINE
  // ============================================================

  static String statusEntregador(String id) =>
      '$baseUrl/delivery/$id/status';

  // ============================================================
  // PEDIDOS DO ENTREGADOR
  // ============================================================

  static String pedidosEntregador(String id) =>
      '$baseUrl/delivery/$id/orders';

  // ============================================================
  // PEDIDOS DISPONÍVEIS
  // ============================================================

  static String pedidosDisponiveis =
      '$baseUrl/delivery/available/orders';

  // ============================================================
  // ACEITAR PEDIDO
  // ============================================================

  static String aceitarPedido(
    String entregadorId,
    String pedidoId,
  ) =>
      '$baseUrl/delivery/'
      '$entregadorId/orders/'
      '$pedidoId/accept';

  // ============================================================
  // CHEGUEI NO RESTAURANTE
  // ============================================================

  static String chegueiRestaurante(
    String pedidoId,
  ) =>
      '$baseUrl/delivery/orders/'
      '$pedidoId/arrived';

  // ============================================================
  // INICIAR ENTREGA
  // ============================================================

  static String iniciarEntrega(
    String pedidoId,
  ) =>
      '$baseUrl/delivery/orders/'
      '$pedidoId/start';

  // ============================================================
  // FINALIZAR ENTREGA
  // ============================================================

  static String finalizarEntrega(
    String pedidoId,
  ) =>
      '$baseUrl/delivery/orders/'
      '$pedidoId/finish';
}