// lib/app/pages/Trip_screen/trip_presenter.dart
import 'dart:async';
import 'dart:convert';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:bam_bam_driver/domain/models/response_model.dart';
import 'package:bam_bam_driver/domain/usecases/trip_usecases.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as media_type;

class TripPresenter {
  TripPresenter(this.tripUsecases);
  final TripUsecases tripUsecases;

  final String baseUrl = ApiWrapper.baseUrl;

  /// Pay extra commission due after trip end (POST application/ride/pay-extra-commission)
  Future<ResponseModel> payExtraCommission({
    required String vendorRequestId,
    String? bookingId,
    String paymentMethod = 'Wallet',
    String? razorpayPaymentId,
  }) async {
    final uri = Uri.parse('${baseUrl}application/ride/pay-extra-commission');
    final body = jsonEncode({
      "vendor_request_id": vendorRequestId,
      if (bookingId != null) "booking_id": bookingId,
      "payment_method": paymentMethod,
      if (razorpayPaymentId != null && razorpayPaymentId.isNotEmpty)
        "razorpay_payment_id": razorpayPaymentId,
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

  /// Create Razorpay Order for Extra Commission (POST application/ride/extra-commission-order)
  Future<ResponseModel> createExtraCommissionOrder({
    required String vendorRequestId,
    String? bookingId,
  }) async {
    final uri = Uri.parse('${baseUrl}application/ride/extra-commission-order');
    final body = jsonEncode({
      "vendor_request_id": vendorRequestId,
      if (bookingId != null) "booking_id": bookingId,
    });
    try {
      final response = await ApiWrapper.client
          .post(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true), body: body)
          .timeout(const Duration(seconds: 30));
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

  /// Fetch Assigned Trip List (GET)
  Future<ResponseModel> getAssignedTripList() async {
    final uri = Uri.parse('${baseUrl}application/assigned/list');
    try {
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true))
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

  /// Fetch Trip Details by trip_id (POST)
  Future<ResponseModel> getTripDetails(String tripId) async {
    final uri = Uri.parse('${baseUrl}application/assigned/view');
    final body = jsonEncode({"trip_id": tripId});
    try {

      final response = await ApiWrapper.client
          .post(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true), body: body)
          .timeout(const Duration(seconds: 60));
       debugPrint('Response Body: ${response.body}');

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

  /// Start Ride towards customer (POST -> application/start-ride)
  Future<ResponseModel> startRide({required String tripId}) async {
    final uri = Uri.parse('${baseUrl}application/start-ride');
    final body = jsonEncode({"trip_id": tripId});
    try {
      final response = await ApiWrapper.client
          .post(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true), body: body)
          .timeout(const Duration(seconds: 30));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// Driver Arrived (POST -> application/driver-arrived)
  Future<ResponseModel> driverArrived({
    required String vendorRequestId,
    String? bookingId,
  }) async {
    final uri = Uri.parse('${baseUrl}application/driver-arrived');
    final body = jsonEncode({
      "vendor_request_id": vendorRequestId,
      if (bookingId != null && bookingId.isNotEmpty) "booking_id": bookingId,
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

  /// Generate OTP for pickup (POST -> application/pickup/generate/otp)
  Future<ResponseModel> generatePickupOtp({
    required String vendorRequestId,
    required String phoneNo,
  }) async {
    final uri = Uri.parse('${baseUrl}application/pickup/generate/otp');
    final body = jsonEncode({
      "vendor_request_id": vendorRequestId,
      "phone_no": phoneNo,
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

  /// Verify OTP for pickup (POST -> application/pickup/verify/otp)
  Future<ResponseModel> verifyPickupOtp({
    required String vendorRequestId,
    
    required String otp,
  }) async {
    final uri = Uri.parse('${baseUrl}application/pickup/verify/otp');
    final body = jsonEncode({
      "booking_id": vendorRequestId,
     
      "otp": otp,
    });
    print(  'Verifying OTP with body: $body'  );
    try {
      final response = await ApiWrapper.client
          .post(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true), body: body)
          .timeout(const Duration(seconds: 60));
          print(  'Response Body: ${response.body}'  );
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

  /// START trip (driver/application/start-trip) — multipart with start_km_photo
  Future<ResponseModel> startTrip({
    required String vendorRequestId,
    required String startKm,
    required double lat,
    required double lon,
    String? startKmPhotoPath,
      required String? otp,
     // local file path
  }) async {
    final uri = Uri.parse('${baseUrl}application/start-trip');
print("vendorRequestId: $vendorRequestId, startKm: $startKm, lat: $lat, lon: $lon, startKmPhotoPath: $startKmPhotoPath, otp: $otp");
    try {
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(Utility.commonHeader(isDefaultAuthorizationKeyAdd: true, forMultipart: true));

      request.fields['vendor_request_id'] = vendorRequestId;
      request.fields['start_km'] = startKm;
      request.fields['lat'] = lat.toString();
      request.fields['lon'] = lon.toString();
request.fields['otp']=otp.toString();
      if (startKmPhotoPath != null && startKmPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'start_km_photo',
          startKmPhotoPath,
          contentType: media_type.MediaType('image', _guessImageSubtype(startKmPhotoPath)),
        ));
      }

      final streamed = await ApiWrapper.client
          .send(request)
          .timeout(const Duration(seconds: 180));
      final body = await streamed.stream.bytesToString();

      return ResponseModel(
        data: body,
        hasError: streamed.statusCode < 200 || streamed.statusCode >= 300,
        statusCode: streamed.statusCode,
      );
    } on TimeoutException {
      return ResponseModel(data: '{"message":"Timeout"}', hasError: true);
    } catch (e) {
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// END trip (driver/application/end-trip) — multipart with end_km_photo and additional charges proof slips
  Future<ResponseModel> endTrip({
    required String vendorRequestId,
    required String endKm,
    required double lat,
    required double lon,
    String? endKmPhotoPath,
    String? additionalChargesDetailsJson,
    Map<String, String>? proofImagePaths,
  }) async {
    final uri = Uri.parse('${baseUrl}application/end-trip');

    try {
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(Utility.commonHeader(isDefaultAuthorizationKeyAdd: true, forMultipart: true));

      request.fields['vendor_request_id'] = vendorRequestId;
      request.fields['end_km'] = endKm;
      request.fields['lat'] = lat.toString();
      request.fields['lon'] = lon.toString();

      if (additionalChargesDetailsJson != null && additionalChargesDetailsJson.isNotEmpty) {
        request.fields['additional_charges_details'] = additionalChargesDetailsJson;
      }

      if (endKmPhotoPath != null && endKmPhotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'end_km_photo',
          endKmPhotoPath,
          contentType: media_type.MediaType('image', _guessImageSubtype(endKmPhotoPath)),
        ));
      }

      if (proofImagePaths != null && proofImagePaths.isNotEmpty) {
        for (final entry in proofImagePaths.entries) {
          if (entry.value.isNotEmpty) {
            request.files.add(await http.MultipartFile.fromPath(
              entry.key,
              entry.value,
              contentType: media_type.MediaType('image', _guessImageSubtype(entry.value)),
            ));
          }
        }
      }

      final streamed = await ApiWrapper.client
          .send(request)
          .timeout(const Duration(seconds: 180));
      final body = await streamed.stream.bytesToString();

      return ResponseModel(
        data: body,
        hasError: streamed.statusCode < 200 || streamed.statusCode >= 300,
        statusCode: streamed.statusCode,
      );
    } on TimeoutException {
      return ResponseModel(data: '{"message":"Timeout"}', hasError: true);
    } catch (e) {
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// Get active route additional charges for a route type
  Future<ResponseModel> getRouteAdditionalCharges(String routeType) async {
    // 1. Try direct driver application route
    try {
      final appUri = Uri.parse(
        '${baseUrl}application/route-additional-charges?route_type=${Uri.encodeComponent(routeType)}',
      );
      final response = await ApiWrapper.client
          .get(appUri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ResponseModel(
          data: response.body,
          hasError: false,
          statusCode: response.statusCode,
        );
      }
    } catch (_) {}

    // 2. Fallback to master route
    final rootUrl = baseUrl.replaceAll('/driver/', '/');
    final uri = Uri.parse(
      '${rootUrl}master/route-additional-charges/by-route?route_type=${Uri.encodeComponent(routeType)}',
    );
    try {
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true))
          .timeout(const Duration(seconds: 20));

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

  // utility to guess mime subtype from file extension (jpeg/png)
  static String _guessImageSubtype(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'jpeg';
    return 'jpeg';
  }


  /// Fetch current ongoing trip for driver (GET -> application/current/ongoing/view)
Future<ResponseModel> getOngoingTrip() async {
  final uri = Uri.parse('${baseUrl}application/current/ongoing/view');
  try {
    final response = await ApiWrapper.client
        .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true))
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
  /// Fetch trip history list (POST -> application/history/list)
  Future<ResponseModel> getTripHistory({
    required String status,
    String? date,
      // yyyy-MM-dd
  }) async {
    final uri = Uri.parse('${baseUrl}application/history/list');
    final body = jsonEncode({
     "status": status,
      "date": date

    });
    
    print(" Fetching trip history with body: $body" );
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

  /// Fetch single history/trip detail (POST -> application/history/view)
  Future<ResponseModel> getHistoryDetail({ required String tripId }) async {
    final uri = Uri.parse('${baseUrl}application/history/view');
    final body = jsonEncode({"trip_id": tripId});
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
  /// Fetch Pending Ride Requests (GET -> application/ride/request/list)
  Future<ResponseModel> getRideRequestList() async {
    final uri = Uri.parse('${baseUrl}application/ride/request/list');
    try {
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true))
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

  /// Accept Ride Request (POST -> application/ride/request/accept)
  Future<ResponseModel> acceptRideRequest(
    String requestId, {
    String paymentMethod = "Wallet",
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    final uri = Uri.parse('${baseUrl}application/ride/request/accept');
    final Map<String, dynamic> payload = {
      "request_id": requestId,
      "payment_method": paymentMethod,
    };
    if (razorpayPaymentId != null && razorpayPaymentId.isNotEmpty) {
      payload["razorpay_payment_id"] = razorpayPaymentId;
    }
    if (razorpayOrderId != null && razorpayOrderId.isNotEmpty) {
      payload["razorpay_order_id"] = razorpayOrderId;
    }
    if (razorpaySignature != null && razorpaySignature.isNotEmpty) {
      payload["razorpay_signature"] = razorpaySignature;
    }

    final body = jsonEncode(payload);
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

  /// Get Commission Preview for Ride Acceptance (POST -> application/ride/request/commission-preview)
  Future<ResponseModel> getCommissionPreview(String requestId) async {
    final uri = Uri.parse('${baseUrl}application/ride/request/commission-preview');
    final body = jsonEncode({"request_id": requestId});
    try {
      final response = await ApiWrapper.client
          .post(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true), body: body)
          .timeout(const Duration(seconds: 30));

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

  /// Create Razorpay Order for Commission (POST -> application/ride/request/commission-order)
  Future<ResponseModel> createCommissionOrder(String requestId) async {
    final uri = Uri.parse('${baseUrl}application/ride/request/commission-order');
    final body = jsonEncode({"request_id": requestId});
    try {
      final response = await ApiWrapper.client
          .post(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true), body: body)
          .timeout(const Duration(seconds: 30));

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

  /// Reject Ride Request (POST -> application/ride/request/reject)
  Future<ResponseModel> rejectRideRequest(String requestId) async {
    final uri = Uri.parse('${baseUrl}application/ride/request/reject');
    final body = jsonEncode({"request_id": requestId});
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

  /// Fetch Rejected Ride Requests (GET -> application/ride/request/rejected)
  Future<ResponseModel> getRejectedRideList() async {
    final uri = Uri.parse('${baseUrl}application/ride/request/rejected');
    try {
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true))
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

  /// Collect Payment (POST -> application/collect/payment)
  Future<ResponseModel> collectPayment({
    required String vendorRequestId,
    required String paymentMode,
    required String paymentUid,
  }) async {
    final uri = Uri.parse('${baseUrl}application/collect/payment');
    final body = jsonEncode({
      "vendor_request_id": vendorRequestId,
      "payment_mode": paymentMode,
      "payment_uid": paymentUid,
    });
    print('Collect Payment API Request:');
    print('URI: $uri');
    print('Headers: ${Utility.commonHeader(isDefaultAuthorizationKeyAdd: true)}');
    print('Body: $body');
    try {
      final response = await ApiWrapper.client
          .post(uri,
              headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
              body: body)
          .timeout(const Duration(seconds: 60));
      print('Collect Payment API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      print('Collect Payment API Error: Timeout');
      return ResponseModel(data: '{"message":"Timeout"}', hasError: true);
    } catch (e) {
      print('Collect Payment API Error: $e');
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// Create Online Payment Order (POST -> application/payment/create-order)
  Future<ResponseModel> createOnlinePaymentOrder({
    required String vendorRequestId,
  }) async {
    final uri = Uri.parse('${baseUrl}application/payment/create-order');
    final body = jsonEncode({
      "vendor_request_id": vendorRequestId,
    });
    print('Create Online Payment Order API Request:');
    print('URI: $uri');
    print('Headers: ${Utility.commonHeader(isDefaultAuthorizationKeyAdd: true)}');
    print('Body: $body');
    try {
      final response = await ApiWrapper.client
          .post(uri,
              headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
              body: body)
          .timeout(const Duration(seconds: 60));
      print('Create Online Payment Order API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      print('Create Online Payment Order API Error: Timeout');
      return ResponseModel(data: '{"message":"Timeout"}', hasError: true);
    } catch (e) {
      print('Create Online Payment Order API Error: $e');
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// Collect Cash Payment (POST -> application/payment/collect-cash)
  Future<ResponseModel> collectCashPayment({
    required String vendorRequestId,
  }) async {
    final uri = Uri.parse('${baseUrl}application/payment/collect-cash');
    final body = jsonEncode({
      "vendor_request_id": vendorRequestId,
    });
    print('Collect Cash Payment API Request:');
    print('URI: $uri');
    print('Headers: ${Utility.commonHeader(isDefaultAuthorizationKeyAdd: true)}');
    print('Body: $body');
    try {
      final response = await ApiWrapper.client
          .post(uri,
              headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
              body: body)
          .timeout(const Duration(seconds: 60));
      print('Collect Cash Payment API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      print('Collect Cash Payment API Error: Timeout');
      return ResponseModel(data: '{"message":"Timeout"}', hasError: true);
    } catch (e) {
      print('Collect Cash Payment API Error: $e');
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// Get cancellation reasons (POST -> application/list/cancellation-reason)
  Future<ResponseModel> getCancellationReasons() async {
    final uri = Uri.parse('${baseUrl}application/list/cancellation-reason');
    final body = jsonEncode({
      "search": "",
      "status": true
    });
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

  /// Cancel trip (POST -> application/cancel-trip)
  Future<ResponseModel> cancelTrip({
    required String vendorRequestId,
    required String cancellationReasonId,
    required String description,
  }) async {
    final uri = Uri.parse('${baseUrl}application/cancel-trip');
    final body = jsonEncode({
      "vendor_request_id": vendorRequestId,
      "cancellation_reason_id": cancellationReasonId,
      "description": description,
    });
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

