import 'package:get/get.dart';
import '../controllers/historical_context_controller.dart';

class HistoricalContextBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HistoricalContextController());
  }
}
