import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../mask/mask_screen.dart';
import '../../app/app_colors.dart';
import '../../services/prefs_service.dart';
import '../../models/trust_contact.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late PrefsService _prefsService;
  
  // Данные для настройки
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _sosController = TextEditingController(
    text: 'Мне нужна помощь! Позвоните мне или приезжайте. Мои координаты: {location}',
  );
  List<TrustContact> _trustContacts = [];
  
  // Контроллеры для добавления контакта
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _locationPermissionGranted = false;
  
  @override
  void initState() {
    super.initState();
    _initPrefs();
  }
  
  Future<void> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _prefsService = PrefsService(prefs);
    _loadContacts();
  }
  
  Future<void> _loadContacts() async {
    final contacts = await _prefsService.getTrustContacts();
    setState(() {
      _trustContacts = contacts;
    });
  }
  
  Future<void> _addContact() async {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      final newContact = TrustContact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        phoneNumber: _phoneController.text,
      );
      await _prefsService.addTrustContact(newContact);
      _nameController.clear();
      _phoneController.clear();
      await _loadContacts();
      setState(() {});
    }
  }
  
  Future<void> _removeContact(String id) async {
    await _prefsService.removeTrustContact(id);
    await _loadContacts();
    setState(() {});
  }
  
  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    setState(() {
      _locationPermissionGranted = status.isGranted;
    });
  }
  
  Future<void> _completeOnboarding() async {
    // Проверяем, что код введён и строго 3 цифры
    if (_codeController.text.length != 3 || !RegExp(r'^\d{3}$').hasMatch(_codeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите секретный код из 3 цифр')),
      );
      return;
    }
    
    // Сохраняем настройки
    await _prefsService.setSecretCode(_codeController.text);
    await _prefsService.setSosMessage(_sosController.text);
    await _prefsService.setSettingsPin('1234');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MaskScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPage(_pages[index], index);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _completeOnboarding(),
                  child: const Text('Пропустить'),
                ),
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeOnboarding();
                    }
                  },
                  child: Text(_currentPage == _pages.length - 1 ? 'Начать' : 'Далее'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPage(OnboardingPage page, int index) {
    if (index == 0) {
      return _buildWelcomePage(page);
    } else if (index == 1) {
      return _buildMaskPage(page);
    } else if (index == 2) {
      return _buildCodePage(page);
    } else if (index == 3) {
      return _buildContactsPage(page);
    } else if (index == 4) {
      return _buildSosMessagePage(page);
    } else if (index == 5) {
      return _buildLocationPage(page);
    } else {
      return _buildFinalPage(page);
    }
  }
  
  Widget _buildWelcomePage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 80, color: AppColors.primary),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMaskPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 80, color: AppColors.primary),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCodePage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 80, color: AppColors.primary),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              children: [
                const Text(
                  'Придумайте секретный код из 3 цифр:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    hintText: 'Например, 112',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 8),
                const Text(
                  '⚠️ Запомните этот код! Он понадобится для активации тревоги.',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactsPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 80, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Имя',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              hintText: 'Телефон',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addContact,
                          child: const Text('+'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _trustContacts.isEmpty
                        ? const Center(child: Text('Нет контактов. Добавьте хотя бы один.'))
                        : ListView.builder(
                            itemCount: _trustContacts.length,
                            itemBuilder: (context, idx) {
                              final contact = _trustContacts[idx];
                              return ListTile(
                                title: Text(contact.name),
                                subtitle: Text(contact.phoneNumber),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: AppColors.error),
                                  onPressed: () => _removeContact(contact.id),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSosMessagePage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 80, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  '{location} — подставится автоматически',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sosController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 80, color: AppColors.primary),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _requestLocationPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: _locationPermissionGranted ? Colors.green : AppColors.primary,
            ),
            child: Text(
              _locationPermissionGranted ? '✅ Доступ разрешён' : 'Разрешить доступ',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinalPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 80, color: AppColors.primary),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text(
                  '✅ Держите приложение в фоне',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '✅ Добавьте виджет на экран блокировки',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '✅ Регулярно проверяйте настройки',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.shield,
      title: 'Добро пожаловать в SilentAid',
      description: 'Приложение, которое позаботится о вашей безопасности незаметно и быстро.',
    ),
    OnboardingPage(
      icon: Icons.calculate,
      title: 'Обычный режим — обычный калькулятор',
      description: 'SilentAid выглядит как полностью рабочий калькулятор. Никто не догадается.',
    ),
    OnboardingPage(
      icon: Icons.lock,
      title: 'Секретный код из 3 цифр',
      description: 'Придумайте код для активации тревоги.',
    ),
    OnboardingPage(
      icon: Icons.contacts,
      title: 'Доверенные контакты',
      description: 'Добавьте контакты, которые получат SMS с вашими координатами.',
    ),
    OnboardingPage(
      icon: Icons.message,
      title: 'Текст SOS-сообщения',
      description: 'Отредактируйте сообщение, которое получат ваши близкие.',
    ),
    OnboardingPage(
      icon: Icons.location_on,
      title: 'Геолокация',
      description: 'Разрешите доступ — ваши координаты отправятся в SMS.',
    ),
    OnboardingPage(
      icon: Icons.check_circle,
      title: 'SilentAid готов!',
      description: 'Берегите себя.',
    ),
  ];
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  
  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}