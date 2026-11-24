import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rental_equipment_app/app_theme.dart';

void showMessage(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

String formatPrice(double price) {
  final parts = price
      .toStringAsFixed(price == price.roundToDouble() ? 0 : 2)
      .split('.');
  final amount = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '$amount${parts.length > 1 ? ',${parts.last}' : ''} ₫';
}

Widget equipmentStatus(String? status) {
  return statusPill(status ?? 'Chưa rõ tình trạng', switch (status) {
    'Sẵn sàng' => rentalSuccess,
    'Đang cho thuê' => rentalAccent,
    'Đang bảo trì' => rentalWarning,
    _ => const Color(0xFF64748B),
  });
}

Widget rentalStatus(int id, String label) {
  final color = switch (id) {
    1 => rentalDanger,
    2 => rentalWarning,
    3 || 4 => rentalAccent,
    5 => rentalSuccess,
    _ => const Color(0xFF64748B),
  };
  return statusPill(label, color);
}

Widget statusPill(String label, Color color) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color.lerp(color, Colors.black, .48),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

Widget equipmentImage(String imageUrl, {double size = 96}) =>
    _catalogImage('equipment', imageUrl, size, Icons.devices_other);

Widget categoryImage(String imageUrl) =>
    _catalogImage('categories', imageUrl, 24, Icons.category_outlined);

Widget _catalogImage(
  String folder,
  String imageUrl,
  double size,
  IconData fallback,
) {
  final icon = Icon(fallback, size: size * 0.65);
  if (imageUrl.isEmpty) return SizedBox.square(dimension: size, child: icon);
  return Image.network(
    "${dotenv.env['API_URL']}/$folder/${Uri.encodeComponent(imageUrl)}",
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stack) =>
        SizedBox.square(dimension: size, child: icon),
  );
}

String formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

Widget pageButtons(int page, int lastPage, ValueChanged<int> onPage) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        tooltip: 'Trang trước',
        onPressed: page > 1 ? () => onPage(page - 1) : null,
        icon: const Icon(Icons.chevron_left),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('Trang $page / $lastPage'),
      ),
      IconButton(
        tooltip: 'Trang sau',
        onPressed: page < lastPage ? () => onPage(page + 1) : null,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}

Future<bool> confirmDelete(BuildContext context, String name) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(name),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      ) ??
      false;
}

class PageContent extends StatelessWidget {
  const PageContent({super.key, required this.children, this.maxWidth = 1080});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final margin = ((constraints.maxWidth - maxWidth) / 2).clamp(
          16.0,
          double.infinity,
        );
        return ListView(
          padding: EdgeInsets.fromLTRB(margin, 20, margin, 26),
          children: children,
        );
      },
    );
  }
}
