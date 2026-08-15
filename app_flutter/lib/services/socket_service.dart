import 'package:socket_io_client/socket_io_client.dart' as io;


class SocketService {


  io.Socket? socket;


  final String serverUrl =
      "http://192.168.1.101:3000";



  void connect() {


    if (socket != null &&
        socket!.connected) {

      return;

    }



    socket = io.io(

      serverUrl,

      io.OptionBuilder()

          .setTransports(
            ['websocket'],
          )

          .enableAutoConnect()

          .enableReconnection()

          .build(),

    );



    socket!.onConnect((_) {

      print(
        "🟢 FoodJet WebSocket conectado",
      );


    });



    socket!.onDisconnect((_) {


      print(
        "🔴 FoodJet WebSocket desconectado",
      );


    });



    socket!.onConnectError((erro) {


      print(
        "❌ Erro WebSocket: $erro",
      );


    });


  }





  void onNovoPedido(
      Function(dynamic pedido) callback,
      ) {


    socket?.on(

      "novo_pedido",

      (pedido) {


        print(
          "📦 Novo pedido recebido:",
        );


        callback(pedido);


      },

    );


  }





  void disconnect(){


    socket?.disconnect();


    socket = null;


  }


}