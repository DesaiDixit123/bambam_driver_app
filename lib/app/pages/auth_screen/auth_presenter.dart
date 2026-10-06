import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as media_type;

import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/data/data.dart';
import 'package:bam_bam_driver/domain/domain.dart';

// adjust path if different


class AuthPresenter {
  AuthPresenter(this.authUsecases);

  final AuthUsecases authUsecases;

  media_type.MediaType _getMediaType(String filePath) {
    final pathLower = filePath.toLowerCase();
    if (pathLower.endsWith('.png')) {
      return media_type.MediaType('image', 'png');
    } else if (pathLower.endsWith('.pdf')) {
      return media_type.MediaType('application', 'pdf');
    } else if (pathLower.endsWith('.webp')) {
      return media_type.MediaType('image', 'webp');
    } else {
      // Default to image/jpeg since picked images are almost always jpeg
      return media_type.MediaType('image', 'jpeg');
    }
  }

  /// GET rent agreement document for rented vehicles
  Future<ResponseModel> getRentAgreement() async {
    final uri = Uri.parse('${ApiWrapper.baseUrl}rent-agreement?_t=${DateTime.now().millisecondsSinceEpoch}');
    try {
      final response = await ApiWrapper.client
          .get(uri, headers: {
            ...Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          })
          .timeout(const Duration(seconds: 30));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(data: '{"message":"Something went wrong"}', hasError: true);
    }
  }

  /// Send OTP to phone (login)
  Future<ResponseModel> sendOtp({
    required String phoneNo,
    required String loginType,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data:
            '{"message":"No internet, please enable mobile data or wi-fi in your phone settings and try again"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}send-otp');

    if (showLoader) {
      if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      Utility.showLoader();
    }

    try {
      final body = jsonEncode({
        'driver_mobile': phoneNo,
        'login_type': loginType,
      });

      final response = await ApiWrapper.client
          .post(
            uri,
            body: body,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
          )
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();

      log(
        'URL :- $uri\nBody :- $body\nStatus :- ${response.statusCode}\nResponse :- ${response.body}',
      );

      print('--- SEND OTP API RESPONSE ---');
      print('URL: $uri');
      print('Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('-----------------------------');

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"Request timed out"}',
        hasError: true,
      );
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"Something went wrong","error":"${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Verify OTP and login driver
  Future<ResponseModel> verifyOtp({
    required String phoneNo,
    required String otp,
    required String loginType,
    String? fcmToken,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data:
            '{"message":"No internet, please enable mobile data or wi-fi in your phone settings and try again"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}verify-otp');

    if (showLoader) {
      if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      Utility.showLoader();
    }

    try {
      final body = jsonEncode({
        'driver_mobile': phoneNo,
        'otp': otp,
        'login_type': loginType,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      });

      final response = await ApiWrapper.client
          .post(
            uri,
            body: body,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
          )
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();

      log(
        'URL :- $uri\nBody :- $body\nStatus :- ${response.statusCode}\nResponse :- ${response.body}',
      );

      print('--- VERIFY OTP API RESPONSE ---');
      print('URL: $uri');
      print('Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('-------------------------------');

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"Request timed out"}',
        hasError: true,
      );
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"Something went wrong","error":"${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Quick Register individual driver (Name, Mobile, Email, Driver Photo)
  Future<ResponseModel> quickRegisterDriver({
    required String driverName,
    required String driverMobile,
    String? email,
    required String driverPhotoPath,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet, please enable mobile data or wi-fi in your settings and try again"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}quick-register');

    if (showLoader) {
      if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      Utility.showLoader();
    }

    try {
      var request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';

      request.fields['driver_name'] = driverName;
      request.fields['driver_mobile'] = driverMobile;
      if (email != null && email.trim().isNotEmpty) {
        request.fields['email'] = email.trim();
      }

      if (driverPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'driver_photo',
          driverPhotoPath,
          contentType: _getMediaType(driverPhotoPath),
        ));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      if (showLoader) Utility.closeLoader();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ResponseModel(
          data: response.body,
          hasError: false,
          statusCode: response.statusCode,
        );
      } else {
        return ResponseModel(
          data: response.body,
          hasError: true,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"Network error: $e"}',
        hasError: true,
        statusCode: 500,
      );
    }
  }

   /// Register new driver publicly using multipart/form-data
  Future<ResponseModel> registerDriver({
    required Map<String, String> fields,
    required String driverPhotoPath,
    required String dlPhotoPath,
    String? panPhotoPath,
    String? aadharPhotoPath,
    String? aadharBackPhotoPath,
    String? rcPhotoPath,
    String? passbookPhotoPath,
    String? rentedVehicleAgreementPath,
    String? insuranceDocumentPath,
    String? fitnessDocumentPath,
    String? permitDocumentPath,
    String? pucDocumentPath,
    String? vehicleFrontPhotoPath,
    String? vehicleBackPhotoPath,
    String? vehicleLeftPhotoPath,
    String? vehicleRightPhotoPath,
    String? vehicleInteriorPhotoPath,
    String? vehicleNumberPlatePhotoPath,
    String? vehicleDickyPhotoPath,
    String? vehicleCarrierPhotoPath,
    String? gstCertificatePhotoPath,
    String? visitingCardPhotoPath,
    String? addressProofDocumentPath,
    String? pccCertificatePath,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet, please enable mobile data or wi-fi in your settings and try again"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}register');

    if (showLoader) {
      if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      Utility.showLoader();
    }

    try {
      var request = http.MultipartRequest('POST', uri);

      // headers
      request.headers.addAll(Utility.commonHeader(forMultipart: true));

      // add form fields
      fields.forEach((k, v) {
        request.fields[k] = v;
      });

      // add files
      final driverPhotoMime = _getMediaType(driverPhotoPath);
      final dlPhotoMime = _getMediaType(dlPhotoPath);

      request.files.add(await http.MultipartFile.fromPath(
        'driver_photo',
        driverPhotoPath,
        contentType: driverPhotoMime,
      ));
      request.files.add(await http.MultipartFile.fromPath(
        'DL_photo',
        dlPhotoPath,
        contentType: dlPhotoMime,
      ));

      void addFileIfPresent(String field, String? path) async {
        if (path != null && path.isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath(
            field,
            path,
            contentType: _getMediaType(path),
          ));
        }
      }

      if (panPhotoPath != null && panPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'pan_photo',
          panPhotoPath,
          contentType: _getMediaType(panPhotoPath),
        ));
      }

      if (aadharPhotoPath != null && aadharPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'aadhar_photo',
          aadharPhotoPath,
          contentType: _getMediaType(aadharPhotoPath),
        ));
      }

      if (aadharBackPhotoPath != null && aadharBackPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'aadhar_back_photo',
          aadharBackPhotoPath,
          contentType: _getMediaType(aadharBackPhotoPath),
        ));
      }

      if (rcPhotoPath != null && rcPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'rc_photo',
          rcPhotoPath,
          contentType: _getMediaType(rcPhotoPath),
        ));
      }

      if (passbookPhotoPath != null && passbookPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'passbook_photo',
          passbookPhotoPath,
          contentType: _getMediaType(passbookPhotoPath),
        ));
      }

      if (rentedVehicleAgreementPath != null && rentedVehicleAgreementPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'rented_vehicle_agreement',
          rentedVehicleAgreementPath,
          contentType: _getMediaType(rentedVehicleAgreementPath),
        ));
      }

      if (insuranceDocumentPath != null && insuranceDocumentPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'insurance_document',
          insuranceDocumentPath,
          contentType: _getMediaType(insuranceDocumentPath),
        ));
      }

      if (fitnessDocumentPath != null && fitnessDocumentPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'fitness_document',
          fitnessDocumentPath,
          contentType: _getMediaType(fitnessDocumentPath),
        ));
      }

      if (permitDocumentPath != null && permitDocumentPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'permit_document',
          permitDocumentPath,
          contentType: _getMediaType(permitDocumentPath),
        ));
      }

      if (pucDocumentPath != null && pucDocumentPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'puc_document',
          pucDocumentPath,
          contentType: _getMediaType(pucDocumentPath),
        ));
      }

      if (vehicleFrontPhotoPath != null && vehicleFrontPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'vehicle_front_photo',
          vehicleFrontPhotoPath,
          contentType: _getMediaType(vehicleFrontPhotoPath),
        ));
      }

      if (vehicleBackPhotoPath != null && vehicleBackPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'vehicle_back_photo',
          vehicleBackPhotoPath,
          contentType: _getMediaType(vehicleBackPhotoPath),
        ));
      }

      if (vehicleLeftPhotoPath != null && vehicleLeftPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'vehicle_left_photo',
          vehicleLeftPhotoPath,
          contentType: _getMediaType(vehicleLeftPhotoPath),
        ));
      }

      if (vehicleRightPhotoPath != null && vehicleRightPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'vehicle_right_photo',
          vehicleRightPhotoPath,
          contentType: _getMediaType(vehicleRightPhotoPath),
        ));
      }

      if (vehicleInteriorPhotoPath != null && vehicleInteriorPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'vehicle_interior_photo',
          vehicleInteriorPhotoPath,
          contentType: _getMediaType(vehicleInteriorPhotoPath),
        ));
      }

      if (vehicleNumberPlatePhotoPath != null && vehicleNumberPlatePhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'vehicle_number_plate_photo',
          vehicleNumberPlatePhotoPath,
          contentType: _getMediaType(vehicleNumberPlatePhotoPath),
        ));
      }

      if (vehicleDickyPhotoPath != null && vehicleDickyPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'vehicle_dicky_photo',
          vehicleDickyPhotoPath,
          contentType: _getMediaType(vehicleDickyPhotoPath),
        ));
      }

      if (vehicleCarrierPhotoPath != null && vehicleCarrierPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'vehicle_carrier_photo',
          vehicleCarrierPhotoPath,
          contentType: _getMediaType(vehicleCarrierPhotoPath),
        ));
      }

      if (gstCertificatePhotoPath != null && gstCertificatePhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'gst_certificate',
          gstCertificatePhotoPath,
          contentType: _getMediaType(gstCertificatePhotoPath),
        ));
      }

      if (visitingCardPhotoPath != null && visitingCardPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'visiting_card',
          visitingCardPhotoPath,
          contentType: _getMediaType(visitingCardPhotoPath),
        ));
      }

      if (addressProofDocumentPath != null && addressProofDocumentPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'address_proof_document',
          addressProofDocumentPath,
          contentType: _getMediaType(addressProofDocumentPath),
        ));
      }

      if (pccCertificatePath != null && pccCertificatePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'pcc_certificate',
          pccCertificatePath,
          contentType: _getMediaType(pccCertificatePath),
        ));
      }

      final streamedRes = await ApiWrapper.client
          .send(request)
          .timeout(const Duration(seconds: 180));
      final responseString = await streamedRes.stream.bytesToString();

      if (showLoader) Utility.closeLoader();

      print('📥 REGISTER RESPONSE status=${streamedRes.statusCode} body=$responseString');

      log(
        'URL :- $uri\nFields :- $fields\nStatus :- ${streamedRes.statusCode}\nResponse :- $responseString',
      );

      return ResponseModel(
        data: responseString,
        hasError: streamedRes.statusCode < 200 || streamedRes.statusCode >= 300,
        statusCode: streamedRes.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"Request timed out"}',
        hasError: true,
      );
    } catch (e, stack) {
      if (showLoader) Utility.closeLoader();
      print('❌ REGISTER ERROR: $e');
      print('❌ STACK: $stack');
      // Use jsonEncode to safely handle newlines and special chars in e.toString()
      final errorData = jsonEncode({
        'message': 'Something went wrong',
        'error': e.toString(),
      });
      return ResponseModel(
        data: errorData,
        hasError: true,
      );
    }
  }

  /// Fetch all Indian states from API
  Future<ResponseModel> getStates() async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
      );
    }
    // 1. Try driver states endpoint
    try {
      final uri = Uri.parse('${ApiWrapper.baseUrl}states');
      final response = await ApiWrapper.client.get(
        uri,
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ResponseModel(
          data: response.body,
          hasError: false,
          statusCode: response.statusCode,
        );
      }
    } catch (_) {}

    // 2. Fallback to vendor common states endpoint
    try {
      final fallbackUri = Uri.parse('https://apis.bambamcabs.com/vendor/common/states/IN');
      final fallbackResponse = await ApiWrapper.client.get(
        fallbackUri,
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 8));
      return ResponseModel(
        data: fallbackResponse.body,
        hasError: fallbackResponse.statusCode < 200 || fallbackResponse.statusCode >= 300,
        statusCode: fallbackResponse.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        data: '{"message":"Error: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Fetch cities for a state from API
  Future<ResponseModel> getCities({required String stateCode}) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
      );
    }
    // 1. Try driver cities endpoint
    try {
      final uri = Uri.parse('${ApiWrapper.baseUrl}cities/$stateCode');
      final response = await ApiWrapper.client.get(
        uri,
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ResponseModel(
          data: response.body,
          hasError: false,
          statusCode: response.statusCode,
        );
      }
    } catch (_) {}

    // 2. Fallback to vendor common cities endpoint
    try {
      final fallbackUri = Uri.parse('https://apis.bambamcabs.com/vendor/common/cities/IN/$stateCode');
      final fallbackResponse = await ApiWrapper.client.get(
        fallbackUri,
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 8));
      return ResponseModel(
        data: fallbackResponse.body,
        hasError: fallbackResponse.statusCode < 200 || fallbackResponse.statusCode >= 300,
        statusCode: fallbackResponse.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        data: '{"message":"Error: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Fetch languages publicly
  Future<ResponseModel> getLanguages() async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}languages');
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({}),
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 4));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        data: '{"message":"Error: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Fetch vehicle types publicly
  Future<ResponseModel> getVehicleTypes() async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}vehicle-types');
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({}),
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 4));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        data: '{"message":"Error: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Reverse geocode GPS coordinates to address details
  Future<ResponseModel> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse('${ApiWrapper.baseUrl}reverse-geocode');
    try {
      final body = jsonEncode({
        'lat': lat,
        'lng': lng,
      });

      final response = await ApiWrapper.client
          .post(
            uri,
            body: body,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
          )
          .timeout(const Duration(seconds: 15));

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        data: '{"message":"Reverse geocoding failed: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Fetch fuel types publicly
  Future<ResponseModel> getFuelTypes() async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}fuel-types');
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({}),
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 4));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        data: '{"message":"Error: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Verify Driving License
  Future<ResponseModel> verifyDL({
    required String dlNumber,
    required String dob,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}verify/dl');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({
          'dl_number': dlNumber.trim().toUpperCase(),
          'dob': dob.trim(),
        }),
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 20));
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"DL Verification error: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Verify Vehicle RC
  Future<ResponseModel> verifyRC({
    required String vehicleNumber,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}verify/rc');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({
          'vehicle_number': vehicleNumber.trim().toUpperCase(),
        }),
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 20));
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"RC Verification error: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Verify PAN Card
  Future<ResponseModel> verifyPAN({
    required String panNumber,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}verify/pan');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({
          'pan_number': panNumber.trim().toUpperCase(),
        }),
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 20));
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"PAN Verification error: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Verify Bank Account via IFSC
  Future<ResponseModel> verifyBank({
    required String accountNumber,
    required String ifscCode,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}verify/bank');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({
          'account_number': accountNumber.trim(),
          'ifsc_code': ifscCode.trim().toUpperCase(),
        }),
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 20));
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"Bank verification error: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Request Aadhaar OTP
  Future<ResponseModel> requestAadhaarOtp({
    required String aadhaarNumber,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}verify/aadhaar-otp');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({
          'aadhaar_number': aadhaarNumber.trim(),
        }),
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 20));
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"Aadhaar OTP request error: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Verify Aadhaar OTP
  Future<ResponseModel> verifyAadhaarOtp({
    required String otp,
    required String refId,
    String? aadhaarNumber,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}verify/aadhaar-verify');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({
          'otp': otp.trim(),
          'ref_id': refId.trim(),
          'reference_id': refId.trim(),
          if (aadhaarNumber != null && aadhaarNumber.isNotEmpty)
            'aadhaar_number': aadhaarNumber.trim(),
        }),
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 20));
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"Aadhaar OTP verify error: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Verify GST Number
  Future<ResponseModel> verifyGST({
    required String gstNumber,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}verify/gst');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({
          'gst_number': gstNumber.trim().toUpperCase(),
        }),
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 20));
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"GST verification error: ${e.toString()}"}',
        hasError: true,
      );
    }
  }

  /// Check if mobile number already exists in database
  Future<ResponseModel> checkDriverMobile({
    required String mobile,
    bool showLoader = false,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet connection"}',
        hasError: true,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}check-mobile');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({
          'mobile': mobile.trim(),
        }),
        headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
      ).timeout(const Duration(seconds: 15));
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"Error verifying mobile: ${e.toString()}"}',
        hasError: true,
      );
    }
  }
}


