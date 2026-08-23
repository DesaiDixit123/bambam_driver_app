import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/repositories/repositories.dart';

class SplashController extends GetxController {
  SplashController(this.splashPresenter);

  final SplashPresenter splashPresenter;
  String? appUrl;

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  void startTimer() async {
    // Optionally check for updates (kept from your code)
    Utility.checker
        .checkUpdate()
        .then((value) {
          // Handle result if needed
        })
        .catchError((e) {
          print("Update check failed: $e");
        });

    Future.delayed(const Duration(seconds: 3)).then((_) {
      final repository = Get.find<Repository>();
      final token = repository.getStringValue(LocalKeys.authToken);

      // ✅ Log token in debug builds only (optional)
      // print("Access Token: $token");

      // ✅ Null-safe and whitespace-safe check
      if (token.isNotEmpty && token.trim().isNotEmpty) {
        // Token exists → go to home
        RouteManagement.gotoHomeScreen();
      } else {
        // No token → go to login
        RouteManagement.gotoLoginScreen();
      }

      update();
    });
  }
}
