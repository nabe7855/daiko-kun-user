class SavedAddress {
  final String id;
  final String customerId;
  final String label;
  final String address;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SavedAddress({
    required this.id,
    required this.customerId,
    required this.label,
    required this.address,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'],
      customerId: json['customer_id'],
      label: json['label'],
      address: json['address'],
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'label': label,
      'address': address,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
