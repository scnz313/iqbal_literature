import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../../../data/repositories/poem_repository.dart';

class SplashBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(
      () => SplashController(
        poemRepository: Get.find<PoemRepository>(),
      ),
    );
  }
}
