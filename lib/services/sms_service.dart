import 'package:url_launcher/url_launcher.dart';

class SmsService {
  Future<bool> sendSms(String phoneNumber, String message) async {
    try {
      final Uri uri = Uri(scheme: 'sms', path: phoneNumber, query: 'body=$message');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Для Android с прямым доступом (требует разрешения SEND_SMS)
  // Пока используем url_launcher как временное решение
}