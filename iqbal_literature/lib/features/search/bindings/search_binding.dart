import 'package:get/get.dart';
import '../controllers/search_controller.dart';
import '../../../data/services/search_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SearchService(FirebaseFirestore.instance));
    Get.lazyPut(() => SearchController(Get.find<SearchService>()));
  }
}