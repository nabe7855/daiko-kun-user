import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_colors.dart';

class AddressSearchScreen extends StatefulWidget {
  final String title;
  const AddressSearchScreen({super.key, required this.title});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
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
        title: Text('${widget.title}を登録'),
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
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: '住所やキーワードを入力',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
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
                        title: Text(
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          final lat = double.parse(result['lat']);
                          final lon = double.parse(result['lon']);
                          Navigator.pop(context, {
                            'address': displayName,
                            'latitude': lat,
                            'longitude': lon,
                          });
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
