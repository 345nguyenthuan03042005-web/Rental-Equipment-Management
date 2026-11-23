import 'package:flutter/material.dart';
import 'package:rental_equipment_app/email_page.dart';
import 'package:rental_equipment_app/member.dart';
import 'package:rental_equipment_app/member_repository.dart';
import 'package:rental_equipment_app/session_helper.dart';

class ProfilePage extends StatefulWidget {
  final String title;
  const ProfilePage({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Member? _member;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    String? token = await SessionHelper.token;
    if (token != null) {
      var data = await MemberRepository.getMember(token);
      if (!mounted) return;
      setState(() {
        _member = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final social = _member?.email.endsWith('@example.invalid') ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_member != null && !social && !_member!.emailVerified)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              tooltip: 'Xác thực email',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmailPage(email: _member!.email),
                  ),
                );
                if (result == true && mounted) _loadData();
              },
            ),
          if (!social)
            IconButton(
              icon: const Icon(Icons.password),
              tooltip: 'Đổi mật khẩu',
              onPressed: () => Navigator.pushNamed(context, '/password'),
            ),
        ],
      ),
      body: _member == null
          ? const Center(child: Text('Chưa tải được hồ sơ'))
          : Table(
              children: [
                TableRow(
                  children: [
                    TableCell(child: Text('Email')),
                    TableCell(
                      child: Text(
                        social
                            ? 'Đăng nhập qua mạng xã hội'
                            : _member!.emailVerified
                            ? '${_member!.email} (đã xác thực)'
                            : _member!.email,
                      ),
                    ),
                  ],
                ), // TableRow
                TableRow(
                  children: [
                    TableCell(child: Text('Tên')),
                    TableCell(child: Text(_member!.givenName)),
                  ],
                ), // TableRow
              ],
            ), // Table
    ); // Scaffold
  }
}
