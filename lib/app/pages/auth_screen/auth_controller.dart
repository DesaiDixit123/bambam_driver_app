//   final HomePresenter bottomBarPresenter;

import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:bam_bam_driver/app/navigators/routes_management.dart';
import 'package:bam_bam_driver/app/pages/pages.dart';
import 'package:bam_bam_driver/app/utils/utility.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:bam_bam_driver/domain/repositories/local_storage_keys.dart';
import 'package:bam_bam_driver/domain/repositories/repository.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

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

  // Call to send otp
  Future<void> driverSendOtp() async {
    final phone = logainMobileNumberController.text.trim();
    if (phone.isEmpty) {
      Utility.showMessage("Enter Phone No", MessageType.error, null, 'ok');
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

        if (body is Map) {
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
        if (data.containsKey('userdetails') && data['userdetails'] is Map) {
          final userDetails = jsonEncode(data['userdetails']);
          Get.find<Repository>().saveValue(LocalKeys.userDetails, userDetails);
        }
      }

      Utility.showMessage(successMsg, MessageType.success, null, 'ok');
      RouteManagement.gotoHomeScreen();
    } catch (e) {
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

  String? driverPhotoPath;
  String? dlPhotoPath;

  List<String> stateList = ["Gujarat", "Maharashtra", "Rajasthan", "Delhi"];
  String selectedRegisterState = "Gujarat";

  List<String> registerCityList = ["Surat", "Ahmedabad", "Bharuch", "Vadodara", "Mumbai", "Pune"];
  String selectedRegisterCity = "Surat";

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



  // Image pickers
  Future<void> pickDriverPhoto() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      driverPhotoPath = picked.path;
      update();
    }
  }

  Future<void> pickDlPhoto() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      dlPhotoPath = picked.path;
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
      selectedVehicleIds.remove(id);
    } else {
      selectedVehicleIds.add(id);
    }
    update();
  }

  // Load masters publicly
  Future<void> fetchRegisterMasters() async {
    try {
      // 1. Fetch languages
      final langRes = await authPresenter.getLanguages();
      if (langRes.data != null) {
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
      if (vehRes.data != null) {
        final body = jsonDecode(vehRes.data);
        if (body is Map && body['Data'] is List && (body['Data'] as List).isNotEmpty) {
          vehiclesList = (body['Data'] as List).map<Map<String, String>>((e) => {
            'id': e['_id'].toString(),
            'name': e['name'].toString(),
          }).toList();
          update();
        }
      }
    } catch (e) {
      print('Error fetching register vehicle-types: $e');
    }
  }




  // Submit registration
  Future<void> submitRegistration() async {
    if (!registerKey.currentState!.validate()) return;

    if (driverPhotoPath == null) {
      Utility.showMessage("Driver image is required", MessageType.error, null, "OK");
      return;
    }
    if (dlPhotoPath == null) {
      Utility.showMessage("Driving license image is required", MessageType.error, null, "OK");
      return;
    }
    if (selectedLanguageIds.isEmpty) {
      Utility.showMessage("Please select at least one language", MessageType.error, null, "OK");
      return;
    }
    if (selectedVehicleIds.isEmpty) {
      Utility.showMessage("Please select at least one vehicle type", MessageType.error, null, "OK");
      return;
    }

    isRegistering = true;
    update();

    final Map<String, String> fields = {
      'driver_name': registerNameController.text.trim(),
      'driver_mobile': registerMobileController.text.trim(),
      'dob': registerDobController.text.trim(),
      'DL_number': registerDlNumberController.text.trim(),
      'DL_issue_date': registerDlIssueController.text.trim(),
      'DL_expiry_date': registerDlExpiryController.text.trim(),
      'state': selectedRegisterState,
      'city': selectedRegisterCity,
      'address': registerAddressController.text.trim(),
      'language_known': jsonEncode(selectedLanguageIds),
      'vehicales_drive': jsonEncode(selectedVehicleIds),
    };

    final res = await authPresenter.registerDriver(
      fields: fields,
      driverPhotoPath: driverPhotoPath!,
      dlPhotoPath: dlPhotoPath!,
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
      Utility.showMessage('Registered successfully! Waiting for Admin approval.', MessageType.success, null, "OK");
      Get.back(); // Go back to login screen
    }
  }
}
