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

   /// Register new driver publicly using multipart/form-data
  Future<ResponseModel> registerDriver({
    required Map<String, String> fields,
    required String driverPhotoPath,
    required String dlPhotoPath,
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

      print('📤 REGISTER REQUEST FIELDS: $fields');
      print('📸 Driver photo path: $driverPhotoPath');
      print('📸 DL photo path: $dlPhotoPath');

      // add files
      final driverPhotoMime = _getMediaType(driverPhotoPath);
      final dlPhotoMime = _getMediaType(dlPhotoPath);

      print('📸 Driver photo resolved content-type: ${driverPhotoMime.toString()}');
      print('📸 DL photo resolved content-type: ${dlPhotoMime.toString()}');

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
}


