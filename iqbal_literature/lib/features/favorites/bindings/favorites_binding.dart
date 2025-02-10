import 'package:get/get.dart';
import '../../poems/controllers/poem_controller.dart';

class FavoritesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PoemController(Get.find(), Get.find(), Get.find()));
  }
}
