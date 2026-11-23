import 'package:flutter/material.dart';
import 'package:rental_equipment_app/equipment.dart';
import 'package:rental_equipment_app/equipment_repository.dart';
import 'package:rental_equipment_app/cart.dart';
import 'package:rental_equipment_app/cart_repository.dart';
import 'package:rental_equipment_app/helper.dart';
import 'package:rental_equipment_app/member_repository.dart';
import 'package:rental_equipment_app/session_helper.dart';

class DetailsPage extends StatefulWidget {
  final String title;
  const DetailsPage({super.key, required this.title});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _days = TextEditingController(text: '1');
  int? _id;
  Equipment? _equipment;
  String? _error;
  bool _isAdmin = false;
  bool _adding = false;
  List<Equipment> _related = [];
  int _relatedPage = 1;
  int _relatedTotal = 0;
  bool _loadingRelated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_id != null) return;
    _id = ModalRoute.of(context)!.settings.arguments as int;
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    try {
      final item = await EquipmentRepository.getEquipment(_id!);
      final token = await SessionHelper.token;
      final member = token == null
          ? null
          : await MemberRepository.getMember(token);
      if (!mounted) return;
      setState(() {
        _equipment = item;
        _isAdmin = member?.role == 2;
        _error = null;
      });
      if (_related.isEmpty) await _loadRelated(item, 1);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tải được thiết bị');
    }
  }

  Future<void> _loadRelated(Equipment item, int page) async {
    setState(() => _loadingRelated = true);
    try {
      final result = await EquipmentRepository.getRelated(item, page);
      if (!mounted) return;
      setState(() {
        _related = result.items;
        _relatedTotal = result.total;
        _relatedPage = page;
      });
    } catch (_) {
      // The equipment details remain available if related items cannot load.
    } finally {
      if (mounted) setState(() => _loadingRelated = false);
    }
  }

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _equipment;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: item == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Text(_error!),
            )
          : PageContent(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 650;
                        final photo = _buildPhoto(item, wide);
                        final info = _buildDetails(item);
                        return wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 26,
                                children: [
                                  Expanded(child: photo),
                                  Expanded(child: info),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 16,
                                children: [photo, info],
                              );
                      },
                    ),
                  ),
                ),
                if (_relatedTotal > 0) ...[
                  const SizedBox(height: 22),
                  Text(
                    'Thiết bị liên quan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        for (final related in _related)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: equipmentImage(related.imageUrl, size: 48),
                            title: Text(related.name),
                            subtitle: Text(
                              '${formatPrice(related.price)}/ngày',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/details',
                              arguments: related.id,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!_loadingRelated && _relatedTotal > 2)
                    pageButtons(
                      _relatedPage,
                      (_relatedTotal + 1) ~/ 2,
                      (page) => _loadRelated(item, page),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _buildPhoto(Equipment item, bool wide) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(13),
      ),
      child: SizedBox(
        width: double.infinity,
        height: wide ? 310 : 188,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: equipmentImage(item.imageUrl, size: wide ? 260 : 164),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(Equipment item) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        equipmentStatus(item.status),
        Text(item.name, style: theme.textTheme.headlineSmall),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: formatPrice(item.price),
                style: theme.textTheme.headlineSmall,
              ),
              TextSpan(text: ' / ngày', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const Divider(height: 12),
        _loadTable(item),
        if (item.status == Equipment.available) ...[
          const SizedBox(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 226),
            child: TextField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số ngày thuê (1–365)',
                prefixIcon: Icon(Icons.date_range_outlined, size: 20),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _adding ? null : _onAddToCart,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Thêm vào giỏ thuê'),
          ),
        ],
        if (_isAdmin && item.status != 'Đang cho thuê')
          OutlinedButton(
            onPressed: () => _editEquipment(item),
            child: const Text('Cập nhật đơn vị và tình trạng'),
          ),
        if (_error != null)
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
      ],
    );
  }

  Future<void> _onAddToCart() async {
    final days = int.tryParse(_days.text.trim());
    if (days == null || days < 1 || days > 365) {
      showMessage(context, 'Nhập số ngày thuê từ 1 đến 365');
      return;
    }

    setState(() => _adding = true);
    try {
      final token = await SessionHelper.token;
      if (!mounted) return;
      if (token == null) {
        await Navigator.pushNamed(context, '/login');
        if (mounted) await _loadEquipment();
        return;
      }
      final obj = Cart(
        id: 0,
        memberId: null,
        equipmentId: _id!,
        quantity: days,
      );
      final result = await CartRepository.add(obj, token);
      if (mounted) {
        showMessage(
          context,
          result > 0 ? 'Đã lưu vào giỏ thuê' : 'Không lưu được vào giỏ thuê',
        );
      }
    } catch (_) {
      if (mounted) showMessage(context, 'Không lưu được vào giỏ thuê');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _editEquipment(Equipment item) async {
    var unit = item.unit ?? '';
    var status = item.status == Equipment.maintenance
        ? Equipment.maintenance
        : Equipment.available;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật thiết bị'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: unit,
              maxLength: 128,
              decoration: const InputDecoration(labelText: 'Đơn vị'),
              onChanged: (value) => unit = value.trim(),
            ),
            DropdownButtonFormField<String>(
              initialValue: status,
              items: [
                for (final value in [
                  Equipment.available,
                  Equipment.maintenance,
                ])
                  DropdownMenuItem(value: value, child: Text(value)),
              ],
              onChanged: (value) => status = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;
    if (unit.isEmpty) {
      showMessage(context, 'Nhập tên đơn vị');
      return;
    }
    try {
      final token = await SessionHelper.token;
      final saved =
          token != null &&
          await EquipmentRepository.update(item.id, unit, status, token);
      if (!mounted) return;
      showMessage(
        context,
        saved ? 'Đã cập nhật thiết bị' : 'Không cập nhật được thiết bị',
      );
      await _loadEquipment();
    } catch (_) {
      if (mounted) showMessage(context, 'Không cập nhật được thiết bị');
    }
  }

  Widget _loadTable(Equipment item) {
    final fields = {
      'Hãng': item.brand,
      'Model': item.model,
      'Thông số': item.specifications,
      'Đơn vị': item.unit,
    };
    final theme = Theme.of(context);
    return Table(
      columnWidths: const {0: FixedColumnWidth(84)},
      children: [
        for (final field in fields.entries)
          if (field.value != null)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 8),
                  child: Text(
                    field.key,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    field.value!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
      ],
    );
  }
}
