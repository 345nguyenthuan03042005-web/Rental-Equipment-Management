import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;
import 'package:rental_equipment_app/rental.dart';

class RentalRepository {
  static final String baseUrl = "${dotenv.env['API_URL']}/api/rental";
  static Future<int> add(String token) async {
    var rs = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'content-type': "application/json",
        "authorization": 'Bearer $token',
      },
    );
    if (rs.statusCode == 200) {
      return int.parse(rs.body);
    }
    return -2;
  }

  static Future<int> updateStatus(int id, int statusId, String token) async {
    var rs = await http.put(
      Uri.parse('$baseUrl/status?id=$id&statusId=$statusId'),
      headers: {
        'content-type': "application/json",
        "authorization": 'Bearer $token',
      },
    );
    if (rs.statusCode == 200) {
      return int.parse(rs.body);
    }
    return -2;
  }

  static Future<Rental> getRental(int id, String token) async {
    var rs = await http.get(
      Uri.parse('$baseUrl/details/$id'),
      headers: {
        'content-type': "application/json",
        "authorization": 'Bearer $token',
      },
    );
    if (rs.statusCode == 200) {
      dynamic data = await jsonDecode(rs.body);
      return Rental.fromMap(data);
    }
    throw Exception('Not found $baseUrl');
  }

  static Future<List<Rental>> getRentals(
    String token, {
    int? number,
    DateTimeRange? dates,
  }) async {
    var rs = await http.get(
      Uri.parse(baseUrl).replace(
        queryParameters: {
          if (number != null) 'number': '$number',
          if (dates != null)
            'from': dates.start.toIso8601String().split('T').first,
          if (dates != null) 'to': dates.end.toIso8601String().split('T').first,
        },
      ),
      headers: {
        'content-type': "application/json",
        "authorization": 'Bearer $token',
      },
    );
    if (rs.statusCode == 200) {
      List<dynamic> data = await jsonDecode(rs.body);
      return data.map((p) => Rental.fromMap(p)).toList();
    }
    throw Exception('Not found $baseUrl');
  }
}
