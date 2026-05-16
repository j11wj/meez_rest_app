import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';

// معالج الخلفية — يجب أن يكون top-level function خارج أي class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase يعرض الإشعار تلقائياً في الخلفية بدون كود إضافي
}

class FcmService {
  static const _fcmTokenKey = 'res_fcm_token';

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();
  final ApiService _api = ApiService();

  Future<void> init() async {
    // 1. طلب صلاحية الإشعارات
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. معالج الرسائل في الخلفية
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. قناة Android عالية الأولوية
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

    // 4. تهيئة الـ local notifications للـ foreground
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotif.initialize(initSettings);

    // 5. استقبال الرسائل والتطبيق مفتوح (Foreground)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. عند فتح التطبيق من إشعار (Background → Foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 7. احفظ الـ token عند تجديده
    _fcm.onTokenRefresh.listen(_saveToken);

    // 8. جلب الـ token الحالي وحفظه
    final token = await _fcm.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveToken(token);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] ?? '';

    if (type == 'new_order') {
      // صوت + اهتزاز + إشعار محلي
      await NotificationService().notifyNewOrder(
        orderId: data['orderId'] ?? '',
        customerName: data['customerName'] ?? 'زبون',
        total: double.tryParse(data['total'] ?? '0') ?? 0,
      );
    } else {
      // أي إشعار آخر — اعرضه كإشعار عادي
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

  void _handleMessageOpenedApp(RemoteMessage message) {
    // يمكن إضافة navigation هنا لاحقاً
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
      id,
      title,
      body,
      const NotificationDetails(android: details),
    );
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  /// يُرسل الـ token للسيرفر — يُستدعى بعد اللوجن
  Future<void> registerTokenOnServer(String authToken) async {
    final fcmToken = await getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;
    await _api.registerFcmToken(fcmToken, authToken);
  }
}
