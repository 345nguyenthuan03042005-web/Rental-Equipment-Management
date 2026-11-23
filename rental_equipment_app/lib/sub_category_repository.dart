import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rental_equipment_app/catalog_database.dart';
import 'package:rental_equipment_app/sub_category.dart';

class SubCategoryRepository {
  static final String baseUrl = "${dotenv.env['API_URL']}/api/subcategory";

  static Future<List<SubCategory>> getSubCategories() => _load(baseUrl);

  static Future<List<SubCategory>> getSubCategoriesByCategory(int id) =>
      _load('$baseUrl/$id');

  static Future<List<SubCategory>> _load(String url) async {
    final response = await CatalogDatabase.get(Uri.parse(url));
    final data = jsonDecode(response.body) as List;
    return data.map((p) => SubCategory.fromMap(p)).toList();
  }
}
