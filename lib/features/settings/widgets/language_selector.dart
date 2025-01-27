import 'package:flutter/material.dart';

class LanguageConstants {
  static const Map<String, String> languageNames = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
  };
}

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
      children: LanguageConstants.languageNames.entries.map((entry) {
        return RadioListTile<String>(
          title: Text(entry.value),
          value: entry.key,
          groupValue: selectedLanguage,
          onChanged: (value) {
            if (value != null) {
              onLanguageChanged(value);
            }
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
}
