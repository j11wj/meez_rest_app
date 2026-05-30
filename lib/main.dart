import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/restaurant_provider.dart';
import 'screens/login_screen.dart';
import 'screens/orders_screen.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  await NotificationService().init();
  await FcmService().init();
  runApp(const MeezPosApp());
}

class MeezPosApp extends StatelessWidget {
  const MeezPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
      ],
      child: MaterialApp(
        title: 'Meez POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        darkTheme: AppTheme.theme,
        themeMode: ThemeMode.dark,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: _Splash(),
        ),
      ),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();
    if (!mounted) return;
    if (auth.isLoggedIn) {
      final orders = context.read<OrdersProvider>();
      orders.initSocket(auth.token);
      await orders.loadOrders(auth.token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 72, color: AppTheme.primary),
            SizedBox(height: 16),
            Text(
              'MEEZ POS',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
