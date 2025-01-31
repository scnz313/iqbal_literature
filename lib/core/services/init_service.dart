import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';  // Add this import
import 'package:flutter/foundation.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/analytics_service.dart';
import '../../data/repositories/book_repository.dart';
import '../../data/repositories/poem_repository.dart';
import '../../config/providers/theme_provider.dart';
import '../../config/providers/locale_provider.dart';
import '../../config/providers/font_scale_provider.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/books/controllers/book_controller.dart';
import '../../features/poems/controllers/poem_controller.dart';
import '../../features/search/controllers/search_controller.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../controllers/font_controller.dart';
import '../../data/services/search_service.dart';

class InitService extends GetxService {
  // Add static instance
  static InitService get to => Get.find<InitService>();
  
  // Make init static
  static Future<void> init() async {
    final initService = Get.put(InitService());
    await initService._initialize();
  }

  Future<void> _initialize() async {
    try {
      // Get Firebase instances
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;

      // Verify Firebase connection
      try {
        await firestore.terminate();
        await firestore.clearPersistence();
        debugPrint('✓ Firebase connection verified');
      } catch (e) {
        debugPrint('Firebase connection error: $e');
      }

      // Initialize services first
      final storageService = StorageService(
        prefs: await SharedPreferences.getInstance(),
        storage: FirebaseStorage.instance,
      );
      Get.put<StorageService>(storageService, permanent: true);

      // Initialize Firebase services
      final analytics = FirebaseAnalytics.instance;  // Add this line
      
      // Initialize Core Services
      final analyticsService = AnalyticsService(analytics);  // Pass analytics instance
      Get.put<AnalyticsService>(analyticsService, permanent: true);
      
      // Initialize Repositories
      Get.lazyPut(() => BookRepository(firestore));
      Get.lazyPut(() => PoemRepository(firestore));
      
      // Initialize Providers
      Get.put<ThemeProvider>(
        ThemeProvider(storageService),
        permanent: true,
      );
      
      Get.put<LocaleProvider>(
        LocaleProvider(storageService),
        permanent: true,
      );
      
      Get.put<FontScaleProvider>(
        FontScaleProvider(storageService),
        permanent: true,
      );
      
      // Initialize FontController before other controllers
      Get.put<FontController>(
        FontController(Get.find<StorageService>()),
        permanent: true,
      );

      // Initialize Controllers
      Get.put<HomeController>(
        HomeController(
          bookRepository: Get.find<BookRepository>(),
          poemRepository: Get.find<PoemRepository>(),
          analyticsService: analyticsService,
        ),
        permanent: true,
      );

      Get.put<BookController>(
        BookController(
          Get.find<BookRepository>(),
          Get.find<AnalyticsService>(),
        ),
        permanent: true,
      );

      Get.put<PoemController>(
        PoemController(
          Get.find<PoemRepository>(),
          Get.find<AnalyticsService>(),
        ),
        permanent: true,
      );

      Get.put<SettingsController>(
        SettingsController(
          Get.find<StorageService>(),
          Get.find<AnalyticsService>(),
        ),
        permanent: true,
      );

      // Initialize search services
      Get.lazyPut(() => SearchService(firestore));
      Get.lazyPut(() => SearchController(Get.find<SearchService>()));
      
      // Additional initialization can go here
      await _initializeDatabase();
    } catch (e) {
      debugPrint('❌ Error during initialization: $e');
      rethrow;
    }
  }

  Future<void> _initializeDatabase() async {
    // Database initialization code here
    // ...existing code...
  }

  Future<void> _registerDependencies() async {
    // Register your repositories and services here
    // ...existing dependency registrations...
    
    // Register search dependencies
    Get.lazyPut<SearchService>(
      () => SearchService(Get.find<FirebaseFirestore>()),
      fenix: true,
    );

    Get.lazyPut<SearchController>(
      () => SearchController(Get.find<SearchService>()),
      fenix: true,
    );
  }
}
