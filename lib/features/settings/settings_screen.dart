import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_viewmodel.dart';
import '../../app/app_colors.dart';
import '../../app/app_theme.dart';
import '../../models/trust_contact.dart';
import '../../services/prefs_service.dart';
import '../mask/mask_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isPinVerified = false;
  PrefsService? _prefsService;
  String _secretCode = '';

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _prefsService = PrefsService(prefs);
    _secretCode = _prefsService!.getSecretCode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPinVerification();
    });
  }

  void _showPinVerification() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.lock_outline, color: AppColors.primary),
            SizedBox(width: 12),
            Text(
              'Введите код доступа',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Введите ваш секретный код (3 цифры)',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              child: TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  hintText: '●●●',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.surfaceLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.surfaceLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 3,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pinController.clear();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MaskScreen()),
                  );
                },
                child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  _verifyPin(_pinController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Войти'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _verifyPin(String enteredPin) {
    if (enteredPin == _secretCode) {
      setState(() {
        _isPinVerified = true;
      });
      Navigator.pop(context);
      Provider.of<SettingsViewmodel>(context, listen: false).loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Неверный код'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPinVerified) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MaskScreen()),
            );
          },
        ),
      ),
      body: Consumer<SettingsViewmodel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Контакты
                _buildCard(
                  icon: Icons.people_outline,
                  title: 'Доверенные контакты',
                  subtitle: 'Кто получит SMS при тревоге',
                  child: Column(
                    children: [
                      ...viewModel.trustContacts.map((contact) => _buildContactTile(
                        contact: contact,
                        onDelete: () => viewModel.removeContact(contact.id),
                      )),
                      _buildAddContactTile(viewModel),
                      if (viewModel.trustContacts.isEmpty)
                        _buildEmptyState(
                          icon: Icons.contacts_outlined,
                          text: 'Нет контактов',
                          hint: 'Добавьте хотя бы один контакт',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Текст SOS
                _buildCard(
                  icon: Icons.message_outlined,
                  title: 'Текст SOS',
                  subtitle: 'Что увидят ваши близкие',
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextField(
                          controller: viewModel.sosController,
                          decoration: InputDecoration(
                            hintText: 'Введите текст сообщения',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.surfaceLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                          ),
                          maxLines: 4,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '{location} — подставится автоматически',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Код
                _buildCard(
                  icon: Icons.lock_outline,
                  title: 'Секретный код',
                  subtitle: '3 цифры для активации тревоги',
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: viewModel.codeController,
                            decoration: InputDecoration(
                              hintText: '●●●',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.surfaceLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceLight,
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              letterSpacing: 8,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Этот код используется для входа в настройки',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // О приложении
                _buildCard(
                  icon: Icons.info_outline,
                  title: 'О приложении',
                  subtitle: 'Версия и поддержка',
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'S',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        title: const Text(
                          'SilentAid',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Версия 1.0.0',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        trailing: const Icon(
                          Icons.verified,
                          color: AppColors.primary,
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.refresh_outlined,
                          color: AppColors.primary,
                        ),
                        title: const Text(
                          'Пройти онбординг заново',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        onTap: () {
                          viewModel.resetOnboarding();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const MaskScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => viewModel.saveSettings(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'СОХРАНИТЬ НАСТРОЙКИ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required TrustContact contact,
    required VoidCallback onDelete,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.2),
        child: Text(
          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        contact.name,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        contact.phoneNumber,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: AppColors.error),
        onPressed: onDelete,
      ),
    );
  }

  Widget _buildAddContactTile(SettingsViewmodel viewModel) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          color: AppColors.primary,
        ),
      ),
      title: const Text(
        'Добавить контакт',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () => _showAddContactDialog(viewModel),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String text,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            hint,
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(SettingsViewmodel viewModel) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Добавить контакт',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Имя',
                hintStyle: TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.surfaceLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                hintText: 'Телефон (+7XXXXXXXXXX)',
                hintStyle: TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.surfaceLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
              ),
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                    viewModel.addContact(
                      TrustContact(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        phoneNumber: phoneController.text,
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Заполните все поля'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Добавить'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}