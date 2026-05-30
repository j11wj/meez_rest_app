import 'dart:async';
import 'dart:io';
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

  bool get _isWindows => Platform.isWindows;
  bool get _isAndroid => Platform.isAndroid;

  Future<void> init() async {
    if (_initialized) return;

    if (_isAndroid) {
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
    }

    _initialized = true;
  }

  Future<void> notifyNewOrder({
    required String orderId,
    required String customerName,
    required double total,
  }) async {
    await stopAlert();

    try {
      if (_isWindows) {
        // Windows toast via PowerShell — no extra package needed
        _showWindowsToast(
          'طلب جديد!',
          '$customerName — ${total.toStringAsFixed(0)} IQD',
        );
      } else if (_isAndroid) {
        final details = AndroidNotificationDetails(
          'new_orders',
          'طلبات جديدة',
          channelDescription: 'إشعارات الطلبات الواردة',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          color: const Color(0xFFFCC050),
          ledColor: const Color(0xFFFCC050),
          ledOnMs: 500,
          ledOffMs: 500,
          ticker: 'طلب جديد',
          icon: '@mipmap/ic_launcher',
          timeoutAfter: 30000,
        );
        await _notifications.show(
          orderId.hashCode,
          'طلب جديد',
          '$customerName — ${total.toStringAsFixed(0)} IQD',
          NotificationDetails(android: details),
        );
      }
    } catch (_) {}

    final stopAt = DateTime.now().add(const Duration(seconds: 30));

    Future<void> playOnce() async {
      try {
        await _audio.stop();
        await _audio.play(AssetSource('sounds/new_order.wav'));
      } catch (_) {}
      if (_isAndroid) {
        try {
          final hasVibrator = await Vibration.hasVibrator();
          if (hasVibrator == true) {
            Vibration.vibrate(pattern: [0, 400, 200, 400, 200, 400]);
          }
        } catch (_) {}
      }
    }

    await playOnce();

    _alertTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (DateTime.now().isAfter(stopAt)) {
        await stopAlert();
        return;
      }
      await playOnce();
    });
  }

  void _showWindowsToast(String title, String body) {
    // Fire-and-forget PowerShell toast — no extra package needed
    final script =
        '[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null;'
        '[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType=WindowsRuntime] | Out-Null;'
        r'$xml = New-Object Windows.Data.Xml.Dom.XmlDocument;'
        r'$xml.LoadXml("<toast><visual><binding template=""ToastGeneric"">'
        '<text>$title</text><text>$body</text>'
        r'</binding></visual></toast>");'
        r'$toast = [Windows.UI.Notifications.ToastNotification]::new($xml);'
        r'[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Meez POS").Show($toast);';
    Process.run('powershell', ['-Command', script]);
  }

  Future<void> stopAlert() async {
    _alertTimer?.cancel();
    _alertTimer = null;
    try {
      await _audio.stop();
    } catch (_) {}
    if (_isAndroid) {
      try {
        Vibration.cancel();
      } catch (_) {}
    }
  }
}
