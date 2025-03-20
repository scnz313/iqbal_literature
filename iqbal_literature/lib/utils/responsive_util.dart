import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ResponsiveUtil {
  // Standard design size for mobile (iPhone 13/14 size)
  static const double designWidth = 390;
  static const double designHeight = 844;

  // Tablet breakpoint
  static const double tabletBreakpoint = 600;
  static const double largeTabletBreakpoint = 900;

  /// Check if the current device is a tablet
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= tabletBreakpoint;
  }

  /// Check if the current device is a large tablet
  static bool isLargeTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= largeTabletBreakpoint;
  }

  /// Get the appropriate font size based on screen type
  static double getFontSize(double size) {
    // Use ScreenUtil to scale font sizes properly
    return size.sp;
  }

  /// Get appropriate width based on screen type
  static double getWidth(double width) {
    return width.w;
  }

  /// Get appropriate height based on screen type
  static double getHeight(double height) {
    return height.h;
  }

  /// Get appropriate padding/margin based on screen type
  static EdgeInsets getPadding(
      {double left = 0, double top = 0, double right = 0, double bottom = 0}) {
    return EdgeInsets.only(
      left: left.w,
      top: top.h,
      right: right.w,
      bottom: bottom.h,
    );
  }

  /// Get symmetric padding/margin based on screen type
  static EdgeInsets getSymmetricPadding({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: horizontal.w,
      vertical: vertical.h,
    );
  }

  /// Get all-sides padding/margin based on screen type
  static EdgeInsets getAllPadding(double padding) {
    return EdgeInsets.all(padding.r);
  }

  /// Get responsive radius for shapes
  static BorderRadius getBorderRadius(double radius) {
    return BorderRadius.circular(radius.r);
  }

  /// Get appropriate scaling factor for icons and other elements
  static double getScaleFactor(BuildContext context) {
    if (isLargeTablet(context)) {
      return 1.3;
    } else if (isTablet(context)) {
      return 1.15;
    } else {
      return 1.0;
    }
  }
}
