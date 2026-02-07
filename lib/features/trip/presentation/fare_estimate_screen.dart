import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';

class FareEstimateScreen extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationName;

  const FareEstimateScreen({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
  });

  @override
  State<FareEstimateScreen> createState() => _FareEstimateScreenState();
}

class _FareEstimateScreenState extends State<FareEstimateScreen> {
  double _distanceKm = 0.0;
  int _estimatedFare = 0;
  bool _isLoading = true;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final start = LatLng(position.latitude, position.longitude);
      final dest = LatLng(widget.destinationLat, widget.destinationLng);

      // OSRM APIを使用して実際の走行ルートを取得
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];

        final double distanceInMeters = route['distance'].toDouble();

        final List<dynamic> coordinates = route['geometry']['coordinates'];
        final List<LatLng> points = coordinates
            .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
            .toList();

        final roadDistanceKm = distanceInMeters / 1000;

        if (mounted) {
          setState(() {
            _distanceKm = roadDistanceKm;
            // 料金計算: 基本3000円 + 200円/km
            _estimatedFare = (3000 + (roadDistanceKm * 200)).round();
            _routePoints = points;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load route');
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
      // 失敗した場合は直線距離でフォールバック
      final position = await Geolocator.getCurrentPosition();
      final start = LatLng(position.latitude, position.longitude);
      final dest = LatLng(widget.destinationLat, widget.destinationLng);
      final distanceInMeters = Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        dest.latitude,
        dest.longitude,
      );

      if (mounted) {
        setState(() {
          _distanceKm = distanceInMeters / 1000;
          _estimatedFare = (3000 + (_distanceKm * 200)).round();
          _routePoints = [start, dest];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'ja_JP',
      symbol: '¥',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('料金見積もり'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ルートプレビュー (OSM)
                SizedBox(
                  height: 250,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _routePoints.isNotEmpty
                          ? LatLng(
                              (_routePoints.first.latitude +
                                      _routePoints.last.latitude) /
                                  2,
                              (_routePoints.first.longitude +
                                      _routePoints.last.longitude) /
                                  2,
                            )
                          : const LatLng(35.6812, 139.7671),
                      initialZoom: 12.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.daiko_kun',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: AppColors.navy,
                            strokeWidth: 5.0,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _routePoints.first,
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.navy,
                            ),
                          ),
                          Marker(
                            point: _routePoints.last,
                            child: const Icon(
                              Icons.flag,
                              color: AppColors.actionOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '道のり距離',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${_distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          '見積料金',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          currencyFormatter.format(_estimatedFare),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '車種を選択してください',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(
                            children: [
                              _VehicleOptionCard(
                                title: 'スタンダード',
                                desc: '2人体制（随伴車あり）',
                                price: currencyFormatter.format(_estimatedFare),
                                isSelected: true,
                                onTap: () {},
                              ),
                              const SizedBox(height: 16),
                              _VehicleOptionCard(
                                title: '大型・輸入車',
                                desc: '熟練ドライバーが対応',
                                price: currencyFormatter.format(
                                  _estimatedFare + 1500,
                                ),
                                isSelected: false,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 配車確定ボタン
                        ElevatedButton(
                          onPressed: () {
                            context.push('/matching');
                          },
                          child: const Text('この料金で配車を確定する'),
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

class _VehicleOptionCard extends StatelessWidget {
  final String title;
  final String desc;
  final String price;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleOptionCard({
    required this.title,
    required this.desc,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.navy.withValues(alpha: 0.05)
              : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.navy
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_car, size: 40, color: AppColors.navy),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
