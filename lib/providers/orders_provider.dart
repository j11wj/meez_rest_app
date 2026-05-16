import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';

class OrdersProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();
  final NotificationService _notif = NotificationService();

  List<Order> _orders = [];
  bool _loading = false;
  String? _error;
  bool _socketConnected = false;

  List<Order> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;
  bool get socketConnected => _socketConnected;

  List<Order> get pendingOrders =>
      _orders.where((o) => o.status == 'PENDING').toList();
  List<Order> get activeOrders => _orders
      .where((o) => o.status == 'ACCEPTED' || o.status == 'ON_THE_WAY')
      .toList();
  List<Order> get doneOrders => _orders
      .where((o) => o.status == 'DELIVERED' || o.status == 'CANCELED')
      .toList();

  void initSocket(String token) {
    _socket.onNewOrder = (data) {
      final orderData = data['order'] as Map<String, dynamic>?;
      if (orderData == null) return;
      final newOrder = Order.fromJson(orderData);
      final exists = _orders.any((o) => o.id == newOrder.id);
      if (!exists) {
        _orders.insert(0, newOrder);
        notifyListeners();
        // إشعار + صوت + اهتزاز
        _notif.notifyNewOrder(
          orderId: newOrder.id,
          customerName: newOrder.customer?.name ?? 'زبون',
          total: newOrder.total,
        );
      }
    };

    _socket.onOrderStatusUpdate = (data) {
      final orderId = data['orderId'] as String?;
      final status = data['status'] as String?;
      if (orderId == null || status == null) return;
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final orderData = data['order'] as Map<String, dynamic>?;
        if (orderData != null) {
          _orders[idx] = Order.fromJson(orderData);
        }
        notifyListeners();
      }
    };

    _socket.connect(token);
    _socketConnected = true;
    notifyListeners();
  }

  Future<void> loadOrders(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _api.getOrders(token);
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'فشل تحميل الطلبات';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> updateStatus(String orderId, String status, String token) async {
    try {
      final updated = await _api.updateOrderStatus(orderId, status, token);
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _orders[idx] = updated;
        notifyListeners();
      }
      // إيقاف التنبيه فور قبول أو إلغاء الطلب
      if (status == 'ACCEPTED' || status == 'CANCELED') {
        await _notif.stopAlert();
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }

  Order? findById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  void disposeSocket() {
    _socket.disconnect();
    _socketConnected = false;
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }
}
