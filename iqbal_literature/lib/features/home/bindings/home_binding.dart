import 'package:get/get.dart';
import '../../daily_verse/bindings/daily_verse_binding.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize DailyVerseController
    DailyVerseBinding().dependencies();
  }
}
