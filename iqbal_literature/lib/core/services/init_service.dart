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
import '../../services/analysis/text_analysis_service.dart';
import '../../services/cache/analysis_cache_service.dart';  // Add this import
import '../../services/api/deepseek_api_client.dart';  // Add this import

class InitService extends GetxService {
  // Add static instance
  static InitService get to => Get.find<InitService>();
  
  // Make init static
  static Future<void> init() async {
    try {
      final initService = Get.put(InitService());
      await initService._initialize();
    } catch (e) {
      debugPrint('InitService error: $e');
      // Continue with partial initialization
    }
  }

  Future<void> _initialize() async {
    try {
      // 1. Initialize Firebase services
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;
      final analytics = FirebaseAnalytics.instance;

      // 2. Initialize Analysis Services FIRST
      final analysisCacheService = AnalysisCacheService();
      await analysisCacheService.init();
      Get.put<AnalysisCacheService>(analysisCacheService, permanent: true);

      final deepseekClient = DeepSeekApiClient();
      Get.put<DeepSeekApiClient>(deepseekClient, permanent: true);

      final textAnalysisService = TextAnalysisService(deepseekClient, analysisCacheService);
      Get.put<TextAnalysisService>(textAnalysisService, permanent: true);

      // 3. Core Services
      final storageService = StorageService(
        prefs: await SharedPreferences.getInstance(),
        storage: storage,
      );
      Get.put<StorageService>(storageService, permanent: true);

      final analyticsService = AnalyticsService(analytics);
      Get.put<AnalyticsService>(analyticsService, permanent: true);

      // 4. Repositories
      final poemRepo = Get.put<PoemRepository>(PoemRepository(firestore), permanent: true);
      final bookRepo = Get.put<BookRepository>(BookRepository(firestore), permanent: true);

      // 5. Controllers - Now all dependencies are available
      await Get.putAsync<PoemController>(() async {
        final controller = PoemController(
          poemRepo,
          analyticsService,
          textAnalysisService,
        );
        return controller;
      }, permanent: true);

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
      debugPrint('Initialization error: $e');
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
