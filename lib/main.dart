import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app_theme.dart';
import 'services/prefs_service.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/mask/mask_screen.dart';
import 'features/emergency/emergency_viewmodel.dart';
import 'features/settings/settings_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final prefsService = PrefsService(prefs);
  final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  
  runApp(MyApp(
    prefsService: prefsService,
    onboardingCompleted: onboardingCompleted,
  ));
}

class MyApp extends StatelessWidget {
  final PrefsService prefsService;
  final bool onboardingCompleted;
  
  const MyApp({
    super.key,
    required this.prefsService,
    required this.onboardingCompleted,
  });
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => EmergencyViewmodel(prefsService: prefsService),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewmodel(prefsService: prefsService),
        ),
      ],
      child: MaterialApp(
        title: 'SilentAid',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: onboardingCompleted
            ? const MaskScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}