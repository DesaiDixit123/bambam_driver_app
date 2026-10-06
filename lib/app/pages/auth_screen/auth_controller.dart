//   final HomePresenter bottomBarPresenter;

import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:bam_bam_driver/app/navigators/routes_management.dart';
import 'package:bam_bam_driver/app/pages/pages.dart';
import 'package:bam_bam_driver/app/utils/utility.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:bam_bam_driver/domain/repositories/local_storage_keys.dart';
import 'package:bam_bam_driver/domain/repositories/repository.dart';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bam_bam_driver/app/theme/colors_value.dart';
import 'package:http/http.dart' as http;
import 'package:bam_bam_driver/app/widgets/verification_dialogs.dart';
import 'package:bam_bam_driver/domain/services/socket_connection.dart';
import 'package:bam_bam_driver/domain/services/audio_service.dart';
import 'package:bam_bam_driver/app/pages/home_screen/Screens/new_ride_popup.dart';
import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';

DateTime? parseDateHelper(dynamic val) {
  if (val == null) return null;
  if (val is DateTime) return val;
  final str = val.toString().trim();
  if (str.isEmpty || str == '—' || str == 'null' || str == 'N/A') return null;

  // DD-MM-YYYY or DD/MM/YYYY
  final dmy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(str);
  if (dmy != null) {
    final d = int.tryParse(dmy.group(1)!);
    final m = int.tryParse(dmy.group(2)!);
    final y = int.tryParse(dmy.group(3)!);
    if (d != null && m != null && y != null) {
      try {
        return DateTime(y, m, d);
      } catch (_) {}
    }
  }

  // ISO or YYYY-MM-DD
  try {
    return DateTime.tryParse(str.split('T').first);
  } catch (_) {}

  return null;
}

String formatDateToDdMmYyyy(dynamic date) {
  if (date == null) return '';
  final parsed = parseDateHelper(date);
  if (parsed != null) {
    return "${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}";
  }
  final s = date.toString().trim();
  if (s == '—' || s == 'null' || s == 'N/A') return '';
  return s;
}

class AuthController extends GetxController {
  AuthController(this.authPresenter);

  final AuthPresenter authPresenter;
  TextEditingController logainMobileNumberController = TextEditingController();
  GlobalKey<FormState> singUpKey = GlobalKey<FormState>();
  GlobalKey<FormState> otpKey = GlobalKey<FormState>();
  String code = "";

  // OTP info returned by backend (for dev)
  String receivedOtp = "";
  String phoneForOtp = "";
  String loginType = 'individual'; // 'individual' or 'company'
  String fcmToken = '';

  @override
  void onInit() {
    super.onInit();
    _initFcmToken();
    _initVerificationListeners();
  }

  Future<void> _initFcmToken() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('FCM permission status: ${settings.authorizationStatus}');

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        fcmToken = token;
        print('FCM token: $fcmToken');
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        fcmToken = newToken;
        print('FCM token refreshed: $fcmToken');
      });
    } catch (e) {
      print('Failed to initialize FCM token: $e');
    }
  }

  void initializeFieldListeners() {
    final controllers = [logainMobileNumberController];
    for (var ctrl in controllers) ctrl.addListener(() => update());
  }

  // Stored verified values to prevent altering after verification
  String? verifiedDlNumber;
  String? verifiedPanNumber;
  String? verifiedAadharNumber;
  String? verifiedIfscCode;
  String? verifiedRcNumber;

  void _initVerificationListeners() {
    registerDlNumberController.addListener(() {
      if (isDlVerified && registerDlNumberController.text.trim().toUpperCase() != (verifiedDlNumber ?? '')) {
        isDlVerified = false;
        update();
      }
    });

    registerAadharController.addListener(() {
      if (isAadhaarVerified && registerAadharController.text.trim() != (verifiedAadharNumber ?? '')) {
        isAadhaarVerified = false;
        update();
      }
    });

    registerPanController.addListener(() {
      if (isPanVerified && registerPanController.text.trim().toUpperCase() != (verifiedPanNumber ?? '')) {
        isPanVerified = false;
        update();
      }
    });

    registerIfscController.addListener(() {
      if (isBankVerified && registerIfscController.text.trim().toUpperCase() != (verifiedIfscCode ?? '')) {
        isBankVerified = false;
        update();
      }
    });

    registerRcNumberController.addListener(() {
      final rc = registerRcNumberController.text.trim().toUpperCase();
      if (registerVehicleNumberController.text.trim().toUpperCase() != rc) {
        registerVehicleNumberController.text = rc;
      }
      if (isRcVerified && rc != (verifiedRcNumber ?? '')) {
        isRcVerified = false;
        update();
      }
    });

    registerMobileController.addListener(() {
      final phone = registerMobileController.text.trim();
      if (mobileAlreadyExistsError != null && phone != checkedValidMobile) {
        mobileAlreadyExistsError = null;
        update();
      }
      if (phone.length == 10 && phone != checkedValidMobile && !isCheckingMobile) {
        checkDriverMobileNumber(phone);
      }
    });
  }

  bool isCheckingMobile = false;
  String? mobileAlreadyExistsError;
  String? checkedValidMobile;

  Future<bool> checkDriverMobileNumber(String mobile, {bool showLoader = false}) async {
    if (mobile.length != 10) return false;
    isCheckingMobile = true;
    update();
    try {
      final res = await authPresenter.checkDriverMobile(mobile: mobile, showLoader: showLoader);
      final body = jsonDecode(res.data);
      final bool isSuccess = !res.hasError && (body['IsSuccess'] == true || body['success'] == true);
      if (!isSuccess) {
        final msg = body['message'] ?? body['Message'] ?? "Driver with this mobile number already exists";
        mobileAlreadyExistsError = msg.toString();
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
        update();
        return false;
      }
      mobileAlreadyExistsError = null;
      checkedValidMobile = mobile;
      update();
      return true;
    } catch (e) {
      return false;
    } finally {
      isCheckingMobile = false;
      update();
    }
  }

  // Call to send otp
  Future<void> driverSendOtp() async {
    final phone = logainMobileNumberController.text.trim();
    if (phone.isEmpty) {
      Utility.showMessage("Enter Phone No", MessageType.error, null, 'ok');
      return;
    }
    if (phone.length != 10) {
      Utility.showMessage("Please enter a valid 10-digit Phone No", MessageType.error, null, 'ok');
      return;
    }

    final response = await authPresenter.sendOtp(
      phoneNo: phone,
      loginType: loginType,
      showLoader: true,
    );
    print(response.data);
    if (response.hasError) {
      try {
        final body = jsonDecode(response.data);
        String msg = '';
        String? approvalStatus;

        if (body is Map) {
          approvalStatus = body['approval_status']?.toString();
          final rawMsg = body['Message']?.toString() ?? body['message']?.toString();
          final errDetail = body['error']?.toString();
          if (rawMsg != null && rawMsg != 'Something went wrong') {
            msg = rawMsg;
          } else if (errDetail != null && errDetail.isNotEmpty) {
            msg = errDetail;
          } else {
            msg = rawMsg ?? 'Failed to send OTP';
          }
        } else {
          msg = response.data.toString();
        }

        // 🚨 Check if Individual Driver is Pending Approval
        if (approvalStatus == 'pending' || msg.toLowerCase().contains('pending')) {
          _showPendingApprovalDialog(msg.isNotEmpty
              ? msg
              : "Your registration request is pending. When BamBam approves your request, then only you will be able to login as an individual driver.");
          return;
        }

        // 🚨 Check if Individual Driver was Rejected
        if (approvalStatus == 'rejected' || msg.toLowerCase().contains('rejected')) {
          _showRejectedDialog(msg.isNotEmpty
              ? msg
              : "Your registration request was rejected by admin. Please contact support.");
          return;
        }

        Utility.showMessage(msg, MessageType.error, null, 'ok');
      } catch (_) {
        Utility.showMessage(
          response.data.toString().isNotEmpty && response.data.toString() != 'null'
              ? response.data.toString()
              : 'Failed to send OTP',
          MessageType.error,
          null,
          'ok',
        );
      }
      return;
    }

    // ✅ parse OTP from response and store it
    try {
      final body = jsonDecode(response.data);
      String otp = "";
      if (body is Map && body.containsKey('Data')) {
        final data = body['Data'];
        if (data is Map && data.containsKey('otp')) {
          otp = data['otp'].toString();
        }
      }

      // save OTP and phone number
      phoneForOtp = phone;
      receivedOtp = otp; // ✅ store OTP for display
      update();

      // navigate to OTP screen
      RouteManagement.gotoOtpVerifyScreen();
    } catch (e) {
      phoneForOtp = phone;
      update();
      RouteManagement.gotoOtpVerifyScreen();
    }
  }

  Future<void> driverVerifyOtp() async {
    if (!otpKey.currentState!.validate()) return;

    final otpToVerify = code.trim();
    final phone = phoneForOtp.isNotEmpty
        ? phoneForOtp
        : logainMobileNumberController.text.trim();

    if (phone.isEmpty) {
      Utility.showMessage("Phone not found", MessageType.error, null, 'ok');
      return;
    }

    final response = await authPresenter.verifyOtp(
      phoneNo: phone,
      otp: otpToVerify,
      loginType: loginType,
      fcmToken: fcmToken,
      showLoader: true,
    );

    // ✅ Handle error case
    if (response.hasError) {
      try {
        final body = jsonDecode(response.data);

        // Pick up message gracefully
        String errorMsg = "Something went wrong";
        if (body is Map) {
          if (body['Message'] != null) {
            errorMsg = body['Message'].toString();
          } else if (body['message'] != null) {
            errorMsg = body['message'].toString();
          }
        }

        if (errorMsg == "Approval Pending") {
          RouteManagement.gotoApprovalPendingScreen();
          return;
        }

        Utility.showMessage(errorMsg, MessageType.error, null, 'ok');
      } catch (e) {
        // fallback if response is not JSON
        Utility.showMessage(
          response.data.toString(),
          MessageType.error,
          null,
          'ok',
        );
      }
      return;
    }

    // ✅ Parse success response
    try {
      final body = jsonDecode(response.data);
      String successMsg = (body['Message'] ?? 'Login successful').toString();

      if (body is Map && body.containsKey('Data')) {
        final data = body['Data'] as Map<String, dynamic>;

        // Save token if present
        final token =
            (data['accesstoken'] ??
                    data['accessToken'] ??
                    data['token'] ??
                    data['jwt_token'])
                ?.toString();

        if (token != null && token.isNotEmpty) {
          Get.find<Repository>().saveValue(LocalKeys.authToken, token);
        }

        // ✅ Save loginType
        Get.find<Repository>().saveValue(LocalKeys.loginType, loginType);

        // Save driver details if present
        Map<String, dynamic>? driverMap;
        if (data.containsKey('driver') && data['driver'] is Map) {
          driverMap = Map<String, dynamic>.from(data['driver']);
        } else if (data.containsKey('userdetails') && data['userdetails'] is Map) {
          driverMap = Map<String, dynamic>.from(data['userdetails']);
        }

        if (driverMap != null) {
          final userDetails = jsonEncode(driverMap);
          Get.find<Repository>().saveValue(LocalKeys.userDetails, userDetails);
          final driverId = driverMap['_id']?.toString() ?? '';
          if (driverId.isNotEmpty) {
            Get.find<Repository>().saveValue(LocalKeys.channelId, driverId);
            SocketConnection.updateChannelId(driverId);
          }
        } else {
          final resolvedId = SocketConnection.getDriverId();
          if (resolvedId.isNotEmpty) {
            SocketConnection.updateChannelId(resolvedId);
          }
        }
      }

      // Clean up previous session state so old rides do not appear
      AudioService.stopRingtone();
      NewRidePopup.activeBookingIds.clear();
      NewRidePopup.dismissedOrSeenBookingIds.clear();
      if (Get.isRegistered<TripController>()) {
        Get.find<TripController>().rideRequests.clear();
      }

      Utility.showMessage(successMsg, MessageType.success, null, 'ok');
      RouteManagement.gotoHomeScreen();
    } catch (e) {
      AudioService.stopRingtone();
      NewRidePopup.activeBookingIds.clear();
      NewRidePopup.dismissedOrSeenBookingIds.clear();
      if (Get.isRegistered<TripController>()) {
        Get.find<TripController>().rideRequests.clear();
      }
      Utility.showMessage('Login successful', MessageType.success, null, 'ok');
      RouteManagement.gotoHomeScreen();
    }
  }

  // ---------------------------------------------------------Logain Screen------------------------------------------------------

  bool isLogin = true;
  bool isSignUp = false;

  var dailcode = '+91';
  bool isValid = false;

  // ---------------------------------------------------------SignUP Screen------------------------------------------------------

  void clearController() {
    logainMobileNumberController.clear();
    fullNameController.clear();
    emailController.clear();
    phoneNumberController.clear();
    pinCodeController.clear();
  }

  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController pinCodeController = TextEditingController();
  // TextEditingController Controller = TextEditingController();

  List<String> cityList = ["Surat", "Ahemdabad", "Bharuch", "Saputara"];

  String selectedCity = "Surat";

  // ---------------------------------------------------------Quick Registration (Individual Driver)-----------------------------
  final GlobalKey<FormState> quickRegisterKey = GlobalKey<FormState>();
  final TextEditingController quickNameController = TextEditingController();
  final TextEditingController quickMobileController = TextEditingController();
  final TextEditingController quickEmailController = TextEditingController();
  String? quickDriverPhotoPath;
  bool isQuickRegistering = false;

  void resetQuickRegisterForm() {
    quickNameController.clear();
    quickMobileController.clear();
    quickEmailController.clear();
    quickDriverPhotoPath = null;
    isQuickRegistering = false;
    update();
  }

  Future<void> pickQuickDriverPhoto(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        quickDriverPhotoPath = picked.path;
        update();
      }
    } catch (e) {
      debugPrint("Error picking driver photo: $e");
    }
  }

  Future<void> quickRegister() async {
    final name = quickNameController.text.trim();
    final mobile = quickMobileController.text.trim();
    final email = quickEmailController.text.trim();

    if (quickDriverPhotoPath == null || quickDriverPhotoPath!.isEmpty) {
      Utility.showMessage("Please upload a driver profile photo", MessageType.error, null, "OK");
      return;
    }

    if (name.isEmpty || name.length < 3) {
      Utility.showMessage("Please enter a valid driver name", MessageType.error, null, "OK");
      return;
    }

    if (mobile.isEmpty || mobile.length != 10) {
      Utility.showMessage("Please enter a valid 10-digit mobile number", MessageType.error, null, "OK");
      return;
    }

    if (email.isNotEmpty && !GetUtils.isEmail(email)) {
      Utility.showMessage("Please enter a valid email address", MessageType.error, null, "OK");
      return;
    }

    isQuickRegistering = true;
    update();

    try {
      final res = await authPresenter.quickRegisterDriver(
        driverName: name,
        driverMobile: mobile,
        email: email.isNotEmpty ? email : null,
        driverPhotoPath: quickDriverPhotoPath!,
        showLoader: true,
      );

      if (res.hasError) {
        try {
          final body = jsonDecode(res.data);
          final msg = body['message'] ?? body['Message'] ?? "Registration failed";
          Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
        } catch (_) {
          Utility.showMessage(res.data.toString(), MessageType.error, null, "OK");
        }
        return;
      }

      // Parse OTP
      try {
        final body = jsonDecode(res.data);
        String otp = "";
        if (body is Map && body.containsKey('Data')) {
          final data = body['Data'];
          if (data is Map && data.containsKey('otp')) {
            otp = data['otp'].toString();
          }
        }
        phoneForOtp = mobile;
        logainMobileNumberController.text = mobile;
        loginType = 'individual';
        receivedOtp = otp;
        update();

        Utility.showMessage("OTP sent successfully to your mobile", MessageType.success, null, "OK");
        RouteManagement.gotoOtpVerifyScreen();
      } catch (e) {
        phoneForOtp = mobile;
        logainMobileNumberController.text = mobile;
        loginType = 'individual';
        update();
        RouteManagement.gotoOtpVerifyScreen();
      }
    } catch (e) {
      Utility.showMessage("Quick register error: $e", MessageType.error, null, "OK");
    } finally {
      isQuickRegistering = false;
      update();
    }
  }

  // ---------------------------------------------------------Registration Fields & Logics--------------------------------------
  final ImagePicker _picker = ImagePicker();
  GlobalKey<FormState> registerKey = GlobalKey<FormState>();

  TextEditingController registerNameController = TextEditingController();
  TextEditingController registerMobileController = TextEditingController();
  TextEditingController registerDobController = TextEditingController();
  TextEditingController registerDlNumberController = TextEditingController();
  TextEditingController registerDlIssueController = TextEditingController();
  TextEditingController registerDlExpiryController = TextEditingController();
  TextEditingController registerAddressController = TextEditingController();
  TextEditingController registerPinCodeController = TextEditingController();
  String addressSelectionType = "current_location"; // "current_location" or "manual"
  double? currentLat;
  double? currentLng;
  bool isFetchingLocation = false;
  String? detectedLocationDisplay;

  void setAddressSelectionType(String type) {
    addressSelectionType = type;
    update();
  }

  /// 📍 Detect driver's current GPS location & reverse geocode
  Future<void> detectCurrentLocation() async {
    try {
      isFetchingLocation = true;
      update();

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Utility.showMessage("Location services are disabled. Please enable GPS in device settings.", MessageType.error, null, "OK");
        isFetchingLocation = false;
        update();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Utility.showMessage("Location permissions are denied.", MessageType.error, null, "OK");
          isFetchingLocation = false;
          update();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Utility.showMessage("Location permissions are permanently denied. Please enable them in app settings.", MessageType.error, null, "OK");
        isFetchingLocation = false;
        update();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      currentLat = position.latitude;
      currentLng = position.longitude;

      // Reverse geocode via backend
      final res = await authPresenter.reverseGeocode(lat: position.latitude, lng: position.longitude);
      if (!res.hasError && res.data.isNotEmpty) {
        final body = jsonDecode(res.data);
        if (body is Map && body.containsKey('Data')) {
          final data = body['Data'];
          final formatted = data['formatted_address']?.toString() ?? "";
          final city = data['city']?.toString() ?? "";
          final state = data['state']?.toString() ?? "";
          final pincode = data['pincode']?.toString() ?? "";

          if (formatted.isNotEmpty) {
            registerAddressController.text = formatted;
            detectedLocationDisplay = formatted;
          }
          if (pincode.isNotEmpty) {
            registerPinCodeController.text = pincode;
          }
          if (state.isNotEmpty) {
            onStateChanged(state);
          }
          if (city.isNotEmpty) {
            if (!citiesList.contains(city)) {
              citiesList.insert(0, city);
            }
            selectedRegisterCity = city;
          }
          Utility.showMessage("Location detected successfully!", MessageType.success, null, "OK");
        }
      } else {
        registerAddressController.text = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        detectedLocationDisplay = registerAddressController.text;
        Utility.showMessage("Location coordinates captured!", MessageType.success, null, "OK");
      }
    } catch (e) {
      print("Error detecting location: $e");
      Utility.showMessage("Failed to detect location: ${e.toString()}", MessageType.error, null, "OK");
    } finally {
      isFetchingLocation = false;
      update();
    }
  }

  /// ⏳ Popup dialog for pending registration
  void _showPendingApprovalDialog(String message) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade300, width: 2),
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 40,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Registration Under Review",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsValue.appColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Get.back(),
                  child: const Text(
                    "Got It",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// ❌ Popup dialog for rejected registration
  void _showRejectedDialog(String message) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade300, width: 2),
                ),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 40,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Registration Rejected",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Get.back(),
                  child: const Text(
                    "Close",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  String? driverPhotoPath;
  String? dlPhotoPath;

  List<Map<String, String>> statesList = [];
  String? selectedRegisterState;

  List<String> citiesList = [];
  String? selectedRegisterCity;

  bool isStatesLoading = false;
  bool isCitiesLoading = false;

  TextEditingController stateSearchController = TextEditingController();
  TextEditingController citySearchController = TextEditingController();
  TextEditingController languageSearchController = TextEditingController();
  TextEditingController vehicleSearchController = TextEditingController();

  List<Map<String, String>> get filteredStates {
    final query = stateSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return statesList;
    return statesList.where((s) => (s['name'] ?? '').toLowerCase().contains(query)).toList();
  }

  List<String> get filteredCities {
    final query = citySearchController.text.trim().toLowerCase();
    if (query.isEmpty) return citiesList;
    return citiesList.where((c) => c.toLowerCase().contains(query)).toList();
  }

  List<Map<String, String>> get filteredLanguages {
    final query = languageSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return languagesList;
    return languagesList.where((l) => (l['name'] ?? '').toLowerCase().contains(query)).toList();
  }

  List<Map<String, String>> get filteredVehicles {
    final query = vehicleSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return vehiclesList;
    return vehiclesList.where((v) => (v['name'] ?? '').toLowerCase().contains(query)).toList();
  }

  String get selectedLanguageNamesText {
    return languagesList
        .where((l) => selectedLanguageIds.contains(l['id']))
        .map((l) => l['name'] ?? '')
        .join(', ');
  }

  String get selectedVehicleNamesText {
    return vehiclesList
        .where((v) => selectedVehicleIds.contains(v['id']))
        .map((v) => v['name'] ?? '')
        .join(', ');
  }

  void onStateChanged(String stateName, {String? stateCode}) {
    selectedRegisterState = stateName;
    selectedRegisterCity = null;
    citiesList = [];
    update();

    if (stateCode == null || stateCode.isEmpty) {
      final found = statesList.firstWhere(
        (s) => (s['name'] ?? '').toLowerCase() == stateName.toLowerCase(),
        orElse: () => {'name': stateName, 'code': ''},
      );
      stateCode = found['code'] ?? '';
    }

    if (stateCode.isNotEmpty) {
      fetchCitiesForState(stateCode);
    }
  }

  Future<void> fetchStates() async {
    isStatesLoading = true;
    update();
    try {
      final res = await authPresenter.getStates();
      if (!res.hasError && res.data.isNotEmpty) {
        final body = jsonDecode(res.data);
        final list = body['data'] ?? body['Data'];
        if (list is List && list.isNotEmpty) {
          statesList = list.map<Map<String, String>>((e) => {
            'name': (e['name'] ?? e['state_name'] ?? '').toString(),
            'code': (e['isoCode'] ?? e['code'] ?? '').toString(),
          }).toList();
          statesList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

          if (selectedRegisterState != null && selectedRegisterState!.isNotEmpty && citiesList.isEmpty) {
            final found = statesList.firstWhere(
              (s) => (s['name'] ?? '').toLowerCase() == selectedRegisterState!.toLowerCase(),
              orElse: () => {'name': selectedRegisterState!, 'code': ''},
            );
            if ((found['code'] ?? '').isNotEmpty) {
              fetchCitiesForState(found['code']!);
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching states: $e');
    } finally {
      isStatesLoading = false;
      update();
    }
  }

  Future<void> fetchCitiesForState(String stateCode) async {
    isCitiesLoading = true;
    update();
    try {
      final res = await authPresenter.getCities(stateCode: stateCode);
      if (!res.hasError && res.data.isNotEmpty) {
        final body = jsonDecode(res.data);
        final list = body['data'] ?? body['Data'];
        if (list is List && list.isNotEmpty) {
          final fetched = list
              .map<String>((e) => (e['name'] ?? e['city_name'] ?? '').toString())
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList();
          fetched.sort();
          citiesList = fetched;
        }
      }
    } catch (e) {
      print('Error fetching cities: $e');
    } finally {
      isCitiesLoading = false;
      update();
    }
  }

  List<Map<String, String>> languagesList = [
    {'id': '695555ab051d8b5192b56e2e', 'name': 'Gujarati'},
    {'id': '6902f851d3910689d1f60d6a', 'name': 'Hindi'},
    {'id': '68ef2de770bc9dc1880f2f72', 'name': 'English'},
  ];
  List<String> selectedLanguageIds = [];

  List<Map<String, String>> vehiclesList = [
    {'id': '69e4995fe276e501e94f7f91', 'name': 'SUV'},
    {'id': '69e344bb2158df9ebd90afec', 'name': 'Sedan'},
    {'id': '69e3293f2158df9ebd90980e', 'name': 'LMV'},
  ];
  List<String> selectedVehicleIds = [];

  bool isLoadingMasters = false;
  bool isRegistering = false;

  int currentRegisterStep = 0; // 0: Personal, 1: DL, 2: KYC, 3: Bank, 4: Vehicle Info & Docs, 5: Vehicle Images

  // Step 1: DL Verification & Dates
  bool isDlVerified = false;
  bool isDlVerifying = false;

  Future<void> verifyDL() async {
    final dlNo = registerDlNumberController.text.trim().toUpperCase();
    final dob = registerDobController.text.trim();
    if (dlNo.isEmpty) {
      Utility.showMessage("Please enter DL number first", MessageType.error, null, "OK");
      return;
    }
    if (dob.isEmpty) {
      Utility.showMessage("Please enter Date of Birth first", MessageType.error, null, "OK");
      return;
    }
    isDlVerifying = true;
    update();
    try {
      final res = await authPresenter.verifyDL(dlNumber: dlNo, dob: dob, showLoader: false);
      if (!res.hasError) {
        isDlVerified = true;
        verifiedDlNumber = dlNo;
        update();
        try {
          final body = jsonDecode(res.data);
          final data = (body['Data'] ?? body['data'] ?? body) as Map<String, dynamic>;
          final name = (data['holder_name'] ?? data['name'] ?? '').toString().trim();
          if (name.isNotEmpty && name != '—' && name != 'null' && name != 'N/A') {
            registerNameController.text = name;
          }
          final issue = (data['issue_date'] ?? data['dl_issue_date'] ?? data['doi'] ?? '').toString();
          if (issue.isNotEmpty && issue != '—' && issue != 'N/A') {
            registerDlIssueController.text = formatDateToDdMmYyyy(issue);
          }
          final expiry = (data['expiry_date'] ?? data['dl_expiry_date'] ?? data['doe'] ?? '').toString();
          if (expiry.isNotEmpty && expiry != '—' && expiry != 'N/A') {
            registerDlExpiryController.text = formatDateToDdMmYyyy(expiry);
          }
          update();
          if (Get.context != null) {
            showDlDetailsDialog(Get.context!, data);
          }
        } catch (_) {
          Utility.showMessage("Driving License verified successfully!", MessageType.success, null, "OK");
        }
      } else {
        final body = jsonDecode(res.data);
        final msg = body['message'] ?? body['Message'] ?? "Invalid Driving License";
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
      }
    } catch (e) {
      Utility.showMessage("DL verification error: $e", MessageType.error, null, "OK");
    } finally {
      isDlVerifying = false;
      update();
    }
  }

  // Step 2: KYC (Aadhaar & PAN)
  TextEditingController registerPanController = TextEditingController();
  TextEditingController registerAadharController = TextEditingController();
  String? panPhotoPath;
  String? aadharPhotoPath;
  String? aadharBackPhotoPath;
  bool isPanVerified = false;
  bool isPanVerifying = false;
  bool isAadhaarVerified = false;
  bool isAadhaarVerifying = false;

  // GST Verification (optional)
  TextEditingController registerGstNumberController = TextEditingController();
  bool isGstVerified = false;
  bool isGstVerifying = false;
  String? gstCertificatePhotoPath;
  String? visitingCardPhotoPath;

  // Address Proof
  String selectedAddressProofType = 'Light Bill'; // 'Light Bill', 'Rent Agreement', 'Phone Bill'
  TextEditingController addressProofNumberController = TextEditingController();
  String? addressProofDocumentPath;

  // Police Criminal Certificate (PCC) - Optional
  TextEditingController pccNumberController = TextEditingController();
  String? pccCertificatePath;

  Future<void> verifyPAN() async {
    final pan = registerPanController.text.trim().toUpperCase();
    if (pan.isEmpty) {
      Utility.showMessage("Please enter PAN number", MessageType.error, null, "OK");
      return;
    }
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan)) {
      Utility.showMessage("Invalid PAN format (e.g. ABCDE1234F)", MessageType.error, null, "OK");
      return;
    }
    isPanVerifying = true;
    update();
    try {
      final res = await authPresenter.verifyPAN(panNumber: pan, showLoader: false);
      if (!res.hasError) {
        isPanVerified = true;
        verifiedPanNumber = pan;
        update();
        try {
          final body = jsonDecode(res.data);
          final data = (body['Data'] ?? body['data'] ?? body) as Map<String, dynamic>;
          if (Get.context != null) {
            showPanDetailsDialog(Get.context!, data);
          }
        } catch (_) {
          Utility.showMessage("PAN verified successfully!", MessageType.success, null, "OK");
        }
      } else {
        final body = jsonDecode(res.data);
        final msg = body['message'] ?? body['Message'] ?? "Invalid PAN Card";
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
      }
    } catch (e) {
      Utility.showMessage("PAN verification error: $e", MessageType.error, null, "OK");
    } finally {
      isPanVerifying = false;
      update();
    }
  }

  // Aadhaar OTP ref ID storage
  String _aadhaarRefId = '';
  bool isAadhaarOtpVerifying = false;
  bool isAadhaarOtpResending = false;

  Future<void> verifyAadhaar() async {
    final aadhar = registerAadharController.text.trim().replaceAll(' ', '');
    if (aadhar.length != 12) {
      Utility.showMessage("Aadhaar must be 12 digits", MessageType.error, null, "OK");
      return;
    }
    isAadhaarVerifying = true;
    update();
    try {
      final res = await authPresenter.requestAadhaarOtp(aadhaarNumber: aadhar, showLoader: false);
      if (!res.hasError) {
        // Parse ref_id from response safely
        try {
          final body = jsonDecode(res.data);
          final dataObj = body['Data'] ?? body['data'] ?? {};
          final newRef = (dataObj['ref_id'] ?? dataObj['reference_id'] ?? dataObj['data']?['ref_id'] ?? dataObj['data']?['reference_id'] ?? '').toString();
          if (newRef.isNotEmpty && newRef != 'null') {
            _aadhaarRefId = newRef;
          }
        } catch (_) {}
        isAadhaarVerifying = false;
        update();
        // Show OTP dialog
        showAadhaarOtpDialog(
          aadhaarNumber: aadhar,
          isVerifying: isAadhaarOtpVerifying,
          isResending: isAadhaarOtpResending,
          onVerify: (otp) async {
            await _verifyAadhaarOtp(otp);
          },
          onResend: () async {
            isAadhaarOtpResending = true;
            update();
            try {
              final res2 = await authPresenter.requestAadhaarOtp(aadhaarNumber: aadhar, showLoader: false);
              if (!res2.hasError) {
                try {
                  final body = jsonDecode(res2.data);
                  final dataObj = body['Data'] ?? body['data'] ?? {};
                  final newRef = (dataObj['ref_id'] ?? dataObj['reference_id'] ?? dataObj['data']?['ref_id'] ?? dataObj['data']?['reference_id'] ?? '').toString();
                  if (newRef.isNotEmpty && newRef != 'null') {
                    _aadhaarRefId = newRef;
                  }
                } catch (_) {}
                Utility.showMessage("OTP resent to your Aadhaar-linked mobile", MessageType.success, null, "OK");
              } else {
                final body = jsonDecode(res2.data);
                final msg = body['message'] ?? body['Message'] ?? "Failed to resend OTP";
                Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
              }
            } catch (e) {
              Utility.showMessage("Resend error: $e", MessageType.error, null, "OK");
            } finally {
              isAadhaarOtpResending = false;
              update();
            }
          },
        );
      } else {
        final body = jsonDecode(res.data);
        final msg = body['message'] ?? body['Message'] ?? "Aadhaar OTP request failed";
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
      }
    } catch (e) {
      Utility.showMessage("Aadhaar OTP request error: $e", MessageType.error, null, "OK");
    } finally {
      isAadhaarVerifying = false;
      update();
    }
  }

  Future<void> _verifyAadhaarOtp(String otp) async {
    isAadhaarOtpVerifying = true;
    update();
    try {
      final aadharNo = registerAadharController.text.trim().replaceAll(' ', '');
      final res = await authPresenter.verifyAadhaarOtp(
        otp: otp,
        refId: _aadhaarRefId,
        aadhaarNumber: aadharNo,
        showLoader: false,
      );

      final body = jsonDecode(res.data);
      final isSuccess = !res.hasError && (body['IsSuccess'] == true || body['success'] == true);

      if (isSuccess) {
        isAadhaarVerified = true;
        verifiedAadharNumber = aadharNo;
        update();
        // Close OTP dialog ONLY on true success
        Get.back();

        // Show Aadhaar details dialog & auto fill
        try {
          final data = ((body['Data'] ?? body['data'] ?? body) as Map<dynamic, dynamic>)
              .map((k, v) => MapEntry(k.toString(), v));

          final name = (data['full_name'] ?? data['name'] ?? '').toString().trim();
          if (name.isNotEmpty && name != '—' && registerNameController.text.trim().isEmpty) {
            registerNameController.text = name;
          }
          final dob = (data['date_of_birth'] ?? data['dob'] ?? '').toString().trim();
          if (dob.isNotEmpty && dob != '—' && registerDobController.text.trim().isEmpty) {
            registerDobController.text = formatDateToDdMmYyyy(dob);
          }
          final addr = (data['full_address'] ?? data['address'] ?? '').toString().trim();
          if (addr.isNotEmpty && addr != '—' && registerAddressController.text.trim().isEmpty) {
            registerAddressController.text = addr;
          }
          update();

          if (Get.context != null) {
            showAadhaarDetailsDialog(Get.context!, data);
          }
        } catch (_) {
          Utility.showMessage("Aadhaar verified successfully!", MessageType.success, null, "OK");
        }
      } else {
        // Wrong OTP or error: keep dialog open, do not verify!
        isAadhaarVerified = false;
        update();
        final msg = body['message'] ?? body['Message'] ?? "Invalid OTP. Please enter correct OTP.";
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
      }
    } catch (e) {
      isAadhaarVerified = false;
      update();
      Utility.showMessage("Invalid OTP. Please enter correct OTP.", MessageType.error, null, "OK");
    } finally {
      isAadhaarOtpVerifying = false;
      update();
    }
  }


  // Step 3: Bank Details
  TextEditingController registerAccountHolderController = TextEditingController();
  TextEditingController registerBankNameController = TextEditingController();
  TextEditingController registerBranchNameController = TextEditingController();
  TextEditingController registerAccountNumberController = TextEditingController();
  TextEditingController registerIfscController = TextEditingController();
  TextEditingController registerUpiController = TextEditingController();
  String? passbookPhotoPath;
  bool isBankVerified = false;
  bool isBankVerifying = false;

  final List<String> popularBanks = [
    "State Bank of India",
    "HDFC Bank",
    "ICICI Bank",
    "Axis Bank",
    "Bank of Baroda",
    "Punjab National Bank",
    "Kotak Mahindra Bank",
    "Canara Bank",
    "Union Bank of India",
    "Bank of India",
    "IndusInd Bank",
    "IDBI Bank",
    "Central Bank of India",
    "Indian Bank",
    "Federal Bank",
    "Yes Bank",
    "Other Bank"
  ];

  Future<void> verifyIFSC() async {
    final ifsc = registerIfscController.text.trim().toUpperCase();
    if (ifsc.length < 5) {
      Utility.showMessage("Please enter valid IFSC code", MessageType.error, null, "OK");
      return;
    }
    isBankVerifying = true;
    update();
    try {
      // Call public Razorpay IFSC API for instant bank & branch lookup
      final response = await http.get(Uri.parse("https://ifsc.razorpay.com/$ifsc")).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        isBankVerified = true;
        verifiedIfscCode = ifsc;
        final bank = (decoded['BANK'] ?? '').toString();
        final branch = (decoded['BRANCH'] ?? '').toString();
        if (bank.isNotEmpty) registerBankNameController.text = bank;
        if (branch.isNotEmpty) registerBranchNameController.text = branch;
        Utility.showMessage("IFSC verified: $bank, $branch", MessageType.success, null, "OK");
      } else {
        // Fallback to backend verify
        final res = await authPresenter.verifyBank(
          accountNumber: registerAccountNumberController.text.trim().isNotEmpty
              ? registerAccountNumberController.text.trim()
              : "0000000000",
          ifscCode: ifsc,
          showLoader: false,
        );
        if (!res.hasError) {
          isBankVerified = true;
          verifiedIfscCode = ifsc;
          Utility.showMessage("IFSC verified successfully!", MessageType.success, null, "OK");
        } else {
          Utility.showMessage("Invalid IFSC Code. Please verify.", MessageType.error, null, "OK");
        }
      }
    } catch (e) {
      Utility.showMessage("IFSC check error: $e", MessageType.error, null, "OK");
    } finally {
      isBankVerifying = false;
      update();
    }
  }

  Future<void> verifyGST() async {
    final gst = registerGstNumberController.text.trim().toUpperCase();
    if (gst.isEmpty) {
      Utility.showMessage("Please enter GST number", MessageType.error, null, "OK");
      return;
    }
    if (gst.length != 15) {
      Utility.showMessage("GST number must be 15 characters", MessageType.error, null, "OK");
      return;
    }
    isGstVerifying = true;
    update();
    try {
      final res = await authPresenter.verifyGST(gstNumber: gst, showLoader: false);
      if (!res.hasError) {
        isGstVerified = true;
        update();
        try {
          final body = jsonDecode(res.data);
          final data = (body['Data'] ?? body['data'] ?? body) as Map<String, dynamic>;
          if (Get.context != null) {
            showGstDetailsDialog(Get.context!, data);
          }
        } catch (_) {
          Utility.showMessage("GST verified successfully!", MessageType.success, null, "OK");
        }
      } else {
        final body = jsonDecode(res.data);
        final msg = body['message'] ?? body['Message'] ?? "Invalid GST number";
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
      }
    } catch (e) {
      Utility.showMessage("GST verification error: $e", MessageType.error, null, "OK");
    } finally {
      isGstVerifying = false;
      update();
    }
  }

  Future<ImageSource?> showImageSourcePicker({String title = "Select Option"}) async {
    return await Get.bottomSheet<ImageSource>(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              "Choose photo / document source",
              style: TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Get.back(result: ImageSource.camera),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: ColorsValue.appColor.withOpacity(0.08),
                        border: Border.all(color: ColorsValue.appColor.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ColorsValue.appColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Camera",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          const Text("Take photo", style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => Get.back(result: ImageSource.gallery),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Gallery / Browse",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          const Text("Choose file", style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
    );
  }

  Future<String?> _pickImageWithPopup({String title = "Select Option"}) async {
    final ImageSource? source = await showImageSourcePicker(title: title);
    if (source == null) return null;
    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85);
      return picked?.path;
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  Future<void> pickGstCertificate() async {
    final String? path = await _pickImageWithPopup(title: "Select GST Certificate");
    if (path != null) {
      gstCertificatePhotoPath = path;
      update();
    }
  }

  Future<void> pickVisitingCard() async {
    final String? path = await _pickImageWithPopup(title: "Select Visiting Card");
    if (path != null) {
      visitingCardPhotoPath = path;
      update();
    }
  }

  Future<void> pickAddressProofDocument() async {
    final String? path = await _pickImageWithPopup(title: "Select Address Proof Document");
    if (path != null) {
      addressProofDocumentPath = path;
      update();
    }
  }

  Future<void> pickPccCertificate() async {
    final String? path = await _pickImageWithPopup(title: "Select Police Criminal Certificate (PCC)");
    if (path != null) {
      pccCertificatePath = path;
      update();
    }
  }

  // Step 4: Vehicle Information & Statutory Documents

  final List<String> brandList = [
    "Maruti Suzuki",
    "Hyundai",
    "Tata Motors",
    "Toyota",
    "Mahindra",
    "Honda",
    "Kia",
    "Renault",
    "Volkswagen",
    "MG Motor",
    "Skoda",
    "Nissan",
    "Other"
  ];
  String selectedBrandName = "Maruti Suzuki";
  TextEditingController customBrandController = TextEditingController();

  String? selectedVehicleType; // _id from vehiclesList
  TextEditingController registerVehicleNumberController = TextEditingController();
  TextEditingController registerVehicleMakeController = TextEditingController(); // brand/make manual input
  TextEditingController registerRcNumberController = TextEditingController(); // RC Number
  bool isRcVerified = false;
  bool isRcVerifying = false;

  Future<void> verifyRC() async {
    String vehNo = registerRcNumberController.text.trim();
    if (vehNo.isEmpty) {
      vehNo = registerVehicleNumberController.text.trim();
    }
    vehNo = vehNo.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (vehNo.isEmpty) {
      Utility.showMessage("Please enter RC number first", MessageType.error, null, "OK");
      return;
    }
    isRcVerifying = true;
    update();
    try {
      final res = await authPresenter.verifyRC(vehicleNumber: vehNo, showLoader: false);
      if (!res.hasError) {
        isRcVerified = true;
        verifiedRcNumber = vehNo;
        registerRcNumberController.text = vehNo;
        registerVehicleNumberController.text = vehNo;

        final body = jsonDecode(res.data);
        final data = ((body['Data'] ?? body['data'] ?? body) as Map<dynamic, dynamic>)
            .map((k, v) => MapEntry(k.toString(), v));

        // Auto populate brand / make
        final bName = (data['maker_model'] ?? data['brand_name'] ?? data['maker_description'] ?? '').toString().trim();
        if (bName.isNotEmpty && bName != 'N/A') {
          registerVehicleMakeController.text = bName;
          if (brandList.contains(bName)) {
            selectedBrandName = bName;
          } else {
            selectedBrandName = "Other";
            customBrandController.text = bName;
          }
        }

        // Auto populate manufacturing year (fallback to registration_date year)
        String mfgYear = (data['manufacturing_year'] ?? '').toString().trim();
        if (mfgYear.isEmpty || mfgYear == 'N/A') {
          final regDate = (data['registration_date'] ?? '').toString().trim();
          if (regDate.isNotEmpty && regDate != 'N/A') {
            mfgYear = regDate;
          }
        }
        if (mfgYear.isNotEmpty && mfgYear != 'N/A') {
          final yearMatch = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(mfgYear);
          if (yearMatch != null) {
            registerVehicleMakeYearController.text = yearMatch.group(0)!;
          } else {
            registerVehicleMakeYearController.text = mfgYear.split('-')[0].split('/')[0];
          }
        }

        // Auto populate fitness expiry
        final fitUpto = (data['fit_up_to'] ?? data['fitness_upto'] ?? '').toString().trim();
        if (fitUpto.isNotEmpty && fitUpto != 'N/A') {
          registerFitnessExpiryController.text = formatDateToDdMmYyyy(fitUpto);
        }

        // Auto populate insurance expiry
        final insUpto = (data['insurance_upto'] ?? data['insurance_expiry'] ?? '').toString().trim();
        if (insUpto.isNotEmpty && insUpto != 'N/A') {
          registerInsuranceExpiryController.text = formatDateToDdMmYyyy(insUpto);
        }

        // Auto populate permit expiry
        final permitUpto = (data['permit_expiry'] ?? data['permit_upto'] ?? '').toString().trim();
        if (permitUpto.isNotEmpty && permitUpto != 'N/A') {
          registerPermitExpiryController.text = formatDateToDdMmYyyy(permitUpto);
        }

        // Auto match fuel type if possible
        final fuel = (data['fuel_type'] ?? '').toString().trim().toUpperCase();
        if (fuel.isNotEmpty && fuel != 'N/A' && fuelTypesList.isNotEmpty) {
          bool matched = false;
          for (final f in fuelTypesList) {
            final fName = (f['name'] ?? '').toUpperCase().trim();
            if (fName == fuel || fName.contains(fuel) || fuel.contains(fName)) {
              selectedFuelType = f['id'];
              matched = true;
              break;
            }
          }
          if (!matched) {
            final parts = fuel.split(RegExp(r'[/, -]+'));
            for (final part in parts) {
              if (part.isEmpty) continue;
              for (final f in fuelTypesList) {
                final fName = (f['name'] ?? '').toUpperCase().trim();
                if (fName == part || fName.contains(part) || part.contains(fName)) {
                  selectedFuelType = f['id'];
                  matched = true;
                  break;
                }
              }
              if (matched) break;
            }
          }
        }

        // Auto-assign vehicle type from verified RC
        if (data['vehicle_type_id'] != null) {
          selectedVehicleType = data['vehicle_type_id'].toString();
        }

        update();

        // Show details dialog!
        if (Get.context != null) {
          showRcDetailsDialog(Get.context!, data);
        } else {
          Utility.showMessage("RC verified successfully!", MessageType.success, null, "OK");
        }
      } else {
        isRcVerified = false;
        final body = jsonDecode(res.data);
        final msg = body['message'] ?? body['Message'] ?? "Invalid Vehicle RC Number";
        Utility.showMessage(msg.toString(), MessageType.error, null, "OK");
      }
    } catch (e) {
      isRcVerified = false;
      Utility.showMessage("RC check error: $e", MessageType.error, null, "OK");
    } finally {
      isRcVerifying = false;
      update();
    }
  }

  List<Map<String, String>> fuelTypesList = [];
  String? selectedFuelType; // _id
  TextEditingController registerVehicleMakeYearController = TextEditingController(text: "2023");
  String selectedSourcing = "Owner Vehicle"; // "Owner Vehicle" or "Rented Vehicle"
  String? rentedVehicleAgreementPath;
  String bambamRentAgreementUrl = '';
  bool isDownloadingAgreement = false;
  String petFriendly = "No"; // "Yes" or "No"
  String luggageCarrier = "No"; // "Yes" or "No"
  String rearSeatBelts = "Yes"; // "Yes" or "No"
  String permitType = "State Permit"; // "State Permit", "All India Permit", "Special Permit", "Local City Permit"

  TextEditingController registerInsuranceExpiryController = TextEditingController();
  TextEditingController registerFitnessExpiryController = TextEditingController();
  TextEditingController registerPermitExpiryController = TextEditingController();

  String? rcPhotoPath;
  String? insuranceDocumentPath;
  String? fitnessDocumentPath;
  String? permitDocumentPath;
  String? pucDocumentPath;

  // Step 5: Vehicle Images
  String? vehicleFrontPhotoPath;
  String? vehicleBackPhotoPath;
  String? vehicleLeftPhotoPath;
  String? vehicleRightPhotoPath;
  String? vehicleInteriorPhotoPath;
  String? vehicleNumberPlatePhotoPath;
  String? vehicleDickyPhotoPath;
  String? vehicleCarrierPhotoPath;

  // Image Pickers
  Future<void> pickDriverPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Driver Profile Photo");
    if (path != null) {
      driverPhotoPath = path;
      update();
    }
  }

  Future<void> pickDlPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Driving License Photo");
    if (path != null) {
      dlPhotoPath = path;
      update();
    }
  }

  Future<void> pickPanPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select PAN Card Photo");
    if (path != null) {
      panPhotoPath = path;
      update();
    }
  }

  Future<void> pickAadharPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Aadhaar Card (Front)");
    if (path != null) {
      aadharPhotoPath = path;
      update();
    }
  }

  Future<void> pickAadharBackPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Aadhaar Card (Back)");
    if (path != null) {
      aadharBackPhotoPath = path;
      update();
    }
  }

  Future<void> pickPassbookPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Bank Passbook / Cheque");
    if (path != null) {
      passbookPhotoPath = path;
      update();
    }
  }

  Future<void> pickRcPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select RC Book Photo");
    if (path != null) {
      rcPhotoPath = path;
      update();
    }
  }

  Future<void> pickRentedVehicleAgreement() async {
    final String? path = await _pickImageWithPopup(title: "Select Car Rent Agreement");
    if (path != null) {
      rentedVehicleAgreementPath = path;
      update();
    }
  }

  /// Download official BamBam Rent Agreement template directly (PDF or Image)
  Future<void> downloadBambamRentAgreement() async {
    try {
      isDownloadingAgreement = true;
      update();

      final res = await authPresenter.getRentAgreement();
      if (res.hasError || res.data == null) {
        Utility.showMessage("Car Rent Agreement has not been uploaded by Admin yet.", MessageType.error, null, "OK");
        return;
      }

      final decoded = jsonDecode(res.data.toString());
      final data = decoded['data'] ?? decoded['Data'];
      if (data == null || data['file_url'] == null || data['file_url'].toString().trim().isEmpty) {
        Utility.showMessage("Car Rent Agreement has not been uploaded by Admin yet.", MessageType.error, null, "OK");
        return;
      }

      final raw = data['file_url'].toString();
      bambamRentAgreementUrl = raw.startsWith('http') ? raw : '${ApiWrapper.imageUrl}$raw';
      if (bambamRentAgreementUrl.startsWith('http://apis.bambamcabs.com')) {
        bambamRentAgreementUrl = bambamRentAgreementUrl.replaceFirst('http://apis.bambamcabs.com', 'https://apis.bambamcabs.com');
      }
      final fileTypeFromApi = (data['file_type'] ?? '').toString().toLowerCase();

      // Download file directly with cache-busting
      final downloadUri = Uri.parse(bambamRentAgreementUrl).replace(
        queryParameters: {'_t': '${DateTime.now().millisecondsSinceEpoch}'},
      );
      final response = await http.get(downloadUri, headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      }).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final bool isPdf = fileTypeFromApi == 'pdf' || bambamRentAgreementUrl.toLowerCase().contains('.pdf');
        String ext = isPdf ? '.pdf' : '.png';
        String mimeType = isPdf ? 'application/pdf' : 'image/png';
        if (!isPdf) {
          if (bambamRentAgreementUrl.toLowerCase().contains('.jpg')) { ext = '.jpg'; mimeType = 'image/jpeg'; }
          if (bambamRentAgreementUrl.toLowerCase().contains('.jpeg')) { ext = '.jpeg'; mimeType = 'image/jpeg'; }
        }
        final fileName = 'BamBam_Car_Rent_Agreement$ext';

        if (!isPdf) {
          // Interactive zoomable image preview dialog
          Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "BamBam Car Rent Agreement",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(maxHeight: Get.height * 0.65),
                      padding: const EdgeInsets.all(8),
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Image.memory(bytes),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5C00),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                            label: const Text(
                              "Download",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            onPressed: () async {
                              Get.back();
                              await Utility.saveBytesToPublicDownloads(
                                bytes: bytes,
                                fileName: fileName,
                                mimeType: mimeType,
                                url: bambamRentAgreementUrl,
                              );
                              Utility.showMessage(
                                "Car Rent Agreement downloaded successfully!\nSaved to your phone's Downloads folder ($fileName).",
                                MessageType.success,
                                null,
                                "OK",
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // PDF downloaded dialog
          Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF7ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf,
                        color: Color(0xFFFF5C00),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "BamBam Car Rent Agreement PDF",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "The official BamBam Car Rent Agreement PDF is ready.\n\n$fileName",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5C00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                      label: const Text(
                        "Download",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () async {
                        Get.back();
                        await Utility.saveBytesToPublicDownloads(
                          bytes: bytes,
                          fileName: fileName,
                          mimeType: mimeType,
                          url: bambamRentAgreementUrl,
                        );
                        Utility.showMessage(
                          "Car Rent Agreement downloaded successfully!\nSaved to your phone's Downloads folder ($fileName).",
                          MessageType.success,
                          null,
                          "OK",
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } else {
        Utility.showMessage(
          "Car Rent Agreement document is not found on server (Error ${response.statusCode}). Please ensure Admin has uploaded it.",
          MessageType.error,
          null,
          "OK",
        );
      }
    } catch (e) {
      debugPrint("Error downloading rent agreement: $e");
      Utility.showMessage("Could not download car rent agreement: $e", MessageType.error, null, "OK");
    } finally {
      isDownloadingAgreement = false;
      update();
    }
  }

  Future<void> pickInsuranceDocument() async {
    final String? path = await _pickImageWithPopup(title: "Select Insurance Document");
    if (path != null) {
      insuranceDocumentPath = path;
      update();
    }
  }

  Future<void> pickFitnessDocument() async {
    final String? path = await _pickImageWithPopup(title: "Select Fitness Certificate");
    if (path != null) {
      fitnessDocumentPath = path;
      update();
    }
  }

  Future<void> pickPermitDocument() async {
    final String? path = await _pickImageWithPopup(title: "Select Permit Document");
    if (path != null) {
      permitDocumentPath = path;
      update();
    }
  }

  Future<void> pickPucDocument() async {
    final String? path = await _pickImageWithPopup(title: "Select PUC Certificate");
    if (path != null) {
      pucDocumentPath = path;
      update();
    }
  }

  Future<void> pickVehicleFrontPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Vehicle Front Photo");
    if (path != null) {
      vehicleFrontPhotoPath = path;
      update();
    }
  }

  Future<void> pickVehicleBackPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Vehicle Back Photo");
    if (path != null) {
      vehicleBackPhotoPath = path;
      update();
    }
  }

  Future<void> pickVehicleLeftPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Vehicle Left Photo");
    if (path != null) {
      vehicleLeftPhotoPath = path;
      update();
    }
  }

  Future<void> pickVehicleRightPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Vehicle Right Photo");
    if (path != null) {
      vehicleRightPhotoPath = path;
      update();
    }
  }

  Future<void> pickVehicleInteriorPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Vehicle Interior Photo");
    if (path != null) {
      vehicleInteriorPhotoPath = path;
      update();
    }
  }

  Future<void> pickVehicleNumberPlatePhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Vehicle Number Plate Photo");
    if (path != null) {
      vehicleNumberPlatePhotoPath = path;
      update();
    }
  }

  Future<void> pickVehicleDickyPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Vehicle Dicky / Boot Photo");
    if (path != null) {
      vehicleDickyPhotoPath = path;
      update();
    }
  }

  Future<void> pickVehicleCarrierPhoto() async {
    final String? path = await _pickImageWithPopup(title: "Select Vehicle Carrier Photo");
    if (path != null) {
      vehicleCarrierPhotoPath = path;
      update();
    }
  }

  // Toggles for chips
  void toggleLanguage(String id) {
    if (selectedLanguageIds.contains(id)) {
      selectedLanguageIds.remove(id);
    } else {
      selectedLanguageIds.add(id);
    }
    update();
  }

  void toggleVehicle(String id) {
    if (selectedVehicleIds.contains(id)) {
      selectedVehicleIds.clear();
    } else {
      selectedVehicleIds = [id];
    }
    update();
  }

  void selectVehicle(String id) {
    selectedVehicleIds = [id];
    update();
  }

  // Load masters publicly
  Future<void> fetchRegisterMasters() async {
    try {
      // 1. Fetch languages
      final langRes = await authPresenter.getLanguages();
      if (!langRes.hasError && langRes.data.isNotEmpty) {
        final body = jsonDecode(langRes.data);
        if (body is Map && body['Data'] is List && (body['Data'] as List).isNotEmpty) {
          languagesList = (body['Data'] as List).map<Map<String, String>>((e) => {
            'id': e['_id'].toString(),
            'name': e['name'].toString(),
          }).toList();
          update();
        }
      }
    } catch (e) {
      print('Error fetching register languages: $e');
    }

    try {
      // 2. Fetch vehicle types
      final vehRes = await authPresenter.getVehicleTypes();
      if (!vehRes.hasError && vehRes.data.isNotEmpty) {
        final body = jsonDecode(vehRes.data);
        if (body is Map && body['Data'] is List && (body['Data'] as List).isNotEmpty) {
          vehiclesList = (body['Data'] as List).map<Map<String, String>>((e) => {
            'id': e['_id'].toString(),
            'name': e['name'].toString(),
          }).toList();
          if (selectedVehicleType == null && vehiclesList.isNotEmpty) {
            selectedVehicleType = vehiclesList.first['id'];
          }
          update();
        }
      }
    } catch (e) {
      print('Error fetching register vehicle-types: $e');
    }

    try {
      // 3. Fetch fuel types
      final fuelRes = await authPresenter.getFuelTypes();
      if (!fuelRes.hasError && fuelRes.data.isNotEmpty) {
        final body = jsonDecode(fuelRes.data);
        if (body is Map && body['Data'] is List && (body['Data'] as List).isNotEmpty) {
          fuelTypesList = (body['Data'] as List).map<Map<String, String>>((e) => {
            'id': e['_id'].toString(),
            'name': e['name'].toString(),
          }).toList();
          if (selectedFuelType == null && fuelTypesList.isNotEmpty) {
            selectedFuelType = fuelTypesList.first['id'];
          }
          update();
        }
      }
    } catch (e) {
      print('Error fetching register fuel-types: $e');
    }

    // 4. Fetch Indian States from API
    fetchStates();
  }

  /// 🚦 Validate current step before proceeding to next
  bool validateCurrentStep() {
    if (currentRegisterStep == 0) {
      // Step 1: Personal Information & Location
      if (driverPhotoPath == null) {
        Utility.showMessage("Driver image is required", MessageType.error, null, "OK");
        return false;
      }
      if (registerNameController.text.trim().length < 3) {
        Utility.showMessage("Enter valid driver name (at least 3 characters)", MessageType.error, null, "OK");
        return false;
      }
      if (!RegExp(r'^[0-9]{10}$').hasMatch(registerMobileController.text.trim())) {
        Utility.showMessage("Enter valid 10-digit mobile number", MessageType.error, null, "OK");
        return false;
      }
      if (mobileAlreadyExistsError != null) {
        Utility.showMessage(mobileAlreadyExistsError!, MessageType.error, null, "OK");
        return false;
      }
      if (registerDobController.text.trim().isEmpty) {
        Utility.showMessage("Please select Date of Birth", MessageType.error, null, "OK");
        return false;
      }
      if (registerAddressController.text.trim().isEmpty) {
        Utility.showMessage("Please detect GPS location or enter address", MessageType.error, null, "OK");
        return false;
      }
      if (selectedRegisterState == null || selectedRegisterState!.isEmpty) {
        Utility.showMessage("Please select State", MessageType.error, null, "OK");
        return false;
      }
      if (selectedRegisterCity == null || selectedRegisterCity!.isEmpty) {
        Utility.showMessage("Please select City", MessageType.error, null, "OK");
        return false;
      }
      return true;
    } else if (currentRegisterStep == 1) {
      // Step 2: Driving License & Experience
      if (dlPhotoPath == null) {
        Utility.showMessage("Driving license image is required", MessageType.error, null, "OK");
        return false;
      }
      if (registerDlNumberController.text.trim().isEmpty) {
        Utility.showMessage("Enter Driving License number", MessageType.error, null, "OK");
        return false;
      }
      if (!isDlVerified) {
        Utility.showMessage("Please verify your Driving License first", MessageType.error, null, "OK");
        return false;
      }
      if (registerDlIssueController.text.trim().isEmpty) {
        Utility.showMessage("Select Driving License issue date", MessageType.error, null, "OK");
        return false;
      }
      if (registerDlExpiryController.text.trim().isEmpty) {
        Utility.showMessage("Select Driving License expiry date", MessageType.error, null, "OK");
        return false;
      }
      if (selectedLanguageIds.isEmpty) {
        Utility.showMessage("Please select at least one language", MessageType.error, null, "OK");
        return false;
      }
      if (selectedVehicleIds.isEmpty) {
        Utility.showMessage("Please select at least one vehicle type", MessageType.error, null, "OK");
        return false;
      }
      return true;
    } else if (currentRegisterStep == 2) {
      // Step 3: Identity Documents (Aadhaar & PAN)
      if (registerAadharController.text.trim().length != 12) {
        Utility.showMessage("Aadhaar number must be exactly 12 digits", MessageType.error, null, "OK");
        return false;
      }
      if (!isAadhaarVerified) {
        Utility.showMessage("Please verify your Aadhaar Card first", MessageType.error, null, "OK");
        return false;
      }
      if (aadharPhotoPath == null) {
        Utility.showMessage("Aadhaar front image is required", MessageType.error, null, "OK");
        return false;
      }
      if (aadharBackPhotoPath == null) {
        Utility.showMessage("Aadhaar back image is required", MessageType.error, null, "OK");
        return false;
      }
      if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(registerPanController.text.trim().toUpperCase())) {
        Utility.showMessage("Invalid PAN number format (e.g. ABCDE1234F)", MessageType.error, null, "OK");
        return false;
      }
      if (!isPanVerified) {
        Utility.showMessage("Please verify your PAN Card first", MessageType.error, null, "OK");
        return false;
      }
      if (panPhotoPath == null) {
        Utility.showMessage("PAN card photo is required", MessageType.error, null, "OK");
        return false;
      }
      // Note: GST, Address Proof, and Visiting Card are optional - never block moving next
      return true;
    } else if (currentRegisterStep == 3) {
      // Step 4: Bank Details
      if (registerIfscController.text.trim().isEmpty) {
        Utility.showMessage("Please enter IFSC code", MessageType.error, null, "OK");
        return false;
      }
      if (!isBankVerified) {
        Utility.showMessage("Please verify your IFSC Code first", MessageType.error, null, "OK");
        return false;
      }
      if (registerBankNameController.text.trim().isEmpty) {
        Utility.showMessage("Please enter or select Bank name", MessageType.error, null, "OK");
        return false;
      }
      if (registerBranchNameController.text.trim().isEmpty) {
        Utility.showMessage("Branch name is required", MessageType.error, null, "OK");
        return false;
      }
      if (registerAccountNumberController.text.trim().length < 8) {
        Utility.showMessage("Enter valid bank account number", MessageType.error, null, "OK");
        return false;
      }
      if (registerAccountHolderController.text.trim().isEmpty) {
        Utility.showMessage("Account holder name is required", MessageType.error, null, "OK");
        return false;
      }
      if (passbookPhotoPath == null) {
        Utility.showMessage("Please upload Bank Passbook or Cheque photo", MessageType.error, null, "OK");
        return false;
      }
      return true;
    } else if (currentRegisterStep == 4) {
      // Step 5: Vehicle Information & Statutory Documents
      if (registerRcNumberController.text.trim().isEmpty) {
        Utility.showMessage("RC number is required", MessageType.error, null, "OK");
        return false;
      }
      if (!isRcVerified) {
        Utility.showMessage("Please verify RC Number first", MessageType.error, null, "OK");
        return false;
      }
      if (registerVehicleMakeController.text.trim().isEmpty) {
        Utility.showMessage("Vehicle brand/make is required", MessageType.error, null, "OK");
        return false;
      }
      if (registerVehicleNumberController.text.trim().isEmpty) {
        Utility.showMessage("Vehicle number is required", MessageType.error, null, "OK");
        return false;
      }
      if (registerVehicleMakeYearController.text.trim().isEmpty) {
        Utility.showMessage("Vehicle make year is required", MessageType.error, null, "OK");
        return false;
      }
      if (rcPhotoPath == null) {
        Utility.showMessage("RC document/photo is required", MessageType.error, null, "OK");
        return false;
      }
      if (registerInsuranceExpiryController.text.trim().isEmpty) {
        Utility.showMessage("Please select Insurance Expiry Date", MessageType.error, null, "OK");
        return false;
      }
      if (insuranceDocumentPath == null) {
        Utility.showMessage("Insurance Policy Document is required", MessageType.error, null, "OK");
        return false;
      }
      if (registerFitnessExpiryController.text.trim().isEmpty) {
        Utility.showMessage("Please select Fitness Expiry Date", MessageType.error, null, "OK");
        return false;
      }
      if (fitnessDocumentPath == null) {
        Utility.showMessage("Fitness Certificate Document is required", MessageType.error, null, "OK");
        return false;
      }
      if (registerPermitExpiryController.text.trim().isEmpty) {
        Utility.showMessage("Please select Permit Expiry Date", MessageType.error, null, "OK");
        return false;
      }
      if (permitDocumentPath == null) {
        Utility.showMessage("Permit Document is required", MessageType.error, null, "OK");
        return false;
      }
      if (pucDocumentPath == null) {
        Utility.showMessage("PUC Document is required", MessageType.error, null, "OK");
        return false;
      }
      return true;
    } else if (currentRegisterStep == 5) {
      // Step 6: Vehicle Images
      if (vehicleFrontPhotoPath == null || vehicleBackPhotoPath == null) {
        Utility.showMessage("Vehicle Front & Back photos are required", MessageType.error, null, "OK");
        return false;
      }
      if (vehicleNumberPlatePhotoPath == null) {
        Utility.showMessage("Vehicle Number Plate photo is required", MessageType.error, null, "OK");
        return false;
      }
      if (luggageCarrier == "Yes" && vehicleCarrierPhotoPath == null) {
        Utility.showMessage("Roof Luggage Carrier photo is required", MessageType.error, null, "OK");
        return false;
      }
      return true;
    }
    return true;
  }

  /// ⏭️ Move to next step or submit on last step
  Future<void> goToNextStep() async {
    if (!validateCurrentStep()) return;

    if (currentRegisterStep == 0) {
      final mobile = registerMobileController.text.trim();
      if (checkedValidMobile != mobile) {
        final isValid = await checkDriverMobileNumber(mobile, showLoader: true);
        if (!isValid) return; // Stop! Do not proceed to next page
      }
    }

    if (currentRegisterStep < 5) {
      currentRegisterStep++;
      update();
    } else {
      submitRegistration();
    }
  }

  /// ⏮️ Move to previous step
  void goToPreviousStep() {
    if (currentRegisterStep > 0) {
      currentRegisterStep--;
      update();
    } else {
      Get.back();
    }
  }

  // Submit registration
  Future<void> submitRegistration() async {
    if (!validateCurrentStep()) return;

    if (!isDlVerified) {
      Utility.showMessage("Please verify your Driving License first", MessageType.error, null, "OK");
      return;
    }
    if (!isAadhaarVerified) {
      Utility.showMessage("Please verify your Aadhaar Card first", MessageType.error, null, "OK");
      return;
    }
    if (!isPanVerified) {
      Utility.showMessage("Please verify your PAN Card first", MessageType.error, null, "OK");
      return;
    }
    if (!isBankVerified) {
      Utility.showMessage("Please verify your IFSC Code first", MessageType.error, null, "OK");
      return;
    }
    if (!isRcVerified) {
      Utility.showMessage("Please verify RC Number first", MessageType.error, null, "OK");
      return;
    }

    isRegistering = true;
    update();

    final brand = registerVehicleMakeController.text.trim().isNotEmpty
        ? registerVehicleMakeController.text.trim()
        : (selectedBrandName != "Other" ? selectedBrandName : customBrandController.text.trim());

    final Map<String, String> fields = {
      // Personal
      'driver_name': registerNameController.text.trim(),
      'driver_mobile': registerMobileController.text.trim(),
      'dob': registerDobController.text.trim(),
      'state': selectedRegisterState ?? '',
      'city': selectedRegisterCity ?? '',
      'address': registerAddressController.text.trim(),
      'pincode': registerPinCodeController.text.trim(),
      'address_type': addressSelectionType,
      if (currentLat != null) 'latitude': currentLat.toString(),
      if (currentLng != null) 'longitude': currentLng.toString(),
      // License & Skills
      'DL_number': registerDlNumberController.text.trim().toUpperCase(),
      'DL_issue_date': registerDlIssueController.text.trim(),
      'DL_expiry_date': registerDlExpiryController.text.trim(),
      'language_known': jsonEncode(selectedLanguageIds),
      'vehicales_drive': jsonEncode(selectedVehicleIds),
      // Identity
      'aadhar_number': registerAadharController.text.trim(),
      'pan_number': registerPanController.text.trim().toUpperCase(),
      // Bank
      'account_holder_name': registerAccountHolderController.text.trim().isNotEmpty
          ? registerAccountHolderController.text.trim()
          : registerNameController.text.trim(),
      'bank_name': registerBankNameController.text.trim(),
      'branch_name': registerBranchNameController.text.trim(),
      'account_number': registerAccountNumberController.text.trim(),
      'ifsc_code': registerIfscController.text.trim().toUpperCase(),
      'upi_id': registerUpiController.text.trim(),
      // Vehicle Details
      'brand_name': brand,
      'vehicle_make': brand,
      if (selectedVehicleType != null) 'vehicle_type': selectedVehicleType!,
      'vehicle_number': registerVehicleNumberController.text.trim().toUpperCase(),
      'vehicle_registration_number': registerVehicleNumberController.text.trim().toUpperCase(),
      if (selectedFuelType != null) 'fuel_type': selectedFuelType!,
      'vehicle_make_year': registerVehicleMakeYearController.text.trim(),
      'vehicle_model': registerVehicleMakeYearController.text.trim(),
      'sourcing': selectedSourcing,
      'pet_friendly': petFriendly,
      'luggage_carrier': luggageCarrier,
      'working_rear_seat_belts': rearSeatBelts,
      'permit_type': permitType,
      'insurance_expiry': registerInsuranceExpiryController.text.trim(),
      'fitness_expiry': registerFitnessExpiryController.text.trim(),
      'permit_expiry': registerPermitExpiryController.text.trim(),
      // GST (optional)
      if (registerGstNumberController.text.trim().isNotEmpty)
        'gst_number': registerGstNumberController.text.trim().toUpperCase(),
      // Address Proof (optional)
      if (addressProofDocumentPath != null || addressProofNumberController.text.trim().isNotEmpty)
        'address_proof_type': selectedAddressProofType,
      if (addressProofNumberController.text.trim().isNotEmpty)
        'address_proof_number': addressProofNumberController.text.trim(),
      // PCC (Police Criminal Certificate - optional)
      if (pccNumberController.text.trim().isNotEmpty)
        'pcc_number': pccNumberController.text.trim(),
      // RC Number
      if (registerRcNumberController.text.trim().isNotEmpty)
        'rc_number': registerRcNumberController.text.trim().toUpperCase(),
    };

    final res = await authPresenter.registerDriver(
      fields: fields,
      driverPhotoPath: driverPhotoPath!,
      dlPhotoPath: dlPhotoPath!,
      panPhotoPath: panPhotoPath,
      aadharPhotoPath: aadharPhotoPath,
      aadharBackPhotoPath: aadharBackPhotoPath,
      rcPhotoPath: rcPhotoPath,
      passbookPhotoPath: passbookPhotoPath,
      rentedVehicleAgreementPath: rentedVehicleAgreementPath,
      insuranceDocumentPath: insuranceDocumentPath,
      fitnessDocumentPath: fitnessDocumentPath,
      permitDocumentPath: permitDocumentPath,
      pucDocumentPath: pucDocumentPath,
      vehicleFrontPhotoPath: vehicleFrontPhotoPath,
      vehicleBackPhotoPath: vehicleBackPhotoPath,
      vehicleLeftPhotoPath: vehicleLeftPhotoPath,
      vehicleRightPhotoPath: vehicleRightPhotoPath,
      vehicleInteriorPhotoPath: vehicleInteriorPhotoPath,
      vehicleNumberPlatePhotoPath: vehicleNumberPlatePhotoPath,
      vehicleDickyPhotoPath: vehicleDickyPhotoPath,
      vehicleCarrierPhotoPath: vehicleCarrierPhotoPath,
      gstCertificatePhotoPath: gstCertificatePhotoPath,
      visitingCardPhotoPath: visitingCardPhotoPath,
      addressProofDocumentPath: addressProofDocumentPath,
      pccCertificatePath: pccCertificatePath,
    );

    isRegistering = false;
    update();

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        final String errorMsg =
            body['Message']?.toString() ??
            body['message']?.toString() ??
            body['error']?.toString() ??
            'Registration failed';
        print('❌ Registration error message: $errorMsg');
        Utility.showMessage(errorMsg, MessageType.error, null, "OK");
      } catch (parseErr) {
        print('❌ Could not parse error JSON: ${res.data}');
        Utility.showMessage('Registration failed. Please try again.', MessageType.error, null, "OK");
      }
    } else {
      resetRegistrationForm();
      Utility.showMessage('Registered successfully! Waiting for Admin approval.', MessageType.success, null, "OK");
      Get.back(); // Go back to login screen
    }
  }

  /// 🔄 Reset all registration form fields, uploaded photos, verification states, and step
  void resetRegistrationForm() {
    currentRegisterStep = 0;

    // Step 0: Personal Details
    registerNameController.clear();
    registerMobileController.clear();
    registerDobController.clear();
    registerAddressController.clear();
    registerPinCodeController.clear();
    addressSelectionType = "Manual";
    currentLat = null;
    currentLng = null;
    selectedRegisterState = null;
    selectedRegisterCity = null;
    citiesList = [];
    mobileAlreadyExistsError = null;
    isCheckingMobile = false;
    driverPhotoPath = null;

    // Step 1: Driving License & Skills
    dlPhotoPath = null;
    registerDlNumberController.clear();
    registerDlIssueController.clear();
    registerDlExpiryController.clear();
    selectedLanguageIds = [];
    selectedVehicleIds = [];
    isDlVerified = false;
    isDlVerifying = false;

    // Step 2: Identity Documents (KYC)
    registerAadharController.clear();
    aadharPhotoPath = null;
    aadharBackPhotoPath = null;
    isAadhaarVerified = false;
    isAadhaarVerifying = false;
    registerPanController.clear();
    panPhotoPath = null;
    isPanVerified = false;
    isPanVerifying = false;
    registerGstNumberController.clear();
    gstCertificatePhotoPath = null;
    isGstVerified = false;
    isGstVerifying = false;
    selectedAddressProofType = "Light Bill";
    addressProofNumberController.clear();
    addressProofDocumentPath = null;
    visitingCardPhotoPath = null;
    pccNumberController.clear();
    pccCertificatePath = null;

    // Step 3: Bank Details
    registerAccountHolderController.clear();
    registerBankNameController.clear();
    registerBranchNameController.clear();
    registerAccountNumberController.clear();
    registerIfscController.clear();
    registerUpiController.clear();
    passbookPhotoPath = null;
    isBankVerified = false;
    isBankVerifying = false;

    // Step 4: Vehicle Information & Statutory Documents
    registerRcNumberController.clear();
    registerVehicleNumberController.clear();
    registerVehicleMakeController.clear();
    registerVehicleMakeYearController.clear();
    selectedVehicleType = null;
    selectedFuelType = null;
    selectedBrandName = "Maruti Suzuki";
    customBrandController.clear();
    selectedSourcing = "Own Vehicle";
    rentedVehicleAgreementPath = null;
    petFriendly = "No";
    luggageCarrier = "No";
    rearSeatBelts = "Yes";
    permitType = "State Permit";
    rcPhotoPath = null;
    registerInsuranceExpiryController.clear();
    insuranceDocumentPath = null;
    registerFitnessExpiryController.clear();
    fitnessDocumentPath = null;
    registerPermitExpiryController.clear();
    permitDocumentPath = null;
    pucDocumentPath = null;
    isRcVerified = false;
    isRcVerifying = false;

    // Step 5: Vehicle Images
    vehicleFrontPhotoPath = null;
    vehicleBackPhotoPath = null;
    vehicleLeftPhotoPath = null;
    vehicleRightPhotoPath = null;
    vehicleInteriorPhotoPath = null;
    vehicleNumberPlatePhotoPath = null;
    vehicleDickyPhotoPath = null;
    vehicleCarrierPhotoPath = null;

    isRegistering = false;
    update();
  }
}
