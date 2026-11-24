import 'package:flutter/material.dart';

const rentalBlue = Color(0xFF164E9A);
const rentalNavy = Color(0xFF102D52);
const rentalAccent = Color(0xFF3B82F6);
const rentalLightBlue = Color(0xFFDBEAFE);
const rentalSuccess = Color(0xFF16A34A);
const rentalWarning = Color(0xFFF59E0B);
const rentalDanger = Color(0xFFEF4444);
const _ink = Color(0xFF172B4D);
const _muted = Color(0xFF64748B);
const _canvas = Color(0xFFF1F5F9);
const _surface = Colors.white;
const _line = Color(0xFFE2E8F0);

ThemeData rentalTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: rentalBlue,
    primary: rentalBlue,
    onPrimary: Colors.white,
    secondary: rentalAccent,
    surface: _surface,
    onSurface: _ink,
    onSurfaceVariant: _muted,
    primaryContainer: rentalLightBlue,
    onPrimaryContainer: rentalNavy,
    outlineVariant: _line,
    error: const Color(0xFFB91C1C),
  );
  final base = ThemeData(
    colorScheme: colors,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: _canvas,
    visualDensity: VisualDensity.standard,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
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
      toolbarHeight: 68,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: _line)),
    ),
    cardTheme: CardThemeData(
      color: _surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _line),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _surface,
      selectedColor: colors.primaryContainer,
      side: const BorderSide(color: _line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        borderSide: const BorderSide(color: rentalAccent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: _line),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: const WidgetStatePropertyAll(_canvas),
      dataRowColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered) ? _canvas : null,
      ),
      headingTextStyle: TextStyle(
        color: colors.primary,
        fontWeight: FontWeight.w700,
      ),
      dividerThickness: 1,
      columnSpacing: 24,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: rentalBlue,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
