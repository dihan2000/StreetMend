import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationFailure implements Exception {
  const LocationFailure(this.message, {this.settingsAvailable = false});
  final String message;
  final bool settingsAvailable;
}

class DevicePosition {
  const DevicePosition(this.latitude, this.longitude, this.accuracy);
  final double latitude;
  final double longitude;
  final double accuracy;
}

/// Called only in response to the user's Use My Location action.
class LocationService {
  Future<DevicePosition> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        'Location services are off. Choose a location manually or enable location in Settings.',
        settingsAvailable: true,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Location permission is blocked. You can choose manually or change access in Settings.',
        settingsAvailable: true,
      );
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const LocationFailure(
        'Location permission was not granted. Please choose the issue location manually.',
      );
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return DevicePosition(
        position.latitude,
        position.longitude,
        position.accuracy,
      );
    } on TimeoutException {
      throw const LocationFailure(
        'GPS took too long. Try again outdoors or select a location manually.',
      );
    }
  }

  Future<bool> openSettings() => Geolocator.openAppSettings();
}
