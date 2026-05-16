class MenuOptionRow {
  final String name;
  final double price;

  MenuOptionRow({required this.name, required this.price});

  factory MenuOptionRow.fromJson(Map<String, dynamic> j) => MenuOptionRow(
        name: j['name']?.toString() ?? '',
        price: _toDouble(j['price']),
      );

  Map<String, dynamic> toJson() => {'name': name, 'price': price};
}

class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final String? image;
  final double price;
  final String? category;
  final bool isAvailable;
  final List<MenuOptionRow> suggestedSauces;
  final List<MenuOptionRow> suggestedAddons;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    this.image,
    required this.price,
    this.category,
    required this.isAvailable,
    required this.suggestedSauces,
    required this.suggestedAddons,
  });

  factory MenuItem.fromJson(Map<String, dynamic> j) {
    return MenuItem(
      id: j['id'] ?? '',
      restaurantId: j['restaurantId'] ?? '',
      name: j['name'] ?? '',
      description: j['description'],
      image: j['image'],
      price: _toDouble(j['price']),
      category: j['category'],
      isAvailable: j['isAvailable'] ?? true,
      suggestedSauces: _parseOptions(j['suggestedSauces']),
      suggestedAddons: _parseOptions(j['suggestedAddons']),
    );
  }

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isAvailable,
    List<MenuOptionRow>? suggestedSauces,
    List<MenuOptionRow>? suggestedAddons,
  }) =>
      MenuItem(
        id: id,
        restaurantId: restaurantId,
        name: name ?? this.name,
        description: description ?? this.description,
        image: image,
        price: price ?? this.price,
        category: category ?? this.category,
        isAvailable: isAvailable ?? this.isAvailable,
        suggestedSauces: suggestedSauces ?? this.suggestedSauces,
        suggestedAddons: suggestedAddons ?? this.suggestedAddons,
      );
}

List<MenuOptionRow> _parseOptions(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MenuOptionRow.fromJson)
        .toList();
  }
  return [];
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
