import 'package:flutter/material.dart';
import 'package:rental_equipment_app/helper.dart';
import 'package:rental_equipment_app/member.dart';
import 'package:rental_equipment_app/member_repository.dart';
import 'package:rental_equipment_app/session_helper.dart';

class MemberPage extends StatefulWidget {
  final String title;
  const MemberPage({super.key, required this.title});

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  final _roles = const {0: 'Thành viên', 1: 'Khách thuê', 2: 'Admin'};
  List<Member> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final token = await SessionHelper.token;
      if (token == null) throw StateError('Missing session');
      final data = await MemberRepository.getMembers(token);
      if (mounted) setState(() => _members = data);
    } catch (_) {
      if (mounted) showMessage(context, 'Không tải được danh sách thành viên');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onEdit(Member member) async {
    final key = GlobalKey<FormState>();
    var name = member.givenName;
    var surname = member.surname ?? '';
    var role = member.role;
    var active = member.isActive;
    final ownAccount = member.email == await SessionHelper.email;
    if (!mounted) return;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(member.email),
          scrollable: true,
          content: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: surname,
                  maxLength: 16,
                  decoration: const InputDecoration(labelText: 'Họ'),
                  onChanged: (value) => surname = value.trim(),
                ),
                TextFormField(
                  initialValue: name,
                  maxLength: 16,
                  decoration: const InputDecoration(labelText: 'Tên'),
                  onChanged: (value) => name = value.trim(),
                  validator: (value) =>
                      (value?.trim() ?? '').isEmpty ? 'Nhập tên' : null,
                ),
                DropdownButtonFormField<int>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Vai trò'),
                  items: [
                    for (final entry in _roles.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: ownAccount
                      ? null
                      : (value) => role = value ?? role,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tài khoản hoạt động'),
                  value: active,
                  onChanged: ownAccount
                      ? null
                      : (value) => setDialogState(() => active = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (save != true || !mounted) return;
    setState(() => _loading = true);
    try {
      final token = await SessionHelper.token;
      final updated = Member(
        id: member.id,
        email: member.email,
        password: '',
        givenName: name,
        surname: surname,
        role: role,
        isActive: active,
      );
      final ok = token != null && await MemberRepository.update(updated, token);
      if (mounted) {
        showMessage(
          context,
          ok ? 'Đã cập nhật thành viên' : 'Không cập nhật được thành viên',
        );
      }
      if (ok && mounted) await _loadMembers();
    } catch (_) {
      if (mounted) showMessage(context, 'Không cập nhật được thành viên');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final item = _members[index];
                return ListTile(
                  title: Text(
                    [
                      item.surname,
                      item.givenName,
                    ].whereType<String>().join(' ').trim(),
                  ),
                  subtitle: Text(
                    '${item.email} · ${_roles[item.role] ?? ""}${item.isActive ? "" : " · Đã khóa"}',
                  ),
                  trailing: IconButton(
                    onPressed: () => _onEdit(item),
                    tooltip: 'Sửa thành viên',
                    icon: const Icon(Icons.edit),
                  ),
                );
              },
            ),
    );
  }
}
