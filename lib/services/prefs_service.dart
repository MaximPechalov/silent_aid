import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/trust_contact.dart';

class PrefsService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  PrefsService(this._prefs);
  
  // Ключи
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keySecretCode = 'secret_code';
  static const String _keySosMessage = 'sos_message';
  static const String _keyCountdownSeconds = 'countdown_seconds';
  static const String _keyContacts = 'trust_contacts';
  static const String _keyPin = 'settings_pin';
  
  // Первый запуск
  bool isFirstLaunch() {
    final value = _prefs.getBool(_keyFirstLaunch);
    if (value == null) {
      _prefs.setBool(_keyFirstLaunch, false);
      return true;
    }
    return false;
  }
  
  // Секретный код
  String getSecretCode() {
    return _prefs.getString(_keySecretCode) ?? '112';
  }
  
  Future<void> setSecretCode(String code) async {
    await _prefs.setString(_keySecretCode, code);
  }
  
  // Текст SOS
  String getSosMessage() {
    return _prefs.getString(_keySosMessage) ?? 
        'Мне нужна помощь! Позвоните мне или приезжайте. Мои координаты: {location}';
  }
  
  Future<void> setSosMessage(String message) async {
    await _prefs.setString(_keySosMessage, message);
  }
  
  // Таймер
  int getCountdownSeconds() {
    return _prefs.getInt(_keyCountdownSeconds) ?? 10;
  }
  
  Future<void> setCountdownSeconds(int seconds) async {
    await _prefs.setInt(_keyCountdownSeconds, seconds);
  }
  
  // PIN настроек
  String getSettingsPin() {
    return _prefs.getString(_keyPin) ?? '1234';
  }
  
  Future<void> setSettingsPin(String pin) async {
    await _prefs.setString(_keyPin, pin);
  }
  
  // Контакты (шифрованное хранение)
  Future<List<TrustContact>> getTrustContacts() async {
    final String? contactsJson = await _secureStorage.read(key: _keyContacts);
    if (contactsJson == null) return [];
    
    final List<dynamic> list = json.decode(contactsJson);
    return list.map((json) => TrustContact.fromJson(json)).toList();
  }
  
  Future<void> saveTrustContacts(List<TrustContact> contacts) async {
    final String jsonString = json.encode(contacts.map((c) => c.toJson()).toList());
    await _secureStorage.write(key: _keyContacts, value: jsonString);
  }
  
  Future<void> addTrustContact(TrustContact contact) async {
    final List<TrustContact> contacts = await getTrustContacts();
    contacts.add(contact);
    await saveTrustContacts(contacts);
  }
  
  Future<void> removeTrustContact(String id) async {
    final List<TrustContact> contacts = await getTrustContacts();
    contacts.removeWhere((c) => c.id == id);
    await saveTrustContacts(contacts);
  }
  
  // Очистка всех данных
  Future<void> clearAllData() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }
}