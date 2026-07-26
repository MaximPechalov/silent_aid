import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/prefs_service.dart';
import '../../models/trust_contact.dart';
import '../mask/mask_screen.dart';

class SettingsViewmodel extends ChangeNotifier {
  final PrefsService prefsService;
  
  List<TrustContact> trustContacts = [];
  TextEditingController sosController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  TextEditingController pinController = TextEditingController();
  bool isLoading = true;
  
  SettingsViewmodel({required this.prefsService}) {
    pinController.text = prefsService.getSettingsPin();
  }
  
  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();
    
    trustContacts = await prefsService.getTrustContacts();
    sosController.text = prefsService.getSosMessage();
    codeController.text = prefsService.getSecretCode();
    pinController.text = prefsService.getSettingsPin();
    
    isLoading = false;
    notifyListeners();
  }
  
  Future<void> addContact(TrustContact contact) async {
    await prefsService.addTrustContact(contact);
    await loadData();
  }
  
  Future<void> removeContact(String id) async {
    await prefsService.removeTrustContact(id);
    await loadData();
  }
  
  Future<void> saveSettings(BuildContext context) async {
    // Проверка кода (строго 3 цифры)
    if (codeController.text.length != 3 || !RegExp(r'^\d{3}$').hasMatch(codeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Секретный код должен быть ровно 3 цифры')),
      );
      return;
    }
    
    // Проверка PIN (строго 4 цифры)
    if (pinController.text.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pinController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN должен быть ровно 4 цифры')),
      );
      return;
    }
    
    await prefsService.setSosMessage(sosController.text);
    await prefsService.setSecretCode(codeController.text);
    await prefsService.setSettingsPin(pinController.text);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MaskScreen()),
      );
    }
  }
  
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
  }
}