// lib/app/pages/Trip_screen/trip_controller.dart
import 'dart:async';
import 'package:bam_bam_driver/app/pages/Trip_screen/Screen/payment_qr_screen.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bam_bam_driver/app/navigators/routes_management.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_page.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_presenter.dart';
import 'package:bam_bam_driver/app/utils/utility.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:bam_bam_driver/domain/repositories/local_storage_keys.dart';
import 'package:bam_bam_driver/domain/repositories/repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:bam_bam_driver/domain/services/audio_service.dart';

class TripController extends GetxController {
  TripController(this.tripPresenter);

  final TripPresenter tripPresenter;

  // Razorpay key
  static const String razorPayKey = "rzp_test_RraS8FmwVpkMfC";

  String loginType = 'individual';
  bool get isIndividual => loginType == 'individual';
  bool get isCompany => loginType == 'company';

  // Razorpay instance
  late Razorpay _razorpay;

  @override
  void onInit() {
    super.onInit();
    final repo = Get.find<Repository>();
    final storedLoginType = repo.getStringValue(LocalKeys.loginType);
    loginType = storedLoginType.isNotEmpty ? storedLoginType : 'individual';

    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void onClose() {
    _waitTimer?.cancel();
    AudioService.stopRingtone();
    _razorpay.clear();
    super.onClose();
  }

  TextEditingController fromDateController = TextEditingController();
  TextEditingController kMController = TextEditingController();
  String code = "";
  GlobalKey<FormState> otpKey = GlobalKey<FormState>();
  GlobalKey<FormState> stratTripKey = GlobalKey<FormState>();
  bool isPerformingTripAction = false;
  File? vehicleMeterImage;

  Future<void> capturePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      vehicleMeterImage = File(photo.path);
      update();
    }
  }

  List<Map<String, dynamic>> assignedTrips = [];
  List<Map<String, dynamic>> rideRequests = [];
  Map<String, dynamic>? selectedTripDetail;

  bool isLoadingTrips = false;
  bool isLoadingRequests = false;
  bool isLoadingTripDetail = false;

  Map<String, dynamic>? tripDetails;
  bool isLoadingDetails = false;

  // OTP related fields
  String latestOtp = '';
  String latestVendorRequestId = '';
  String latestTravelerMobile = '';
  // ---- History state ----
  bool isLoadingHistory = false;
  bool isLoadingHistoryDetail = false;
  int historyTotal = 0;
  Map<String, dynamic>? historyFiltersApplied;
  List<Map<String, dynamic>> historyTrips = [];

  /// Default date range helpers (you can adjust defaults)
  String? selectedHistoryDateApi() {
    if (fromDateController.text.isEmpty) return null;

    try {
      final parsed = DateFormat('dd-MM-yyyy').parse(fromDateController.text);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return null;
    }
  }

  /// Fetch trip history list (POST)
  Future<void> fetchTripHistory({String status = 'Completed'}) async {
    isLoadingHistory = true;
    update();

    final date = selectedHistoryDateApi();

    final res = await tripPresenter.getTripHistory(status: status, date: date);
    isLoadingHistory = false;

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to load history',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(
          'Failed to load history',
          MessageType.error,
          null,
          'OK',
        );
      }
      update();
      return;
    }

    try {
      final body = jsonDecode(res.data);
      log(res.data);
      if (body['IsSuccess'] == true && body['Data'] is Map) {
        final data = body['Data'];
        historyTotal = data['total'] ?? 0;
        historyFiltersApplied = Map<String, dynamic>.from(
          data['filters_applied'] ?? {},
        );
        final list = data['data'] ?? [];
        historyTrips = List<Map<String, dynamic>>.from(
          list.map<Map<String, dynamic>>((x) => Map<String, dynamic>.from(x)),
        );
      } else {
        Utility.showMessage(
          body['Message'] ?? 'No history found',
          MessageType.information,
          null,
          'OK',
        );
        historyTrips = [];
        historyTotal = 0;
      }
    } catch (e) {
      Utility.showMessage(
        'Error parsing history: $e',
        MessageType.error,
        null,
        'OK',
      );
      historyTrips = [];
      historyTotal = 0;
    }

    update();
  }

  /// Fetch single history/trip detail and populate tripDetails (for Completed Trip view)
  Future<void> fetchHistoryDetail(String tripId) async {
    isLoadingHistoryDetail = true;
    tripDetails = null;
    update();

    final res = await tripPresenter.getHistoryDetail(tripId: tripId);

    isLoadingHistoryDetail = false;
    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        log(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to fetch history detail',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(
          'Failed to fetch history detail',
          MessageType.error,
          null,
          'OK',
        );
      }
      update();
      return;
    }

    try {
      final body = jsonDecode(res.data);
      if (body['IsSuccess'] == true && body['Data'] is Map) {
        tripDetails = Map<String, dynamic>.from(body['Data']);
      } else {
        Utility.showMessage(
          body['Message'] ?? 'Invalid history detail',
          MessageType.error,
          null,
          'OK',
        );
      }
    } catch (e) {
      Utility.showMessage(
        'Error parsing history detail: $e',
        MessageType.error,
        null,
        'OK',
      );
    }

    update();
  }

  /// Fetch assigned trips - unchanged (already implemented)
  Future<void> fetchAssignedTrips() async {
    log('===== fetchAssignedTrips() CALLED =====');
    log('loginType: $loginType');
    isLoadingTrips = true;
    update();



    final res = await tripPresenter.getAssignedTripList();
    isLoadingTrips = false;

    log('fetchAssignedTrips - hasError: ${res.hasError}');
    log('fetchAssignedTrips - raw response: ${res.data}');

    if (res.hasError) {
      log('fetchAssignedTrips - ERROR: request failed');
      assignedTrips = [];
    } else {
      try {
        final body = jsonDecode(res.data);
        log('fetchAssignedTrips - IsSuccess: ${body['IsSuccess']}');
        log('fetchAssignedTrips - Data type: ${body['Data']?.runtimeType}');
        if (body['IsSuccess'] == true && body['Data'] is List) {
          assignedTrips = List<Map<String, dynamic>>.from(body['Data']);
          log(
            'fetchAssignedTrips - assignedTrips count: ${assignedTrips.length}',
          );
          for (var i = 0; i < assignedTrips.length; i++) {
            log('fetchAssignedTrips - trip[$i]: ${assignedTrips[i]}');
          }
        } else {
          log('fetchAssignedTrips - Data is not a List or IsSuccess != true');
          assignedTrips = [];
        }
      } catch (e) {
        log('fetchAssignedTrips - PARSE ERROR: $e');
        assignedTrips = [];
      }
    }

    // Also fetch pending ride requests
    log('fetchAssignedTrips - now calling fetchRideRequests()...');
    await fetchRideRequests();

    log(
      'fetchAssignedTrips - FINAL assignedTrips: ${assignedTrips.length}, rideRequests: ${rideRequests.length}',
    );
    log('===== fetchAssignedTrips() DONE =====');

    update();
  }

  /// Fetch pending ride requests
  Future<void> fetchRideRequests() async {
    isLoadingRequests = true;
    update();

    final res = await tripPresenter.getRideRequestList();
    isLoadingRequests = false;

    if (res.hasError) {
      rideRequests = [];
    } else {
      try {
        final body = jsonDecode(res.data);
        if (body['IsSuccess'] == true && body['Data'] is List) {
          final rawList = List<Map<String, dynamic>>.from(body['Data']);
          final seenBookingIds = <String>{};
          final uniqueList = <Map<String, dynamic>>[];

          for (final item in rawList) {
            final booking = item['booking_details'] is Map
                ? item['booking_details'] as Map<String, dynamic>
                : (item['booking'] is Map
                    ? item['booking'] as Map<String, dynamic>
                    : item);
            final bId = (booking['booking_id'] ??
                    booking['_id'] ??
                    item['request_id'] ??
                    item['_id'] ??
                    '')
                .toString();

            if (bId.isNotEmpty && !seenBookingIds.contains(bId)) {
              seenBookingIds.add(bId);
              uniqueList.add(item);
            } else if (bId.isEmpty) {
              uniqueList.add(item);
            }
          }

          rideRequests = uniqueList;
        } else {
          rideRequests = [];
        }
      } catch (_) {
        rideRequests = [];
      }
    }
    update();
  }

  /// Accept a ride request
  Future<void> acceptRideRequest(String requestId) async {
    AudioService.stopRingtone();
    Utility.showLoader();
    final res = await tripPresenter.acceptRideRequest(requestId);
    Utility.closeLoader();

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to accept ride',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(
          'Failed to accept ride',
          MessageType.error,
          null,
          'OK',
        );
      }
    } else {
      Utility.showMessage(
        'Ride accepted successfully',
        MessageType.success,
        null,
        'OK',
      );

      try {
        final body = jsonDecode(res.data);
        final data = body['Data'];
        final String? bookingId = data is Map<String, dynamic>
            ? (data['booking']?['_id']?.toString() ??
                  data['_id']?.toString() ??
                  data['booking_id']?.toString())
            : null;

        // Refresh lists in background
        await fetchAssignedTrips();

        if (bookingId != null && bookingId.isNotEmpty) {
          if (loginType == 'individual') {
            // For individual drivers, navigate to trip details
            RouteManagement.gotoTripDetilesScreen(
              isComplectTrip: false,
              tripId: bookingId,
            );
          } else {
            // Auto-navigate to tracking screen (start trip page)
            RouteManagement.gotoTriptrackingScreen(
              isStartTrip: true,
              tripId: bookingId,
            );
          }
        }
      } catch (e) {
        log("Error navigating after acceptance: $e");
        await fetchAssignedTrips();
      }
    }

    update();
  }

  /// Reject a ride request
  Future<void> rejectRideRequest(String requestId) async {
    AudioService.stopRingtone();
    Utility.showLoader();
    final res = await tripPresenter.rejectRideRequest(requestId);
    Utility.closeLoader();

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to reject ride',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(
          'Failed to reject ride',
          MessageType.error,
          null,
          'OK',
        );
      }
    } else {
      Utility.showMessage('Ride rejected', MessageType.information, null, 'OK');
      // Refresh list
      await fetchRideRequests();
    }
    update();
  }

  /// Fetch trip details by trip_id
  Future<void> fetchTripDetails(String tripId) async {
    isLoadingDetails = true;
    tripDetails = null;
    update();

    final res = await tripPresenter.getTripDetails(tripId);

    isLoadingDetails = false;
    if (res.hasError) {
      Utility.showMessage(
        "Failed to fetch trip details",
        MessageType.error,
        null,
        "OK",
      );
      update();
      return;
    }

    try {
      final body = jsonDecode(res.data);
      if (body['IsSuccess'] == true && body['Data'] is Map) {
        tripDetails = Map<String, dynamic>.from(body['Data']);
        log("trip detailsSS: ${res.data}");
        // keep vendor_request_id if present in response (the root _id is the trip id)
        final rootId = tripDetails?['_id']?.toString() ?? '';

        if (rootId.isNotEmpty) latestVendorRequestId = rootId;

        if (tripDetails?['ride_status'] == 'Driver Arrived') {
          // Only start timer if not already running (to avoid resetting elapsed time)
          if (_waitTimer == null || !_waitTimer!.isActive) {
            startWaitingTimer();
          }
        } else {
          stopWaitingTimer();
        }
      } else {
        Utility.showMessage(
          body['Message'] ?? "Invalid response",
          MessageType.error,
          null,
          "OK",
        );
      }
    } catch (e) {
      Utility.showMessage(
        "Error parsing details: $e",
        MessageType.error,
        null,
        "OK",
      );
    }

    update();
  }

  var otpp = "";

  /// Verify pickup OTP
  Future<void> verifyPickupOtp({required String otp}) async {
    otpp = otp;
    // vendorRequestId & mobile should already be set when generatePickupOtp was called.
    final vendorId = tripDetails?["booking_id"]['_id']?.toString() ?? '';

    if (vendorId.isEmpty) {
      Utility.showMessage(
        'Missing vendor request or phone',
        MessageType.error,
        null,
        'OK',
      );
      return;
    }

    final res = await tripPresenter.verifyPickupOtp(
      vendorRequestId: vendorId,
      otp: otp,
    );

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(
          body['Message'] ?? 'OTP verification failed',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(
          'OTP verification failed',
          MessageType.error,
          null,
          'OK',
        );
      }
      return;
    }

    try {
      final body = jsonDecode(res.data);
      if (body['IsSuccess'] == true) {
        Utility.showMessage(
          body['Message'] ?? 'OTP verified',
          MessageType.success,
          null,
          'OK',
        );
        // on success, go to vehicle meter screen to capture km/photo and call start-trip
        RouteManagement.gotoVehicalMiterScreen(isStartTrip: true);
      } else {
        Utility.showMessage(
          body['Message'] ?? 'OTP verification failed',
          MessageType.error,
          null,
          'OK',
        );
      }
    } catch (e) {
      Utility.showMessage(
        'Error parsing verify response',
        MessageType.error,
        null,
        'OK',
      );
    }

    update();
  }

  /// Start trip - call startTrip API with multipart (start_km_photo)
  Future<void> startTrip({
    required String vendorRequestId,
    required String startKm,
    required double lat,
    required double lon,
  }) async {
    String? photoPath = vehicleMeterImage?.path;

    final res = await tripPresenter.startTrip(
      vendorRequestId: vendorRequestId,
      startKm: startKm,
      lat: lat,
      lon: lon,
      startKmPhotoPath: photoPath,
      otp: otpp,
    );
    log("start trip response: ${res.data}");
    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        log(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to start trip',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        log(res.data);
        Utility.showMessage(
          'Failed to start trip',
          MessageType.error,
          null,
          'OK',
        );
      }
      return;
    }

    try {
      final body = jsonDecode(res.data);
      if (body['IsSuccess'] == true) {
        Utility.showMessage(
          body['Message'] ?? 'Trip started',
          MessageType.success,
          null,
          'OK',
        );

        // update tripDetails if available
        if (body['Data'] is Map) {
          tripDetails = Map<String, dynamic>.from(body['Data']);
          // ensure we have vendor id if returned
          final rootId = tripDetails?['_id']?.toString() ?? '';
          if (rootId.isNotEmpty) latestVendorRequestId = rootId;
        }

        // navigate to tracking screen (pass trip id if you want)
        RouteManagement.gotoTriptrackingScreen(isStartTrip: true);
      } else {
        Utility.showMessage(
          body['Message'] ?? 'Failed to start trip',
          MessageType.error,
          null,
          'OK',
        );
      }
    } catch (e) {
      Utility.showMessage(
        'Error parsing start trip',
        MessageType.error,
        null,
        'OK',
      );
    }

    update();
  }

  /// End trip - call endTrip API with multipart (end_km_photo)
  Future<void> endTrip({
    required String vendorRequestId,
    required String endKm,
    required double lat,
    required double lon,
  }) async {
    String? photoPath = vehicleMeterImage?.path;

    final res = await tripPresenter.endTrip(
      vendorRequestId: vendorRequestId,
      endKm: endKm,
      lat: lat,
      lon: lon,
      endKmPhotoPath: photoPath,
    );
    log("end trip response: ${res.data}");
    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to end trip',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(
          'Failed to end trip',
          MessageType.error,
          null,
          'OK',
        );
      }
      return;
    }

    try {
      final body = jsonDecode(res.data);
      if (body['IsSuccess'] == true) {
        Utility.showMessage(
          body['Message'] ?? 'Trip ended',
          MessageType.success,
          null,
          'OK',
        );

        // update tripDetails if present
        if (body['Data'] is Map) {
          tripDetails = Map<String, dynamic>.from(body['Data']);
        }

        // Navigate to complete trip screen
        RouteManagement.gotoComplectTripScreen();
      } else {
        Utility.showMessage(
          body['Message'] ?? 'Failed to end trip',
          MessageType.error,
          null,
          'OK',
        );
      }
    } catch (e) {
      Utility.showMessage(
        'Error parsing end trip',
        MessageType.error,
        null,
        'OK',
      );
    }

    update();
  }

  /// Fetch the current ongoing trip (for driver) and populate tripDetails
  Future<void> fetchOngoingTrip() async {
    isLoadingDetails = true;
    tripDetails = null;
    update();

    final res = await tripPresenter.getOngoingTrip();
    isLoadingDetails = false;

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to fetch ongoing trip',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(
          'Failed to fetch ongoing trip',
          MessageType.error,
          null,
          'OK',
        );
      }
      update();
      return;
    }

    try {
      final body = jsonDecode(res.data);
      if (body['IsSuccess'] == true && body['Data'] is Map) {
        tripDetails = Map<String, dynamic>.from(body['Data']);
      } else if (body['IsSuccess'] == true &&
          body['Data'] is List &&
          body['Data'].isNotEmpty) {
        // some APIs return Data as a list with single item — handle gracefully
        tripDetails = Map<String, dynamic>.from(body['Data'][0]);
      } else {
        // no ongoing trip
        tripDetails = null;
        // you can show message if desired
        // Utility.showMessage(body['Message'] ?? 'No ongoing trip', MessageType.information, null, 'OK');
      }

      if (tripDetails?['ride_status'] == 'Driver Arrived') {
        startWaitingTimer();
      } else {
        stopWaitingTimer();
      }
    } catch (e) {
      Utility.showMessage(
        'Error parsing ongoing trip: $e',
        MessageType.error,
        null,
        'OK',
      );
    }

    update();
  }

  /// Collect Online Payment using Razorpay
    /// Collect Online Payment - navigates to UPI QR Screen
  Future<void> collectOnlinePayment() async {
    if (tripDetails == null) {
      Utility.showMessage(
        'Trip details not available',
        MessageType.error,
        null,
        'OK',
      );
      return;
    }
    Get.to(() => const PaymentQrScreen());
  }

  Future<void> collectCashPayment() async {
    if (tripDetails == null) {
      Utility.showMessage(
        'Trip details not available',
        MessageType.error,
        null,
        'OK',
      );
      return;
    }

    final vendorRequestId =
        tripDetails!['vendor_request_id']?.toString() ??
        tripDetails!['_id']?.toString();

    if (vendorRequestId == null || vendorRequestId.isEmpty) {
      Utility.showMessage(
        'Vendor request ID not found',
        MessageType.error,
        null,
        'OK',
      );
      return;
    }

    Utility.showLoader();
    final res = await tripPresenter.collectCashPayment(
      vendorRequestId: vendorRequestId,
    );
    Utility.closeLoader();

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to collect cash payment',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(
          'Failed to collect cash payment',
          MessageType.error,
          null,
          'OK',
        );
      }
    } else {
      try {
        final body = jsonDecode(res.data);
        if (body['IsSuccess'] == true) {
          Utility.showMessage(
            body['Message'] ?? 'Cash payment collected successfully',
            MessageType.success,
            null,
            'OK',
          );
          // Navigate to home screen
          RouteManagement.gotoHomeScreen();
        } else {
          Utility.showMessage(
            body['Message'] ?? 'Cash payment collection failed',
            MessageType.error,
            null,
            'OK',
          );
        }
      } catch (e) {
        Utility.showMessage(
          'Error processing cash payment response',
          MessageType.error,
          null,
          'OK',
        );
      }
    }
  }

  /// Handle Razorpay payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId ?? '';
    if (paymentId.isEmpty) {
      Utility.showMessage(
        'Payment ID not received',
        MessageType.error,
        null,
        'OK',
      );
      return;
    }

    final vendorRequestId =
        tripDetails!['vendor_request_id']?.toString() ??
        tripDetails!['_id']?.toString() ??
        '';

    // Call the collect payment API
    final res = await tripPresenter.collectPayment(
      vendorRequestId: vendorRequestId,
      paymentMode: 'Razorpay',
      paymentUid: paymentId,
    );

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to collect payment',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(
          'Failed to collect payment',
          MessageType.error,
          null,
          'OK',
        );
      }
    } else {
      try {
        final body = jsonDecode(res.data);
        if (body['IsSuccess'] == true) {
          Utility.showMessage(
            body['Message'] ?? 'Payment collected successfully',
            MessageType.success,
            null,
            'OK',
          );
          // Navigate to home screen
          RouteManagement.gotoHomeScreen();
        } else {
          Utility.showMessage(
            body['Message'] ?? 'Payment collection failed',
            MessageType.error,
            null,
            'OK',
          );
        }
      } catch (e) {
        Utility.showMessage(
          'Error processing payment response',
          MessageType.error,
          null,
          'OK',
        );
      }
    }
  }

  /// Handle Razorpay payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    Utility.showMessage(
      'Payment failed: ${response.message ?? 'Unknown error'}',
      MessageType.error,
      null,
      'OK',
    );
  }

  /// Handle Razorpay external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    Utility.showMessage(
      'External wallet selected: ${response.walletName}',
      MessageType.information,
      null,
      'OK',
    );
  }

  List<dynamic> cancellationReasons = [];
  bool isLoadingReasons = false;

  Future<void> fetchCancellationReasons() async {
    isLoadingReasons = true;
    update();

    final res = await tripPresenter.getCancellationReasons();
    isLoadingReasons = false;

    if (res.hasError) {
      log("Error fetching cancellation reasons: ${res.data}");
      update();
      return;
    }

    try {
      final body = jsonDecode(res.data);
      if (body['IsSuccess'] == true && body['Data'] is List) {
        cancellationReasons = List<dynamic>.from(body['Data']);
      }
    } catch (e) {
      log("Error parsing cancellation reasons: $e");
    }
    update();
  }

  Future<bool> cancelTrip({
    required String vendorRequestId,
    required String cancellationReasonId,
    required String description,
  }) async {
    Utility.showLoader();
    final res = await tripPresenter.cancelTrip(
      vendorRequestId: vendorRequestId,
      cancellationReasonId: cancellationReasonId,
      description: description,
    );
    Utility.closeLoader();

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to cancel trip',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(
          'Failed to cancel trip',
          MessageType.error,
          null,
          'OK',
        );
      }
      return false;
    }

    try {
      final body = jsonDecode(res.data);
      if (body['IsSuccess'] == true) {
        Utility.showMessage(
          body['Message'] ?? 'Trip cancelled successfully',
          MessageType.success,
          null,
          'OK',
        );
        return true;
      } else {
        Utility.showMessage(
          body['Message'] ?? 'Failed to cancel trip',
          MessageType.error,
          null,
          'OK',
        );
        return false;
      }
    } catch (e) {
      Utility.showMessage(
        'Error parsing response',
        MessageType.error,
        null,
        'OK',
      );
      return false;
    }
  }

  // ---- Driver Waiting Time Timer ----
  Timer? _waitTimer;
  int elapsedSeconds = 0;
  int freeWaitingSeconds = 0;
  int chargeableSeconds = 0;
  double accumulatedWaitingCharge = 0.0;
  double waitingChargePerMinute = 0.0;

  void startWaitingTimer({
    String? overrideStartedAt,
    int? overrideFreeMins,
    double? overrideChargePerMin,
  }) {
    _waitTimer?.cancel();

    // Use override values (from direct API response) OR fall back to tripDetails
    final startedAtStr = overrideStartedAt
        ?? tripDetails?['waiting_timer_started_at']?.toString()
        ?? tripDetails?['driver_arrived_at']?.toString();

    if (startedAtStr == null || startedAtStr.isEmpty) {
      print('⚠️ startWaitingTimer: no start time found, cannot start timer');
      return;
    }

    DateTime startedAt;
    try {
      startedAt = DateTime.parse(startedAtStr).toLocal();
    } catch (e) {
      print('⚠️ startWaitingTimer: error parsing start time: $e');
      return;
    }

    final freeMins = overrideFreeMins
        ?? int.tryParse((tripDetails?['free_waiting_minutes'] ?? 0).toString())
        ?? 0;
    freeWaitingSeconds = freeMins * 60;

    final chargePerMin = overrideChargePerMin
        ?? double.tryParse((tripDetails?['charge_per_minute'] ?? tripDetails?['waiting_charge_per_minute'] ?? 0).toString())
        ?? 0.0;

    waitingChargePerMinute = chargePerMin;

    print('✅ startWaitingTimer: start=$startedAtStr freeMins=$freeMins charge/min=$chargePerMin');

    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = now.difference(startedAt);
      elapsedSeconds = diff.inSeconds;

      if (elapsedSeconds <= freeWaitingSeconds) {
        chargeableSeconds = 0;
        accumulatedWaitingCharge = 0.0;
      } else {
        chargeableSeconds = elapsedSeconds - freeWaitingSeconds;
        final chargeableMinutes = chargeableSeconds ~/ 60;
        accumulatedWaitingCharge = chargeableMinutes * chargePerMin;
      }
      update();
    });
  }

  void stopWaitingTimer() {
    _waitTimer?.cancel();
    _waitTimer = null;
    elapsedSeconds = 0;
    freeWaitingSeconds = 0;
    chargeableSeconds = 0;
    accumulatedWaitingCharge = 0.0;
    update();
  }

  Future<void> notifyDriverArrived(String vendorRequestId) async {
    isPerformingTripAction = true;
    update();

    final res = await tripPresenter.driverArrived(vendorRequestId: vendorRequestId);

    isPerformingTripAction = false;
    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to notify arrival',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(
          'Failed to notify arrival',
          MessageType.error,
          null,
          'OK',
        );
      }
      update();
      return;
    }

    try {
      final body = jsonDecode(res.data);
      if (body['IsSuccess'] == true) {
        Utility.showMessage(
          body['Message'] ?? 'Arrival notified successfully',
          MessageType.success,
          null,
          'OK',
        );

        // ✅ Immediately start timer using response data (do NOT wait for fetchTripDetails)
        final data = body['Data'] as Map<String, dynamic>? ?? {};
        final arrivedAt = data['waiting_timer_started_at']?.toString()
            ?? data['driver_arrived_at']?.toString();
        final freeMins = int.tryParse((data['free_waiting_minutes'] ?? 0).toString()) ?? 0;
        final chargePerMin = double.tryParse((data['charge_per_minute'] ?? 0).toString()) ?? 0.0;

        if (arrivedAt != null && arrivedAt.isNotEmpty) {
          startWaitingTimer(
            overrideStartedAt: arrivedAt,
            overrideFreeMins: freeMins,
            overrideChargePerMin: chargePerMin,
          );
        }

        // Also refresh screen details in background
        fetchTripDetails(vendorRequestId);
      } else {
        Utility.showMessage(
          body['Message'] ?? 'Failed to notify arrival',
          MessageType.error,
          null,
          'OK',
        );
      }
    } catch (e) {
      Utility.showMessage(
        'Error parsing arrival response: $e',
        MessageType.error,
        null,
        'OK',
      );
    }

    update();
  }

  /// Confirm Online Payment Received
  Future<void> confirmOnlinePaymentReceipt() async {
    if (tripDetails == null) {
      Utility.showMessage(
        'Trip details not available',
        MessageType.error,
        null,
        'OK',
      );
      return;
    }

    final vendorRequestId =
        tripDetails!['vendor_request_id']?.toString() ??
        tripDetails!['_id']?.toString();

    if (vendorRequestId == null || vendorRequestId.isEmpty) {
      Utility.showMessage(
        'Vendor request ID not found',
        MessageType.error,
        null,
        'OK',
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text("Confirm Payment"),
        content: const Text("Have you verified that the payment has been successfully received?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // close dialog
              Utility.showLoader();
              final res = await tripPresenter.collectPayment(
                vendorRequestId: vendorRequestId,
                paymentMode: 'ONLINE',
                paymentUid: 'UPI_QR_COLLECTED',
              );
              Utility.closeLoader();

              if (res.hasError) {
                try {
                  final body = jsonDecode(res.data);
                  Utility.showMessage(
                    body['Message'] ?? 'Failed to complete online payment',
                    MessageType.error,
                    null,
                    'OK',
                  );
                } catch (_) {
                  Utility.showMessage(
                    'Failed to complete online payment',
                    MessageType.error,
                    null,
                    'OK',
                  );
                }
              } else {
                try {
                  final body = jsonDecode(res.data);
                  if (body['IsSuccess'] == true) {
                    Utility.showMessage(
                      'Payment received successfully.',
                      MessageType.success,
                      null,
                      'OK',
                    );
                    RouteManagement.gotoHomeScreen();
                  } else {
                    Utility.showMessage(
                      body['Message'] ?? 'Failed to complete online payment',
                      MessageType.error,
                      null,
                      'OK',
                    );
                  }
                } catch (e) {
                  Utility.showMessage(
                    'Error processing payment response',
                    MessageType.error,
                    null,
                    'OK',
                  );
                }
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

}