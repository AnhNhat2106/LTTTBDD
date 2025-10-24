import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  /// 🔹 Hàm load theme, được gọi trong main.dart
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? false;
  }

  /// 🔹 Chuyển đổi theme và lưu lại
  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', _isDark);
  }

  ThemeData get themeData => _isDark ? _darkTheme : _lightTheme;

  // 🌘 Giao diện TỐI (Ocean Night)
  static final _darkTheme = ThemeData.dark().copyWith(
    primaryColor: const Color(0xFF1976D2), // xanh dương đậm
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1976D2),
      secondary: Color(0xFF64B5F6),
      surface: Color(0xFF0D1B2A),
    ),
    scaffoldBackgroundColor: const Color(0xFF0D1B2A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1565C0),
      foregroundColor: Colors.white,
      elevation: 3,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF64B5F6), width: 2),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
      bodyLarge: TextStyle(color: Colors.white),
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white, size: 22),
  );

  // ☀️ Giao diện SÁNG (Ocean Light)
  static final _lightTheme = ThemeData.light().copyWith(
    primaryColor: const Color(0xFF1976D2),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1976D2),
      secondary: Color(0xFF64B5F6),
      surface: Color(0xFFE3F2FD),
    ),
    scaffoldBackgroundColor: const Color(0xFFE3F2FD),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1976D2),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
      bodyLarge: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
