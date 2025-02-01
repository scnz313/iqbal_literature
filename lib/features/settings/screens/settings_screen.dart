import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../core/controllers/font_controller.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../widgets/language_selector.dart';
import 'about_screen.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'settings'.tr,
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
            title: 'theme'.tr,
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
          _buildSection(
            context,
            title: 'night_mode'.tr,
            icon: Icons.nightlight_round,
            child: Column(
              children: [
                Obx(() => SwitchListTile(
                      title: Text('enable_scheduler'.tr),
                      value: controller.isNightModeScheduled.value,
                      onChanged: controller.enableNightModeSchedule,
                    )),
                Obx(() {
                  if (!controller.isNightModeScheduled.value) return const SizedBox();
                  return Column(
                    children: [
                      ListTile(
                        title: Text('start_time'.tr),
                        trailing: Text(controller.nightModeStartTime.value.format(context)),
                        onTap: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: controller.nightModeStartTime.value,
                          );
                          if (time != null) {
                            controller.setNightModeStartTime(time);
                          }
                        },
                      ),
                      ListTile(
                        title: Text('end_time'.tr),
                        trailing: Text(controller.nightModeEndTime.value.format(context)),
                        onTap: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: controller.nightModeEndTime.value,
                          );
                          if (time != null) {
                            controller.setNightModeEndTime(time);
                          }
                        },
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // About Section
          _buildSection(
            context,
            title: 'about'.tr,
            icon: Icons.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'version'.tr}: ${controller.appVersion}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: controller.showAbout,
                  child: Text('about_app'.tr),
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const AboutScreen()),
          ),

          // Version number
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
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
      title: Text(label.tr),
      value: value,
      groupValue: controller.currentTheme.value,
      onChanged: (value) => controller.changeTheme(value!),
    );
  }
}
