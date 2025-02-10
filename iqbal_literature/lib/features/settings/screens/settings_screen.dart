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
      appBar: CustomAppBar(
        title: 'settings'.tr,
        showBackButton: false,  // Hide the back button
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
                  onPressed: () => _showAboutDialog(context),
                  child: Text('about_app'.tr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Iqbal's Quote
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Khudi ko kar buland itna ke har taqdir se pehle,\nKhuda bande se khud pooche, bata teri raza kya hai?',
                  style: TextStyle(
                    fontFamily: 'JameelNooriNastaleeq',
                    fontSize: 20,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 24),

              // About Iqbal Section
              Text('About Allama Iqbal & This App', 
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              const Text(
                'Allama Iqbal, the visionary poet-philosopher of the East, dedicated his life to reawakening the Muslim Ummah through spiritual revival and intellectual empowerment. His philosophy of Khudi (self-realization) ignited a transformative movement urging Muslims to embrace self-awareness, unity, and progress through knowledge and faith. His timeless verses not only inspired the creation of Pakistan but continue to guide millions in reclaiming their identity and purpose.\n\nThis app is a digital tribute to Iqbal\'s wisdom, designed to make his revolutionary teachings accessible to modern seekers. Here, you\'ll explore his poetry, reflect on his philosophical insights, and discover how to embody his ideals in today\'s world.',
              ),
              const Divider(height: 32),

              // Developer Section
              Text('About the Developer', 
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              const ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text('👨💻 Hashim Hameem'),
                subtitle: Text('A passionate full-stack & Android developer from Kashmir, merging technology with tradition to preserve cultural legacies.'),
              ),
              const Divider(),
              Text('🛠 Languages & Tools:', 
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Android', 'NextJS', 'JavaScript', 'Java', 'Python', 'PHP',
                  'HTML5', 'Node.js', 'Express', 'Flask', 'Bootstrap',
                  'MSSQL', 'MySQL', 'SQLite'
                ].map((skill) => Chip(label: Text(skill))).toList(),
              ),
              const Divider(),
              Text('📫 Let\'s Connect:', 
                  style: Theme.of(context).textTheme.titleSmall),
              const ListTile(
                leading: Icon(Icons.email),
                title: Text('✉️ Email'),
                subtitle: Text('hashimdar141@yahoo.com'),
              ),
              const ListTile(
                leading: Icon(Icons.link),
                title: Text('🐦 Twitter'),
                subtitle: Text('@HashimScnz'),
              ),
              const ListTile(
                leading: Icon(Icons.work),
                title: Text('💼 LinkedIn'),
                subtitle: Text('Hashim Hameem'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '"This app is my humble effort to honor Iqbal\'s legacy – may his words continue to light our path."',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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
