import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/localization/language_constants.dart';

class LanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final Function(String) onLanguageChanged;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
          child: Text(
            'select_language'.tr,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        _buildLanguageTile(
          context,
          name: 'English',
          code: 'en',
          flag: '🇺🇸',
        ),
        _buildLanguageTile(
          context,
          name: 'اردو',
          code: 'ur',
          flag: '🇵🇰',
        ),
      ],
    );
  }

  Widget _buildLanguageTile(
    BuildContext context, {
    required String name,
    required String code,
    required String flag,
  }) {
    final isSelected = selectedLanguage == code;

    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          // Provide haptic feedback on selection
          HapticFeedback.selectionClick();
          onLanguageChanged(code);
        },
        child: RadioListTile<String>(
          title: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(name),
            ],
          ),
          value: code,
          groupValue: selectedLanguage,
          onChanged: (value) {
            if (value != null) onLanguageChanged(value);
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
