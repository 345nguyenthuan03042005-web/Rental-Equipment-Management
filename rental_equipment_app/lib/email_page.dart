import 'package:flutter/material.dart';
import 'package:rental_equipment_app/account_layout.dart';
import 'package:rental_equipment_app/helper.dart';
import 'package:rental_equipment_app/member_repository.dart';

class EmailPage extends StatefulWidget {
  final String email;
  final bool reset;

  const EmailPage({super.key, this.email = '', this.reset = false});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      showMessage(context, 'Nhập email hợp lệ.');
      return;
    }
    setState(() => _sending = true);
    try {
      final sent = await MemberRepository.sendEmailCode(email, widget.reset);
      if (!mounted) return;
      if (sent) setState(() => _sent = true);
      showMessage(
        context,
        sent ? 'Kiểm tra hộp thư để lấy mã xác thực.' : 'Không gửi được mã.',
      );
    } catch (error) {
      if (mounted) {
        showMessage(context, error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _onSave() async {
    final code = _code.text.trim();
    final password = widget.reset ? _password.text : null;
    if (!RegExp(r'^\d{8}$').hasMatch(code) ||
        (password != null && password.length < 6)) {
      showMessage(
        context,
        'Nhập mã 8 số và mật khẩu mới ít nhất 6 ký tự nếu đặt lại.',
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final ok = await MemberRepository.confirmEmailCode(
        _email.text.trim(),
        code,
        password,
      );
      if (!mounted) return;
      if (ok) {
        showMessage(
          context,
          widget.reset ? 'Đã đặt lại mật khẩu.' : 'Đã xác thực email.',
        );
        Navigator.pop(context, true);
      } else {
        showMessage(context, 'Mã sai, hết hạn hoặc mật khẩu không hợp lệ.');
      }
    } catch (_) {
      if (mounted) showMessage(context, 'Không kết nối được máy chủ.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reset ? 'Quên mật khẩu' : 'Xác thực email'),
      ),
      body: AccountLayout(
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            enabled: !_sending,
            onChanged: (_) => setState(() => _sent = false),
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          OutlinedButton(
            onPressed: _sending ? null : _send,
            child: Text(_sent ? 'Gửi lại mã' : 'Gửi mã'),
          ),
          if (_sent) ...[
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 8,
              enabled: !_sending,
              decoration: const InputDecoration(labelText: 'Mã trong email'),
            ),
            if (widget.reset)
              TextField(
                controller: _password,
                obscureText: true,
                enabled: !_sending,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              ),
            FilledButton(
              onPressed: _sending ? null : _onSave,
              child: const Text('Xác nhận'),
            ),
          ],
        ],
      ),
    );
  }
}
