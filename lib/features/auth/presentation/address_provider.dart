import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/saved_address_model.dart';
import 'auth_provider.dart';

class AddressNotifier extends AsyncNotifier<List<SavedAddress>> {
  @override
  Future<List<SavedAddress>> build() async {
    return _fetchAddresses();
  }

  Future<List<SavedAddress>> _fetchAddresses() async {
    final user = ref.read(authProvider).value;
    if (user == null) return [];

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/customer/${user.id}/addresses'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => SavedAddress.fromJson(e)).toList();
      }
    } catch (e) {
      print('Fetch addresses error: $e');
    }
    return [];
  }

  Future<bool> addAddress(
    String label,
    String address,
    String description,
    double lat,
    double lng,
  ) async {
    final user = ref.read(authProvider).value;
    if (user == null) return false;

    state = const AsyncValue.loading();
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/customer/addresses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customer_id': user.id,
          'label': label,
          'address': address,
          'description': description,
          'latitude': lat,
          'longitude': lng,
        }),
      );

      if (response.statusCode == 201) {
        state = AsyncValue.data(await _fetchAddresses());
        return true;
      }
    } catch (e) {
      print('Add address error: $e');
    }
    state = AsyncValue.data(await _fetchAddresses());
    return false;
  }

  Future<bool> deleteAddress(String addressId) async {
    state = const AsyncValue.loading();
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8080/customer/addresses/$addressId'),
      );

      if (response.statusCode == 200) {
        state = AsyncValue.data(await _fetchAddresses());
        return true;
      }
    } catch (e) {
      print('Delete address error: $e');
    }
    state = AsyncValue.data(await _fetchAddresses());
    return false;
  }
}

final addressProvider =
    AsyncNotifierProvider<AddressNotifier, List<SavedAddress>>(
      AddressNotifier.new,
    );
