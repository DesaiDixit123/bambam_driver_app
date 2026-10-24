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
    try {
      Utility.checker
          .checkUpdate()
          .then((value) {
            // Handle result if needed
          })
          .catchError((e) {
            print("Update check failed: $e");
          });
    } catch (e) {
      print("Update check error: $e");
    }

    Future.delayed(const Duration(seconds: 3)).then((_) {
      try {
        final repository = Get.find<Repository>();
        final token = repository.getStringValue(LocalKeys.authToken);

        // ✅ Null-safe and whitespace-safe check
        if (token.isNotEmpty && token.trim().isNotEmpty) {
          String approvalStatus = repository.getStringValue(LocalKeys.driverApprovalStatus).toLowerCase().trim();
          bool isProfileCompleted = repository.getBoolValue(LocalKeys.isProfileCompleted);

          final userDetailsStr = repository.getStringValue(LocalKeys.userDetails);
          if (userDetailsStr.isNotEmpty) {
            try {
              final ud = jsonDecode(userDetailsStr);
              if (ud is Map) {
                if (approvalStatus.isEmpty && ud['approval_status'] != null) {
                  approvalStatus = ud['approval_status'].toString().toLowerCase().trim();
                  repository.saveValue(LocalKeys.driverApprovalStatus, approvalStatus);
                }
                if (ud['is_profile_completed'] != null) {
                  isProfileCompleted = ud['is_profile_completed'] == true;
                  repository.saveValue(LocalKeys.isProfileCompleted, isProfileCompleted);
                }
              }
            } catch (_) {}
          }

          // Only show ApprovalPendingScreen if 6-step profile has been completed & submitted
          if (isProfileCompleted &&
              (approvalStatus == 'pending' || approvalStatus == 'rejected' || approvalStatus == 'draft')) {
            RouteManagement.gotoApprovalPendingScreen();
          } else {
            RouteManagement.gotoHomeScreen();
          }
        } else {
          // No token → go to login
          RouteManagement.gotoLoginScreen();
        }
      } catch (e) {
        print("Splash navigation error: $e");
        RouteManagement.gotoLoginScreen();
      }
    });
  }
}
