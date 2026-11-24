import 'package:flutter/material.dart';
import 'package:rental_equipment_app/account_layout.dart';
import 'package:rental_equipment_app/helper.dart';
import 'package:rental_equipment_app/member_repository.dart';
import 'package:rental_equipment_app/session_helper.dart';

class PasswordPage extends StatefulWidget {
  final String title;
  const PasswordPage({super.key, required this.title});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _key = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await SessionHelper.token;
      if (token != null &&
          await MemberRepository.changePassword(
            _current.text,
            _password.text,
            token,
          )) {
        if (mounted) {
          showMessage(context, 'Đã đổi mật khẩu');
          Navigator.pop(context);
        }
        return;
      }
      if (mounted) {
        setState(() => _error = 'Kiểm tra mật khẩu hiện tại và mật khẩu mới');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Form(
        key: _key,
        child: AccountLayout(
          children: [
            PasswordField(
              controller: _current,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Nhập mật khẩu hiện tại' : null,
            ),
            PasswordField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              validator: (value) =>
                  (value ?? '').length < 6 ? 'Cần ít nhất 6 ký tự' : null,
            ),
            PasswordField(
              decoration: const InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
              ),
              validator: (value) =>
                  value != _password.text ? 'Mật khẩu chưa trùng khớp' : null,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _onSave,
              child: const Text('Đổi mật khẩu'),
            ),
            if (_error != null) Text(_error!),
          ],
        ),
      ),
    );
  }
}
