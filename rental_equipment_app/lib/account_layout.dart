import 'package:flutter/material.dart';
import 'package:rental_equipment_app/app_theme.dart';

class AccountLayout extends StatelessWidget {
  const AccountLayout({
    super.key,
    required this.children,
    this.withPhoto = false,
  });

  final List<Widget> children;
  final bool withPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = withPhoto && constraints.maxWidth >= 820;
        final padding = constraints.maxWidth < 480 ? 16.0 : 24.0;
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - padding * 2).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 860 : 465),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      if (wide)
                        SizedBox(
                          width: 328,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 12, 0, 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: ColoredBox(
                                color: theme.colorScheme.primary,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        32,
                                        24,
                                        24,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Quản lý thiết bị cho thuê',
                                              style: theme
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onPrimary,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 197,
                                      width: double.infinity,
                                      child: CatalogPhoto(
                                        alignment: Alignment.centerRight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(wide ? 32 : 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 12,
                            children: children,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
