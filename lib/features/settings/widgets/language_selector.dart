import 'package:flutter/material.dart';
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
      children: [
        RadioListTile<String>(
          title: const Text('English'),
          value: 'en',
          groupValue: selectedLanguage,
          onChanged: (value) {
            if (value != null) onLanguageChanged(value);
          },
        ),
        RadioListTile<String>(
          title: const Text('اردو'),
          value: 'ur', 
          groupValue: selectedLanguage,
          onChanged: (value) {
            if (value != null) onLanguageChanged(value);
          },
        ),
      ],
    );
  }
}
