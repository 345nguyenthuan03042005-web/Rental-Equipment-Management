import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rental_equipment_app/category.dart';
import 'package:rental_equipment_app/category_repository.dart';
import 'package:rental_equipment_app/helper.dart';
import 'package:rental_equipment_app/session_helper.dart';

class CategoryPage extends StatefulWidget {
  final String title;
  const CategoryPage({super.key, required this.title});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await CategoryRepository.getCategories();
      if (mounted) setState(() => _categories = data);
    } catch (_) {
      if (mounted) showMessage(context, 'Không tải được danh mục');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onEdit([Category? item]) async {
    final key = GlobalKey<FormState>();
    final fields = {
      'name': item?.name ?? '',
      'title': item?.title ?? '',
      'description': item?.description ?? '',
    };
    final labels = {
      'name': 'Tên danh mục',
      'title': 'Tiêu đề',
      'description': 'Mô tả',
    };
    final limits = {'name': 64, 'title': 128, 'description': 1024};
    XFile? image;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Thêm danh mục' : 'Sửa danh mục'),
          scrollable: true,
          content: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in labels.keys)
                  TextFormField(
                    initialValue: fields[field],
                    maxLength: limits[field],
                    decoration: InputDecoration(labelText: labels[field]),
                    onChanged: (value) => fields[field] = value.trim(),
                    validator: (value) =>
                        (value?.trim() ?? '').isEmpty ? 'Bắt buộc' : null,
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.image),
                  label: Text(
                    image?.name ?? (item == null ? 'Chọn ảnh' : 'Thay ảnh'),
                  ),
                  onPressed: () async {
                    try {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (picked == null || !context.mounted) return;
                      if (await picked.length() > 5 * 1024 * 1024) {
                        if (context.mounted) {
                          showMessage(context, 'Ảnh tối đa 5 MB');
                        }
                        return;
                      }
                      if (context.mounted) setDialogState(() => image = picked);
                    } catch (_) {
                      if (context.mounted) {
                        showMessage(context, 'Không mở được ảnh');
                      }
                    }
                  },
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
    await _save(() async {
      final token = await SessionHelper.token;
      return token != null &&
          await CategoryRepository.save(item?.id, fields, token, image);
    });
  }

  Future<void> _onDelete(Category item) async {
    if (!await confirmDelete(context, item.name) || !mounted) return;
    await _save(() async {
      final token = await SessionHelper.token;
      return token != null && await CategoryRepository.delete(item.id, token);
    });
  }

  Future<void> _save(Future<bool> Function() action) async {
    setState(() => _loading = true);
    try {
      final ok = await action();
      if (!mounted) return;
      if (ok) await _loadCategories();
      if (mounted) {
        showMessage(
          context,
          ok ? 'Đã cập nhật danh mục' : 'Không cập nhật được danh mục',
        );
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _onEdit,
        tooltip: 'Thêm danh mục',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final item = _categories[index];
                return ListTile(
                  leading: categoryImage(item.icon),
                  title: Text(item.name),
                  subtitle: Text(item.title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _onEdit(item),
                        tooltip: 'Sửa',
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () => _onDelete(item),
                        tooltip: 'Xóa',
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
