// profile_presenter.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:get/get.dart';

import 'package:http_parser/http_parser.dart' as media_type;
import 'package:http/http.dart' as http;
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/domain.dart';


class ProfilePresenter {
  ProfilePresenter(ProfileUsecases profileUsecases);

  final String baseUrl = ApiWrapper.baseUrl;

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

  /// GET driver profile
  Future<ResponseModel> getProfile() async {
    final uri = Uri.parse('${baseUrl}profile');
    try {
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true))
          .timeout(const Duration(seconds: 120));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
    } catch (e) {
      return ResponseModel(data: '{"message":"Something went wrong"}', hasError: true);
    }
  }

  /// GET rent agreement document for rented vehicles
  Future<ResponseModel> getRentAgreement() async {
    final uri = Uri.parse('${baseUrl}rent-agreement?_t=${DateTime.now().millisecondsSinceEpoch}');
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

  /// PUT update profile with multipart/form-data
  /// PUT update profile with multipart/form-data
  ///
  /// fields is a map of simple form fields (string values)
  /// filePaths is map of any file field name pointing to local file paths (optional)
  Future<ResponseModel> updateProfile({
    required Map<String, String> fields,
    Map<String, String?>? filePaths,
  }) async {
    final uri = Uri.parse('${baseUrl}update/application');

    try {
      var request = http.MultipartRequest('PUT', uri);

      // headers (include Authorization)
      request.headers.addAll(Utility.commonHeader(isDefaultAuthorizationKeyAdd: true, forMultipart: true));

      // add form fields
      fields.forEach((k, v) {
        if (v != null) request.fields[k] = v;
      });

      // add files if provided
      if (filePaths != null) {
        for (var entry in filePaths.entries) {
          if (entry.value != null && entry.value!.isNotEmpty) {
            final f = File(entry.value!);
            if (await f.exists()) {
              request.files.add(await http.MultipartFile.fromPath(
                entry.key,
                entry.value!,
                contentType: _getMediaType(entry.value!),
              ));
            }
          }
        }
      }

      final streamedRes = await ApiWrapper.client
          .send(request)
          .timeout(const Duration(seconds: 180));
      final body = await streamedRes.stream.bytesToString();

      return ResponseModel(
        data: body,
        hasError: streamedRes.statusCode < 200 || streamedRes.statusCode >= 300,
        statusCode: streamedRes.statusCode,
      );
    } on TimeoutException catch (_) {
      return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
    } catch (e) {
      return ResponseModel(data: '{"message":"Something went wrong: ${e.toString()}"}', hasError: true);
    }
  }

  /// Master data: Vehicle types
  Future<ResponseModel> getVehicleTypes() async {
    final uri = Uri.parse('${baseUrl}vehicle-types');
    try {
      final response = await ApiWrapper.client
          .post(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false))
          .timeout(const Duration(seconds: 15));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(data: '{"message":"Error: ${e.toString()}"}', hasError: true);
    }
  }

  /// Master data: Fuel types
  Future<ResponseModel> getFuelTypes() async {
    final uri = Uri.parse('${baseUrl}fuel-types');
    try {
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false))
          .timeout(const Duration(seconds: 15));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(data: '{"message":"Error: ${e.toString()}"}', hasError: true);
    }
  }

  /// Master data: Languages
  Future<ResponseModel> getLanguages() async {
    final uri = Uri.parse('${baseUrl}languages');
    try {
      final response = await ApiWrapper.client
          .post(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false))
          .timeout(const Duration(seconds: 15));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(data: '{"message":"Error: ${e.toString()}"}', hasError: true);
    }
  }

  /// Master data: States
  Future<ResponseModel> getStates() async {
    final uri = Uri.parse('${baseUrl}states');
    try {
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false))
          .timeout(const Duration(seconds: 15));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(data: '{"message":"Error: ${e.toString()}"}', hasError: true);
    }
  }

  /// Master data: Cities
  Future<ResponseModel> getCities(String stateCode) async {
    final uri = Uri.parse('${baseUrl}cities/$stateCode');
    try {
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false))
          .timeout(const Duration(seconds: 15));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(data: '{"message":"Error: ${e.toString()}"}', hasError: true);
    }
  }

  /// Verification: Driving License
  Future<ResponseModel> verifyDL({required String dlNumber, required String dob, bool showLoader = true}) async {
    final uri = Uri.parse('${baseUrl}verify/dl');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({'dl_number': dlNumber.trim().toUpperCase(), 'dob': dob.trim()}),
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
      return ResponseModel(data: '{"message":"DL verification error: ${e.toString()}"}', hasError: true);
    }
  }

  /// Verification: PAN
  Future<ResponseModel> verifyPAN({required String panNumber, bool showLoader = true}) async {
    final uri = Uri.parse('${baseUrl}verify/pan');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({'pan_number': panNumber.trim().toUpperCase()}),
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
      return ResponseModel(data: '{"message":"PAN verification error: ${e.toString()}"}', hasError: true);
    }
  }

  /// Verification: GST
  Future<ResponseModel> verifyGST({required String gstNumber, bool showLoader = true}) async {
    final uri = Uri.parse('${baseUrl}verify/gst');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({'gst_number': gstNumber.trim().toUpperCase()}),
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
      return ResponseModel(data: '{"message":"GST verification error: ${e.toString()}"}', hasError: true);
    }
  }

  /// Verification: RC
  Future<ResponseModel> verifyRC({required String vehicleNumber, bool showLoader = true}) async {
    final uri = Uri.parse('${baseUrl}verify/rc');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({'vehicle_number': vehicleNumber.trim().toUpperCase()}),
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
      return ResponseModel(data: '{"message":"RC verification error: ${e.toString()}"}', hasError: true);
    }
  }

  /// Verification: Bank Account & IFSC
  Future<ResponseModel> verifyBank({required String accountNumber, required String ifscCode, bool showLoader = true}) async {
    final uri = Uri.parse('${baseUrl}verify/bank');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({'account_number': accountNumber.trim(), 'ifsc_code': ifscCode.trim().toUpperCase()}),
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
      return ResponseModel(data: '{"message":"Bank verification error: ${e.toString()}"}', hasError: true);
    }
  }

  /// Verification: IFSC Code Only (fetches Bank Name & Branch)
  Future<ResponseModel> verifyIFSC({required String ifscCode, bool showLoader = true}) async {
    final uri = Uri.parse('${baseUrl}verify/ifsc');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({'ifsc_code': ifscCode.trim().toUpperCase()}),
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
      return ResponseModel(data: '{"message":"IFSC verification error: ${e.toString()}"}', hasError: true);
    }
  }

  /// Verification: Aadhaar OTP Request
  Future<ResponseModel> requestAadhaarOtp({required String aadhaarNumber, bool showLoader = true}) async {
    final uri = Uri.parse('${baseUrl}verify/aadhaar-otp');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({'aadhaar_number': aadhaarNumber.trim()}),
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
      return ResponseModel(data: '{"message":"Aadhaar OTP request error: ${e.toString()}"}', hasError: true);
    }
  }

  /// Verification: Aadhaar OTP Verify
  Future<ResponseModel> verifyAadhaarOtp({required String otp, required String refId, bool showLoader = true}) async {
    final uri = Uri.parse('${baseUrl}verify/aadhaar-verify');
    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client.post(
        uri,
        body: jsonEncode({'otp': otp.trim(), 'ref_id': refId.trim()}),
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
      return ResponseModel(data: '{"message":"Aadhaar verify error: ${e.toString()}"}', hasError: true);
    }
  }



  Future<ResponseModel> createTicket({
    required String issueType,
    required String description,
    required String bookingId,
    File? attachment,
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

    final uri = Uri.parse('${baseUrl}support-ticket/save');

    if (showLoader) {
      if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      Utility.showLoader();
    }

    try {
      final request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['issue_type'] = issueType;
      request.fields['description'] = description;
      request.fields['booking_id'] = bookingId;

      // Add attachment (field name 'attachment' as shown in Postman)
      if (attachment != null && await attachment.exists()) {
        final ext = attachment.path.split('.').last.toLowerCase();
        final mime = (ext == 'png') ? 'png' : (ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : 'octet-stream';
        final contentType = media_type.MediaType('image', mime);
        final multipartFile = await http.MultipartFile.fromPath(
          'attachment',
          attachment.path,
          contentType: contentType,
        );
        request.files.add(multipartFile);
      }

      // Headers (don't set Content-Type here — MultipartRequest sets boundary)
      request.headers.addAll(Utility.commonHeader(forMultipart: true));

      final streamedResponse = await ApiWrapper.client.send(request).timeout(
            const Duration(seconds: 120),
          );

      final responseString = await streamedResponse.stream.bytesToString();

      if (showLoader) Utility.closeLoader();

      log('URL :- $uri\nFields :- {issue_type, description, booking_id}\nStatusCode :- ${streamedResponse.statusCode}\nResponse :- $responseString');

      return ResponseModel(
        data: responseString,
        hasError: streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300,
        statusCode: streamedResponse.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Something went wrong","error":"${e.toString()}"}', hasError: true);
    }
  }

  /// View support ticket details (POST JSON with ticket_id)
  Future<ResponseModel> viewTicket({
    required String ticketId,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(data: '{"message":"No internet"}', hasError: true, statusCode: 1000);
    }

    final uri = Uri.parse('${baseUrl}support-ticket/view');

    if (showLoader) {
      if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      Utility.showLoader();
    }

    try {
      final body = jsonEncode({'ticket_id': ticketId});
      final response = await ApiWrapper.client
          .post(uri, body: body, headers: Utility.commonHeader())
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();

      log('URL :- $uri\nBody :- $body\nStatus :- ${response.statusCode}\nResponse :- ${response.body}');

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Something went wrong","error":"${e.toString()}"}', hasError: true);
    }
  }

  /// List tickets without pagination (POST JSON {search, status})
  Future<ResponseModel> listTicketsWithoutPagination({
    String search = '',
    String status = '',
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(data: '{"message":"No internet"}', hasError: true, statusCode: 1000);
    }

    final uri = Uri.parse('${baseUrl}support-ticket/list/without/pagination');

    if (showLoader) {
      if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      Utility.showLoader();
    }

    try {
      final body = jsonEncode({'search': search, 'status': status});
      final response = await ApiWrapper.client
          .post(uri, body: body, headers: Utility.commonHeader())
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();

      log('URL :- $uri\nBody :- $body\nStatus :- ${response.statusCode}\nResponse :- ${response.body}');

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Something went wrong","error":"${e.toString()}"}', hasError: true);
    }
  }

  /// List tickets with pagination (POST JSON {page, limit, search, status})
  Future<ResponseModel> listTicketsWithPagination({
    int page = 1,
    int limit = 10,
    String search = '',
    String status = '',
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(data: '{"message":"No internet"}', hasError: true, statusCode: 1000);
    }

    final uri = Uri.parse('${baseUrl}support-ticket/list/with/pagination');

    if (showLoader) {
      if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      Utility.showLoader();
    }

    try {
      final body = jsonEncode({'page': page, 'limit': limit, 'search': search, 'status': status});
      final response = await ApiWrapper.client
          .post(uri, body: body, headers: Utility.commonHeader())
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();

      log('URL :- $uri\nBody :- $body\nStatus :- ${response.statusCode}\nResponse :- ${response.body}');

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Something went wrong","error":"${e.toString()}"}', hasError: true);
    }
  }

  /// Delete Driver Account
  Future<ResponseModel> deleteAccount({bool showLoader = true}) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(data: '{"message":"No internet"}', hasError: true, statusCode: 1000);
    }

    final uri = Uri.parse('${baseUrl}delete-account');

    if (showLoader) {
      if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      Utility.showLoader();
    }

    try {
      final response = await ApiWrapper.client
          .post(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true))
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();

      log('URL :- $uri\nStatus :- ${response.statusCode}\nResponse :- ${response.body}');

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Something went wrong","error":"${e.toString()}"}', hasError: true);
    }
  }

  /// Reverse Geocode
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
          .post(uri, body: body, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false))
          .timeout(const Duration(seconds: 15));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(data: '{"message":"Error: ${e.toString()}"}', hasError: true);
    }
  }

}
