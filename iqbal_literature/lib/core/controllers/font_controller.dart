import 'package:get/get.dart';
import '../../data/services/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../utils/responsive_util.dart';

class FontController extends GetxController {
  static const double minScale = 0.8;
  static const double maxScale = 1.5;

  final StorageService _storageService;
  final RxDouble scaleFactor = 1.0.obs;
  final RxDouble deviceScaleFactor = 1.0.obs;

  FontController(this._storageService) {
    _loadFontScale();
  }

  Future<void> _loadFontScale() async {
    try {
      final saved = await _storageService.read<double>('font_scale');
      if (saved != null) {
        scaleFactor.value = saved.clamp(minScale, maxScale);
        debugPrint('Loaded font scale: ${scaleFactor.value}');
      }
    } catch (e) {
      debugPrint('Error loading font scale: $e');
    }
  }

  Future<void> setScaleFactor(double scale) async {
    try {
      scale = scale.clamp(minScale, maxScale);
      scaleFactor.value = scale;
      await _storageService.write('font_scale', scale);
      debugPrint('Font scale set to: $scale');
    } catch (e) {
      debugPrint('Error saving font scale: $e');
    }
  }

  /// Update device-specific scale factor based on screen size
  void updateDeviceScaleFactor(BuildContext context) {
    final scaleFactor = ResponsiveUtil.getScaleFactor(context);
    deviceScaleFactor.value = scaleFactor;
  }

  /// Get the effective scale factor (user preference * device scale)
  double getEffectiveScale(BuildContext context) {
    updateDeviceScaleFactor(context);
    return scaleFactor.value * deviceScaleFactor.value;
  }

  static FontController get to => Get.find();
}
