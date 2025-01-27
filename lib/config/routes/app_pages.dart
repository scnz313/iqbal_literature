import 'package:get/get.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/books/screens/books_screen.dart';
import '../../features/poems/screens/poems_screen.dart';
import '../../features/poems/views/poem_detail_view.dart';
import '../../features/poems/bindings/poem_binding.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

class Routes {
  static const String home = '/';
  static const String books = '/books';
  static const String poems = '/poems';
  static const String poemDetail = '/poem-detail';
  static const String search = '/search';
  static const String settings = '/settings';
}

class AppPages {
  static const initial = Routes.home;

  static final routes = [
    GetPage(
      name: Routes.home,
      page: () => const HomeScreen(),
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
      binding: PoemBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.poemDetail,
      page: () => const PoemDetailView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.search,
      page: () => const SearchScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}