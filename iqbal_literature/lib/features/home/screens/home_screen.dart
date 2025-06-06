import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../books/screens/books_screen.dart';
import '../../poems/screens/poems_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../settings/screens/settings_screen.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iqbal Literature'),
        centerTitle: true,
        actions: [
          // Only show bookmark icon for Books (0) and Poems (1) screens
          Obx(() {
            final currentIndex = controller.currentIndex.value;
            if (currentIndex == 0 || currentIndex == 1) {
              return IconButton(
                icon: const Icon(Icons.bookmark_outline),
                onPressed: () {
                  Get.toNamed('/favorites');
                },
                tooltip: 'Bookmarks',
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() => IndexedStack(
            index: controller.currentIndex.value,
            children: const [
              BooksScreen(),
              PoemsScreen(),
              SearchScreen(),
              SettingsScreen(),
            ],
          )),
      bottomNavigationBar: Obx(() => NavigationBar(
            selectedIndex: controller.currentIndex.value,
            onDestinationSelected: controller.changePage,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.book_outlined),
                selectedIcon: Icon(Icons.book),
                label: 'Books',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_books_outlined),
                selectedIcon: Icon(Icons.library_books),
                label: 'Poems',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          )),
    );
  }
}
