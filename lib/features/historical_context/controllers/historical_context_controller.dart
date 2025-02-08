import 'package:get/get.dart';
import '../../../services/api/openrouter_service.dart';

class HistoricalContextController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> timelineEvents = <Map<String, dynamic>>[].obs;

  Future<void> loadTimelineData(String bookName, {String? timePeriod}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final events = await OpenRouterService.getTimelineEvents(
        bookName: bookName,
        timePeriod: timePeriod,
      );
      
      timelineEvents.value = events;
    } catch (e) {
      error.value = 'Failed to load timeline data: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
