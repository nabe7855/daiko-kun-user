import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  // プロフィールを更新する
  Future<bool> updateProfile(String id, String name, String email) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'name': name, 'email': email}),
      );

      if (response.statusCode == 200) {
        // 現在のステートを更新する
        final currentUser = state.value;
        if (currentUser != null) {
          final updatedUser = UserModel(
            id: currentUser.id,
            name: name,
            phoneNumber: currentUser.phoneNumber,
            email: email,
            socialId: currentUser.socialId,
            socialProvider: currentUser.socialProvider,
            status: currentUser.status,
          );
          state = AsyncValue.data(updatedUser);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // FCMトークンを更新する
  Future<void> updateFCMToken(String id, String token) async {
    try {
      await http.patch(
        Uri.parse('$baseUrl/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'fcm_token': token}),
      );
    } catch (e) {
      debugPrint('FCM token update error: $e');
    }
  }

  // アカウントを削除する
  Future<bool> deleteAccount(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  AuthNotifier.new,
);
