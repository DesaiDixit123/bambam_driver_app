import 'dart:convert';
import 'dart:io';

import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:bam_bam_driver/domain/repositories/local_storage_keys.dart';
import 'package:bam_bam_driver/domain/repositories/repository.dart';
import 'package:bam_bam_driver/domain/usecases/home_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bam_bam_driver/domain/services/audio_service.dart';

class HomeController extends GetxController {
  HomeController(this.homeUsecases);

  final HomePresenter homeUsecases;

  // Dashboard values
  int ongoingTrip = 0;
  int assignedTrip = 0;
  int tripHistory = 0;
  int newRequests = 0;
  int rejectedRides = 0;

  bool isLoadingDashboard = false;

  // UI fields already present
  bool oneWay = true;
  bool isOnline = true;
  bool isLeave = false;
  String leaveRemark = '';
  String loginType = 'individual';
  TextEditingController formController = TextEditingController();
  bool isRingtonePlaying = false;

  void startRingtone() {
    isRingtonePlaying = true;
    update();
  }

  void stopRingtone() {
    AudioService.stopRingtone();
    isRingtonePlaying = false;
    update();
  }

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // controllers used in AddFineScreen
  final TextEditingController bookindIdController = TextEditingController();
  final TextEditingController vehicalNumberController = TextEditingController();
  final TextEditingController penaltyAmountController = TextEditingController();
  final TextEditingController penaltyDescriptionController = TextEditingController();

  // penalty image file
  File? penaltyPhoto;
  // loading state for submission
  bool isSubmittingFine = false;
  bool isLoadingFines = false;
  List<Map<String, dynamic>> fines = [];

  // Fine detail state:
  bool isLoadingFineDetail = false;
  Map<String, dynamic>? fineDetails;

  @override
  void onInit() {
    super.onInit();
    final repo = Get.find<Repository>();
    loginType = repo.getStringValue(LocalKeys.loginType);
    if (loginType.isEmpty) loginType = 'individual';
    update();
  }

  /// Toggle online status and call backend
  Future<void> toggleOnlineStatus(bool value) async {
    stopRingtone();
    isOnline = value;
    if (value == true) {
      isLeave = false; // Turn off leave if coming online
    }
    update();

    final res = await homeUsecases.homeUsecases.updateOnlineStatus(
      isOnline: value,
      leaveStatus: isLeave ? true : false,
    );
    if (res.hasError) {
      // revert state on error
      isOnline = !value;
      update();
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(body['Message'] ?? 'Failed to update status', MessageType.error, null, 'OK');
      } catch (_) {
        Utility.showMessage('Failed to update status', MessageType.error, null, 'OK');
      }
    } else {
      Utility.showMessage('Status updated successfully', MessageType.success, null, 'OK');
    }
  }

  /// Toggle leave status and call backend
  Future<void> toggleLeaveStatus(bool leaveStatus, {String? remark}) async {
    stopRingtone();
    isLeave = leaveStatus;
    leaveRemark = remark ?? '';
    if (leaveStatus) {
      isOnline = false; // Auto offline if on leave
    }
    update();

    final res = await homeUsecases.homeUsecases.updateOnlineStatus(
      isOnline: isOnline,
      leaveStatus: leaveStatus,
      leaveRemark: leaveRemark,
    );
    if (res.hasError) {
      isLeave = !leaveStatus; // Revert
      update();
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(body['Message'] ?? 'Failed to update leave status', MessageType.error, null, 'OK');
      } catch (_) {
        Utility.showMessage('Failed to update leave status', MessageType.error, null, 'OK');
      }
    } else {
      Utility.showMessage(leaveStatus ? 'You are now on Leave' : 'Leave removed successfully', MessageType.success, null, 'OK');
    }
  }

  /// Fetch all fines
  Future<void> fetchAllFines({String status = '', String startDate = '', String endDate = ''}) async {
    isLoadingFines = true;
    update();

    final res = await homeUsecases.homeUsecases.getAllFines(status: status, startDate: startDate, endDate: endDate);

    isLoadingFines = false;
    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(body['Message'] ?? 'Failed to fetch fines', MessageType.error, null, 'OK');
      } catch (_) {
        Utility.showMessage('Failed to fetch fines', MessageType.error, null, 'OK');
      }
      update();
      return;
    }

    try {
      final body = jsonDecode(res.data);
      if (body['IsSuccess'] == true && body['Data'] is List) {
        fines = List<Map<String, dynamic>>.from(body['Data']);
      } else {
        fines = [];
        Utility.showMessage(body['Message'] ?? 'No fines found', MessageType.information, null, 'OK');
      }
    } catch (e) {
      Utility.showMessage('Error parsing fines', MessageType.error, null, 'OK');
      fines = [];
    }

    update();
  }

  /// Fetch a single fine detail
  Future<void> fetchFineDetails(String fineId) async {
    isLoadingFineDetail = true;
    fineDetails = null;
    update();

    final res = await homeUsecases.homeUsecases.getFineDetails(fineId: fineId);

    isLoadingFineDetail = false;
    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(body['Message'] ?? 'Failed to fetch fine details', MessageType.error, null, 'OK');
      } catch (_) {
        Utility.showMessage('Failed to fetch fine details', MessageType.error, null, 'OK');
      }
      update();
      return;
    }

    try {
      final body = jsonDecode(res.data);
      if (body['IsSuccess'] == true && body['Data'] is Map) {
        fineDetails = Map<String, dynamic>.from(body['Data']);
      } else {
        Utility.showMessage(body['Message'] ?? 'Invalid fine response', MessageType.error, null, 'OK');
      }
    } catch (e) {
      Utility.showMessage('Error parsing fine details', MessageType.error, null, 'OK');
    }

    update();
  }

  /// pick penalty photo from gallery or camera
  Future<void> pickPenaltyPhoto({bool fromCamera = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null) {
        penaltyPhoto = File(file.path);
        update();
      }
    } catch (e) {
      Utility.showMessage('Failed to pick photo', MessageType.error, null, 'OK');
    }
  }

  /// submit fine (calls TripPresenter.addFine)
  Future<void> submitFine() async {
    final bookingId = bookindIdController.text.trim();
    final vehicleNo = vehicalNumberController.text.trim();
    final penaltyAmount = penaltyAmountController.text.trim();
    final penaltyDesc = penaltyDescriptionController.text.trim();

    if (bookingId.isEmpty) {
      Utility.showMessage('Enter Booking ID', MessageType.error, null, 'OK');
      return;
    }
    if (vehicleNo.isEmpty) {
      Utility.showMessage('Enter Vehicle No.', MessageType.error, null, 'OK');
      return;
    }
    if (penaltyAmount.isEmpty) {
      Utility.showMessage('Enter Penalty Amount', MessageType.error, null, 'OK');
      return;
    }
    if (penaltyDesc.isEmpty) {
      Utility.showMessage('Enter Penalty Description', MessageType.error, null, 'OK');
      return;
    }

    try {
      isSubmittingFine = true;
      update();

      final repo = Get.find<Repository>();
      final homeUsecasesLocal = HomeUsecases(repo);

      final res = await homeUsecasesLocal.addFine(
        bookingId: bookingId,
        penaltyAmount: penaltyAmount,
        penaltyDescription: penaltyDesc,
        vehicleNo: vehicleNo,
        penaltyPhoto: penaltyPhoto,
      );

      isSubmittingFine = false;
      update();

      if (res.hasError) {
        try {
          final body = jsonDecode(res.data);
          Utility.showMessage(body['Message'] ?? 'Failed to submit fine', MessageType.error, null, 'OK');
        } catch (_) {
          Utility.showMessage('Failed to submit fine', MessageType.error, null, 'OK');
        }
        return;
      }

      final body = jsonDecode(res.data);
      if (body['IsSuccess'] == true) {
        Utility.showMessage(body['Message'] ?? 'Fine submitted successfully', MessageType.success, null, 'OK');
        bookindIdController.clear();
        vehicalNumberController.clear();
        penaltyAmountController.clear();
        penaltyDescriptionController.clear();
        penaltyPhoto = null;
        fetchAllFines(status: '', startDate: '', endDate: '');
        update();
        Get.back();
      } else {
        Utility.showMessage(body['Message'] ?? 'Failed to submit fine', MessageType.error, null, 'OK');
      }
    } catch (e) {
      isSubmittingFine = false;
      update();
      Utility.showMessage('Error submitting fine', MessageType.error, null, 'OK');
    }
  }

  /// Call the dashboard API and update fields
  Future<void> fetchDashboard({bool showLoader = false}) async {
    isLoadingDashboard = true;
    update();
    try {
      await homeUsecases.homeUsecases.getDashboard(showLoader: showLoader);
    } catch (e) {
    } finally {
      isLoadingDashboard = false;
      update();
    }
  }

  /// Replaced fetchDashboard with a robust implementation (actual parsing)
  Future<void> fetchDashboardSafe({bool showLoader = false}) async {
    isLoadingDashboard = true;
    update();
    try {
      final response = await homeUsecases.homeUsecases.getDashboard(showLoader: showLoader);
      if (response.hasError) {
        try {
          final body = jsonDecode(response.data);
          final msg = body['Message'] ?? body['message'] ?? 'Failed to fetch dashboard';
          Utility.showMessage(msg.toString(), MessageType.error, null, 'OK');
        } catch (_) {
          Utility.showMessage('Failed to fetch dashboard', MessageType.error, null, 'OK');
        }
        return;
      }

      final body = jsonDecode(response.data);
      if (body is Map && body.containsKey('Data')) {
        final data = body['Data'] as Map<String, dynamic>;
        ongoingTrip = (data['ongoingTrip'] is num) ? (data['ongoingTrip'] as num).toInt() : int.tryParse('${data['ongoingTrip']}') ?? 0;
        assignedTrip = (data['assignedTrip'] is num) ? (data['assignedTrip'] as num).toInt() : int.tryParse('${data['assignedTrip']}') ?? 0;
        tripHistory = (data['tripHistory'] is num) ? (data['tripHistory'] as num).toInt() : int.tryParse('${data['tripHistory']}') ?? 0;
        newRequests = (data['newRequests'] is num) ? (data['newRequests'] as num).toInt() : int.tryParse('${data['newRequests']}') ?? 0;
        rejectedRides = (data['rejectedRides'] is num) ? (data['rejectedRides'] as num).toInt() : int.tryParse('${data['rejectedRides']}') ?? 0;
      } else {
        ongoingTrip = 0;
        assignedTrip = 0;
        tripHistory = 0;
        newRequests = 0;
        rejectedRides = 0;
      }
    } catch (e) {
      Utility.showMessage('Failed to load dashboard', MessageType.error, null, 'OK');
    } finally {
      isLoadingDashboard = false;
      update();
    }
  }

  void showLogoutDelog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.twenty)),
          child: SingleChildScrollView(
            child: Container(
              padding: Dimens.edgeInsets20,
              width: Get.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Dimens.twenty),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () => Get.back(),
                        child: SvgPicture.asset(AssetConstants.ic_cancel, height: Dimens.twentyFive),
                      ),
                    ],
                  ),
                  Dimens.boxHeight10,
                  SvgPicture.asset(AssetConstants.logout_bg),
                  Dimens.boxHeight12,
                  Center(
                    child: Text(
                      "Are you sure want to logout?",
                      style: Styles.txtBlackColorW70020,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Dimens.boxHeight30,
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        stopRingtone();
                        Get.back();
                        final repo = Get.find<Repository>();
                        repo.clearData(LocalKeys.authToken);
                        repo.clearData(LocalKeys.userDetails);
                        RouteManagement.gotoLoginScreen();
                        Utility.showMessage("Logout successful", MessageType.success, null, 'ok');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsValue.appColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.twenty)),
                      ),
                      child: Padding(
                        padding: Dimens.edgeInsets24_10_24_10,
                        child: Text("Yes, Logout", style: Styles.txtBlackColorW50016),
                      ),
                    ),
                  ),
                  Dimens.boxHeight24,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
