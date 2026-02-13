import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import 'chat_screen.dart';

class TripScreen extends StatefulWidget {
  final String? requestId;
  const TripScreen({super.key, this.requestId});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  Timer? _pollingTimer;
  Map<String, dynamic>? _requestData;
  final MapController _mapController = MapController();

  // デフォルト位置（データ取得後に更新）
  LatLng _userLocation = const LatLng(35.681236, 139.767125);
  LatLng _driverLocation = const LatLng(35.685236, 139.767125); // 少し離れた場所

  @override
  void initState() {
    super.initState();
    if (widget.requestId != null) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        String baseUrl = 'http://localhost:8080';

        // IDで指定して1件取得
        final response = await http.get(
          Uri.parse('$baseUrl/customer/ride-requests/${widget.requestId}'),
        );

        if (response.statusCode == 200) {
          final myRequest = json.decode(response.body);

          if (myRequest != null) {
            final status = myRequest['status'];

            // 完了ステータスなら即時遷移
            if (status == 'completed') {
              _pollingTimer?.cancel();
              final fare =
                  (myRequest['actual_fare'] ?? myRequest['estimated_fare'] ?? 0)
                      .toString();
              if (mounted) {
                // 画面を一瞬更新してから遷移
                setState(() {
                  _requestData = myRequest;
                });
                context.go('/rating?requestId=${widget.requestId}&fare=$fare');
                return;
              }
            }

            // 緊急停止やキャンセル
            if (status == 'cancelled') {
              _pollingTimer?.cancel();
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('走行がキャンセルされました')));
                context.go('/'); // ホームに戻る
                return;
              }
            }

            setState(() {
              _requestData = myRequest;

              if (myRequest['pickup_lat'] != null &&
                  myRequest['pickup_lng'] != null) {
                _userLocation = LatLng(
                  myRequest['pickup_lat'],
                  myRequest['pickup_lng'],
                );
                // ドライバー位置の更新
                if (myRequest['driver_current_lat'] != null &&
                    myRequest['driver_current_lng'] != null) {
                  _driverLocation = LatLng(
                    myRequest['driver_current_lat'],
                    myRequest['driver_current_lng'],
                  );
                } else {
                  // フォールバック（ドライバー情報はあるが位置がない場合）
                  _driverLocation = LatLng(
                    _userLocation.latitude + 0.005,
                    _userLocation.longitude + 0.005,
                  );
                }
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }

  Future<void> _showEmergencyDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('緊急停止・通報'),
        content: const Text('現在走行中のサービスを緊急停止し、運営に通報しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _reportEmergency();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('停止・通報する'),
          ),
        ],
      ),
    );
  }

  Future<void> _reportEmergency() async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://localhost:8080/ride-requests/${widget.requestId}/emergency',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reporter_id': _requestData?['customer_id'],
          'reporter_type': 'customer',
          'reason': 'User triggered emergency stop from app',
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('緊急停止しました。運営に報告されました。')));
        }
      }
    } catch (e) {
      debugPrint('Error reporting emergency: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _requestData?['status'] ?? 'pending';
    final driverName = _requestData?['driver_name'] ?? 'ドライバー';
    final licenseNumber = _requestData?['license_number'] ?? '';
    final driverPhone = _requestData?['driver_phone'] ?? '';

    String statusText;
    String subStatusText;
    Color statusColor;

    switch (status) {
      case 'accepted':
        statusText = 'お迎えに向かっています';
        subStatusText = '約 5 分';
        statusColor = AppColors.navy;
        break;
      case 'arrived':
        statusText = 'ドライバーが到着しました';
        subStatusText = 'すぐ外へ';
        statusColor = AppColors.actionOrange;
        break;
      case 'started':
        statusText = '目的地に向かっています';
        subStatusText = '走行中';
        statusColor = AppColors.navy;
        break;
      case 'completed':
        statusText = '目的地に到着しました';
        subStatusText = '精算画面へ...';
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusText = 'キャンセルされました';
        subStatusText = '停止中';
        statusColor = AppColors.error;
        break;
      default:
        statusText = '待機中 ($status)';
        subStatusText = '...';
        statusColor = Colors.grey;
    }

    return Scaffold(
      body: Stack(
        children: [
          // 地図
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'jp.daikokun.app.user.v1',
              ),
              PolylineLayer(
                polylines: [
                  if (status == 'accepted' || status == 'arrived')
                    Polyline(
                      points: [_driverLocation, _userLocation],
                      strokeWidth: 3.0,
                      color: AppColors.actionOrange.withOpacity(0.5),
                      isDotted: true,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // ユーザー（出発地）
                  Marker(
                    point: _userLocation,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                  // ドライバー（モック位置）
                  if (status != 'pending' && status != 'cancelled')
                    Marker(
                      point: _driverLocation,
                      child: const Icon(
                        Icons.directions_car,
                        color: AppColors.actionOrange,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 上部情報：到着予定 / ステータス
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subStatusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.access_time, color: Colors.white, size: 40),
                ],
              ),
            ),
          ),

          // マップ操作ボタン
          if (status != 'pending' && status != 'cancelled')
            Positioned(
              right: 16,
              bottom: 260, // ドライバー詳細カードの上に配置
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'move_to_driver',
                    onPressed: _moveToDriver,
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.actionOrange,
                    child: const Icon(Icons.directions_car),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.small(
                    heroTag: 'move_to_user',
                    onPressed: _moveToUser,
                    backgroundColor: AppColors.white,
                    foregroundColor: Colors.blue,
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),

          // 下部情報：ドライバー詳細
          if (status != 'pending' && status != 'cancelled')
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 35,
                          backgroundColor: AppColors.background,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '免許番号: $licenseNumber',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  Text(
                                    ' ${(_requestData?['driver_average_rating'] ?? 0.0).toStringAsFixed(1)} (${_requestData?['driver_rating_count'] ?? 0}件の評価)',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (driverPhone.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              // 電話をかけるアクション（url_launcherなどが必要だが今回は省略）
                              debugPrint('Call driver: $driverPhone');
                            },
                            icon: const Icon(
                              Icons.phone,
                              size: 35,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (widget.requestId != null &&
                                  _requestData != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      rideId: widget.requestId!,
                                      senderId: _requestData!['customer_id'],
                                      senderType: 'customer',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: AppColors.textBlack,
                            ),
                            child: const Text('メッセージを送る'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _showEmergencyDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('緊急停止/通報'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _moveToUser() {
    _mapController.move(_userLocation, 15.0);
  }

  void _moveToDriver() {
    _mapController.move(_driverLocation, 15.0);
  }
}
