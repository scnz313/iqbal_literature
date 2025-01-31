import 'package:get/get.dart';
import '../../data/services/storage_service.dart';

class FontScaleProvider extends GetxController {
  final StorageService _storageService;
  final RxDouble fontScale = 1.0.obs;

  FontScaleProvider(this._storageService) {
    _loadFontScale();
  }

  Future<void> _loadFontScale() async {
    try {
      final savedScale = await _storageService.read<double>('font_scale');
      if (savedScale != null) {
        fontScale.value = savedScale;
      }
    } catch (e) {
      print('Error loading font scale: $e');
    }
  }

  Future<void> setFontScale(double scale) async {
    try {
      fontScale.value = scale;
      await _storageService.write('font_scale', scale);
      Get.forceAppUpdate(); // Force rebuild of all GetX widgets
    } catch (e) {
      print('Error saving font scale: $e');
    }
  }

  static FontScaleProvider get to => Get.find<FontScaleProvider>();
}
