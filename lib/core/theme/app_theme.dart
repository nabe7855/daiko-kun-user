import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.actionOrange,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // テキストテーマ: 全体的に大きく読みやすい設定
      textTheme: GoogleFonts.notoSansJpTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textBlack,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textBlack,
        ),
        bodyLarge: const TextStyle(
          fontSize: 20, // 標準より大きめ
          color: AppColors.textDarkGray,
        ),
        bodyMedium: const TextStyle(
          fontSize: 18,
          color: AppColors.textDarkGray,
        ),
        labelLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),

      // ボタンテーマ: 誤操作を防ぐ大きなサイズ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionOrange,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 60), // 高さ60dp以上
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),

      // 入力欄テーマ
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
    );
  }
}
