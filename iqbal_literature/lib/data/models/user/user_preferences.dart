class UserPreferences {
  final String language;
  final String theme;
  final bool notificationsEnabled;
  final bool autoPlayAudio;
  final String fontSizeLevel;
  final Map<String, dynamic> customSettings;

  UserPreferences({
    required this.language,
    required this.theme,
    required this.notificationsEnabled,
    required this.autoPlayAudio,
    required this.fontSizeLevel,
    required this.customSettings,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      language: json['language'] as String,
      theme: json['theme'] as String,
      notificationsEnabled: json['notifications_enabled'] as bool,
      autoPlayAudio: json['auto_play_audio'] as bool,
      fontSizeLevel: json['font_size_level'] as String,
      customSettings: json['custom_settings'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'theme': theme,
      'notifications_enabled': notificationsEnabled,
      'auto_play_audio': autoPlayAudio,
      'font_size_level': fontSizeLevel,
      'custom_settings': customSettings,
    };
  }
}
