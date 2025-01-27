import 'package:get/get.dart';
import '../controllers/poem_controller.dart';
import '../../../data/repositories/poem_repository.dart';
import '../../../data/services/analytics_service.dart';

class PoemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PoemController>(
      () => PoemController(
        Get.find<PoemRepository>(),
        Get.find<AnalyticsService>(),
      ),
    );
  }
}