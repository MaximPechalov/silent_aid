import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mask/mask_screen.dart';
import '../../app/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
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
      title: 'Секретный код: 112',
      description: 'Введите 112 и нажмите = для активации тревоги. Код можно изменить в настройках.',
    ),
    OnboardingPage(
      icon: Icons.contacts,
      title: 'Доверенные контакты',
      description: 'Добавьте контакты, которые получат SMS с вашими координатами при тревоге.',
    ),
    OnboardingPage(
      icon: Icons.location_on,
      title: 'Геолокация',
      description: 'Разрешите доступ к геолокации — ваши координаты отправятся в SMS.',
    ),
    OnboardingPage(
      icon: Icons.check_circle,
      title: 'SilentAid готов!',
      description: 'Держите приложение в фоне. Берегите себя.',
    ),
  ];

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
                return _buildPage(_pages[index]);
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
  
  Widget _buildPage(OnboardingPage page) {
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
  
  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MaskScreen()),
      );
    }
  }
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