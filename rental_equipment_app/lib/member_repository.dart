import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:rental_equipment_app/login.dart';
import 'package:rental_equipment_app/login_response.dart';
import 'package:rental_equipment_app/member.dart';

class MemberRepository {
  static Future<int> add(Member obj) async {
    String path = "${dotenv.env['API_URL']}/api/auth/register";
    var response = await post(
      Uri.parse(path),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(obj.toMap()),
    );
    if (response.statusCode == 200) {
      return int.parse(response.body);
    }
    return -2;
  }

  static Future<LoginResponse?> login(Login obj) async {
    final response = await _accountPost('/auth/login', obj.toMap());
    if (response.statusCode == 200) {
      return LoginResponse.fromMap(jsonDecode(response.body));
    }
    return null;
  }

  static Future<Member?> getMember(
    String token, {
    bool failOnServerError = false,
  }) async {
    String path = "${dotenv.env['API_URL']}/api/auth";
    var response = await http
        .get(
          Uri.parse(path),
          headers: {
            'content-type': 'application/json',
            'authorization': 'Bearer $token',
          },
        )
        .timeout(_accountTimeout);
    if (response.statusCode == 200) {
      return Member.fromMap(jsonDecode(response.body));
    }
    if (failOnServerError && ![401, 403, 404].contains(response.statusCode)) {
      throw Exception('Chưa tải được hồ sơ tài khoản.');
    }
    return null;
  }

  static Future<bool> changePassword(
    String current,
    String password,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse("${dotenv.env['API_URL']}/api/auth/password"),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode({'currentPassword': current, 'newPassword': password}),
    );
    return response.statusCode == 200;
  }

  static Future<List<Member>> getMembers(String token) async {
    final response = await http.get(
      Uri.parse("${dotenv.env['API_URL']}/api/member"),
      headers: {'authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Không tải được thành viên');
    }
    final data = jsonDecode(response.body) as List;
    return data.map((p) => Member.fromMap(p)).toList();
  }

  static Future<bool> update(Member member, String token) async {
    final response = await http.put(
      Uri.parse("${dotenv.env['API_URL']}/api/member/${member.id}"),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'givenName': member.givenName,
        'surname': member.surname,
        'role': member.role,
        'isActive': member.isActive,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<bool> sendEmailCode(String email, bool reset) async {
    final response = await _accountPost('/email/send', {
      'email': email,
      'purpose': reset ? 'reset' : 'verify',
    });
    if (response.statusCode == 503) {
      throw Exception('Máy chủ chưa cấu hình gửi email.');
    }
    if (response.statusCode == 429) {
      throw Exception('Hãy đợi một lát rồi thử lại.');
    }
    return response.statusCode == 202;
  }

  static Future<bool> confirmEmailCode(
    String email,
    String code,
    String? password,
  ) async {
    final response = await _accountPost(
      password == null ? '/email/verify' : '/email/reset',
      {'email': email, 'code': code, 'password': ?password},
    );
    return response.statusCode == 200;
  }

  static Future<List<String>> getSocialProviders() async {
    final response = await http
        .get(Uri.parse("${dotenv.env['API_URL']}/api/social"))
        .timeout(_accountTimeout);
    if (response.statusCode != 200) {
      throw Exception('Không tải được cấu hình đăng nhập.');
    }
    return List<String>.from(jsonDecode(response.body));
  }

  static Future<Map<String, dynamic>> startSocial(String provider) async {
    final response = await _accountPost('/social/$provider/start', {});
    if (response.statusCode != 200) {
      throw Exception(switch (response.statusCode) {
        404 => 'Phương thức đăng nhập này chưa được bật trên máy chủ.',
        429 => 'Bạn thử quá nhiều lần. Hãy đợi một lát rồi thử lại.',
        _ => 'Máy chủ chưa mở được trang đăng nhập. Hãy thử lại.',
      });
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> finishSocial(
    String state,
    String key,
    String code,
  ) async {
    final response = await _accountPost('/social/result', {
      'state': state,
      'key': key,
      'code': code,
    });
    if (response.statusCode == 202) return null;
    if (response.statusCode != 200) {
      throw Exception(switch (response.statusCode) {
        400 => 'Mã xác nhận không đúng.',
        404 => 'Phiên đăng nhập đã hết hạn. Hãy bắt đầu lại.',
        422 => 'Nhà cung cấp chưa xác thực được tài khoản. Hãy bắt đầu lại.',
        _ => 'Chưa kiểm tra được kết quả đăng nhập. Hãy thử lại.',
      });
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static const _accountTimeout = Duration(seconds: 75);

  static Future<http.Response> _accountPost(
    String route,
    Map<String, dynamic> body,
  ) => http
      .post(
        Uri.parse("${dotenv.env['API_URL']}/api$route"),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(body),
      )
      .timeout(_accountTimeout);
}
