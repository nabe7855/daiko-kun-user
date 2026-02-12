import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_colors.dart';

class MatchingScreen extends StatefulWidget {
  final String? requestId;
  const MatchingScreen({super.key, this.requestId});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _messageIndex = 0;
  Timer? _messageTimer;
  Timer? _pollingTimer;

  final List<String> _searchMessages = [
    'ドライバーを探しています...',
    '近くの優良ドライバーに通知中...',
    '最適なドライバーを選定中...',
    'もうすぐ見つかります...',
  ];

  @override
  void initState() {
    super.initState();

    // アニメーションコントローラー（波紋エフェクト用）
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // メッセージローテーション
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _searchMessages.length;
        });
      }
    });

    // バックエンドのステータスをポーリング
    if (widget.requestId != null) {
      _startPolling();
    } else {
      // リクエストIDがない場合はデバッグ用に5秒後に遷移
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) context.go('/trip?requestId=${widget.requestId}');
      });
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        // DriverSideと同じAPIを使う
        final response = await http.get(
          Uri.parse('http://localhost:8080/admin/ride-requests'),
        );

        if (response.statusCode == 200) {
          final List<dynamic> requests = json.decode(response.body);
          final myRequest = requests.firstWhere(
            (r) => r['id'] == widget.requestId,
            orElse: () => null,
          );

          if (myRequest != null && myRequest['status'] != 'pending') {
            _pollingTimer?.cancel();
            if (mounted) {
              context.go('/trip?requestId=${widget.requestId}');
            }
          }
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textBlack),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // アニメーション付き検索インジケーター
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // 外側の波紋1
                      Container(
                        width: 250 * _animationController.value,
                        height: 250 * _animationController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.actionOrange.withValues(
                              alpha: 1.0 - _animationController.value,
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                      // 外側の波紋2（位相をずらす）
                      Container(
                        width: 250 * ((_animationController.value + 0.5) % 1.0),
                        height:
                            250 * ((_animationController.value + 0.5) % 1.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.actionOrange.withValues(
                              alpha:
                                  1.0 -
                                  ((_animationController.value + 0.5) % 1.0),
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                      // 中央のサークル
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_search,
                          size: 80,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 60),

            // ステータスメッセージ（アニメーション付き）
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _searchMessages[_messageIndex],
                key: ValueKey<int>(_messageIndex),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                '通常30秒以内にマッチングが完了します',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),

            const Spacer(),

            // キャンセルボタン
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: OutlinedButton(
                onPressed: () {
                  context.pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'リクエストをキャンセル',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
