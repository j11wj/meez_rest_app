import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audio = AudioPlayer();
  bool _initialized = false;
  Timer? _alertTimer;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'new_orders',
      'طلبات جديدة',
      description: 'إشعارات الطلبات الواردة',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> notifyNewOrder({
    required String orderId,
    required String customerName,
    required double total,
  }) async {
    // إيقاف أي تنبيه سابق لم ينته بعد
    await stopAlert();

    // إشعار في شريط الحالة (مرة واحدة كافية)
    try {
      final details = AndroidNotificationDetails(
        'new_orders',
        'طلبات جديدة',
        channelDescription: 'إشعارات الطلبات الواردة',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        color: const Color(0xFF1A237E),
        ledColor: const Color(0xFF1A237E),
        ledOnMs: 500,
        ledOffMs: 500,
        ticker: 'طلب جديد',
        icon: '@mipmap/ic_launcher',
        // إبقاء الإشعار 30 ثانية ثم يختفي تلقائياً
        timeoutAfter: 30000,
      );

      await _notifications.show(
        orderId.hashCode,
        'طلب جديد',
        '$customerName — ${total.toStringAsFixed(0)} IQD',
        NotificationDetails(android: details),
      );
    } catch (_) {}

    // صوت + اهتزاز يتكرران كل 3 ثوانٍ لمدة 30 ثانية
    final stopAt = DateTime.now().add(const Duration(seconds: 30));

    Future<void> playOnce() async {
      try {
        await _audio.stop();
        await _audio.play(AssetSource('sounds/new_order.wav'));
      } catch (_) {}
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator) {
          await Vibration.vibrate(pattern: [0, 400, 200, 400, 200, 400]);
        }
      } catch (_) {}
    }

    // تشغيل فوري
    await playOnce();

    // تكرار كل 3 ثوانٍ حتى انتهاء المدة
    _alertTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (DateTime.now().isAfter(stopAt)) {
        await stopAlert();
        return;
      }
      await playOnce();
    });
  }

  Future<void> stopAlert() async {
    _alertTimer?.cancel();
    _alertTimer = null;
    try {
      await _audio.stop();
    } catch (_) {}
    try {
      await Vibration.cancel();
    } catch (_) {}
  }
}
