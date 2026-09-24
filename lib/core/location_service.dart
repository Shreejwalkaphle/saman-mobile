import 'package:geolocator/geolocator.dart';

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CustomerLocation {
  const CustomerLocation(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class LocationService {
  Future<CustomerLocation> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceException(
        'Location service बन्द छ। Device location on गरेर फेरि प्रयास गर्नुहोस्।',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationServiceException('Location permission दिइएन।');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permission permanently blocked छ। App settingsबाट अनुमति दिनुहोस्।',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return CustomerLocation(position.latitude, position.longitude);
  }
}
