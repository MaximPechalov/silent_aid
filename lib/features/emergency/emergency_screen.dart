import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'emergency_viewmodel.dart';
import 'emergency_sent_screen.dart';
import '../../app/app_colors.dart';
import '../mask/mask_screen.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmergencyViewmodel>(context, listen: false).startEmergency();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emergencyBackground,
      body: SafeArea(
        child: Consumer<EmergencyViewmodel>(
          builder: (context, viewModel, child) {
            // Если тревога не активна и таймер закончился — переходим на экран отправки
            if (!viewModel.isEmergencyActive && viewModel.countdown <= 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencySentScreen()),
                );
              });
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ВЫ В БЕЗОПАСНОСТИ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Сообщение будет отправлено через ${viewModel.countdown} сек',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: viewModel.countdown / 10,
                    backgroundColor: Colors.white30,
                    color: AppColors.emergencyProgress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => viewModel.cancelEmergency(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.emergencyBackground,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ОТМЕНИТЬ ПОМОЩЬ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (viewModel.trustContacts.isNotEmpty)
                    Column(
                      children: [
                        const Text(
                          'Сообщение получит:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        ...viewModel.trustContacts.map((contact) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '📱 ${contact.name} — ${contact.phoneNumber}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        )),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}