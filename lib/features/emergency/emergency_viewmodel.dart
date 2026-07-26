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
  bool isSending = false;
  String statusMessage = '';
  
  EmergencyViewmodel({required this.prefsService}) {
    loadContacts();
  }
  
  Future<void> loadContacts() async {
    trustContacts = await prefsService.getTrustContacts();
    notifyListeners();
  }
  
  void startEmergency() {
    isEmergencyActive = true;
    statusMessage = 'Подготовка...';
    countdown = 10;
    notifyListeners();
    _startCountdown();
  }
  
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (countdown > 1 && isEmergencyActive) {
        countdown--;
        statusMessage = 'Отправка через $countdown сек';
        notifyListeners();
        _startCountdown();
      } else if (countdown == 1 && isEmergencyActive) {
        countdown--;
        statusMessage = 'Отправка...';
        notifyListeners();
        _sendHelp();
      }
    });
  }
  
  Future<void> _sendHelp() async {
    isSending = true;
    statusMessage = 'Получение геолокации...';
    notifyListeners();

    // Получаем геолокацию
    final Position? position = await _locationService.getCurrentLocation();
    
    String locationText;
    if (position != null) {
      locationText = _locationService.formatLocationWithAddress(position);
    } else {
      locationText = '⚠️ Геолокация не определена. Проверьте доступ к геолокации.';
    }

    // Формируем сообщение
    String baseMessage = prefsService.getSosMessage();
    String fullMessage = baseMessage.replaceAll('{location}', locationText);
    
    // Добавляем время
    final String time = DateTime.now().toString().substring(0, 19);
    fullMessage += '\n\n🕐 Время: $time';

    statusMessage = 'Открытие SMS...';
    notifyListeners();

    // Отправляем SMS всем контактам
    if (trustContacts.isEmpty) {
      statusMessage = '❌ Нет доверенных контактов!';
      isSending = false;
      isEmergencyActive = false;
      notifyListeners();
      return;
    }

    final List<String> phoneNumbers = trustContacts.map((c) => c.phoneNumber).toList();
    
    // Отправляем первому контакту (для теста)
    if (phoneNumbers.isNotEmpty) {
      final bool success = await _smsService.sendSms(
        phoneNumbers.first,
        fullMessage,
      );
      
      if (success) {
        statusMessage = '✅ SMS открыто для отправки';
      } else {
        statusMessage = '❌ Ошибка открытия SMS';
      }
    }

    isSending = false;
    isEmergencyActive = false;
    notifyListeners();
  }
  
  void cancelEmergency(BuildContext context) {
    isEmergencyActive = false;
    countdown = 10;
    statusMessage = '';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MaskScreen()),
    );
  }
}