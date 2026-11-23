import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:rental_equipment_app/category.dart';
import 'package:rental_equipment_app/catalog_database.dart';

class CategoryRepository {
  static final String baseUrl = "${dotenv.env['API_URL']}/api/category";

  static Future<List<Category>> getCategories() async {
    final response = await CatalogDatabase.get(Uri.parse(baseUrl));
    final data = jsonDecode(response.body) as List;
    return data.map((p) => Category.fromMap(p)).toList();
  }

  static Future<bool> save(
    int? id,
    Map<String, String> fields,
    String token,
    XFile? image,
  ) async {
    final url = Uri.parse(id == null ? baseUrl : '$baseUrl/$id');
    final request = http.MultipartRequest(id == null ? 'POST' : 'PUT', url)
      ..headers['authorization'] = 'Bearer $token'
      ..fields.addAll(fields);
    if (image != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          await image.readAsBytes(),
          filename: image.name,
        ),
      );
    }
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 400) {
      throw Exception(
        'Kiểm tra dữ liệu và chọn ảnh PNG hoặc JPEG tối đa 5 MB.',
      );
    }
    return response.statusCode == 200;
  }

  static Future<bool> delete(int id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'authorization': 'Bearer $token'},
    );
    if (response.statusCode == 409) {
      throw Exception('Danh mục vẫn còn thiết bị.');
    }
    return response.statusCode == 200;
  }
}
