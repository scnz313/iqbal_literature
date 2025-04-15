import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
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
        showBackButton: false, // Hide the back button
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
                    _buildThemeOption(context, 'Sepia', 'sepia'),
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
                      title: Text('Enable Scheduler'.tr),
                      value: controller.isNightModeScheduled.value,
                      onChanged: controller.enableNightModeSchedule,
                    )),
                Obx(() {
                  if (!controller.isNightModeScheduled.value)
                    return const SizedBox();
                  return Column(
                    children: [
                      ListTile(
                        title: Text('start_time'.tr),
                        trailing: Text(controller.nightModeStartTime.value
                            .format(context)),
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
                        trailing: Text(
                            controller.nightModeEndTime.value.format(context)),
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
                  child: Text('about'.tr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width > 600 ? 600.0 : size.width * 0.9;
    final maxHeight = size.height * 0.9;

    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              elevation: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.05,
                        child: Image.asset(
                          'assets/images/notebook_lines.png',
                          fit: BoxFit.cover,
                          repeat: ImageRepeat.repeat,
                        ),
                      ),
                    ),

                    // Main content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with gradient
                        _buildAboutHeader(context, animation),

                        // Scrollable content
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              // Quote Section
                              _buildQuoteSection(context, animation),

                              // About Section
                              _buildMainContent(context, animation),

                              // Developer Info
                              _buildDeveloperInfo(context, animation),

                              // Skills Section
                              _buildSkillsSection(context, animation),

                              // Contact Section
                              _buildContactSection(context, animation),
                            ],
                          ),
                        ),

                        // Footer
                        _buildFooter(context),
                      ],
                    ),

                    // Close button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildAboutHeader(BuildContext context, Animation<double> animation) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        children: [
          // Animated app icon
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            )),
            child: const Icon(
              Icons.auto_stories,
              size: 48,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Animated title
          DefaultTextStyle(
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            child: AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'Iqbal Literature',
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              isRepeatingAnimation: false,
              totalRepeatCount: 1,
            ),
          ),

          const SizedBox(height: 8),

          // Animated version number
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
            )),
            child: Text(
              'Version ${controller.appVersion}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
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

  Widget _buildQuoteCard(BuildContext context, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'aaj kyun seene hamare sharar-abad nahi\nhum wahi sokhta-samaan hain tujhe yaad nahi',
          style: TextStyle(
            fontFamily: 'JameelNooriNastaleeq',
            fontSize: 20,
            height: 1.8,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About Allama Iqbal & This App',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const Text(
            'Allama Iqbal, the visionary poet-philosopher of the East, dedicated his life to reawakening the Muslim Ummah through spiritual revival and intellectual empowerment. His philosophy of Khudi (self-realization) ignited a transformative movement urging Muslims to embrace self-awareness, unity, and progress through knowledge and faith. His timeless verses not only inspired the creation of Pakistan but continue to guide millions in reclaiming their identity and purpose.\n\nThis app is a digital tribute to Iqbal\'s wisdom, designed to make his revolutionary teachings accessible to modern seekers. Here, you\'ll explore his poetry, reflect on his philosophical insights, and discover how to embody his ideals in today\'s world.',
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperSection(
      BuildContext context, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About the Developer',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('👨💻 Hashim Hameem'),
            subtitle: Text(
                'A passionate full-stack & Android developer from Kashmir, merging technology with tradition to preserve cultural legacies.'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(
      BuildContext context, Animation<double> animation) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.7, 0.9, curve: Curves.easeOut),
        )),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🛠 Skills & Technologies',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Android',
                  'NextJS',
                  'JavaScript',
                  'Java',
                  'Python',
                  'PHP',
                  'Flutter',
                  'Dart',
                  'Firebase',
                  'AWS'
                ].map((skill) => _buildSkillChip(context, skill)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillChip(BuildContext context, String skill) {
    return Material(
      color: Colors.transparent,
      child: Chip(
        label: Text(skill),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
    );
  }

  Widget _buildContactSection(
      BuildContext context, Animation<double> animation) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
        )),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📫 Let\'s Connect',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              _buildContactTile(Icons.email, 'Email', 'hashimdar141@yahoo.com'),
              _buildContactTile(Icons.link, 'Twitter', '@HashimScnz'),
              _buildContactTile(Icons.work, 'LinkedIn', 'Hashim Hameem'),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '"This app is my humble effort to honor Iqbal\'s legacy – may his words continue to light our path."',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildGradientButton(BuildContext context,
      {required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor:
            Theme.of(context).colorScheme.primary, // Changed from primary
        foregroundColor:
            Theme.of(context).colorScheme.onPrimary, // Changed from onPrimary
      ),
      child: Text(label),
    );
  }

  Widget _buildQuoteSection(BuildContext context, Animation<double> animation) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
          )),
          child: _buildQuoteCard(context, animation),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, Animation<double> animation) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: const Interval(0.5, 0.7, curve: Curves.easeOut),
          )),
          child: _buildAboutSection(context, animation),
        ),
      ),
    );
  }

  Widget _buildDeveloperInfo(
      BuildContext context, Animation<double> animation) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
          )),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDeveloperSection(context, animation),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {
              final url = 'https://github.com/HASHIM-HAMEEM';
              launchURL(url);
            },
            icon: const Icon(Icons.code),
            label: const Text('View Source'),
          ),
          _buildGradientButton(
            context,
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> launchURL(String urlString) async {
    try {
      if (await canLaunchUrlString(urlString)) {
        await launchUrlString(
          urlString,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
      } else {
        Get.snackbar(
          'Error',
          'Could not open link: $urlString',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      Get.snackbar(
        'Error',
        'Could not open link. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
