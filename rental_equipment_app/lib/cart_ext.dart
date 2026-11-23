import 'package:rental_equipment_app/cart.dart';

class CartExt extends Cart {
  final String name;
  final String imageUrl;
  final double price;
  final String? unit;
  final String? status;
  CartExt({
    required super.id,
    required super.memberId,
    required super.equipmentId,
    required super.quantity,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.unit,
    this.status,
  });
  @override
  Map<String, Object?> toMap() {
    //TODO: implement toMap
    var map = super.toMap();
    map['name'] = name;
    map['imageUrl'] = imageUrl;
    map['price'] = price;
    return map;
  }

  factory CartExt.fromMap(Map<String, dynamic> map) {
    return CartExt(
      id: map['id'],
      memberId: map['memberId'],
      equipmentId: map['equipmentId'],
      quantity: map['quantity'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      unit: map['unit'],
      status: map['status'],
      imageUrl: map['imageUrl'],
    );
  }
}
