import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/app_config.dart';

class SocketService {
  io.Socket? _socket;

  Function(Map<String, dynamic>)? onNewOrder;
  Function(Map<String, dynamic>)? onOrderStatusUpdate;

  void connect(String token) {
    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(10)
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {});
    _socket!.onDisconnect((_) {});
    _socket!.onConnectError((_) {});

    _socket!.on('restaurant_new_order', (data) {
      final map = _toMap(data);
      if (map != null) onNewOrder?.call(map);
    });

    _socket!.on('order_status_update', (data) {
      final map = _toMap(data);
      if (map != null) onOrderStatusUpdate?.call(map);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;

  Map<String, dynamic>? _toMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
}
