import 'package:get/get.dart';
import '../controllers/book_controller.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/services/analytics_service.dart';

class BookBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookController>(() => BookController(
      Get.find<BookRepository>(),
      Get.find<AnalyticsService>(),
    ));
  }
}