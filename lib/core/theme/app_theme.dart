import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors - Warm Campus Utility
  static const Color burntOrange = Color(0xFFC2410C); // #C2410C Primary
  static const Color flameOrange = Color(0xFFF97316); // #F97316
  static const Color deepOrange = Color(0xFF9A3412);  // #9A3412
  static const Color peachTint = Color(0xFFFFEDD5);   // #FFEDD5 Container
  static const Color peachBg = Color(0xFFFFF7ED);     // #FFF7ED Subtle
  
  // Neutral Surfaces & Borders
  static const Color canvasPaper = Color(0xFFFAFAF9); // #FAFAF9 Stone 50
  static const Color cardWhite = Colors.white;
  static const Color borderStone = Color(0xFFE7E5E4); // #E7E5E4 Stone 200
  static const Color stoneBorder = Color(0xFFE7E5E4);
  static const Color borderStoneLight = Color(0xFFF5F5F4);
  
  // Text Colors
  static const Color textStone900 = Color(0xFF1C1917); // Stone 900
  static const Color textStone700 = Color(0xFF44403C); // Stone 700
  static const Color textStone600 = Color(0xFF57534E); // Stone 600
  static const Color textStone500 = Color(0xFF78716C); // Stone 500
  static const Color textStone400 = Color(0xFFA8A29E); // Stone 400
  static const Color textStone300 = Color(0xFFD6D3D1); // Stone 300

  // Status Badge Colors (Never generic blue)
  // Safe / Scheduled (Mint)
  static const Color mintBg = Color(0xFFECFDF5);
  static const Color emeraldText = Color(0xFF065F46);
  static const Color mintBorder = Color(0xFFA7F3D0);

  // Cancelled / Deficit (Blush)
  static const Color blushBg = Color(0xFFFEF2F2);
  static const Color oxbloodText = Color(0xFF991B1B);
  static const Color blushBorder = Color(0xFFFECACA);

  // Relocated / Room Changed / Day Override (Sky)
  static const Color skyBg = Color(0xFFEFF6FF);
  static const Color navyText = Color(0xFF1E40AF);
  static const Color skyBorder = Color(0xFFBFDBFE);

  // Extra Session (Lilac)
  static const Color lilacBg = Color(0xFFF5F3FF);
  static const Color plumText = Color(0xFF5B21B6);
  static const Color lilacBorder = Color(0xFFDDD6FE);

  // In Progress / Live (Orange Tint)
  static const Color liveOrangeBg = Color(0xFFFFF7ED);
  static const Color liveOrangeText = Color(0xFFC2410C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: burntOrange,
        primary: burntOrange,
        secondary: flameOrange,
        surface: canvasPaper,
        surfaceTint: Colors.transparent,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: canvasPaper,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: textStone900,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          color: textStone900,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          color: textStone900,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: textStone900,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: textStone900,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: textStone900,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textStone900,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textStone700,
        ),
        bodySmall: GoogleFonts.inter(
          color: textStone500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvasPaper,
        foregroundColor: textStone900,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textStone900,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderStone, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: burntOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderStone),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderStone),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: burntOrange, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardWhite,
        elevation: 4,
        indicatorColor: peachTint,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: burntOrange);
          }
          return const IconThemeData(color: textStone500);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: burntOrange,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textStone500,
          );
        }),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
