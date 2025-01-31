import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as app_search;
import '../widgets/search_result_tile.dart';
import '../widgets/search_result.dart';

class SearchScreen extends GetView<app_search.SearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Back Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(28),
                            ),
                            onTap: () => Get.back(),
                            child: const SizedBox(
                              width: 48,
                              height: 56,
                              child: Icon(Icons.arrow_back),
                            ),
                          ),
                        ),
                        // Search TextField
                        Expanded(
                          child: Row(
                            children: [
                              // English text field (LTR)
                              Expanded(
                                child: TextField(
                                  controller: controller.searchController,
                                  onChanged: controller.onSearchChanged,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  textDirection: TextDirection.ltr,
                                  decoration: InputDecoration(
                                    hintText: 'Search in English...',
                                    hintStyle: TextStyle(
                                      color: theme.hintColor,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              // Vertical divider
                              Container(
                                height: 24,
                                width: 1,
                                color: theme.dividerColor,
                              ),
                              // Urdu text field (RTL)
                              Expanded(
                                child: TextField(
                                  controller: controller.urduSearchController,
                                  onChanged: controller.onSearchChanged,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.textTheme.bodyLarge?.color,
                                    fontFamily: 'JameelNooriNastaleeq',
                                  ),
                                  textDirection: TextDirection.rtl,
                                  decoration: InputDecoration(
                                    hintText: 'اردو میں تلاش کریں...',
                                    hintStyle: TextStyle(
                                      color: theme.hintColor,
                                      fontFamily: 'JameelNooriNastaleeq',
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Clear/Loading Button
                        Obx(() => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(28),
                            ),
                            onTap: controller.isLoading.value 
                                ? null 
                                : controller.clearSearch,
                            child: SizedBox(
                              width: 48,
                              height: 56,
                              child: controller.isLoading.value
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.clear,
                                      color: theme.hintColor,
                                    ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Search Results
            Expanded(
              child: Obx(() {
                if (controller.searchResults.isEmpty && 
                    controller.searchController.text.isNotEmpty && 
                    !controller.isLoading.value) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: theme.hintColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'کوئی نتیجہ نہیں ملا',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.hintColor,
                            fontFamily: 'JameelNooriNastaleeq',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.searchResults.length,
                  itemBuilder: (context, index) {
                    return SearchResultTile(
                      result: controller.searchResults[index],
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
