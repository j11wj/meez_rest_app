import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';
import '../models/restaurant_model.dart';
import '../services/api_service.dart';

class RestaurantProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  MyRestaurant? _restaurant;
  List<MenuItem> _menuItems = [];
  bool _loading = false;
  bool _menuLoading = false;
  String? _error;

  MyRestaurant? get restaurant => _restaurant;
  List<MenuItem> get menuItems => _menuItems;
  bool get loading => _loading;
  bool get menuLoading => _menuLoading;
  String? get error => _error;

  Future<void> loadRestaurant(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _restaurant = await _api.getMyRestaurant(token);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load restaurant';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> toggleOpen(String token) async {
    if (_restaurant == null) return false;
    try {
      _restaurant = await _api.toggleOpen(_restaurant!.id, token);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMenuItems(String token) async {
    if (_restaurant == null) return;
    _menuLoading = true;
    notifyListeners();
    try {
      _menuItems = await _api.getMenuItems(_restaurant!.id, token);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load menu';
    }
    _menuLoading = false;
    notifyListeners();
  }

  Future<bool> createItem(Map<String, dynamic> data, String token) async {
    try {
      final item = await _api.createMenuItem(data, token);
      _menuItems.insert(0, item);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(String id, Map<String, dynamic> data, String token) async {
    try {
      final updated = await _api.updateMenuItem(id, data, token);
      final idx = _menuItems.indexWhere((m) => m.id == id);
      if (idx != -1) _menuItems[idx] = updated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleItemAvailability(String id, String token) async {
    try {
      await _api.toggleMenuItemAvailability(id, token);
      final idx = _menuItems.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _menuItems[idx] = _menuItems[idx].copyWith(
          isAvailable: !_menuItems[idx].isAvailable,
        );
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String id, String token) async {
    try {
      await _api.deleteMenuItem(id, token);
      _menuItems.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
