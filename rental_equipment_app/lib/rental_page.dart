import 'package:flutter/material.dart';
import 'package:rental_equipment_app/helper.dart';
import 'package:rental_equipment_app/management_layout.dart';
import 'package:rental_equipment_app/member_repository.dart';
import 'package:rental_equipment_app/rental.dart';
import 'package:rental_equipment_app/rental_repository.dart';
import 'package:rental_equipment_app/session_helper.dart';
import 'package:rental_equipment_app/status_repository.dart';

class RentalPage extends StatefulWidget {
  final String title;
  const RentalPage({super.key, required this.title});

  @override
  State<RentalPage> createState() => _RentalPageState();
}

class _RentalPageState extends State<RentalPage> {
  List<Rental>? _rentals;
  Map<int, String> _statuses = {};
  String? _error;
  bool _isAdmin = false;
  bool _saving = false;
  final _search = TextEditingController();
  int? _number;
  DateTimeRange? _dates;
  int _request = 0;

  Future<void> _loadRentals() async {
    final request = ++_request;
    try {
      final token = await SessionHelper.token;
      if (token == null) throw StateError('Missing session');
      final rentals = await RentalRepository.getRentals(
        token,
        number: _number,
        dates: _dates,
      );
      final statuses = await StatusRepository.getStatuses();
      final member = await MemberRepository.getMember(token);
      if (!mounted || request != _request) return;
      setState(() {
        _rentals = rentals;
        _statuses = {for (final status in statuses) status.id: status.name};
        _isAdmin = member?.role == 2;
        _error = null;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = 'Không tải được phiếu thuê');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch() {
    final value = _search.text.trim().replaceFirst(RegExp(r'^#'), '');
    final number = int.tryParse(value);
    if (value.isNotEmpty &&
        (number == null || number < 1 || number > 2147483647)) {
      showMessage(context, 'Nhập mã phiếu thuê hợp lệ');
      return;
    }
    _number = number;
    _loadRentals();
  }

  Future<void> _onDate() async {
    final dates = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dates,
    );
    if (dates == null || !mounted) return;
    setState(() => _dates = dates);
    await _loadRentals();
  }

  List<int> _nextStatuses(int status) {
    if (!_isAdmin) return status == 2 ? [1] : [];
    return switch (status) {
      2 => [3, 1],
      3 => [4, 1],
      4 => [5],
      _ => [],
    };
  }

  Widget _loadListView(List<Rental> rentals) {
    return ManagementTable(
      columns: const ['Mã phiếu', 'Ngày lập', 'Trạng thái'],
      itemCount: rentals.length,
      emptyLabel: 'Chưa có phiếu thuê',
      rowBuilder: (index) {
        final item = rentals[index];
        return (
          cells: [
            RecordName(title: 'Phiếu #${item.id}'),
            Text(formatDate(item.dated)),
            Align(
              alignment: Alignment.centerLeft,
              child: rentalStatus(
                item.statusId,
                _statuses[item.statusId] ?? '',
              ),
            ),
          ],
          actions: [
            if (_nextStatuses(item.statusId).isNotEmpty)
              IconButton(
                onPressed: _saving ? null : () => _onUpdate(item),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Đổi trạng thái phiếu',
              ),
            IconButton(
              onPressed: () => _onDetails(item),
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'Chi tiết phiếu',
            ),
          ],
        );
      },
    );
  }

  Future<void> _onDetails(Rental item) async {
    await Navigator.pushNamed(context, '/rental/details', arguments: item.id);
  }

  Future<void> _onUpdate(Rental item) async {
    final options = _nextStatuses(item.statusId);
    var selected = options.first;
    final status = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cập nhật phiếu #${item.id}'),
        content: DropdownButtonFormField<int>(
          initialValue: selected,
          decoration: const InputDecoration(labelText: 'Trạng thái'),
          items: [
            for (final id in options)
              DropdownMenuItem(value: id, child: Text(_statuses[id] ?? '')),
          ],
          onChanged: (value) => selected = value ?? selected,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, selected),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (status == null || !mounted) return;
    await _onSave(item.id, status);
  }

  Future<void> _onSave(int id, int status) async {
    setState(() => _saving = true);
    try {
      final token = await SessionHelper.token;
      final changed =
          token != null &&
          await RentalRepository.updateStatus(id, status, token) > 0;
      if (!mounted) return;
      showMessage(
        context,
        changed ? 'Đã cập nhật phiếu thuê' : 'Không cập nhật được phiếu thuê',
      );
      await _loadRentals();
    } catch (_) {
      if (mounted) showMessage(context, 'Không cập nhật được phiếu thuê');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rentals = _rentals;
    return ManagementScaffold(
      title: widget.title,
      route: '/rental',
      showNavigation: _isAdmin,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 360,
                    child: TextField(
                      controller: _search,
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _onSearch(),
                      decoration: InputDecoration(
                        labelText: 'Tìm theo mã phiếu thuê',
                        suffixIcon: IconButton(
                          onPressed: _onSearch,
                          tooltip: 'Tìm',
                          icon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                  if (_isAdmin)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      onPressed: _onDate,
                      label: Text(
                        _dates == null
                            ? 'Lọc theo ngày'
                            : '${formatDate(_dates!.start)} – ${formatDate(_dates!.end)}',
                      ),
                    ),
                  if (_isAdmin && _dates != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _dates = null);
                        _loadRentals();
                      },
                      child: const Text('Bỏ lọc'),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _error != null
                ? Center(
                    child: TextButton(
                      onPressed: _loadRentals,
                      child: Text('$_error. Thử lại'),
                    ),
                  )
                : rentals == null
                ? const Center(child: CircularProgressIndicator())
                : rentals.isEmpty
                ? const Center(child: Text('Chưa có phiếu thuê'))
                : _loadListView(rentals),
          ),
        ],
      ),
    );
  }
}
