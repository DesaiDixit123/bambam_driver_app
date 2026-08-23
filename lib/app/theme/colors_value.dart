// coverage:ignore-file
// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'package:flutter/material.dart';

/// A list of custom color used in the application.
///
/// Will be ignored for test since all are static values and would not change.
abstract class ColorsValue {
  static Color appColor = const Color(0xffEC642F);
  static Color whiteColor = const Color(0xFFFFFFFF);
  static Color blackColor = const Color(0xFF000000);
  static Color appBg = const Color(0xffFFFFFF);
  static Color redColor = const Color(0xFFD80032);

  ///  Text Colors
  static Color txtBlackColor = const Color(0xff0B1727);
  static Color txtG5Colors = const Color(0xff5E6E82);
  static Color txtG7Color = const Color(0xff9DA9BB);
  static Color txtG6Color = const Color(0xff748194);
  static Color txtGreenColor = const Color(0xff12724A);
  static Color txtRedColor = const Color(0xffFF3B30);

  /// Container colors
  /// CB ----> Container background
  static Color bulycolorsCB = const Color(0xffEDF2F9); //#D8E2EF
  static Color yellocolorsCB = const Color(0xffFDF1EC); //#D8E2EF
  static Color yellocolors2CB = const Color(0xffFFF7F4); //#D8E2EF
  static Color l4CB = const Color(0xffF9FAFD); //#D8E2EF
  static Color borderColors = const Color(0xffD8E2EF); //#D8E2EF
  static Color coupanBG = const Color(0xffF7F7FC); //#D8E2EF
}
