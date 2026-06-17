import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_page.dart';

// Paleta SilviaTextil v2
// Primaria     : azul profundo  #1E40AF
// Primaria grad: azul médio     #2563EB
// Acento       : âmbar dourado  #F59E0B
// Fundo        : cinza suave    #F1F5F9
// Superfície   : branco         #FFFFFF
// Borda        : cinza claro    #E2E8F0

class SewingStoreApp extends StatelessWidget {
  const SewingStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SilviaTextil',
      theme: _buildTheme(),
      home: const HomePage(),
    );
  }

  ThemeData _buildTheme() {
    const Color primary = Color(0xFF1E40AF);
    const Color accent = Color(0xFFF59E0B);

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        surface: Colors.white,
        error: const Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      useMaterial3: true,

      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: Color(0xFF0F172A),
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
          fontSize: 16,
        ),
        bodyMedium: TextStyle(color: Color(0xFF475569), height: 1.5),
        bodySmall: TextStyle(color: Color(0xFF64748B)),
      ),

      // Cards — borda fina, sem elevação (sombra aplicada inline)
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        margin: EdgeInsets.zero,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIconColor: const Color(0xFF94A3B8),
      ),

      // Botão preenchido
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
          elevation: 0,
        ),
      ),

      // Botão outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: const Color(0xFF1E293B),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        extendedPadding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: StadiumBorder(),
        elevation: 4,
      ),

      // AppBar (gradiente aplicado via flexibleSpace no HomePage)
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Bottom navigation
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFDBEAFE),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 22);
          }
          return const IconThemeData(color: Color(0xFF94A3B8), size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => TextStyle(
            fontSize: 11,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: s.contains(WidgetState.selected)
                ? primary
                : const Color(0xFF94A3B8),
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? primary : null),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            s.contains(WidgetState.selected)
                ? primary.withValues(alpha: 0.3)
                : null),
      ),
    );
  }
}
