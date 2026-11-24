import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rental_equipment_app/account_layout.dart';
import 'package:rental_equipment_app/email_page.dart';
import 'package:rental_equipment_app/helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rental_equipment_app/login.dart';
import 'package:rental_equipment_app/login_response.dart';
import 'package:rental_equipment_app/member_repository.dart';
import 'package:rental_equipment_app/session_helper.dart';

class LoginPage extends StatefulWidget {
  final String title;
  const LoginPage({super.key, required this.title});
  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  Future<List<String>>? _providerRequest;
  static const _names = {
    'google': 'Gmail',
    'facebook': 'Facebook',
    'zalo': 'Zalo',
  };
  static const _icons = {
    'google': Icons.mail_outline,
    'facebook': Icons.facebook,
    'zalo': Icons.chat_bubble_outline,
  };

  @override
  void initState() {
    super.initState();
    _providerRequest = MemberRepository.getSocialProviders();
  }

  @override
  void reassemble() {
    super.reassemble();
    _loadProviders();
  }

  void _loadProviders() {
    final request = MemberRepository.getSocialProviders();
    setState(() {
      _providerRequest = request;
    });
  }

  Future<void> _onSocial(String provider) async {
    try {
      final attempt = await MemberRepository.startSocial(provider);
      if (!mounted) return;
      String code = '';
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Đăng nhập với ${_names[provider]}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mở trang đăng nhập rồi nhập đủ 8 chữ số từ trình duyệt, kể cả số 0 ở đầu.',
              ),
              TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 8,
                onChanged: (value) => code = value,
                decoration: const InputDecoration(labelText: 'Mã xác nhận'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () async {
                final opened = await launchUrl(
                  Uri.parse(attempt['url']),
                  mode: LaunchMode.externalApplication,
                );
                if (!opened && context.mounted) {
                  showMessage(context, 'Không mở được trình duyệt.');
                }
              },
              child: const Text('Mở trang đăng nhập'),
            ),
            FilledButton(
              onPressed: () async {
                if (!RegExp(r'^[0-9]{8}$').hasMatch(code)) {
                  showMessage(context, 'Nhập đủ 8 chữ số, kể cả số 0 ở đầu.');
                  return;
                }
                try {
                  final data = await MemberRepository.finishSocial(
                    attempt['state'],
                    attempt['key'],
                    code,
                  );
                  if (!context.mounted) return;
                  if (data == null) {
                    showMessage(context, 'Đang chờ kết quả đăng nhập.');
                    return;
                  }
                  Navigator.pop(context, data);
                } catch (error) {
                  if (context.mounted) {
                    showMessage(
                      context,
                      error.toString().replaceFirst('Exception: ', ''),
                    );
                  }
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
      if (!mounted || result == null) return;
      await SessionHelper.save(result['email'], result['token']);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        showMessage(context, error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _onEmail(bool reset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EmailPage(email: _emailController.text.trim(), reset: reset),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              'Đăng nhập tài khoản',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ), // TextFormField
            PasswordField(
              controller: _passwordController,
              onFieldSubmitted: (_) => _login(),
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ), // TextFormField

            FilledButton.icon(
              onPressed: _login,
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Đăng ký tài khoản'),
            ),
            if (_error != null && _error!.isNotEmpty)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _onEmail(false),
                  child: const Text('Xác thực email'),
                ),
                TextButton(
                  onPressed: () => _onEmail(true),
                  child: const Text('Quên mật khẩu'),
                ),
              ],
            ),
            const Divider(),
            _buildSocialButtons(),
          ],
        ), // Column
      ), // Form
    ); // Scaffold
  }

  Widget _buildSocialButtons() {
    return FutureBuilder<List<String>>(
      future: _providerRequest,
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final providers = loading ? const <String>[] : snapshot.data ?? [];
        final unavailable = _names.entries
            .where((entry) => !providers.contains(entry.key))
            .map((entry) => entry.value)
            .join(', ');
        final status = loading
            ? 'Đang kiểm tra cấu hình đăng nhập…'
            : snapshot.hasError
            ? 'Chưa kiểm tra được cấu hình đăng nhập từ Web API.'
            : 'Web API chưa bật: $unavailable.';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            for (final provider in _names.entries)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: providers.contains(provider.key)
                    ? () => _onSocial(provider.key)
                    : null,
                icon: Icon(_icons[provider.key], size: 18),
                label: Text('Đăng nhập bằng ${provider.value}'),
              ),
            if (loading || snapshot.hasError || unavailable.isNotEmpty)
              Text(
                status,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            if (!loading && snapshot.hasError)
              TextButton(
                onPressed: _loadProviders,
                child: const Text('Thử lại'),
              ),
          ],
        );
      },
    );
  }

  void _login() async {
    String email = _emailController.text.trim();
    var obj = Login(email: email, password: _passwordController.text);
    LoginResponse? result = await MemberRepository.login(obj);
    if (!mounted) return;
    if (result != null) {
      if (result.success) {
        await SessionHelper.save(email, result.token!);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Đăng nhập thành công')));
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _error = result.message == 'Hãy xác thực email trước khi đăng nhập.'
            ? result.message
            : 'Email hoặc mật khẩu chưa đúng';
      });
    } else {
      setState(() {
        _error = "Không đăng nhập được";
      });
    }
  }
}
