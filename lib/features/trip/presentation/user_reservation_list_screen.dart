import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';

class UserReservationListScreen extends ConsumerStatefulWidget {
  const UserReservationListScreen({super.key});

  @override
  ConsumerState<UserReservationListScreen> createState() =>
      _UserReservationListScreenState();
}

class _UserReservationListScreenState
    extends ConsumerState<UserReservationListScreen> {
  bool _isLoading = true;
  List<dynamic> _reservations = [];

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:8080/customer/ride-requests/reserved?customer_id=${Uri.encodeComponent(user.name ?? user.phoneNumber)}',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _reservations = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching reservations: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予約済みのライド'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReservations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
          ? const Center(child: Text('予約済みのライドはありません'))
          : ListView.builder(
              itemCount: _reservations.length,
              itemBuilder: (context, index) {
                final res = _reservations[index];
                final scheduledAt = DateTime.parse(res['scheduled_at']);
                final pickupDate = DateFormat(
                  'yyyy/MM/dd (E)',
                ).format(scheduledAt);
                final pickupTime = DateFormat('HH:mm').format(scheduledAt);

                final status = res['status'];
                final driverName = res['driver_name'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$pickupDate $pickupTime',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'accepted'
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status == 'accepted' ? '事業者受諾済み' : '事業者探し中',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'accepted'
                                      ? Colors.green.shade800
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.location_on,
                          'お迎え',
                          res['pickup_address'] ?? '住所未設定',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.flag,
                          '目的地',
                          res['destination_address'] ?? '住所未設定',
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '担当事業者',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  driverName ?? '未定',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '¥${(res['estimated_fare'] as num).toInt()}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                        if (status == 'pending')
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _showCancelDialog(res['id']),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                                child: const Text('予約をキャンセル'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予約のキャンセル'),
        content: const Text('この予約をキャンセルしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelReservation(requestId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('キャンセルする'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelReservation(String requestId) async {
    try {
      final response = await http.patch(
        Uri.parse(
          'http://localhost:8080/customer/ride-requests/$requestId/status',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': 'cancelled'}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('予約をキャンセルしました')));
          _fetchReservations();
        }
      }
    } catch (e) {
      debugPrint('Error cancelling reservation: $e');
    }
  }
}
