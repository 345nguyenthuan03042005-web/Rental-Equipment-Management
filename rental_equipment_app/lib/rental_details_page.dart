import 'package:flutter/material.dart';
import 'package:rental_equipment_app/payment_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rental_equipment_app/helper.dart';
import 'package:rental_equipment_app/rental.dart';
import 'package:rental_equipment_app/rental_repository.dart';
import 'package:rental_equipment_app/session_helper.dart';
import 'package:rental_equipment_app/status_repository.dart';

class RentalDetailsPage extends StatefulWidget {
  final String title;
  const RentalDetailsPage({super.key, required this.title});

  @override
  State<RentalDetailsPage> createState() => _RentalDetailsPageState();
}

class _RentalDetailsPageState extends State<RentalDetailsPage> {
  int? _id;
  Rental? _rental;
  Map<int, String> _statuses = {};
  String? _error;
  RentalPayment? _payment;
  List<String> _methods = [];
  bool _paying = false;
  static const _paymentNames = {'vnpay': 'VNPay', 'vietqr': 'VietQR'};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_id != null) return;
    _id = ModalRoute.of(context)!.settings.arguments as int;
    _loadRental();
  }

  Future<void> _loadRental() async {
    try {
      final token = await SessionHelper.token;
      if (token == null) throw StateError('Missing session');
      final data = await RentalRepository.getRental(_id!, token);
      final statuses = await StatusRepository.getStatuses();
      if (!mounted) return;
      setState(() {
        _rental = data;
        _statuses = {for (final status in statuses) status.id: status.name};
        _error = null;
      });
      await _loadPayment();
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tải được phiếu thuê');
    }
  }

  Future<void> _loadPayment() async {
    setState(() => _paying = true);
    try {
      final token = await SessionHelper.token;
      if (token == null) return;
      final result = await PaymentRepository.getPayment(_id!, token);
      if (!mounted) return;
      setState(() {
        _payment = result.payment;
        _methods = result.methods;
      });
    } catch (_) {
      if (mounted) showMessage(context, 'Chưa kiểm tra được thanh toán.');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _startPayment(String method) async {
    setState(() => _paying = true);
    try {
      final token = await SessionHelper.token;
      if (token == null) return;
      final payment = await PaymentRepository.start(_id!, method, token);
      if (mounted) setState(() => _payment = payment);
    } catch (error) {
      if (mounted) {
        showMessage(context, error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _openPayment(String url) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        showMessage(context, 'Không mở được cổng thanh toán.');
      }
    } catch (_) {
      if (mounted) showMessage(context, 'Không mở được cổng thanh toán.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rental = _rental;
    final payment = _payment;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _error != null
          ? Center(
              child: TextButton(
                onPressed: _loadRental,
                child: Text('$_error. Thử lại'),
              ),
            )
          : rental == null
          ? const Center(child: CircularProgressIndicator())
          : PageContent(
              maxWidth: 840,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Phiếu #${rental.id}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            rentalStatus(
                              rental.statusId,
                              _statuses[rental.statusId] ??
                                  '${rental.statusId}',
                            ),
                          ],
                        ),
                        Text('Ngày lập ${formatDate(rental.dated)}'),
                        const Divider(),
                        Text(
                          'Thiết bị thuê',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        for (final item in rental.details)
                          ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              '${item.unit ?? "Chưa phân đơn vị"} · ${item.days} ngày × ${formatPrice(item.price)}',
                            ),
                            trailing: Text(formatPrice(item.days * item.price)),
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Tổng tiền: ${formatPrice(rental.details.fold<double>(0, (sum, item) => sum + item.days * item.price))}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        if (_methods.isNotEmpty || payment != null) ...[
                          const Divider(),
                          Text(switch (payment?.state) {
                            1 =>
                              'Đã thanh toán qua ${_paymentNames[payment!.method]}',
                            0 =>
                              'Chờ xác nhận thanh toán qua ${_paymentNames[payment!.method]}',
                            2 => 'Giao dịch trước đã kết thúc',
                            _ => 'Thanh toán phiếu thuê',
                          }),
                          if (payment?.state != 1)
                            Wrap(
                              spacing: 8,
                              children: [
                                if (payment?.url != null)
                                  FilledButton(
                                    onPressed: _paying
                                        ? null
                                        : () => _openPayment(payment!.url!),
                                    child: const Text('Mở cổng thanh toán'),
                                  )
                                else
                                  for (final method in _methods.where(
                                    (method) =>
                                        payment?.state != 0 ||
                                        payment?.method == method,
                                  ))
                                    FilledButton(
                                      onPressed: _paying
                                          ? null
                                          : () => _startPayment(method),
                                      child: Text(
                                        _paymentNames[method] ?? method,
                                      ),
                                    ),
                                if (payment != null)
                                  OutlinedButton(
                                    onPressed: _paying ? null : _loadPayment,
                                    child: const Text('Kiểm tra thanh toán'),
                                  ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
