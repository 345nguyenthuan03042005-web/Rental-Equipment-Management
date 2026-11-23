class Equipment {
  static const available = 'Sẵn sàng';
  static const maintenance = 'Đang bảo trì';

  final int id;
  final int subCategoryId;
  final String name;
  final String imageUrl;
  final double price;
  final String? brand;
  final String? model;
  final String? specifications;
  final String? unit;
  final String? status;

  Equipment({
    required this.id,
    required this.subCategoryId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.brand,
    this.model,
    this.specifications,
    this.unit,
    this.status,
  });

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'],
      subCategoryId: map['subCategoryId'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      price: (map['price'] as num).toDouble(),
      brand: map['brand'],
      model: map['model'],
      specifications: map['specifications'],
      unit: map['unit'],
      status: map['status'],
    );
  }
}
