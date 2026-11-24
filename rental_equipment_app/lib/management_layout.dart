import 'package:flutter/material.dart';
import 'package:rental_equipment_app/app_theme.dart';

const managementBreakpoint = 1024.0;

class ManagementNavigation extends StatelessWidget {
  const ManagementNavigation({
    super.key,
    required this.activeRoute,
    required this.onSelected,
  });

  static const _destinations = [
    ('/', 'Thiết bị cho thuê', Icons.home_outlined),
    ('/admin/category', 'Danh mục', Icons.category_outlined),
    ('/admin/equipment', 'Thiết bị', Icons.devices_other_outlined),
    ('/admin/member', 'Thành viên', Icons.group_outlined),
    ('/rental', 'Phiếu thuê', Icons.receipt_long_outlined),
  ];

  final String activeRoute;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: rentalNavy,
      child: SafeArea(
        right: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(6, 10, 4, 20),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: rentalBlue,
                      borderRadius: BorderRadius.all(Radius.circular(9)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Quản lý thiết bị cho thuê',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 8),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 16, 10, 8),
              child: Text(
                'Quản trị',
                style: TextStyle(color: rentalLightBlue, fontSize: 12),
              ),
            ),
            for (final (route, label, icon) in _destinations)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  leading: Icon(icon, size: 20),
                  title: Text(label),
                  selected: activeRoute == route,
                  selectedTileColor: rentalBlue,
                  selectedColor: Colors.white,
                  textColor: rentalLightBlue,
                  iconColor: rentalLightBlue,
                  hoverColor: Colors.white12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () => onSelected(route),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Drawer managementDrawer(String route, ValueChanged<String> onSelected) {
  return Drawer(
    child: Builder(
      builder: (context) => ManagementNavigation(
        activeRoute: route,
        onSelected: (value) {
          Navigator.of(context).pop();
          onSelected(value);
        },
      ),
    ),
  );
}

class ManagementScaffold extends StatelessWidget {
  const ManagementScaffold({
    super.key,
    required this.title,
    required this.route,
    required this.body,
    this.showNavigation = true,
  });

  final String title;
  final String route;
  final Widget body;
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= managementBreakpoint;
    final sidebar = showNavigation && wide;
    final drawer = showNavigation && !wide;
    void select(String value) {
      if (value == route) return;
      final navigator = Navigator.of(context);
      if (value == '/') {
        navigator.popUntil((entry) => entry.isFirst);
      } else {
        navigator.pushNamed(value);
      }
    }

    return Scaffold(
      drawer: drawer ? managementDrawer(route, select) : null,
      appBar: AppBar(
        title: Row(
          children: [
            if (sidebar) ...[
              Text('Quản trị', style: Theme.of(context).textTheme.bodyMedium),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right, size: 17),
              ),
            ],
            Flexible(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        leading: drawer
            ? Builder(
                builder: (context) => IconButton(
                  tooltip: 'Mở menu quản trị',
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        actions: [if (drawer) const BackButton(), const SizedBox(width: 8)],
      ),
      body: Row(
        children: [
          if (sidebar)
            SizedBox(
              width: 228,
              child: ManagementNavigation(
                activeRoute: route,
                onSelected: select,
              ),
            ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: EdgeInsets.all(wide ? 24 : 12),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ManagementTable extends StatelessWidget {
  const ManagementTable({
    super.key,
    required this.columns,
    required this.itemCount,
    required this.rowBuilder,
    required this.emptyLabel,
  });

  final List<String> columns;
  final int itemCount;
  final ({List<Widget> cells, List<Widget> actions}) Function(int) rowBuilder;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (itemCount == 0) {
      return Center(
        child: Text(
          emptyLabel,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 680;
            final widths = [
              for (var i = 0; i < columns.length; i++) i == 0 ? 3 : 2,
            ];
            const actionsWidth = 108.0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (wide)
                  ColoredBox(
                    color: theme.scaffoldBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                      child: Row(
                        children: [
                          for (var i = 0; i < columns.length; i++)
                            Expanded(
                              flex: widths[i],
                              child: Text(
                                columns[i],
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                          SizedBox(
                            width: actionsWidth,
                            child: Center(
                              child: Text(
                                'Thao tác',
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Flexible(
                  child: ListView.separated(
                    primary: false,
                    shrinkWrap: true,
                    itemCount: itemCount,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final row = rowBuilder(index);
                      final actions = Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: row.actions,
                      );
                      return Material(
                        color: index.isOdd
                            ? theme.scaffoldBackgroundColor.withValues(
                                alpha: .38,
                              )
                            : colors.surface,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 16 : 12,
                            8,
                            wide ? 8 : 2,
                            8,
                          ),
                          child: Row(
                            children: [
                              if (wide) ...[
                                for (var i = 0; i < row.cells.length; i++)
                                  Expanded(
                                    flex: widths[i],
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: row.cells[i],
                                    ),
                                  ),
                                SizedBox(width: actionsWidth, child: actions),
                              ] else ...[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 5,
                                    children: row.cells,
                                  ),
                                ),
                                actions,
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class RecordName extends StatelessWidget {
  const RecordName({super.key, required this.title, this.leading});

  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[
          ClipRRect(borderRadius: BorderRadius.circular(8), child: leading),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
