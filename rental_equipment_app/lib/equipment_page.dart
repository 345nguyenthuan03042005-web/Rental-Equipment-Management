import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rental_equipment_app/category.dart';
import 'package:rental_equipment_app/category_repository.dart';
import 'package:rental_equipment_app/equipment.dart';
import 'package:rental_equipment_app/equipment_repository.dart';
import 'package:rental_equipment_app/helper.dart';
import 'package:rental_equipment_app/session_helper.dart';
import 'package:rental_equipment_app/sub_category.dart';
import 'package:rental_equipment_app/sub_category_repository.dart';

class EquipmentPage extends StatefulWidget {
  final String title;
  const EquipmentPage({super.key, required this.title});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  List<Category> _categories = [];
  List<SubCategory> _groups = [];
  List<Equipment> _equipment = [];
  int? _categoryId;
  int _page = 1;
  int _lastPage = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await CategoryRepository.getCategories();
      final groups = await SubCategoryRepository.getSubCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _groups = groups;
      });
      await _loadEquipment(1);
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Không tải được danh mục và nhóm thiết bị');
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadEquipment(int page) async {
    setState(() => _loading = true);
    try {
      var result = await EquipmentRepository.getPage(
        page: page,
        categoryId: _categoryId,
        useCache: false,
      );
      if (!mounted) return;
      if (page > 1 && result.items.isEmpty) {
        page = result.total > 0 ? (result.total + 11) ~/ 12 : 1;
        result = await EquipmentRepository.getPage(
          page: page,
          categoryId: _categoryId,
          useCache: false,
        );
        if (!mounted) return;
      }
      setState(() {
        _equipment = result.items;
        _page = page;
        _lastPage = result.total == 0 ? 1 : (result.total + 11) ~/ 12;
      });
    } catch (_) {
      if (mounted) showMessage(context, 'Không tải được thiết bị');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onEdit([Equipment? item]) async {
    final groups = _groups
        .where(
          (p) =>
              _categoryId == null ||
              p.categoryId == _categoryId ||
              p.id == item?.subCategoryId,
        )
        .toList();
    if (groups.isEmpty) {
      showMessage(context, 'Hãy thêm danh mục trước khi thêm thiết bị');
      return;
    }
    final key = GlobalKey<FormState>();
    final fields = {
      'name': item?.name ?? '',
      'price': item?.price.toString() ?? '',
      'brand': item?.brand ?? '',
      'model': item?.model ?? '',
      'specifications': item?.specifications ?? '',
      'unit': item?.unit ?? '',
      'status': item?.status == Equipment.maintenance
          ? Equipment.maintenance
          : Equipment.available,
      'subCategoryId': '${item?.subCategoryId ?? groups.first.id}',
    };
    final labels = {
      'name': 'Tên thiết bị',
      'price': 'Giá thuê mỗi ngày',
      'brand': 'Hãng',
      'model': 'Model',
      'specifications': 'Thông số',
      'unit': 'Đơn vị',
    };
    final limits = {
      'name': 128,
      'price': 11,
      'brand': 64,
      'model': 128,
      'specifications': 256,
      'unit': 128,
    };
    XFile? image;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Thêm thiết bị' : 'Sửa thiết bị'),
          scrollable: true,
          content: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: fields['subCategoryId'],
                  decoration: const InputDecoration(labelText: 'Nhóm thiết bị'),
                  items: [
                    for (final group in groups)
                      DropdownMenuItem(
                        value: '${group.id}',
                        child: Text(
                          '${_categories.firstWhere((p) => p.id == group.categoryId).name} · ${group.name}',
                        ),
                      ),
                  ],
                  onChanged: (value) => fields['subCategoryId'] = value!,
                ),
                for (final field in labels.keys)
                  TextFormField(
                    initialValue: fields[field],
                    maxLength: limits[field],
                    keyboardType: field == 'price'
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    decoration: InputDecoration(labelText: labels[field]),
                    onChanged: (value) => fields[field] = value.trim(),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (field == 'price' &&
                          !RegExp(r'^\d{1,8}([.,]\d{1,2})?$').hasMatch(text)) {
                        return 'Nhập giá hợp lệ';
                      }
                      return (field == 'name' || field == 'unit') &&
                              text.isEmpty
                          ? 'Bắt buộc'
                          : null;
                    },
                  ),
                DropdownButtonFormField<String>(
                  initialValue: fields['status'],
                  decoration: const InputDecoration(labelText: 'Tình trạng'),
                  items: [
                    for (final status in [
                      Equipment.available,
                      Equipment.maintenance,
                    ])
                      DropdownMenuItem(value: status, child: Text(status)),
                  ],
                  onChanged: (value) => fields['status'] = value!,
                ),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final file = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (file == null || !context.mounted) return;
                      if (await file.length() > 5 * 1024 * 1024) {
                        if (context.mounted) {
                          showMessage(context, 'Ảnh tối đa 5 MB');
                        }
                        return;
                      }
                      if (context.mounted) setDialogState(() => image = file);
                    } catch (_) {
                      if (context.mounted) {
                        showMessage(context, 'Không mở được ảnh');
                      }
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: Text(
                    image?.name ??
                        (item == null ? 'Chọn ảnh PNG/JPEG' : 'Thay ảnh'),
                  ),
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
                if (!key.currentState!.validate()) return;
                if (item == null && image == null) {
                  showMessage(context, 'Chọn ảnh cho thiết bị');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    fields['price'] = fields['price']!.replaceAll(',', '.');
    await _save(() async {
      final token = await SessionHelper.token;
      if (token == null) throw Exception('Hãy đăng nhập lại');
      await EquipmentRepository.save(item?.id, fields, image, token);
    }, item == null ? 1 : _page);
  }

  Future<void> _onDelete(Equipment item) async {
    if (!await confirmDelete(context, item.name) || !mounted) return;
    await _save(() async {
      final token = await SessionHelper.token;
      if (token == null || !await EquipmentRepository.delete(item.id, token)) {
        throw Exception('Không xóa được thiết bị');
      }
    }, _page);
  }

  Future<void> _save(Future<void> Function() action, int page) async {
    setState(() => _loading = true);
    try {
      await action();
      if (!mounted) return;
      showMessage(context, 'Đã cập nhật thiết bị');
      await _loadEquipment(page);
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
        tooltip: 'Thêm thiết bị',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          DropdownButton<int>(
            value: _categoryId ?? 0,
            items: [
              const DropdownMenuItem(value: 0, child: Text('Tất cả danh mục')),
              for (final category in _categories)
                DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                ),
            ],
            onChanged: _loading
                ? null
                : (id) {
                    _categoryId = id == 0 ? null : id;
                    _loadEquipment(1);
                  },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _equipment.isEmpty
                ? const Center(child: Text('Chưa có thiết bị'))
                : ListView.builder(
                    itemCount: _equipment.length,
                    itemBuilder: (context, index) {
                      final item = _equipment[index];
                      final rented = item.status == 'Đang cho thuê';
                      return ListTile(
                        leading: equipmentImage(item.imageUrl, size: 48),
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.unit ?? ""} · ${item.status ?? ""}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: rented ? null : () => _onEdit(item),
                              tooltip: 'Sửa',
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: rented ? null : () => _onDelete(item),
                              tooltip: 'Xóa',
                              icon: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (!_loading) pageButtons(_page, _lastPage, _loadEquipment),
        ],
      ),
    );
  }
}
