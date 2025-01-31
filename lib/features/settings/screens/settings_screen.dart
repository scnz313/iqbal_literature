import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../core/controllers/font_controller.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../widgets/language_selector.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Settings',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Section
          _buildSection(
            context,
            title: 'language'.tr,
            icon: Icons.language,
            child: Obx(() => LanguageSelector(
                  selectedLanguage: controller.currentLanguage.value,
                  onLanguageChanged: controller.changeLanguage,
                )),
          ),

          const SizedBox(height: 16),

          // Theme Section
          _buildSection(
            context,
            title: 'Theme',
            icon: Icons.palette,
            child: Obx(() => Column(
              children: [
                _buildThemeOption(context, 'System', 'system'),
                _buildThemeOption(context, 'Light', 'light'),
                _buildThemeOption(context, 'Dark', 'dark'),
              ],
            )),
          ),

          const SizedBox(height: 16),

          // Night Mode Scheduler
          Obx(() => SwitchListTile(
                title: const Text('Enable Night Mode Scheduler'),
                value: controller.isNightModeScheduled.value,
                onChanged: (bool val) {
                  controller.enableNightModeSchedule(val);
                },
              )),

          const SizedBox(height: 16),

          // About Section
          _buildSection(
            context,
            title: 'About',
            icon: Icons.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version: ${controller.appVersion}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: controller.showAbout,
                  child: const Text('About App'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: controller.currentTheme.value,
      onChanged: (value) => controller.changeTheme(value!),
    );
  }
}
