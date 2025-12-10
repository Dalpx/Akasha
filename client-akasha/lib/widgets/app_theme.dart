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
          fontFamily: 'Roboto', 
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
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _constants.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      )
    );
  }

  static ThemeData get darkTheme {
    
    final Color backgroundDark = _constants.foreground;
    final Color cardDark = _constants.primary;
    final Color inputDark = _constants.primary;

    final Color foregroundDark = _constants.background;
    
    final Color borderDark = _constants.mutedForeground;
    final Color mutedForegroundDark = _constants.border;
    
    final Color primaryAccent = _constants.secondary;


    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: backgroundDark,

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 58,
          fontWeight: FontWeight.w400,
          fontFamily: 'Roboto',
          color: foregroundDark,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: foregroundDark),
        titleLarge: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.bold,
            color: foregroundDark,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: mutedForegroundDark,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.bold,
          color: primaryAccent,
        ),
      ),

      cardTheme: CardThemeData(color: cardDark, elevation: 0),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryAccent,
        selectionHandleColor: primaryAccent,
        selectionColor: primaryAccent.withOpacity(0.3),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryAccent, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderDark),
        ),
        hintStyle: TextStyle(color: mutedForegroundDark),
        labelStyle: TextStyle(fontSize: 16, color: mutedForegroundDark),
        isDense: false,
        hoverColor: Colors.transparent, 
        filled: true,
        fillColor: inputDark,
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
        
        backgroundColor: backgroundDark,
        
        iconTheme: IconThemeData(color: primaryAccent),
        
        actionsIconTheme: IconThemeData(color: primaryAccent),
        
        titleTextStyle: TextStyle(
          fontSize: 22, 
          fontWeight: FontWeight.bold,
          color: foregroundDark,
        ),
        
        elevation: 0, 
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        
        backgroundColor: cardDark,
        selectedItemColor: primaryAccent,
        unselectedItemColor: borderDark,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 0, 
        type: BottomNavigationBarType.fixed,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: TextStyle(
          color: foregroundDark,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: mutedForegroundDark,
        ),
      ),
    );
  }
}