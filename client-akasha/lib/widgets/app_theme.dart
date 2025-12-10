import 'package:akasha/core/constants.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static final Constants _constants = Constants();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: _constants.background,

      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontSize: 58,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),

        bodyMedium: TextStyle(fontSize: 14, color: _constants.primary),

        titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),

        labelSmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),

        headlineSmall: TextStyle(
          fontWeight: FontWeight.bold,
          color: _constants.primary,
        ),
      ),

      cardTheme: CardThemeData(color: _constants.card, elevation: 0),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: _constants.primary,
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _constants.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _constants.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _constants.border),
        ),
        hintStyle: TextStyle(color: _constants.border),
        labelStyle: TextStyle(fontSize: 16, color: _constants.border),
        isDense: false,
        hoverColor: Colors.transparent,
        filled: true,
        fillColor: _constants.input,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          foregroundColor: _constants.primaryForeground,
          backgroundColor: _constants.primary,
          textStyle: const TextStyle(fontSize: 14),
        ),
      ),

      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,

        backgroundColor: _constants.background,

        iconTheme: IconThemeData(color: _constants.primary),

        actionsIconTheme: IconThemeData(color: _constants.primary),

        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF000000),
        ),

        elevation: 0,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _constants.card,
        selectedItemColor: _constants.primary,
        unselectedItemColor: _constants.mutedForeground,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _constants.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      tabBarTheme: TabBarThemeData(
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
        labelColor: Constants().primary,
        indicatorColor: Constants().primary,
        dividerHeight: 0,
        overlayColor: MaterialStateProperty.all(
          Constants().primary.withOpacity(0.12),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Constants().border
          )
        ),
        color: Constants().card,
        
        elevation: 0
      )
      
    );

    
  }
}
