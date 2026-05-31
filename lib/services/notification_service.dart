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

  bool get _isAndroid => Platform.isAndroid;
  bool get _isMacOS => Platform.isMacOS;
  bool get _isWindows => Platform.isWindows;
  bool get _isDesktop => _isMacOS || _isWindows;

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

    // إشعار النظام
    try {
      if (_isDesktop) {
        _showDesktopNotification(
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

    // صوت + اهتزاز يتكرران كل 3 ثوانٍ لمدة 30 ثانية
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

  void _showDesktopNotification(String title, String body) {
    try {
      if (_isMacOS) {
        // macOS: osascript — لا يحتاج أي package
        Process.run('osascript', [
          '-e',
          'display notification "$body" with title "$title" sound name "Glass"',
        ]);
      } else if (_isWindows) {
        // Windows: PowerShell toast
        final xml = '<toast><visual><binding template="ToastGeneric">'
            '<text>$title</text><text>$body</text>'
            '</binding></visual></toast>';
        final script = '[Windows.UI.Notifications.ToastNotificationManager,'
            'Windows.UI.Notifications,ContentType=WindowsRuntime]|Out-Null;'
            '[Windows.Data.Xml.Dom.XmlDocument,'
            'Windows.Data.Xml.Dom,ContentType=WindowsRuntime]|Out-Null;'
            r'$x=New-Object Windows.Data.Xml.Dom.XmlDocument;'
            '\$x.LoadXml(\'$xml\');'
            r'[Windows.UI.Notifications.ToastNotificationManager]'
            r'::CreateToastNotifier("Meez POS").Show('
            r'[Windows.UI.Notifications.ToastNotification]::new($x));';
        Process.run('powershell', ['-Command', script]);
      }
    } catch (_) {}
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
