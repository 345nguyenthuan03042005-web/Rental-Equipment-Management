import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RentalPayment {
  final String method;
  final int state;
  final String? url;

  RentalPayment.fromMap(Map<String, dynamic> map)
    : method = map['method'],
      state = map['state'],
      url = map['checkoutUrl'];
}

class PaymentRepository {
  static String get baseUrl => "${dotenv.env['API_URL']}/api/payment";

  static Future<({List<String> methods, RentalPayment? payment})> getPayment(
    int id,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: {'authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Không đọc được trạng thái thanh toán.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      methods: List<String>.from(data['methods']),
      payment: data['payment'] == null
          ? null
          : RentalPayment.fromMap(data['payment']),
    );
  }

  static Future<RentalPayment> start(
    int id,
    String method,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$id/$method'),
      headers: {'authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return RentalPayment.fromMap(jsonDecode(response.body));
    }
    if (response.statusCode == 400 ||
        response.statusCode == 409 ||
        response.statusCode == 502) {
      throw Exception(utf8.decode(response.bodyBytes).replaceAll('"', ''));
    }
    throw Exception('Không tạo được liên kết thanh toán.');
  }
}
