import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage _) async {}

class FcmService {
  static const _fcmTokenKey = 'res_fcm_token';

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();
  final ApiService _api = ApiService();

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  Future<void> init() async {
    if (!_isMobile) return;

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'new_orders',
        'طلبات جديدة',
        description: 'إشعارات الطلبات الواردة للمطعم',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );
      final androidPlugin = _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _localNotif.initialize(initSettings);
    }

    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    fcm.onTokenRefresh.listen(_saveToken);

    final token = await fcm.getToken();
    if (token != null && token.isNotEmpty) await _saveToken(token);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] ?? '';
    if (type == 'new_order') {
      await NotificationService().notifyNewOrder(
        orderId: data['orderId'] ?? '',
        customerName: data['customerName'] ?? 'زبون',
        total: double.tryParse(data['total'] ?? '0') ?? 0,
      );
    } else {
      final notification = message.notification;
      if (notification != null) {
        await _showLocalNotification(
          title: notification.title ?? 'إشعار',
          body: notification.body ?? '',
          id: message.hashCode,
        );
      }
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const details = AndroidNotificationDetails(
      'new_orders',
      'طلبات جديدة',
      channelDescription: 'إشعارات الطلبات الواردة للمطعم',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    await _localNotif.show(
        id, title, body, const NotificationDetails(android: details));
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  Future<String?> getToken() async {
    if (!_isMobile) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  Future<void> registerTokenOnServer(String authToken) async {
    final fcmToken = await getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;
    await _api.registerFcmToken(fcmToken, authToken);
  }
}
