import 'package:flutter/material.dart';
import 'package:rental_equipment_app/cart_ext.dart';
import 'package:rental_equipment_app/cart_repository.dart';
import 'package:rental_equipment_app/helper.dart';
import 'package:rental_equipment_app/rental_repository.dart';
import 'package:rental_equipment_app/session_helper.dart';

class CartPage extends StatefulWidget {
  final String title;
  const CartPage({super.key, required this.title});
  @override
  State<StatefulWidget> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartExt> _carts = [];
  String? _error;
  bool _checkingOut = false;
  @override
  void initState() {
    super.initState();
    _loadCarts();
  }

  Future<void> _loadCarts() async {
    String? token = await SessionHelper.token;
    if (token == null) return;
    try {
      final carts = await CartRepository.getCarts(token);
      if (mounted) {
        setState(() {
          _carts = carts;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tải được giỏ thuê');
    }
  }

  Widget _loadTable() {
    return DataTable(
      columns: [
        DataColumn(label: Text('Thiết bị')),
        DataColumn(label: Text('Đơn vị')),
        DataColumn(label: Text('Giá/ngày')),
        DataColumn(label: Text('Số ngày')),
        DataColumn(label: Text('Thành tiền')),
        DataColumn(label: Text('Thao tác')),
      ],
      rows: _carts
          .map(
            (p) => DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      equipmentImage(p.imageUrl, size: 36),
                      const SizedBox(width: 8),
                      Text(p.name),
                    ],
                  ),
                ),
                DataCell(
                  Text([p.unit, p.status].whereType<String>().join(' · ')),
                ),
                DataCell(Text(formatPrice(p.price))),
                DataCell(
                  Text('${p.quantity}'),
                  showEditIcon: true,
                  onTap: _checkingOut ? null : () => _onUpdate(p),
                ),
                DataCell(Text(formatPrice(p.price * p.quantity))),
                DataCell(
                  ElevatedButton.icon(
                    onPressed: _checkingOut ? null : () => _onDelete(p.id),
                    label: Text('Xóa'),
                    icon: Icon(Icons.delete),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Future<void> _onUpdate(CartExt item) async {
    final key = GlobalKey<FormState>();
    int quantity = item.quantity;
    final days = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa số ngày thuê'),
        content: Form(
          key: key,
          child: TextFormField(
            initialValue: '$quantity',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Số ngày (1–365)'),
            validator: (value) {
              final number = int.tryParse(value?.trim() ?? '');
              return number == null || number < 1 || number > 365
                  ? 'Nhập từ 1 đến 365 ngày'
                  : null;
            },
            onChanged: (value) => quantity = int.tryParse(value.trim()) ?? 0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(context, quantity);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (days == null || !mounted) return;
    setState(() => _checkingOut = true);
    try {
      final token = await SessionHelper.token;
      if (token == null ||
          await CartRepository.update(item.id, days, token) <= 0) {
        throw StateError('Cart update failed');
      }
      await _loadCarts();
    } catch (_) {
      if (mounted) setState(() => _error = 'Không cập nhật được số ngày thuê');
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  void _onDelete(int id) async {
    String? token = await SessionHelper.token;
    if (token != null && token.isNotEmpty) {
      int ret;
      try {
        ret = await CartRepository.delete(id, token);
      } catch (_) {
        ret = 0;
      }
      if (!mounted) return;
      if (ret > 0) {
        _loadCarts();
      } else {
        setState(() {
          _error = "Không xóa được thiết bị";
        });
      }
    } else if (mounted) {
      setState(() {
        _error = "Vui lòng đăng nhập";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _carts.fold<double>(
      0,
      (sum, item) => sum + item.price * item.quantity,
    );
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: PageContent(
        children: [
          if (_carts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 42,
                      color: theme.colorScheme.primary,
                    ),
                    Text(
                      'Giỏ thuê đang trống',
                      style: theme.textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Xem thiết bị'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Card(
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: _loadTable(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  runSpacing: 10,
                  spacing: 22,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Tổng tiền thuê', style: theme.textTheme.titleMedium),
                    Text(
                      formatPrice(total),
                      style: theme.textTheme.headlineSmall,
                    ),
                    FilledButton.icon(
                      onPressed: _checkingOut ? null : _onCheckout,
                      label: const Text('Lập phiếu thuê'),
                      icon: const Icon(Icons.shopping_cart_checkout),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onCheckout() async {
    setState(() {
      _checkingOut = true;
      _error = null;
    });
    try {
      final token = await SessionHelper.token;
      if (!mounted) return;
      if (token == null) {
        setState(() => _error = 'Vui lòng đăng nhập');
        return;
      }
      final id = await RentalRepository.add(token);
      if (!mounted) return;
      if (id > 0) {
        showMessage(context, 'Đã lập phiếu thuê');
        await Navigator.pushNamed(context, '/rental/details', arguments: id);
        if (mounted) Navigator.pop(context);
      } else {
        setState(
          () =>
              _error = 'Không lập được phiếu. Kiểm tra thiết bị còn sẵn sàng.',
        );
        await _loadCarts();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Không lập được phiếu thuê');
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }
}
