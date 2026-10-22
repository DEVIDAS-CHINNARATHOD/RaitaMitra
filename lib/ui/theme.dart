import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const ink = Color(0xFF142C47);
const blueInk = Color(0xFF102E4B);
const blueText = Color(0xFF1684C2);
const blueMuted = Color(0xFF64809B);
const muted = Color(0xFF7A8DA3);
const paper = Color(0xFFFFFFFF);
const line = Color(0xFFE3EBF2);
const brandBlue = Color(0xFF429BC8);
const headerBlue = brandBlue;
const accentBlue = Color(0xFF1684C2);
const skyBlue = Color(0xFF9BCFEB);
const paleBlue = Color(0xFFEAF6FC);
const selectedBlue = Color(0xFFD8EEF9);
const navBlueStart = Color(0xFF4098C6);
const navBlueEnd = Color(0xFF68B5D8);

class ScenicAppBarBackground extends StatelessWidget {
  const ScenicAppBarBackground({super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
    child: Image.asset(
      'assets/images/header_landscape.png',
      fit: BoxFit.cover,
      alignment: Alignment.bottomCenter,
    ),
  );
}

ThemeData appTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: brandBlue,
        brightness: Brightness.light,
      ).copyWith(
        primary: brandBlue,
        onPrimary: blueInk,
        primaryContainer: selectedBlue,
        onPrimaryContainer: blueInk,
        secondary: skyBlue,
        onSecondary: blueInk,
        secondaryContainer: paleBlue,
        onSecondaryContainer: blueInk,
        surface: paper,
        onSurface: ink,
        outline: line,
        surfaceTint: Colors.transparent,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: blueInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: blueInk,
      ),
      toolbarHeight: 92,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: ink,
        height: 1.14,
        letterSpacing: -.8,
      ),
      headlineMedium: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w600,
        color: ink,
        letterSpacing: -.7,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: ink),
      bodySmall: TextStyle(fontSize: 12, height: 1.5, color: muted),
    ),
    iconTheme: const IconThemeData(color: accentBlue),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: brandBlue, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brandBlue,
        foregroundColor: blueInk,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentBlue,
        minimumSize: const Size(48, 50),
        side: const BorderSide(color: accentBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    cardTheme: CardThemeData(
      color: paper,
      elevation: 1,
      margin: EdgeInsets.zero,
      shadowColor: Color(0x1A183B5B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: line),
      ),
    ),
    dividerTheme: const DividerThemeData(color: line, space: 1),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accentBlue),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: paper,
      selectedColor: skyBlue,
      side: const BorderSide(color: line),
      labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: brandBlue,
      foregroundColor: blueInk,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      extendedTextStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: blueInk,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: Color(0xFFE1F3FC),
      height: 70,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? blueText
              : Colors.white,
          size: 23,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accentBlue,
      linearTrackColor: paleBlue,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: blueInk,
      unselectedLabelColor: muted,
      indicatorColor: brandBlue,
    ),
  );
}
