import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/address_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  LatLng _currentLocation = const LatLng(35.681236, 139.767125); // 東京駅
  String _addressText = '現在地を取得中...';
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _addressText = '位置サービスが無効です');
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _addressText = '位置情報の権限がありません');
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _addressText = '位置情報の権限が永久に拒否されています');
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _addressText = '現在地付近'; // 本来はGeocodingで住所取得
        });
        _mapController.move(_currentLocation, 15.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _addressText = '現在地を取得できませんでした');
      }
    }
  }

  void _navigateToFareEstimate({
    required double lat,
    required double lng,
    required String name,
  }) {
    final encodedName = Uri.encodeComponent(name);
    context.push(
      '/fare_estimate?lat=$lat&lng=$lng&name=$encodedName&startLat=${_currentLocation.latitude}&startLng=${_currentLocation.longitude}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 地図 (OSM)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'jp.daikokun.app.user.v1',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_history,
                      color: AppColors.actionOrange,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 上部検索/現在地表示
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.navy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _addressText,
                      style: const TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 下部操作パネル
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
                  const Text(
                    'どちらへ帰りますか？',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // 目的地入力
                  InkWell(
                    onTap: () async {
                      final result = await context.push('/search');
                      if (result != null && result is Map<String, dynamic>) {
                        _navigateToFareEstimate(
                          lat: result['lat'],
                          lng: result['lon'],
                          name: result['name'],
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.navy.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, size: 30),
                          SizedBox(width: 12),
                          Text('目的地を検索する', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // クイック保存済み住所ボタン
                  addressesAsync.when(
                    data: (addresses) {
                      final home = addresses.cast<dynamic>().firstWhere(
                        (a) => a.label == '自宅',
                        orElse: () => null,
                      );
                      final work = addresses.cast<dynamic>().firstWhere(
                        (a) => a.label == '職場',
                        orElse: () => null,
                      );

                      return Row(
                        children: [
                          if (home != null)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _QuickAddressButton(
                                  icon: Icons.home,
                                  label: '自宅へ',
                                  onTap: () => _navigateToFareEstimate(
                                    lat: home.latitude,
                                    lng: home.longitude,
                                    name: home.address,
                                  ),
                                ),
                              ),
                            ),
                          if (work != null)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _QuickAddressButton(
                                  icon: Icons.work,
                                  label: '職場へ',
                                  onTap: () => _navigateToFareEstimate(
                                    lat: work.latitude,
                                    lng: work.longitude,
                                    name: work.address,
                                  ),
                                ),
                              ),
                            ),
                          if (home == null && work == null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await context.push('/search');
                                  if (result != null &&
                                      result is Map<String, dynamic>) {
                                    _navigateToFareEstimate(
                                      lat: result['lat'],
                                      lng: result['lon'],
                                      name: result['name'],
                                    );
                                  }
                                },
                                icon: const Icon(Icons.home, size: 28),
                                label: const Text('自宅へ帰る'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.navy,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAddressButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAddressButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
