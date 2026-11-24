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
                                color: rentalNavy,
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
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          CatalogPhoto(
                                            alignment: Alignment.centerRight,
                                          ),
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Color(0x66102D52),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
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
                          padding: EdgeInsets.all(wide ? 32 : 20),
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

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    this.controller,
    required this.decoration,
    this.enabled = true,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController? controller;
  final InputDecoration decoration;
  final bool enabled;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: !_isVisible,
      autocorrect: false,
      enableSuggestions: false,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      decoration: widget.decoration.copyWith(
        suffixIcon: IconButton(
          tooltip: _isVisible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
          icon: Icon(
            _isVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: widget.enabled
              ? () => setState(() => _isVisible = !_isVisible)
              : null,
        ),
      ),
    );
  }
}
