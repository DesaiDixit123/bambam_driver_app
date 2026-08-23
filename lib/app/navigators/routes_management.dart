import 'package:bam_bam_driver/app/pages/Trip_screen/Screen/assigned_trip_screen.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/Screen/trip_detiles_screen.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_binding.dart';
import 'package:get/get.dart';

import 'app_pages.dart';

abstract class RouteManagement {
  static void gotoHomeScreen() => Get.offAllNamed<void>(Routes.homeScreen);
  static void goToInAppUpdateScreen(String appUrl) =>
      Get.offAllNamed<void>(Routes.inAppUpdateScreen, arguments: appUrl);
  static void gotoLoginScreen() => Get.toNamed<void>(Routes.loginScreen);
  static void gotoOtpVerifyScreen() =>
      Get.toNamed<void>(Routes.otpVerifyScreen);
  static void gotoBookingHistoryScreen() =>
      Get.toNamed<void>(Routes.bookingHistoryScreen);
  static void gotoProfileScreen() => Get.toNamed<void>(Routes.profileScreen);
  static void gotoBookinghistoryDetilesScreen(
    bool isCancle,
    bool isAginbooking,
    bool isReview,
  ) => Get.toNamed<void>(
    Routes.bookinghistoryDetilesScreen,
    arguments: [isCancle, isAginbooking, isReview],
  );
  static void gotoPersonalDetilesScreen() =>
      Get.toNamed<void>(Routes.personalDetilesScreen);
  static void gotoTermsConditionsScreen() =>
      Get.toNamed<void>(Routes.termsConditionsScreen);
  static void gotoPrivcyPolicyScreen() =>
      Get.toNamed<void>(Routes.privcyPolicyScreen);
  static void gotoCreatTicketScreen() =>
      Get.toNamed<void>(Routes.creatTicketScreen);
  static void gotoTicketDetilesScreen() =>
      Get.toNamed<void>(Routes.ticketDetilesScreen);
  static void gotoMyTicketlistScreen() =>
      Get.toNamed<void>(Routes.myTicketlistScreen);
  static void gotoNotificationScreen() =>
      Get.toNamed<void>(Routes.notificationScreen);
  static void gotoOngoingtripScreen() =>
      Get.toNamed<void>(Routes.ongoingtripScreen);
  static void gotoCompletedtripsScreen() =>
      Get.toNamed<void>(Routes.completedtripsScreen);

  // wherever RouteManagement is defined
static void gotoFineDetilesScreen({ String? fineId, Map<String, dynamic>? arguments }) {
  final args = (arguments != null)
      ? arguments
      : (fineId != null ? {'fine_id': fineId} : null);

  if (args != null) {
    Get.toNamed<void>(Routes.fineDetilesScreen, arguments: args);
  } else {
    Get.toNamed<void>(Routes.fineDetilesScreen);
  }
}

  static void gotoAddFineScreen() => Get.toNamed<void>(Routes.addFineScreen);
  static void gotoIssuedFinesScreen() =>
      Get.toNamed<void>(Routes.issuedFinesScreen);
  static void gotoSupportScreen() => Get.toNamed<void>(Routes.supportScreen);
  static void gotoRulesScreen() => Get.toNamed<void>(Routes.rulesScreen);
  static void gotoComplectTripScreen() =>
      Get.toNamed<void>(Routes.complectTripScreen);
  static void gotoOtpScreen() => Get.toNamed<void>(Routes.otpScreen);
  // static void gotoTripDetilesScreen({required bool isComplectTrip}) =>
  //     Get.toNamed<void>(Routes.tripDetilesScreen, arguments: isComplectTrip);
    static void gotoTripDetilesScreen({
    required bool isComplectTrip,
    String? tripId,
  }) {
    Get.to(
      () => const TripDetilesScreen(),
      binding: TripBinding(),
      arguments: {
        'isComplectTrip': isComplectTrip,
        if (tripId != null) 'trip_id': tripId,
      },
    );
  }

  /// Navigate to Assigned Trip screen (if you have a binding for Trip list)
  static void gotoAssignedTripScreen({bool showOnlyRequests = false, bool showOnlyAssigned = false}) {
    Get.to(
      () => const AssignedTripScreen(),
      binding: TripBinding(),
      arguments: {
        'showOnlyRequests': showOnlyRequests,
        'showOnlyAssigned': showOnlyAssigned,
      },
    );
  }
  static void gotoTriptrackingScreen({required bool isStartTrip, String? tripId}) =>
      Get.toNamed<void>(
        Routes.triptrackingScreen,
        arguments: {
          'isStartTrip': isStartTrip,
          if (tripId != null) 'trip_id': tripId,
        },
      );
  static void gotoVehicalMiterScreen({required bool isStartTrip}) =>
      Get.toNamed<void>(Routes.vehicalMiterScreen, arguments: isStartTrip);
  static void gotoApprovalPendingScreen() =>
      Get.toNamed<void>(Routes.approvalPendingScreen);

  static void gotoRegisterScreen() =>
      Get.toNamed<void>(Routes.registerScreen);

  static void gotoRejectedRidesScreen() =>
      Get.toNamed<void>(Routes.rejectedRidesScreen);

}

