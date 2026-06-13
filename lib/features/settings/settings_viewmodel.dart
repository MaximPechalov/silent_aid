import 'package:flutter/material.dart';
import '../../services/prefs_service.dart';
import '../../models/trust_contact.dart';
import '../mask/mask_screen.dart';

class SettingsViewmodel extends ChangeNotifier {
  final PrefsService prefsService;
  
  List<TrustContact> trustContacts = [];
  TextEditingController sosController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  
  SettingsViewmodel({required this.prefsService});
  
  Future<void> loadData() async {
    trustContacts = await prefsService.getTrustContacts();
    sosController.text = prefsService.getSosMessage();
    codeController.text = prefsService.getSecretCode();
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
    await prefsService.setSosMessage(sosController.text);
    if (codeController.text.length >= 4) {
      await prefsService.setSecretCode(codeController.text);
    }
    
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
}