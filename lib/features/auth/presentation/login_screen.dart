import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/user_model.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isAgreed = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!_isAgreed || _phoneController.text.isEmpty) return;

    final success = await ref
        .read(authProvider.notifier)
        .requestOTP(_phoneController.text);
    if (success && mounted) {
      context.push('/otp?phone=${Uri.encodeComponent(_phoneController.text)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ログイン済みチェック（リロード時など）
    ref.listen<AsyncValue<UserModel?>>(authProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        context.go('/home');
      } else if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: ${next.error}')));
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // ロゴ
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.actionOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'D',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                '携帯電話番号を入力',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ご本人確認のためSMSで認証コードを送ります',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              // 電話番号入力
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Image.network(
                          'https://flagcdn.com/w20/jp.png',
                          width: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '+81',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                    const VerticalDivider(width: 20),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '805 1992 137',
                          border: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_phoneController.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _phoneController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.cancel, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 利用規約
              Row(
                children: [
                  Checkbox(
                    value: _isAgreed,
                    onChanged: (value) {
                      setState(() {
                        _isAgreed = value ?? false;
                      });
                    },
                    activeColor: AppColors.actionOrange,
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        children: [
                          const TextSpan(text: 'ご確認のうえ同意してください '),
                          TextSpan(
                            text: '《利用規約及びプライバシーポリシー》',
                            style: TextStyle(
                              color: AppColors.actionOrange,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // 次へボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_isAgreed &&
                          _phoneController.text.isNotEmpty &&
                          !authState.isLoading)
                      ? _handleNext
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionOrange,
                    disabledBackgroundColor: AppColors.actionOrange.withOpacity(
                      0.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '次へ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
              // 区切り線
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'または',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 32),
              // ソーシャルログイン
              _buildSocialButton(
                icon: Icons.g_mobiledata,
                label: 'Googleでログイン',
                color: Colors.grey.shade100,
                textColor: Colors.black,
              ),
              const SizedBox(height: 16),
              _buildSocialButton(
                icon: Icons.facebook,
                label: 'Facebookでログイン',
                color: Colors.grey.shade100,
                textColor: Colors.black,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: Colors.blue),
        label: Text(label, style: TextStyle(color: textColor, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }
}
