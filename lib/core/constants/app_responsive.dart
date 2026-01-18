import 'package:flutter/widgets.dart';

class AppResponsive {
  static double vw(BoxConstraints constraints, double percent) {
    return constraints.maxWidth * (percent / 100);
  }

  static double vh(BoxConstraints constraints, double percent) {
    return constraints.maxHeight * (percent / 100);
  }

  static double clamp(num value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }

  static double scaledByWidth(
    BoxConstraints constraints,
    double designValue, {
    double designWidth = 375,
  }) {
    final double scale = constraints.maxWidth / designWidth;
    return designValue * scale;
  }

  static double scaledByHeight(
    BoxConstraints constraints,
    double designValue, {
    double designHeight = 812,
  }) {
    final double scale = constraints.maxHeight / designHeight;
    return designValue * scale;
  }

  static double sp(
    BoxConstraints constraints,
    double designFontSize, {
    double designWidth = 375,
  }) {
    return scaledByWidth(
      constraints,
      designFontSize,
      designWidth: designWidth,
    );
  }
}
