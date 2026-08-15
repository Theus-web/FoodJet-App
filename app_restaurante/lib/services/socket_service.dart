import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket;

  // ============================================================
  // CONECTAR
  // ============================================================

  void conectar({
    required String restauranteId,
    required Function(dynamic pedido) onNovoPedido,
  }) {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _socket = IO.io(
      'http://192.168.1.101:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('====================================');
      print('SOCKET RESTAURANTE CONECTADO');
      print('Restaurante: $restauranteId');
      print('====================================');

      _socket!.emit(
        'entrar_restaurante',
        restauranteId,
      );
    });

    _socket!.on(
      'novo_pedido',
      (data) {
        print('====================================');
        print('NOVO PEDIDO RECEBIDO');
        print(data);
        print('====================================');

        onNovoPedido(data);
      },
    );

    _socket!.onDisconnect((_) {
      print('Socket restaurante desconectado');
    });

    _socket!.onConnectError((erro) {
      print('Erro ao conectar Socket.IO: $erro');
    });
  }

  // ============================================================
  // DESCONECTAR
  // ============================================================

  void desconectar() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}