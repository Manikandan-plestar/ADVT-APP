import 'package:flutter/foundation.dart';

class LocationDetails {
  final String area;
  final String city;
  final String district;
  final String state;
  final String country;
  final double latitude;
  final double longitude;

  LocationDetails({
    required this.area,
    required this.city,
    required this.district,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  String get formattedAddress => "$area, $city, $state";
}

class LocationService extends ChangeNotifier {
  LocationDetails _currentLocation = LocationDetails(
    area: "T. Nagar",
    city: "Chennai",
    district: "Chennai",
    state: "Tamil Nadu",
    country: "India",
    latitude: 13.0418,
    longitude: 80.2341,
  );

  bool _hasPermission = true;
  bool _isFetching = false;

  LocationDetails get currentLocation => _currentLocation;
  bool get hasPermission => _hasPermission;
  bool get isFetching => _isFetching;

  /// Purpose: Request location permission from the user.
  /// Current behavior: Mocks granted permission.
  /// Future behavior: Integrate geolocator package permission requests.
  Future<bool> requestPermission() async {
    _hasPermission = true;
    notifyListeners();
    return true;
  }

  /// Purpose: Get current user location and address details.
  /// Current behavior: Returns mock location data for T. Nagar, Chennai.
  /// Future behavior: Geolocation GPS lookup + Geocoding reverse lookup API.
  Future<LocationDetails> getCurrentLocation() async {
    _isFetching = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _isFetching = false;
    notifyListeners();
    return _currentLocation;
  }

  /// Purpose: Update selected location manually.
  void setLocation(LocationDetails newLoc) {
    _currentLocation = newLoc;
    notifyListeners();
  }
}
