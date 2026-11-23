class Cart {
  final int id;
  final String? memberId;
  final int equipmentId;
  final int quantity;
  Cart({
    required this.id,
    required this.memberId,
    required this.equipmentId,
    required this.quantity,
  });
  factory Cart.fromMap(Map<String, dynamic> map) {
    return Cart(
      id: map['id'],
      memberId: map['memberId'],
      equipmentId: map['equipmentId'],
      quantity: map['quantity'],
    );
  }
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'equipmentId': equipmentId,
      'quantity': quantity,
    };
  }
}
