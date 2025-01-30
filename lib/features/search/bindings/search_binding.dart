import 'package:get/get.dart';
import 'package:iqbal_literature/features/search/controllers/search_controller.dart';
import 'package:iqbal_literature/data/repositories/book_repository.dart';
import 'package:iqbal_literature/data/repositories/poem_repository.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SearchController>(
      () => SearchController(
        Get.find<BookRepository>(),
        Get.find<PoemRepository>(),
      ),
    );
  }
}