import 'package:flutter/material.dart';
import '../../utils/responsive_util.dart';

/// A wrapper widget that adapts its child based on screen size
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? largeTablet;
  final double? width;
  final double? height;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.largeTablet,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Return different widgets based on screen size
    if (ResponsiveUtil.isLargeTablet(context) && largeTablet != null) {
      return SizedBox(
        width: width != null ? ResponsiveUtil.getWidth(width!) : null,
        height: height != null ? ResponsiveUtil.getHeight(height!) : null,
        child: largeTablet!,
      );
    }

    if (ResponsiveUtil.isTablet(context) && tablet != null) {
      return SizedBox(
        width: width != null ? ResponsiveUtil.getWidth(width!) : null,
        height: height != null ? ResponsiveUtil.getHeight(height!) : null,
        child: tablet!,
      );
    }

    // Default to mobile layout
    return SizedBox(
      width: width != null ? ResponsiveUtil.getWidth(width!) : null,
      height: height != null ? ResponsiveUtil.getHeight(height!) : null,
      child: mobile,
    );
  }

  /// Convenience method to check screen size
  static bool isTablet(BuildContext context) {
    return ResponsiveUtil.isTablet(context);
  }

  /// Convenience method to check large tablet screens
  static bool isLargeTablet(BuildContext context) {
    return ResponsiveUtil.isLargeTablet(context);
  }

  /// Convenience method for getting scaling factor
  static double getScaleFactor(BuildContext context) {
    return ResponsiveUtil.getScaleFactor(context);
  }
}
