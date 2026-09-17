import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api.dart';
import 'auth_service.dart';

class SocketService {
  io.Socket? _socket;

  io.Socket? get socket => _socket;

  Future<void> connect({
    required void Function(dynamic data) onNewDelivery,
    void Function(dynamic data)? onCancelled,
    void Function(dynamic data)? onConnected,
  }) async {
    // Evita abrir mais de uma conexão.
    if (_socket?.connected == true) {
      return;
    }

    final token = await AuthService.getToken();

    // Api.baseUrl normalmente termina em /api.
    // O Socket.IO roda na raiz do backend, então removemos /api.
    final socketUrl = Api.baseUrl.endsWith('/api')
        ? Api.baseUrl.substring(
            0,
            Api.baseUrl.length - 4,
          )
        : Api.baseUrl;

    _socket?.disconnect();
    _socket?.dispose();

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({
            'token': token,
          })
          .setExtraHeaders({
            'Authorization': token == null
                ? ''
                : 'Bearer $token',
          })
          .build(),
    );

    _socket!.onConnect((dynamic data) {
      onConnected?.call(data);
    });

    _socket!.onConnectError((dynamic data) {
      // Mantemos o erro no Socket.IO sem derrubar o aplicativo.
      // A conexão poderá ser restabelecida automaticamente.
    });

    _socket!.onError((dynamic data) {
      // Erros do Socket.IO não devem interromper a interface.
    });

    // Evento específico para entregadores.
    _socket!.on(
      'novo_pedido_entregador',
      onNewDelivery,
    );

    // Mantém compatibilidade com o evento geral de pedidos.
    _socket!.on(
      'novo_pedido',
      onNewDelivery,
    );

    // Cancelamento de pedido.
    _socket!.on(
      'pedido_cancelado',
      (dynamic data) {
        onCancelled?.call(data);
      },
    );

    _socket!.connect();
  }

  void emit(
    String event,
    dynamic data,
  ) {
    if (_socket?.connected != true) {
      return;
    }

    _socket!.emit(
      event,
      data,
    );
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}