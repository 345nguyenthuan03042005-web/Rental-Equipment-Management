class Rental {
  final int id;
  final int statusId;
  final String memberId;
  final DateTime dated;
  final List<RentalDetail> details;

  Rental({
    required this.id,
    required this.statusId,
    required this.memberId,
    required this.dated,
    required this.details,
  });

  factory Rental.fromMap(Map<String, dynamic> map) {
    return Rental(
      id: map['id'],
      statusId: map['statusId'],
      memberId: map['memberId'],
      dated: DateTime.parse(map['dated']),
      details: (map['details'] as List)
          .map((p) => RentalDetail.fromMap(p))
          .toList(),
    );
  }
}

class RentalDetail {
  final String name;
  final String? unit;
  final int days;
  final double price;

  RentalDetail({
    required this.name,
    this.unit,
    required this.days,
    required this.price,
  });

  factory RentalDetail.fromMap(Map<String, dynamic> map) {
    return RentalDetail(
      name: map['equipment']?['name'] ?? 'Thiết bị #${map['equipmentId']}',
      unit: map['unit'],
      days: map['quantity'],
      price: (map['price'] as num).toDouble(),
    );
  }
}
