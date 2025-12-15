// File: lib/services/location_service.dart

import '../models/location_model.dart';
import 'dart:async';

// --- MOCK DATA SOURCE (Simulating JSON from the Backend) ---
final List<Map<String, dynamic>> _mockLocationsJson = [
  {
    'id': 'ATM001',
    'name': 'Central City ATM - 24/7',
    'address': '101 Main St, Cityville, 560001',
    'latitude': 12.9716, // Near user location
    'longitude': 77.5946,
    'type': 'ATM',
    'distance_km': 0.8,
    'is_open': true,
    'working_hours': '24/7',
    'services': ['24/7', 'Cash Deposit', 'Cardless Withdrawal', 'Wheelchair Access'],
  },
  {
    'id': 'BR005',
    'name': 'Corporate Business Branch',
    'address': '25 Market Road, Cityville, 560002',
    'latitude': 12.9780,
    'longitude': 77.5990,
    'type': 'Branch',
    'distance_km': 1.5,
    'is_open': false,
    'working_hours': '10:00 AM - 4:00 PM',
    'services': ['Forex Services', 'Locker Facility', 'Advisory', 'Wheelchair Access'],
  },
  {
    'id': 'CDM010',
    'name': 'Tech Park Cash Deposit',
    'address': '40, Tech Park Ave, Cityville, 560003',
    'latitude': 12.9850,
    'longitude': 77.6050,
    'type': 'CDM',
    'distance_km': 2.3,
    'is_open': true,
    'working_hours': '24/7',
    'services': ['Cash Deposit', 'CDM', '24/7'],
  },
  {
    'id': 'ATM022',
    'name': 'Outer Ring ATM',
    'address': '700 Outer Ring Road',
    'latitude': 12.9550,
    'longitude': 77.5850,
    'type': 'ATM',
    'distance_km': 6.1,
    'is_open': false,
    'working_hours': '24/7',
    'services': ['24/7', 'Cash Deposit'],
  }
];
// -----------------------------------------------------------------

class LocationService {
  // fetchNearbyLocations expects non-nullable List<String> due to the default value.
  Future<List<LocationModel>> fetchNearbyLocations({
    required double userLat,
    required double userLong,
    String typeFilter = 'All',
    List<String> serviceFilters = const [], // Non-nullable, defaults to empty list
    double maxDistanceKm = 10.0, // Added for radius filtering logic
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    List<LocationModel> allLocations = _mockLocationsJson.map((json) => LocationModel.fromJson(json)).toList();

    // Filtering Logic
    return allLocations.where((location) {
      // 1. Type Filter
      bool matchesType = (typeFilter == 'All') || (location.type == typeFilter);

      // 2. Distance Filter (Simulated distance check)
      bool withinDistance = location.distanceKm <= maxDistanceKm;

      // 3. Service Filter
      // Checks if the location's services contain ALL of the selected serviceFilters.
      bool matchesServices = serviceFilters.isEmpty ||
          serviceFilters.every((filter) => location.services.contains(filter));

      return matchesType && withinDistance && matchesServices;
    }).toList();
  }
}