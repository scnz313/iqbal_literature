import 'package:get/get.dart';
import '../controllers/daily_verse_controller.dart';

class DailyVerseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DailyVerseController>(() => DailyVerseController());
  }
}
