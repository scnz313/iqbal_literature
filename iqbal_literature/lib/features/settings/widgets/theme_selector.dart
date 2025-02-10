import 'package:flutter/material.dart';

class ThemeSelector extends StatelessWidget {
  final String selectedTheme;
  final Function(String) onThemeChanged;

  const ThemeSelector({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildThemeOption(
          context,
          'light',
          'Light',
          Icons.light_mode,
        ),
        _buildThemeOption(
          context,
          'dark',
          'Dark',
          Icons.dark_mode,
        ),
        _buildThemeOption(
          context,
          'system',
          'System',
          Icons.settings_brightness,
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
      value: value,
      groupValue: selectedTheme,
      onChanged: (value) {
        if (value != null) {
          onThemeChanged(value);
        }
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}
