import 'dart:convert';
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

      // ✅ Null-safe and whitespace-safe check
      if (token.isNotEmpty && token.trim().isNotEmpty) {
        String approvalStatus = repository.getStringValue(LocalKeys.driverApprovalStatus).toLowerCase().trim();
        if (approvalStatus.isEmpty) {
          final userDetailsStr = repository.getStringValue(LocalKeys.userDetails);
          if (userDetailsStr.isNotEmpty) {
            try {
              final ud = jsonDecode(userDetailsStr);
              if (ud is Map && ud['approval_status'] != null) {
                approvalStatus = ud['approval_status'].toString().toLowerCase().trim();
                repository.saveValue(LocalKeys.driverApprovalStatus, approvalStatus);
              }
            } catch (_) {}
          }
        }

        // Check if approval is pending or rejected
        if (approvalStatus == 'pending' || approvalStatus == 'rejected' || approvalStatus == 'draft') {
          RouteManagement.gotoApprovalPendingScreen();
        } else {
          RouteManagement.gotoHomeScreen();
        }
      } else {
        // No token → go to login
        RouteManagement.gotoLoginScreen();
      }

      update();
    });
  }
}
