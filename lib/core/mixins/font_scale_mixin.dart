import 'package:get/get.dart';
import '../controllers/font_controller.dart';

mixin FontScaleMixin {
  double scaleFont(double baseSize) {
    final fontController = Get.find<FontController>();
    return baseSize * fontController.scaleFactor.value;
  }
}
