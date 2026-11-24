import 'package:flutter/material.dart';
import 'package:rental_equipment_app/account_layout.dart';
import 'package:rental_equipment_app/member.dart';
import 'package:rental_equipment_app/member_repository.dart';

class RegisterPage extends StatefulWidget {
  final String title;
  const RegisterPage({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _givenNameController = TextEditingController();
  final _surnameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _givenNameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Form(
        child: AccountLayout(
          withPhoto: true,
          children: [
            Text(
              'Tạo tài khoản',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _surnameController,
                    decoration: const InputDecoration(labelText: 'Họ'),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _givenNameController,
                    decoration: const InputDecoration(labelText: 'Tên'),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            PasswordField(
              controller: _passwordController,
              onFieldSubmitted: (_) => _register(),
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            FilledButton.icon(
              onPressed: _register,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Đăng ký'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ); // Scaffold
  }

  void _register() async {
    Member obj = Member(
      id: null,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      givenName: _givenNameController.text.trim(),
      surname: _surnameController.text.trim(),
      role: 0,
    );
    int ret = await MemberRepository.add(obj);
    if (!mounted) return;
    if (ret > 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đăng ký thành công')));
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = ret == -1
            ? "Email đã được sử dụng"
            : "Kiểm tra thông tin đăng ký";
      });
    }
  }
}
