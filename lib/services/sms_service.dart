import 'package:url_launcher/url_launcher.dart';

class SmsService {
  // Отправка SMS через открытие приложения SMS
  Future<bool> sendSms(String phoneNumber, String message) async {
    try {
      final Uri uri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        query: 'body=${Uri.encodeComponent(message)}',
      );
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Отправка SMS нескольким контактам (последовательно)
  Future<Map<String, bool>> sendSmsToMultiple(
    List<String> phoneNumbers,
    String message,
  ) async {
    final Map<String, bool> results = {};
    
    for (String phone in phoneNumbers) {
      final bool success = await sendSms(phone, message);
      results[phone] = success;
    }
    
    return results;
  }
}