class OrderItem {
  final String id;
  final String menuItemId;
  final String menuItemName;
  final double price;
  final int quantity;
  final double extrasPrice;
  final String? notes;

  OrderItem({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.price,
    required this.quantity,
    required this.extrasPrice,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final mi = json['menuItem'] as Map<String, dynamic>? ?? {};
    return OrderItem(
      id: json['id'] ?? '',
      menuItemId: json['menuItemId'] ?? '',
      menuItemName: mi['name'] ?? 'Item',
      price: _toDouble(json['price']),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      extrasPrice: _toDouble(json['extrasPrice']),
      notes: json['notes'],
    );
  }

  double get itemTotal => (price + extrasPrice) * quantity;
}

class RestaurantInfo {
  final String id;
  final String name;
  final String? image;
  final String? phone;
  final String? address;

  RestaurantInfo({
    required this.id,
    required this.name,
    this.image,
    this.phone,
    this.address,
  });

  factory RestaurantInfo.fromJson(Map<String, dynamic> json) {
    return RestaurantInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      phone: json['phone'],
      address: json['address'],
    );
  }
}

class CustomerInfo {
  final String id;
  final String name;
  final String? phone;

  CustomerInfo({required this.id, required this.name, this.phone});

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
    );
  }
}

class Order {
  final String id;
  final String status;
  final double subtotal;
  final double fare;
  final double discount;
  final double total;
  final String paymentMethod;
  final String? description;
  final CustomerInfo? customer;
  final RestaurantInfo? restaurant;
  final List<OrderItem> items;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.status,
    required this.subtotal,
    required this.fare,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    this.description,
    this.customer,
    this.restaurant,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return Order(
      id: json['id'] ?? '',
      status: json['status'] ?? 'PENDING',
      subtotal: _toDouble(json['subtotal']),
      fare: _toDouble(json['fare']),
      discount: _toDouble(json['discount']),
      total: _toDouble(json['total']),
      paymentMethod: json['paymentMethod'] ?? 'CASH',
      description: json['description'],
      customer: json['customer'] != null
          ? CustomerInfo.fromJson(json['customer'])
          : null,
      restaurant: json['restaurant'] != null
          ? RestaurantInfo.fromJson(json['restaurant'])
          : null,
      items: itemsJson.map((e) => OrderItem.fromJson(e)).toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get shortId => id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
