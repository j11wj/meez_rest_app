import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/auth_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/restaurant_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  final String _base = AppConfig.baseUrl;

  Map<String, String> _headers([String? token]) {
    final h = {'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Future<AuthUser> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(body['message']?.toString() ?? 'فشل تسجيل الدخول', res.statusCode);
    }
    final token = body['access_token'] ?? body['token'] ?? '';
    return AuthUser.fromJson(body, token);
  }

  Future<String?> refreshToken(String userId, String refreshToken) async {
    final res = await http.post(
      Uri.parse('$_base/auth/refresh'),
      headers: _headers(),
      body: jsonEncode({'userId': userId, 'refreshToken': refreshToken}),
    );
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['access_token'] as String?;
  }

  Future<void> registerFcmToken(String fcmToken, String token) async {
    try {
      await http.patch(
        Uri.parse('$_base/restaurants/me/fcm-token'),
        headers: _headers(token),
        body: jsonEncode({'fcmToken': fcmToken}),
      );
    } catch (_) {}
  }

  Future<void> logout(String userId, String refreshToken) async {
    try {
      await http.post(
        Uri.parse('$_base/auth/logout'),
        headers: _headers(),
        body: jsonEncode({'userId': userId, 'refreshToken': refreshToken}),
      );
    } catch (_) {}
  }

  Future<List<Order>> getOrders(String token) async {
    final res = await http.get(
      Uri.parse('$_base/orders'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw ApiException('Failed to load orders', res.statusCode);
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> getOrder(String id, String token) async {
    final res = await http.get(
      Uri.parse('$_base/orders/$id'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw ApiException('Order not found', res.statusCode);
    }
    return Order.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Order> updateOrderStatus(String id, String status, String token) async {
    final res = await http.patch(
      Uri.parse('$_base/orders/$id/status'),
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(body['message']?.toString() ?? 'Failed to update status', res.statusCode);
    }
    return Order.fromJson(body);
  }

  // ── Restaurant ──────────────────────────────────────────────────────────────

  Future<MyRestaurant> getMyRestaurant(String token) async {
    final res = await http.get(
      Uri.parse('$_base/restaurants/me'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw ApiException('Failed to load restaurant', res.statusCode);
    }
    return MyRestaurant.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<MyRestaurant> toggleOpen(String restaurantId, String token) async {
    final res = await http.patch(
      Uri.parse('$_base/restaurants/$restaurantId/toggle-open'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw ApiException('Failed to toggle status', res.statusCode);
    }
    return MyRestaurant.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Menu Items ───────────────────────────────────────────────────────────────

  Future<List<MenuItem>> getMenuItems(String restaurantId, String token) async {
    final res = await http.get(
      Uri.parse('$_base/menu-items?restaurantId=$restaurantId'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw ApiException('Failed to load menu', res.statusCode);
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MenuItem> createMenuItem(Map<String, dynamic> data, String token) async {
    final res = await http.post(
      Uri.parse('$_base/menu-items'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw ApiException(body['message']?.toString() ?? 'Failed to create item', res.statusCode);
    }
    return MenuItem.fromJson(body);
  }

  Future<MenuItem> updateMenuItem(String id, Map<String, dynamic> data, String token) async {
    final res = await http.patch(
      Uri.parse('$_base/menu-items/$id'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(body['message']?.toString() ?? 'Failed to update item', res.statusCode);
    }
    return MenuItem.fromJson(body);
  }

  Future<void> toggleMenuItemAvailability(String id, String token) async {
    final res = await http.patch(
      Uri.parse('$_base/menu-items/$id/toggle-availability'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw ApiException('Failed to toggle item', res.statusCode);
    }
  }

  Future<void> deleteMenuItem(String id, String token) async {
    final res = await http.delete(
      Uri.parse('$_base/menu-items/$id'),
      headers: _headers(token),
    );
    if (res.statusCode != 204) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException(body['message']?.toString() ?? 'Failed to delete item', res.statusCode);
    }
  }

  // ── Zones ────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getZones(String token) async {
    final res = await http.get(
      Uri.parse('$_base/zones'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw ApiException('فشل تحميل المناطق', res.statusCode);
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getZonePricings(String token) async {
    final res = await http.get(
      Uri.parse('$_base/zones/pricing/all'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ── Driver-only order ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> requestDriverOnly({
    required String token,
    required String toZoneId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String farePayedBy,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/orders/restaurant/request-driver'),
      headers: _headers(token),
      body: jsonEncode({
        'toZoneId': toZoneId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerAddress': customerAddress,
        'farePayedBy': farePayedBy,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException(body['message']?.toString() ?? 'فشل إرسال الطلب', res.statusCode);
    }
    return body;
  }
}
