
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as media_type;

class HomeUsecases {
  final Repository repository;
  HomeUsecases(this.repository);
  /// Calls POST /driver/application/fine/add (multipart form-data)
  Future<ResponseModel> addFine({
    required String bookingId,
    required String penaltyAmount,
    required String penaltyDescription,
    required String vehicleNo,
    File? penaltyPhoto,
    bool showLoader = true,
  }) async {
    final api = ApiWrapper();
    final headers = Utility.commonHeader(isDefaultAuthorizationKeyAdd: true, forMultipart: true);

    try {
      // Prepare multipart request
      final uri = Uri.parse('${ApiWrapper.baseUrl}application/fine/add');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(headers);

      // Add text fields
      request.fields['booking_id'] = bookingId;
      request.fields['penalty_amount'] = penaltyAmount;
      request.fields['penalty_description'] = penaltyDescription;
      request.fields['vehicle_no'] = vehicleNo;

      // Add image file if provided
      if (penaltyPhoto != null && await penaltyPhoto.exists()) {
        final extension = penaltyPhoto.path.split('.').last.toLowerCase();
        final subtype = (extension == 'png') ? 'png' : (extension == 'webp') ? 'webp' : 'jpeg';
        request.files.add(await http.MultipartFile.fromPath(
          'penalty_photo',
          penaltyPhoto.path,
          contentType: media_type.MediaType('image', subtype),
        ));
      }

      // Send the request
      final streamedResponse = await ApiWrapper.client.send(request);
      final responseString = await streamedResponse.stream.bytesToString();

      return ResponseModel(
        data: responseString,
        hasError: streamedResponse.statusCode < 200 ||
            streamedResponse.statusCode >= 300,
        statusCode: streamedResponse.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        data: '{"Message": "Error submitting fine: $e"}',
        hasError: true,
        statusCode: 500,
      );
    }
  }
  /// Calls GET /driver/application/dashboard
  Future<ResponseModel> getDashboard({bool showLoader = true}) async {
    // Build headers (Authorization if token present)
    final headers = Utility.commonHeader(isDefaultAuthorizationKeyAdd: true);

    // ApiWrapper instance (your existing API wrapper)
    final api = ApiWrapper();

    // Use Request.get (same enum/usage as in your ApiWrapper.makeRequest)
    final res = await api.makeRequest(
      'application/dashboard',
      Request.get,
      null,
      showLoader,
      headers, isTokenRequired: true,
    );

    return res;
  }

   /// POST -> application/get-all-fine-list
  Future<ResponseModel> getAllFines({
    String status = '',
    String startDate = '',
    String endDate = '',
  }) async {
    final uri = Uri.parse('${ApiWrapper.baseUrl}application/get-all-fine-list');
    final body = jsonEncode({
      if (status.isNotEmpty) 'status': status,
      if (startDate.isNotEmpty) 'start_date': startDate,
      if (endDate.isNotEmpty) 'end_date': endDate,
    });

    try {
      final response = await ApiWrapper.client
          .post(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true), body: body)
          .timeout(const Duration(seconds: 60));

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      return ResponseModel(data: '{"message":"Timeout"}', hasError: true);
    } catch (e) {
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// POST -> application/fine/view
  Future<ResponseModel> getFineDetails({required String fineId}) async {
    final uri = Uri.parse('${ApiWrapper.baseUrl}application/fine/view');
    final body = jsonEncode({"fine_id": fineId});

    try {
      final response = await ApiWrapper.client
          .post(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true), body: body)
          .timeout(const Duration(seconds: 60));

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      return ResponseModel(data: '{"message":"Timeout"}', hasError: true);
    } catch (e) {
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// POST -> /update-online-status
  Future<ResponseModel> updateOnlineStatus({
    bool? isOnline,
    bool? leaveStatus,
    String? leaveRemark,
  }) async {
    final uri = Uri.parse('${ApiWrapper.baseUrl}update-online-status');
    final Map<String, dynamic> bodyMap = {};
    if (isOnline != null) bodyMap["is_online"] = isOnline;
    if (leaveStatus != null) bodyMap["leave_status"] = leaveStatus;
    if (leaveRemark != null) bodyMap["leave_remark"] = leaveRemark;

    final body = jsonEncode(bodyMap);

    try {
      final response = await ApiWrapper.client
          .post(uri,
              headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
              body: body)
          .timeout(const Duration(seconds: 60));

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      return ResponseModel(data: '{"message":"Timeout"}', hasError: true);
    } catch (e) {
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }
}
