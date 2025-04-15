import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'utils/responsive_util.dart';
import 'utils/font_downloader.dart';
import 'config/routes/app_pages.dart';
import 'firebase_options.dart';
import 'services/cache/cache_service.dart';
import 'services/api/gemini_api.dart';
import 'package:flutter/foundation.dart';
import 'data/repositories/book_repository.dart';
import 'data/repositories/poem_repository.dart';
import 'services/cache/analysis_cache_service.dart';
import 'services/api/deepseek_api_client.dart';
import 'services/analysis/text_analysis_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/themes/app_theme.dart';
import 'features/home/controllers/home_controller.dart';
import 'data/services/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/services/storage_service.dart';
import 'data/services/search_service.dart';
import 'features/books/controllers/book_controller.dart';
import 'features/poems/controllers/poem_controller.dart';
import 'features/search/controllers/search_controller.dart' as app;
import 'features/settings/controllers/settings_controller.dart';
import 'config/providers/theme_provider.dart';
import 'config/providers/locale_provider.dart';
import 'config/providers/font_scale_provider.dart';
import 'core/localization/app_translations.dart';
import 'data/models/notes/word_note.dart';
import 'data/repositories/note_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimize system UI initialization
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // Allow both portrait orientations
    DeviceOrientation.landscapeLeft, // Allow landscape for tablets
    DeviceOrientation.landscapeRight,
  ]);

  try {
    // Initialize Hive for local storage
    await Hive.initFlutter();

    // Register Hive adapters
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(WordNoteAdapter());
    }

    // Clear Hive boxes to start fresh - remove this after fixing caching issues
    try {
      final booksBox = await Hive.openBox('books_cache');
      final favoritesBox = await Hive.openBox('favorite_books');
      await booksBox.clear();
      debugPrint('🧹 Cleared books cache to fix null ID issue');
    } catch (e) {
      debugPrint('⚠️ Error clearing book cache: $e');
    }

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Preload fonts for PDF export in the background
    FontDownloader.preloadFonts().then((_) {
      debugPrint('✅ Font preloading completed for PDF export');
    });

    // Initialize services
    await CacheService.init();

    // Initialize GeminiAPI with newer key
    GeminiAPI.configure("AIzaSyC8sY9B8jI7cpdv8DFbMSmSVqjkwfH_ARQ");

    // Initialize core dependencies
    final prefs = await SharedPreferences.getInstance();
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;
    final analytics = FirebaseAnalytics.instance;

    // Register core services
    Get.put<SharedPreferences>(prefs, permanent: true);
    Get.put<FirebaseFirestore>(firestore, permanent: true);
    Get.put<FirebaseStorage>(storage, permanent: true);
    Get.put<FirebaseAnalytics>(analytics, permanent: true);

    // Initialize service layer
    final storageService = StorageService(storage: storage, prefs: prefs);
    await storageService.initialize();
    Get.put<StorageService>(storageService, permanent: true);

    final analyticsService = AnalyticsService(analytics);
    Get.put<AnalyticsService>(analyticsService, permanent: true);

    final analysisCacheService = AnalysisCacheService();
    await analysisCacheService.init();
    Get.put<AnalysisCacheService>(analysisCacheService, permanent: true);

    // Initialize repositories
    final bookRepository = BookRepository(firestore);
    final poemRepository = PoemRepository(firestore);

    Get.put<BookRepository>(bookRepository, permanent: true);
    Get.put<PoemRepository>(poemRepository, permanent: true);

    // Initialize providers
    final themeProvider = ThemeProvider(storageService);
    await themeProvider.loadTheme();
    Get.put<ThemeProvider>(themeProvider, permanent: true);

    final localeProvider = LocaleProvider(storageService);
    await localeProvider.loadLanguage();
    Get.put<LocaleProvider>(localeProvider, permanent: true);

    final fontScaleProvider = FontScaleProvider(storageService);
    Get.put<FontScaleProvider>(fontScaleProvider, permanent: true);

    // Initialize API services
    final deepseekClient = DeepSeekApiClient();
    Get.put<DeepSeekApiClient>(deepseekClient, permanent: true);

    final textAnalysisService =
        TextAnalysisService(deepseekClient, analysisCacheService);
    Get.put<TextAnalysisService>(textAnalysisService, permanent: true);

    // Initialize SearchService
    final searchService = SearchService(firestore);
    Get.put<SearchService>(searchService, permanent: true);

    // Initialize controllers
    Get.put<HomeController>(
      HomeController(
        bookRepository: bookRepository,
        poemRepository: poemRepository,
        analyticsService: analyticsService,
      ),
      permanent: true,
    );

    Get.put<BookController>(
      BookController(bookRepository, analyticsService),
      permanent: true,
    );

    Get.put<PoemController>(
      PoemController(
        poemRepository,
        analyticsService,
        textAnalysisService,
      ),
      permanent: true,
    );

    Get.put<app.SearchController>(
      app.SearchController(searchService),
      permanent: true,
    );

    Get.put<SettingsController>(
      SettingsController(storageService, analyticsService),
      permanent: true,
    );

    // Preload books data
    bookRepository.getAllBooks().then((books) {
      debugPrint('📚 Preloaded ${books.length} books on app start');
    });

    // Register NoteRepository as a singleton
    if (!Get.isRegistered<NoteRepository>()) {
      Get.put(NoteRepository(), permanent: true);
    }

    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error during initialization: $e');
    runApp(const FallbackApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    // Use Obx to make the entire app reactive to locale changes
    return ScreenUtilInit(
        designSize:
            const Size(ResponsiveUtil.designWidth, ResponsiveUtil.designHeight),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return Obx(() {
            final localeProvider = Get.find<LocaleProvider>();
            final themeProvider = Get.find<ThemeProvider>();

            return GetMaterialApp(
              title: 'app_name'.tr,
              debugShowCheckedModeBanner: false,
              initialRoute: AppPages.initial,
              getPages: AppPages.routes,

              // Theme configuration
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              defaultTransition: Transition.fadeIn,

              // Add translations
              translations: AppTranslations(),

              // Configure localization
              locale: localeProvider.locale.value,
              fallbackLocale: const Locale('en', 'US'),

              unknownRoute: GetPage(
                name: '/notfound',
                page: () => const NotFoundScreen(),
              ),
            );
          });
        });
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Page Not Found', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Get.offAllNamed(Routes.home),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class FallbackApp extends StatelessWidget {
  const FallbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Something went wrong', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text('Please try again later', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
