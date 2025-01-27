import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:iqbal_literature/config/providers/theme_provider.dart';
import 'package:iqbal_literature/data/services/analytics_service.dart';
import 'package:iqbal_literature/data/services/storage_service.dart';

class MockAnalyticsService extends GetxService with Mock implements AnalyticsService {
  @override
  void onInit() {}
}

class MockStorageService extends GetxService with Mock implements StorageService {
  @override
  void onInit() {}
}

class MockThemeProvider extends GetxService with Mock implements ThemeProvider {
  @override
  void onInit() {}
  
  @override
  ThemeMode get themeMode => ThemeMode.system;
  
  @override
  bool get isDarkMode => false;
}