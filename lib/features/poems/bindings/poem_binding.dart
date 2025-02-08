import 'package:get/get.dart';
import '../controllers/poem_controller.dart';

class PoemBinding extends Bindings {
  @override
  void dependencies() {
    // Only create new controller if one doesn't exist
    if (!Get.isRegistered<PoemController>()) {
      Get.put<PoemController>(
        PoemController(
          Get.find(),
          Get.find(),
          Get.find(),
          Get.find(),
        ),
        permanent: true,
      );
    }
  }
}