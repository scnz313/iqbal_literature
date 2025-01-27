// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:iqbal_literature/main.dart';
import 'package:iqbal_literature/config/providers/locale_provider.dart';
import 'package:iqbal_literature/config/providers/theme_provider.dart';
import 'package:iqbal_literature/data/services/storage_service.dart';
import 'package:iqbal_literature/features/home/controllers/home_controller.dart';
import './helpers/firebase_mock.dart';
import 'package:iqbal_literature/data/models/book/book.dart';
import 'package:iqbal_literature/data/models/poem/poem.dart';
import 'package:iqbal_literature/features/books/controllers/book_controller.dart';
import 'package:iqbal_literature/features/poems/controllers/poem_controller.dart';
import 'package:iqbal_literature/features/search/controllers/search_controller.dart';
import 'package:iqbal_literature/features/settings/controllers/settings_controller.dart';
import 'package:iqbal_literature/features/home/screens/home_screen.dart';

class MockStorageService extends GetxService implements StorageService {
  final Map<String, dynamic> _storage = {
    'theme': 'light',
    'language': 'en',
  };

  @override
  T? read<T>(String key) => _storage[key] as T?;
  
  @override
  Future<bool> write<T>(String key, T value) async {
    _storage[key] = value;
    return true;
  }
  
  @override
  Future<bool> delete(String key) async {
    _storage.remove(key);
    return true;
  }
  
  @override
  Future<void> clearCache() async {}
  
  @override
  bool containsKey(String key) => _storage.containsKey(key);
  
  @override
  Future<bool> clear() async {
    _storage.clear();
    return true;
  }
  
  Future<void> init() async {}
  
  Future<void> remove(String key) async {
    _storage.remove(key);
  }
  
  Future<void> writeIfNull(String key, dynamic value) async {
    _storage.putIfAbsent(key, () => value);
  }
  
  Future<List<String>> getKeys() async => _storage.keys.toList();
  
  @override
  Future<String> getCacheSize() async => '0 KB';
  
  @override
  String getLanguage() => _storage['language'] as String? ?? 'en';
  
  @override
  String getTheme() => _storage['theme'] as String? ?? 'light';
  
  @override
  Future<void> initialize() async {}
  
  Future<void> setLanguage(String languageCode) async {
    _storage['language'] = languageCode;
  }
  
  Future<void> setTheme(String theme) async {
    _storage['theme'] = theme;
  }

  @override
  Future<void> reload() async {}

  @override
  Future<bool> saveLanguage(String languageCode) async {
    _storage['language'] = languageCode;
    return true;
  }

  @override
  Future<bool> saveTheme(String theme) async {
    _storage['theme'] = theme;
    return true;
  }
}

class MockLocaleProvider extends GetxController implements LocaleProvider {
  final _locale = const Locale('en').obs;
  
  @override
  Locale get locale => _locale.value;
  
  void changeLocale(Locale value) => _locale.value = value;
  
  @override
  void setLocale(Locale locale) => _locale.value = locale;
  
  @override
  Future<void> loadLanguage() async {}
  
  @override
  Future<void> saveLanguage(String languageCode) async {}
  
  @override
  void changeLanguage(String languageCode) {}
  
  @override
  String getCurrentLanguageName() => 'English';
}

class MockHomeController extends GetxController implements HomeController {
  @override
  final RxBool isLoading = false.obs;
  
  @override
  final RxList<Book> books = <Book>[].obs;
  
  @override 
  final RxList<Poem> poems = <Poem>[].obs;
  
  @override
  final RxInt currentIndex = 0.obs;
  
  @override
  final RxString error = ''.obs;
  
  @override
  final List<Widget> pages = [];

  @override
  void onInit() {
    super.onInit();
    loadData();
  }
  
  @override
  Future<void> loadData() async {
    isLoading.value = true;
    await Future.delayed(Duration.zero);
    isLoading.value = false;
  }
  
  @override
  Future<void> refreshData() async {
    return loadData();
  }
  
  @override
  void changePage(int index) {
    currentIndex.value = index;
  }
  
  @override 
  void onBookTap(Book book) {
    // Mock navigation
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseMock();

  late MockStorageService storageService;
  late ThemeProvider themeProvider;
  late MockLocaleProvider localeProvider;
  late MockHomeController homeController;
  late MockBookController bookController;
  late MockPoemController poemController;
  late MockSearchController searchController;
  late MockSettingsController settingsController;

  setUp(() {
    Get.reset();
    
    // Initialize services
    storageService = MockStorageService();
    Get.put<StorageService>(storageService);
    
    // Initialize providers
    themeProvider = ThemeProvider(storageService);
    Get.put<ThemeProvider>(themeProvider);
    
    localeProvider = MockLocaleProvider();
    Get.put<LocaleProvider>(localeProvider);
    
    // Initialize controllers
    homeController = MockHomeController();
    Get.put<HomeController>(homeController);
    
    bookController = MockBookController();
    Get.put<BookController>(bookController);
    
    poemController = MockPoemController();
    Get.put<PoemController>(poemController);
    
    searchController = MockSearchController();
    Get.put<SearchController>(searchController);
    
    settingsController = MockSettingsController();
    Get.put<SettingsController>(settingsController);
  });

  testWidgets('App should initialize with home screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: IqbalLiteratureApp(),
    ));
    
    // Verify home screen is shown
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    
    // Verify bottom navigation items
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.book), findsOneWidget);
    expect(find.byIcon(Icons.article), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  tearDown(() {
    Get.reset();
  });
}

// Mock controllers
class MockBookController extends GetxController implements BookController {
  @override 
  final RxBool isLoadingMore = false.obs;
  
  final _currentPage = 0.obs;
  final _hasMoreData = true.obs;
  final _isLoadingMore = false.obs;
  final _lastDocumentId = Rxn<int>();
  final _scrollController = ScrollController();

  @override
  final RxBool isLoading = false.obs;
  
  @override
  final RxList<Book> books = <Book>[].obs;
  
  @override
  final RxList<Poem> poems = <Poem>[].obs;
  
  @override
  class MockBookController extends GetxController implements BookController {
    @override
    final RxBool isLoadingMore = false.obs;
    
    @override
    final RxInt currentPage = 1.obs;
    
    @override
    final RxBool hasMoreData = true.obs;
    
    @override 
    final RxString error = ''.obs;
    
    @override
    final RxSet<String> favoriteBookIds = <String>{}.obs;
    
    @override
    final RxBool isLoading = false.obs;
    
    @override
    final RxList<Book> books = <Book>[].obs;
    
    @override
    final RxString lastDocumentId = ''.obs;

    final scrollController = ScrollController();
    
    @override
    ScrollController get scrollController => scrollController;

    @override
    void onInit() {
      super.onInit();
      scrollController.addListener(scrollListener);
      loadBooks();
    }

    @override
    void onClose() {
      scrollController.dispose();
      super.onClose();
    }

    void scrollListener() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        if (!isLoadingMore.value && hasMoreData.value) {
          loadNextPage();
        }
      }
    }

    @override
    bool isFavorite(Book book) => favoriteBookIds.contains(book.id);

    @override
    Future<void> loadBookDetails(Book book) async {
      try {
        isLoading.value = true;
        error.value = '';
        await Future.delayed(const Duration(milliseconds: 500));
        error.value = '';
      } catch (e) {
        error.value = e.toString();
      } finally {
        isLoading.value = false;
      }
    }

    @override
    Future<void> loadBooks() async {
      try {
        if (currentPage.value == 1) {
          isLoading.value = true;
          error.value = '';
        } else {
          isLoadingMore.value = true;
        }

        await Future.delayed(const Duration(milliseconds: 500));
        
        final newBooks = List.generate(
          20,
          (i) => Book(id: '${currentPage.value * 20 + i}', name: 'Book ${currentPage.value * 20 + i}', language: 'en', icon: 'e88f')
        );

        if (currentPage.value == 1) {
          books.clear();
        }

        if (newBooks.isEmpty) {
          hasMoreData.value = false;
        } else {
          books.addAll(newBooks);
          currentPage.value++;
        }

      } catch (e) {
        error.value = e.toString();
      } finally {
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }

    @override
    Future<void> loadFavorites() async {
      try {
        favoriteBookIds.addAll(['1', '2', '3']);
      } catch (e) {
        error.value = e.toString();
      }
    }

    @override
    Future<void> refreshBooks() async {
      currentPage.value = 1;
      hasMoreData.value = true;
      await loadBooks();
    }

    @override  
    Future<void> shareBook(Book book) async {}

    @override
    Future<void> onBookTap(Book book) async {}

    @override
    Future<void> toggleFavorite(Book book) async {
      try {
        if (favoriteBookIds.contains(book.id)) {
          favoriteBookIds.remove(book.id);
        } else {
          favoriteBookIds.add(book.id);
        }
      } catch (e) {
        error.value = e.toString();
      }
    }

    @override
    Future<void> loadNextPage() async {
      if (!isLoadingMore.value && hasMoreData.value) {
        await loadBooks();
      }
    }
  }

  @override
  ScrollController get scrollController => _scrollController;

  @override
  bool isFavorite(Book book) => favoriteBookIds.contains(book.id);

  @override
  Future<void> loadBookDetails(Book book) async {}

  @override
  Future<void> loadBooks() async {}

  @override
  Future<void> loadFavorites() async {}

  @override
  Future<void> refreshBooks() async {}

  @override
  Future<void> shareBook(Book book) async {}

  @override
  Future<void> onBookTap(Book book) async {}

  @override
  Future<void> toggleFavorite(Book book) async {}

  @override
  Future<void> loadNextPage() async {}

  @override
  void onInit() {
    super.onInit();
    loadBooks();
  }
}

class MockPoemController extends GetxController implements PoemController {
  @override
  final RxBool isLoading = false.obs;
  
  @override
  final RxBool isLoadingMore = false.obs; // Add this
  
  final _lastDocumentId = Rxn<int>();
  
  @override
  int? get lastDocumentId => _lastDocumentId.value;
  
  @override
  Future<void> onPoemTap(Poem poem) async {}
  
  @override
  Future<void> refreshPoems() async {}
  
  @override
  Future<void> sharePoem(Poem poem) async {}
  
  @override
  final RxList<Poem> poems = <Poem>[].obs;

  final _currentBookId = ''.obs;
  final _currentPage = 0.obs;
  final _hasMoreData = true.obs;
  final _scrollController = ScrollController(); // Add this
  
  @override
  String get currentBookId => _currentBookId.value;
  
  @override 
  int get currentPage => _currentPage.value;
  
  @override
  final RxString error = ''.obs;
  
  @override
  bool get hasMoreData => _hasMoreData.value;

  @override
  ScrollController get scrollController => _scrollController; // Add this

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
    loadPoems();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
      if (!isLoadingMore.value && hasMoreData) {
        loadPoems();
      }
    }
  }

  @override
  Future<void> loadPoems() async {
    if (currentPage == 1) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }
    await Future.delayed(Duration.zero);
    isLoading.value = false;
    isLoadingMore.value = false;
  }

  // Rest of the implementation...
}

class MockSearchController extends GetxController implements SearchController {
  final _searchController = TextEditingController();
  
  @override
  TextEditingController get searchController => _searchController;
  
  @override
  final RxString error = ''.obs;
  
  @override
  Future<void> onSearchSubmitted(String value) async {}
  
  @override
  Future<void> showFilters() async {}
  
  @override
  final RxBool isLoading = false.obs;
  
  @override
  final RxString searchQuery = ''.obs;
  
  @override
  final RxList<dynamic> searchResults = <dynamic>[].obs;

  @override
  Future<void> search(String query) async {}

  @override
  void clearSearch() {}

  @override
  Future<void> navigateToBookDetail(Book book) async {}
  
  @override
  Future<void> navigateToPoemDetail(Poem poem) async {}
  
  @override
  void onResultTap(dynamic result) {}
  
  @override
  void onSearchChanged(String value) {}
}

class MockSettingsController extends GetxController implements SettingsController {
  final _cacheSize = '0 KB'.obs;
  final _currentLanguage = 'en'.obs;
  final _currentTheme = 'light'.obs;
  final _appVersion = '1.0.0'.obs;
  
  @override
  String get cacheSize => _cacheSize.value;
  
  @override
  String get currentLanguage => _currentLanguage.value;
  
  @override
  String get currentTheme => _currentTheme.value;
  
  @override
  String get appVersion => _appVersion.value;
  @override
  set appVersion(String value) => _appVersion.value = value;
  
  @override
  Future<void> changeTheme(String theme) async {
    _currentTheme.value = theme;
  }
  
  @override
  final RxBool isDarkMode = false.obs;
  
  @override 
  ThemeMode get themeMode => ThemeMode.system;

  @override
  Future<void> calculateCacheSize() async {}

  @override
  Future<void> changeLanguage(String languageCode) async {}

  @override
  Future<void> changeTheme(ThemeMode mode) async {}

  @override
  Future<void> clearCache() async {}

  @override
  void toggleTheme() {}
  
  @override
  String get appVersion => '1.0.0';
  
  @override
  Future<void> getAppVersion() async {}
  
  @override
  Future<void> loadSettings() async {}
  
  @override
  Future<void> showAbout() async {}
}
