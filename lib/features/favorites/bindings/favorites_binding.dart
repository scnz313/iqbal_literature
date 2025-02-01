import 'package:get/get.dart';
import '../../books/controllers/book_controller.dart';
import '../../poems/controllers/poem_controller.dart';

class FavoritesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BookController(Get.find(), Get.find()));
    Get.lazyPut(() => PoemController(Get.find(), Get.find()));
  }
}
