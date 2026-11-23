import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:rental_equipment_app/catalog_database.dart';
import 'package:rental_equipment_app/equipment.dart';

class EquipmentRepository {
  static String get _baseUrl => "${dotenv.env['API_URL']}/api/equipment";

  static Uri _url([String path = '', String? unit]) {
    return Uri.parse('$_baseUrl$path')
        .replace(queryParameters: unit == null ? null : {'unit': unit});
  }

  static Future<Equipment> getEquipment(int id) async {
    final response = await CatalogDatabase.get(_url('/details/$id'));
    return Equipment.fromMap(jsonDecode(response.body));
  }

  static Future<List<String>> getUnits() async {
    final response = await CatalogDatabase.get(_url('/units'));
    return List<String>.from(jsonDecode(response.body));
  }

  static Future<List<Equipment>> getEquipments({String? unit}) async {
    return _readList(await http.get(_url('', unit)));
  }

  static Future<List<Equipment>> getEquipmentsByCategory(
    int id, {
    String? unit,
  }) async {
    return _readList(await http.get(_url('/category/$id', unit)));
  }

  static Future<List<Equipment>> getEquipmentsByCategories(
    List<int> ids, {
    String? unit,
  }) async {
    return _readList(
      await http.post(
        _url('/subcategories', unit),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(ids),
      ),
    );
  }

  static List<Equipment> _readList(http.Response response) {
    if (response.statusCode != 200) throw Exception('Không tải được thiết bị');
    final data = jsonDecode(response.body) as List;
    return data.map((item) => Equipment.fromMap(item)).toList();
  }

  static Future<bool> update(
    int id,
    String unit,
    String status,
    String token,
  ) async {
    final response = await http.put(
      _url('/$id'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode({'unit': unit, 'status': status}),
    );
    return response.statusCode == 200;
  }

  static Future<EquipmentPageResult> getRelated(
    Equipment item,
    int page,
  ) async {
    final url = _url('/relation/page').replace(
      queryParameters: {
        'id': '${item.id}',
        'subCategoryId': '${item.subCategoryId}',
        'page': '$page',
      },
    );
    final response = await CatalogDatabase.get(url);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return EquipmentPageResult(
      (data['items'] as List).map((p) => Equipment.fromMap(p)).toList(),
      data['total'] as int,
      response.offline,
    );
  }

  static Future<EquipmentPageResult> getPage({
    required int page,
    int? categoryId,
    List<int> subCategoryIds = const [],
    String? unit,
    String search = '',
    bool useCache = true,
  }) async {
    final url = _url('/page').replace(
      queryParameters: {
        'page': page.toString(),
        'pageSize': '12',
        if (categoryId != null) 'categoryId': categoryId.toString(),
        if (subCategoryIds.isNotEmpty)
          'subCategoryIds': subCategoryIds.map((id) => id.toString()).toList(),
        'unit': ?unit,
        if (search.isNotEmpty) 'search': search,
      },
    );
    final result = await CatalogDatabase.get(url, useCache: useCache);
    final data = jsonDecode(result.body) as Map<String, dynamic>;
    return EquipmentPageResult(
      (data['items'] as List).map((p) => Equipment.fromMap(p)).toList(),
      data['total'] as int,
      result.offline,
    );
  }

  static Future<void> save(
    int? id,
    Map<String, String> fields,
    XFile? image,
    String token,
  ) async {
    final url = id == null ? _url() : _url('/$id');
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
    if (response.statusCode != 200) {
      throw Exception(
        response.statusCode == 400
            ? 'Kiểm tra thông tin, định dạng PNG/JPEG và kích thước ảnh (tối đa 5 MB).'
            : response.statusCode == 409
            ? 'Thiết bị đang cho thuê hoặc đã thay đổi.'
            : 'Không lưu được thiết bị.',
      );
    }
  }

  static Future<bool> delete(int id, String token) async {
    final response = await http.delete(
      _url('/$id'),
      headers: {'authorization': 'Bearer $token'},
    );
    if (response.statusCode == 409) {
      throw Exception(
        'Thiết bị đang cho thuê hoặc có trong giỏ hay phiếu thuê.',
      );
    }
    return response.statusCode == 200;
  }
}

class EquipmentPageResult {
  final List<Equipment> items;
  final int total;
  final bool offline;

  EquipmentPageResult(this.items, this.total, this.offline);
}
