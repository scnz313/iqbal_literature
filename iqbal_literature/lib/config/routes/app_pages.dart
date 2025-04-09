import 'package:get/get.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/books/screens/books_screen.dart';
import '../../features/poems/screens/poems_screen.dart';
import '../../features/poems/views/poem_detail_view.dart';
import '../../features/poems/bindings/poem_binding.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/search/bindings/search_binding.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/favorites/bindings/favorites_binding.dart';
import '../../data/repositories/poem_repository.dart';
import '../../data/services/analytics_service.dart';
import '../../features/poems/controllers/poem_controller.dart';
import '../../features/historical_context/screens/timeline_screen.dart';
import '../../features/historical_context/bindings/historical_context_binding.dart';
import '../../features/splash/views/splash_view.dart';
import '../../features/splash/bindings/splash_binding.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/daily_verse/screens/daily_verse_screen.dart';
import '../../features/daily_verse/bindings/daily_verse_binding.dart';
import 'app_routes.dart';

class Routes {
  static const String home = '/';
  static const String books = '/books';
  static const String poems = '/poems';
  static const String poemDetail = '/poem-detail';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String bookPoems = '/book-poems'; // Add this new route
  static const String favorites = '/favorites'; // Add this new route
  static const String timeline = '/timeline'; // Add this new route
  static const String splash = '/splash';
  static const String dailyVerse = '/daily-verse';
}

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: Routes.books,
      page: () => const BooksScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.poems,
      page: () => const PoemsScreen(),
      binding: PoemBinding(), // Use PoemBinding instead of BindingsBuilder
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.poemDetail,
      page: () => const PoemDetailView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.search,
      page: () => const SearchScreen(),
      binding: SearchBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.bookPoems, // Add new route for book-specific poems
      page: () => const PoemsScreen(),
      binding: PoemBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.favorites, // Add new route for favorites
      page: () => const FavoritesScreen(),
      binding: FavoritesBinding(),
    ),
    GetPage(
      name: Routes.timeline,
      page: () => const TimelineScreen(),
      binding: HistoricalContextBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.dailyVerse,
      page: () => const DailyVerseScreen(),
      binding: DailyVerseBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
