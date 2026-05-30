class MyRestaurant {
  final String id;
  final String name;
  final bool isOpen;
  final bool isActive;
  final String? image;
  final String? address;
  final String? phone;
  final String? zoneId;

  MyRestaurant({
    required this.id,
    required this.name,
    required this.isOpen,
    required this.isActive,
    this.image,
    this.address,
    this.phone,
    this.zoneId,
  });

  factory MyRestaurant.fromJson(Map<String, dynamic> j) => MyRestaurant(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        isOpen: j['isOpen'] ?? false,
        isActive: j['isActive'] ?? false,
        image: j['image'],
        address: j['address'],
        phone: j['phone'],
        zoneId: j['zoneId'],
      );

  MyRestaurant copyWith({bool? isOpen, bool? isActive}) => MyRestaurant(
        id: id,
        name: name,
        isOpen: isOpen ?? this.isOpen,
        isActive: isActive ?? this.isActive,
        image: image,
        address: address,
        phone: phone,
        zoneId: zoneId,
      );
}
