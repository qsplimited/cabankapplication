// File: lib/models/location_model.dart

class LocationModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String type; // e.g., 'ATM', 'Branch', 'CDM'
  final double distanceKm;
  final bool isOpen;
  final String? phoneNumber;
  final List<String> services; // e.g., '24/7', 'Cash Deposit', 'Wheelchair Access'
  final String? workingHours; // e.g., '9:30 AM - 4:30 PM'

  LocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.distanceKm,
    required this.isOpen,
    this.phoneNumber,
    this.workingHours,
    this.services = const [],
  });

  // Factory constructor to parse JSON from the Mock API
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: json['type'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      isOpen: json['is_open'] as bool,
      phoneNumber: json['phone_number'] as String?,
      workingHours: json['working_hours'] as String?,
      services: List<String>.from(json['services'] as List<dynamic>),
    );
  }
}