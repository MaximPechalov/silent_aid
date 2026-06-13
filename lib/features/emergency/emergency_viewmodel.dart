import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/prefs_service.dart';
import '../../services/location_service.dart';
import '../../services/sms_service.dart';
import '../../models/trust_contact.dart';
import '../mask/mask_screen.dart';

class EmergencyViewmodel extends ChangeNotifier {
  final PrefsService prefsService;
  final LocationService _locationService = LocationService();
  final SmsService _smsService = SmsService();
  
  int countdown = 10;
  List<TrustContact> trustContacts = [];
  bool isEmergencyActive = false;
  
  EmergencyViewmodel({required this.prefsService}) {
    loadContacts();
  }
  
  Future<void> loadContacts() async {
    trustContacts = await prefsService.getTrustContacts();
    notifyListeners();
  }
  
  void startEmergency() {
    isEmergencyActive = true;
    _startCountdown();
  }
  
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (countdown > 1 && isEmergencyActive) {
        countdown--;
        notifyListeners();
        _startCountdown();
      } else if (countdown == 1 && isEmergencyActive) {
        countdown--;
        notifyListeners();
        _sendHelp();
      }
    });
  }
  
  Future<void> _sendHelp() async {
    final Position? position = await _locationService.getCurrentLocation();
    final String location = position != null
        ? _locationService.formatLocation(position)
        : 'не определены';
    
    final String message = prefsService.getSosMessage().replaceAll('{location}', location);
    
    for (var contact in trustContacts) {
      await _smsService.sendSms(contact.phoneNumber, message);
    }
    
    isEmergencyActive = false;
    notifyListeners();
  }
  
  void cancelEmergency(BuildContext context) {
    isEmergencyActive = false;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MaskScreen()),
    );
  }
}