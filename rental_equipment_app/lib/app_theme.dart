import 'package:flutter/material.dart';

const _ink = Color(0xFF173B38);
const _accent = Color(0xFFA9482D);
const _canvas = Color(0xFFF5F3EE);
const _surface = Color(0xFFFFFDF9);
const _line = Color(0xFFE4E0D7);

ThemeData rentalTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: _ink,
    primary: _ink,
    secondary: _accent,
    surface: _surface,
    primaryContainer: const Color(0xFFDFEBE4),
    onPrimaryContainer: const Color(0xFF17372F),
    outlineVariant: _line,
  );
  final base = ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: _canvas,
    visualDensity: VisualDensity.standard,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _line),
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        color: _ink,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: _ink,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: _ink,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: _ink,
      toolbarHeight: 64,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: _line)),
    ),
    cardTheme: CardThemeData(
      color: _surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _line),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _surface,
      selectedColor: colors.primaryContainer,
      side: const BorderSide(color: _line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: TextStyle(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: _ink, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: _line),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(colors.primaryContainer),
      headingTextStyle: TextStyle(
        color: colors.primary,
        fontWeight: FontWeight.w700,
      ),
      dividerThickness: 1,
      columnSpacing: 24,
    ),
    dividerTheme: const DividerThemeData(color: _line),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

class CatalogPhoto extends StatelessWidget {
  const CatalogPhoto({super.key, this.alignment = Alignment.center});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/catalog-hero.png',
      alignment: alignment,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stack) => ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Center(
          child: Icon(
            Icons.photo_camera_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
