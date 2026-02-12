import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/models/location_stop.dart';

class FareEstimateScreen extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationName;
  final double? startLat;
  final double? startLng;

  const FareEstimateScreen({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
    this.startLat,
    this.startLng,
  });

  @override
  State<FareEstimateScreen> createState() => _FareEstimateScreenState();
}

class _FareEstimateScreenState extends State<FareEstimateScreen> {
  double _distanceKm = 0.0;
  int _estimatedFare = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<LatLng> _routePoints = [];
  List<double> _segmentDistancesKm = [];
  final List<LocationStop> _waypoints = [];
  final MapController _mapController = MapController();

  Future<void> _requestRide() async {
    setState(() => _isLoading = true);

    try {
      LatLng start;
      if (widget.startLat != null && widget.startLng != null) {
        start = LatLng(widget.startLat!, widget.startLng!);
      } else {
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            timeLimit: const Duration(seconds: 5),
          );
        } catch (e) {
          debugPrint('Location error: $e');
        }
        start = position != null
            ? LatLng(position.latitude, position.longitude)
            : const LatLng(35.681236, 139.767125);
      }

      // 出発地の住所を逆ジオコーディングで取得
      String pickupAddress = '現在地';
      try {
        final reverseGeoUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${start.latitude}&lon=${start.longitude}&zoom=18&addressdetails=1',
        );
        final geoResponse = await http.get(
          reverseGeoUrl,
          headers: {
            'User-Agent':
                'DaikoKunApp/1.0', // Nominatim requires a valid User-Agent
          },
        );

        if (geoResponse.statusCode == 200) {
          final geoData = json.decode(geoResponse.body);
          // 住所が長すぎる場合は調整が必要だが、一旦display_nameを使用
          pickupAddress = geoData['display_name'] ?? '現在地';

          // 日本の住所形式に合わせて簡易的な整形（例：国名を除くなど）
          if (pickupAddress.contains('日本, ')) {
            pickupAddress = pickupAddress.replaceAll('日本, ', '');
          }
        }
      } catch (e) {
        debugPrint('Reverse geocoding error: $e');
      }

      final response = await http.post(
        Uri.parse('http://localhost:8080/customer/ride-requests'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer_id': '山田 太郎', // ユーザー名をわかりやすく変更
          'pickup_lat': start.latitude,
          'pickup_lng': start.longitude,
          'destination_lat': widget.destinationLat,
          'destination_lng': widget.destinationLng,
          'pickup_address': pickupAddress,
          'destination_address': widget.destinationName,
          'estimated_fare': _estimatedFare.toDouble(),
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final String requestId = data['id'];

        if (mounted) {
          context.push('/matching?requestId=$requestId');
        }
      } else {
        throw Exception(
          'Failed to create ride request: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error requesting ride: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('配車依頼に失敗しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      LatLng start;
      if (widget.startLat != null && widget.startLng != null) {
        start = LatLng(widget.startLat!, widget.startLng!);
      } else {
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            timeLimit: const Duration(seconds: 5),
          );
        } catch (e) {
          debugPrint('Location error: $e');
        }

        start = position != null
            ? LatLng(position.latitude, position.longitude)
            : const LatLng(35.681236, 139.767125); // デフォルト東京駅
      }

      final dest = LatLng(widget.destinationLat, widget.destinationLng);

      // 中継点を含むすべての地点をリスト化
      final List<LatLng> allStops = [
        start,
        ..._waypoints.map((w) => w.location),
        dest,
      ];

      // OSRM APIを使用して実際の走行ルートを取得 (複数地点対応)
      final coordinatesString = allStops
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordinatesString'
        '?overview=full&geometries=geojson',
      );

      debugPrint('Fetching route: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];
        final List<dynamic> legs = route['legs'];

        final double distanceInMeters = route['distance'].toDouble();

        final List<dynamic> coordinates = route['geometry']['coordinates'];
        final List<LatLng> points = coordinates
            .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
            .toList();

        final roadDistanceKm = distanceInMeters / 1000;

        if (mounted) {
          setState(() {
            _distanceKm = roadDistanceKm;
            _estimatedFare = (3000 + (roadDistanceKm * 200)).round();
            _routePoints = points;
            _segmentDistancesKm = legs
                .map((leg) => (leg['distance'] as num).toDouble() / 1000)
                .toList();
            _errorMessage = null;
          });

          // ルート全体が収まるように地図を調整
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_routePoints.isNotEmpty) {
              _mapController.fitCamera(
                CameraFit.coordinates(
                  coordinates: _routePoints,
                  padding: const EdgeInsets.all(50),
                ),
              );
            }
          });
        }
      } else {
        throw Exception('APIエラー: ステータスコード ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'ルート取得に失敗しました: $e\n(OSRM APIの制限の可能性があります)';

          double totalDist = 0;
          final List<LatLng> fallbackPoints = [
            const LatLng(35.681236, 139.767125), // Start fallback
            ..._waypoints.map((w) => w.location),
            LatLng(widget.destinationLat, widget.destinationLng),
          ];

          for (int i = 0; i < fallbackPoints.length - 1; i++) {
            totalDist += Geolocator.distanceBetween(
              fallbackPoints[i].latitude,
              fallbackPoints[i].longitude,
              fallbackPoints[i + 1].latitude,
              fallbackPoints[i + 1].longitude,
            );
          }

          _distanceKm = totalDist / 1000;
          _estimatedFare = (3000 + (_distanceKm * 200)).round();
          _routePoints = fallbackPoints;
          _segmentDistancesKm =
              []; // Simple fallback doesn't support legs easily here
        });
      }
    } finally {
      if (mounted) {
        setState(() {
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
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // ルートプレビュー (OSM)
                      SizedBox(
                        height: 250,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: const MapOptions(
                            initialCenter: LatLng(35.6812, 139.7671),
                            initialZoom: 12.0,
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
                                Polyline(
                                  points: _routePoints,
                                  color: AppColors.navy,
                                  strokeWidth: 5.0,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                // 出発地
                                Marker(
                                  point: _routePoints.first,
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                  ),
                                ),
                                // 中継点
                                ..._waypoints.map(
                                  (w) => Marker(
                                    point: w.location,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                // 目的地
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
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 地点リスト
                                _buildRouteList(),
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '合計距離',
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
                                const Text(
                                  '見積料金',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
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
                                _VehicleOptionCard(
                                  title: 'スタンダード',
                                  desc: '2人体制（随伴車あり）',
                                  price: currencyFormatter.format(
                                    _estimatedFare,
                                  ),
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
                                const SizedBox(height: 32),
                                // 配車確定ボタン
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _requestRide,
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text('この料金で配車を確定する'),
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteList() {
    return Column(
      children: [
        _buildLocationTile(
          Icons.my_location,
          '現在地',
          Colors.blue,
          trailing: '基本 ¥3,000',
        ),

        // 中継点（並び替え可能）
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _waypoints.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _waypoints.removeAt(oldIndex);
              _waypoints.insert(newIndex, item);
              _isLoading = true;
              _calculateRoute();
            });
          },
          itemBuilder: (context, index) {
            final waypoint = _waypoints[index];
            return Column(
              key: ValueKey(waypoint),
              children: [
                _buildSegmentDivider(index), // 前の地点からの距離
                _buildLocationTile(
                  Icons.location_on,
                  waypoint.name,
                  Colors.green,
                  onDelete: () {
                    setState(() {
                      _waypoints.removeAt(index);
                      _isLoading = true;
                      _calculateRoute();
                    });
                  },
                ),
              ],
            );
          },
        ),

        // 最後の区間
        _buildSegmentDivider(_waypoints.length),

        _buildLocationTile(
          Icons.flag,
          widget.destinationName,
          AppColors.actionOrange,
        ),
        if (_waypoints.length < 3) _buildAddWaypointButton(),
      ],
    );
  }

  Widget _buildSegmentDivider(int legIndex) {
    if (_segmentDistancesKm.length <= legIndex) {
      return const SizedBox(height: 8, child: Center(child: VerticalDivider()));
    }

    final dist = _segmentDistancesKm[legIndex];
    final fare = (dist * 200).round();
    final formatter = NumberFormat.currency(
      locale: 'ja_JP',
      symbol: '¥',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dist.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '+ ${formatter.format(fare)}',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile(
    IconData icon,
    String name,
    Color color, {
    VoidCallback? onDelete,
    String? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (onDelete != null)
            const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildAddWaypointButton() {
    return InkWell(
      onTap: () async {
        final result = await context.push('/search');
        if (result != null && result is Map<String, dynamic>) {
          setState(() {
            _waypoints.add(
              LocationStop(
                name: result['name'],
                location: LatLng(result['lat'], result['lon']),
              ),
            );
            _isLoading = true;
            _calculateRoute();
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: AppColors.navy,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              '中継点を追加する',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
