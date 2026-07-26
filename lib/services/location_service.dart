import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<bool> checkPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<Position?> getCurrentLocation() async {
    bool hasPermission = await checkPermission();
    if (!hasPermission) {
      return null;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      return null;
    }
  }

  String formatLocation(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  String formatLocationWithAddress(Position position) {
    return '📍 Координаты: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\n'
           '📍 Ссылка: https://maps.google.com/?q=${position.latitude},${position.longitude}';
  }
}