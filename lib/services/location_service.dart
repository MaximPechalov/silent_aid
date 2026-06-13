import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
  
  Future<Position?> getCurrentLocation() async {
    bool hasPermission = await checkPermission();
    if (!hasPermission) return null;
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  
  String formatLocation(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }
}