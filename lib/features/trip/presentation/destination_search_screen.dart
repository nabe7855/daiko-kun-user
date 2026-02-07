import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_colors.dart';

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  State<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length > 2) {
        _searchDestination(query);
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _searchDestination(String query) async {
    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1&countrycodes=jp',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'daiko_kun_app'},
      );

      // 非同期処理の間にクエリが変わっていたら無視する（レースコンディション対策）
      if (_lastQuery != query) return;

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _searchResults = json.decode(response.body);
          });
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted && _lastQuery == query) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目的地を検索'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textBlack,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                hintText: '住所や施設名を入力',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _lastQuery = '';
                    setState(() {
                      _searchResults = [];
                      _isLoading = false;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _searchDestination,
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(color: AppColors.actionOrange),
          Expanded(
            child:
                _searchResults.isEmpty &&
                    !_isLoading &&
                    _searchController.text.length > 2
                ? const Center(child: Text('結果が見つかりませんでした'))
                : ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      final displayName = result['display_name'];

                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: AppColors.navy,
                        ),
                        title: Text(
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16),
                        ),
                        onTap: () {
                          final lat = result['lat'];
                          final lon = result['lon'];
                          final name = result['display_name'];
                          context.push(
                            '/fare_estimate?lat=$lat&lng=$lon&name=${Uri.encodeComponent(name)}',
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
