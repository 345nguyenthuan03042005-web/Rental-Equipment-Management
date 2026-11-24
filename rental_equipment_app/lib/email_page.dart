import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _requestAccepted = false;

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
      final accepted = await MemberRepository.sendEmailCode(
        email,
        widget.reset,
      );
      if (!mounted) return;
      if (accepted) setState(() => _requestAccepted = true);
      showMessage(
        context,
        accepted
            ? 'Nếu địa chỉ đủ điều kiện, mã sẽ được gửi qua email. Hãy kiểm tra cả mục Spam.'
            : 'Máy chủ không nhận yêu cầu gửi mã.',
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
    final code = _code.text;
    final password = widget.reset ? _password.text : null;
    if (code.length != 8) {
      showMessage(context, 'Nhập đủ 8 chữ số, kể cả số 0 ở đầu.');
      return;
    }
    if (password != null && password.length < 6) {
      showMessage(context, 'Mật khẩu mới phải có ít nhất 6 ký tự.');
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
            onChanged: (_) {
              _code.clear();
              setState(() => _requestAccepted = false);
            },
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          OutlinedButton(
            onPressed: _sending ? null : _send,
            child: Text(_requestAccepted ? 'Gửi lại mã' : 'Gửi mã'),
          ),
          if (_requestAccepted) ...[
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 8,
              enabled: !_sending,
              decoration: const InputDecoration(labelText: 'Mã trong email'),
            ),
            if (widget.reset)
              PasswordField(
                controller: _password,
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
