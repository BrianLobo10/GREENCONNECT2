import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00C853);
  static const Color secondary = Color(0xFFA5D6A7);
  static const Color background = Color(0xFFF9FBE7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFD32F2F);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

