import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_viewmodel.dart';
import '../../app/app_colors.dart';
import '../../models/trust_contact.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsViewmodel>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsViewmodel>(
        builder: (context, viewModel, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection('ДОВЕРЕННЫЕ КОНТАКТЫ', [
                ...viewModel.trustContacts.map((contact) => ListTile(
                  title: Text(contact.name),
                  subtitle: Text(contact.phoneNumber),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => viewModel.removeContact(contact.id),
                  ),
                )),
                ListTile(
                  leading: const Icon(Icons.add_circle, color: AppColors.primary),
                  title: const Text('Добавить контакт'),
                  onTap: () => _showAddContactDialog(viewModel),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSection('ТЕКСТ SOS', [
                ListTile(
                  title: TextField(
                    controller: viewModel.sosController,
                    decoration: const InputDecoration(
                      hintText: 'Введите текст сообщения',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    '{location} — подставится автоматически',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSection('СЕКРЕТНЫЙ КОД', [
                ListTile(
                  title: TextField(
                    controller: viewModel.codeController,
                    decoration: const InputDecoration(
                      hintText: 'Код для активации тревоги',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSection('О ПРИЛОЖЕНИИ', [
                const ListTile(
                  title: Text('SilentAid'),
                  subtitle: Text('Версия 1.0.0'),
                ),
              ]),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => viewModel.saveSettings(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('СОХРАНИТЬ НАСТРОЙКИ'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
  
  void _showAddContactDialog(SettingsViewmodel viewModel) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить контакт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Имя'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(hintText: 'Телефон'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
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
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}