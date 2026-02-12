import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/user_model.dart';

class AuthNotifier extends Notifier<AsyncValue<UserModel?>> {
  @override
  AsyncValue<UserModel?> build() {
    return const AsyncValue.data(null);
  }

  static const String baseUrl = 'http://localhost:8080/customer';

  // SMS認証コードをリクエストする
  Future<bool> requestOTP(String phoneNumber) async {
    state = const AsyncValue.loading();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phoneNumber}),
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null); // まだログインはしていない
        return true;
      } else {
        state = AsyncValue.error(
          'コード送信失敗: ${response.statusCode}',
          StackTrace.current,
        );
        return false;
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // 認証コードを検証してログイン/登録を完了する
  Future<bool> verifyOTP(String phoneNumber, String code) async {
    state = const AsyncValue.loading();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phoneNumber, 'code': code}),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final user = UserModel.fromJson(userData);
        state = AsyncValue.data(user);
        return true;
      } else {
        state = AsyncValue.error(
          '認証失敗: ${response.statusCode}',
          StackTrace.current,
        );
        return false;
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  void logout() {
    state = const AsyncValue.data(null);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  AuthNotifier.new,
);
