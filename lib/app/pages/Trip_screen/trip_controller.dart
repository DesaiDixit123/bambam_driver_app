// lib/app/pages/Trip_screen/trip_controller.dart
import 'dart:async';
import 'package:bam_bam_driver/app/pages/Trip_screen/Screen/payment_qr_screen.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bam_bam_driver/app/navigators/routes_management.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_page.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_presenter.dart';
import 'package:bam_bam_driver/app/pages/home_screen/home_controller.dart';
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
import 'package:bam_bam_driver/app/theme/colors_value.dart';
import 'package:bam_bam_driver/app/theme/styles.dart';
import 'package:bam_bam_driver/app/theme/dimens.dart';

class TripController extends GetxController {
  TripController(this.tripPresenter);

  final TripPresenter tripPresenter;

  // Razorpay key
  static const String razorPayKey = "rzp_test_RraS8FmwVpkMfC";

  String loginType = 'individual';
  bool get isIndividual {
    try {
      final repo = Get.find<Repository>();
      final stored = repo.getStringValue(LocalKeys.loginType).toLowerCase().trim();
      if (stored == 'company') return false;
      if (stored == 'individual') return true;
      final userDetailsStr = repo.getStringValue(LocalKeys.userDetails);
      if (userDetailsStr.isNotEmpty) {
        final ud = jsonDecode(userDetailsStr);
        if (ud is Map && ud['login_type']?.toString().toLowerCase().trim() == 'company') {
          return false;
        }
      }
      if (Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        if (homeCtrl.loginType.toLowerCase().trim() == 'company' || !homeCtrl.isIndividual) {
          return false;
        }
      }
    } catch (_) {}
    return loginType.toLowerCase().trim() != 'company';
  }
  bool get isCompany => !isIndividual;

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

  // ---- Driver Additional Charges State ----
  List<Map<String, dynamic>> driverAdditionalCharges = [];
  bool isLoadingCharges = false;

  /// Fetch active route additional charges configured for this trip's route type
  Future<void> fetchRouteAdditionalCharges({String? routeType}) async {
    try {
      isLoadingCharges = true;
      update();

      if (tripDetails == null) {
        await fetchOngoingTrip();
      }

      String rType = routeType ?? '';
      if (rType.isEmpty && tripDetails != null) {
        final booking = tripDetails!['booking_id'] is Map ? tripDetails!['booking_id'] : {};
        final travel = booking['travelDetailsId'] is Map ? booking['travelDetailsId'] : {};
        final explore = travel['exploreId'] is Map ? travel['exploreId'] : {};
        rType = (explore['trip_type'] ?? travel['trip_type'] ?? booking['trip_type'] ?? 'Oneway').toString();
      }
      if (rType.isEmpty) rType = 'Oneway';

      final res = await tripPresenter.getRouteAdditionalCharges(rType);
      if (!res.hasError && res.data != null) {
        final body = jsonDecode(res.data);
        final data = body['Data'] is Map ? body['Data'] : null;
        if (data != null && data['charges'] is List) {
          final List list = data['charges'];
          driverAdditionalCharges = list
              .where((c) => c is Map && (c['added_by'] == 'driver' || c['added_by'] == null))
              .map((c) {
            return {
              'charge_id': c['charge_id']?.toString() ?? '',
              'title': c['title']?.toString() ?? 'Additional Charge',
              'is_selected': false,
              'amount_controller': TextEditingController(),
              'proof_image': null as File?,
            };
          }).toList();
        }
      }
    } catch (e) {
      log("Error fetching route additional charges: $e");
      // Only provide standard fallback on network/server exception
      if (driverAdditionalCharges.isEmpty) {
        driverAdditionalCharges = [
          {
            'charge_id': '',
            'title': 'Toll Charges',
            'is_selected': false,
            'amount_controller': TextEditingController(),
            'proof_image': null as File?,
          },
          {
            'charge_id': '',
            'title': 'Parking Charges',
            'is_selected': false,
            'amount_controller': TextEditingController(),
            'proof_image': null as File?,
          },
          {
            'charge_id': '',
            'title': 'State Tax / Border Tax',
            'is_selected': false,
            'amount_controller': TextEditingController(),
            'proof_image': null as File?,
          },
        ];
      }
    } finally {
      isLoadingCharges = false;
      update();
    }
  }

  void toggleDriverChargeSelected(int index, bool val) {
    if (index >= 0 && index < driverAdditionalCharges.length) {
      driverAdditionalCharges[index]['is_selected'] = val;
      update();
    }
  }

  Future<void> captureChargeProof(int index) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (photo != null && index >= 0 && index < driverAdditionalCharges.length) {
        driverAdditionalCharges[index]['proof_image'] = File(photo.path);
        update();
      }
    } catch (e) {
      log("Error capturing charge proof: $e");
    }
  }

  void removeChargeProof(int index) {
    if (index >= 0 && index < driverAdditionalCharges.length) {
      driverAdditionalCharges[index]['proof_image'] = null;
      update();
    }
  }

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

  bool _isCommissionPayment = false;
  String? _pendingCommissionRequestId;
  bool _isExtraCommissionPayment = false;
  String? _pendingExtraCommissionVendorRequestId;

  /// Accept a ride request (handles commission flow for individual drivers)
  Future<void> acceptRideRequest(
    String requestId, {
    Map<String, dynamic>? fallbackData,
  }) async {
    AudioService.stopRingtone();

    final bool isCompanyRide = loginType == 'company' &&
        fallbackData?['target_register_type'] != 'individual' &&
        fallbackData?['booking']?['target_register_type'] != 'individual' &&
        fallbackData?['rideDetails']?['target_register_type'] != 'individual' &&
        (fallbackData?['driver_assigned_by_vendor'] != null || fallbackData?['is_assigned_by_vendor'] == true);

    // If strictly a company-assigned ride without commission, directly accept
    if (isCompanyRide) {
      await _performAcceptRide(requestId);
      return;
    }

    // Individual / Commission ride: Fetch commission preview first
    Utility.showLoader();
    final res = await tripPresenter.getCommissionPreview(requestId);
    Utility.closeLoader();
    await Future.delayed(const Duration(milliseconds: 150));

    if (!res.hasError) {
      try {
        final body = jsonDecode(res.data);
        final data = body['Data'];
        if (data != null && data is Map<String, dynamic>) {
          final String bookingId = (data['booking_id'] ?? fallbackData?['booking_id'] ?? '').toString();
          final String tripType = (data['trip_type'] ?? fallbackData?['trip_type'] ?? 'Trip').toString();
          final String pickup = (data['pickup_address'] ?? fallbackData?['pickup_address'] ?? 'N/A').toString();
          final String drop = (data['drop_address'] ?? fallbackData?['drop_address'] ?? 'N/A').toString();
          final num totalFare = (data['total_fare'] as num?) ?? (fallbackData?['total_fare'] as num?) ?? 0;
          final num commissionPercent = (data['commission_percent'] as num?) ?? (fallbackData?['commission_percent'] as num?) ?? 10;
          final num normalCommission = (data['normal_commission'] as num?) ??
              ((commissionPercent > 0 && totalFare > 0) ? ((totalFare * commissionPercent) / 100).round() : ((data['commission_amount'] as num?) ?? 0));
          final num pendingCommission = (data['pending_commission'] as num?) ?? 0;
          final num totalCommissionToPay = (data['commission_amount'] as num?) ?? (normalCommission + pendingCommission);
          final num walletBalance = (data['wallet_balance'] as num?) ?? 0;
          final bool canPayWallet = data['can_pay_wallet'] == true || (walletBalance >= totalCommissionToPay && totalCommissionToPay > 0);

          showCommissionPaymentDialog(
            requestId: requestId,
            bookingId: bookingId,
            tripType: tripType,
            pickupAddress: pickup,
            dropAddress: drop,
            totalFare: totalFare,
            commissionPercent: commissionPercent,
            commissionAmount: normalCommission,
            pendingCommission: pendingCommission,
            totalCommissionToPay: totalCommissionToPay,
            walletBalance: walletBalance,
            canPayWallet: canPayWallet,
          );
          return;
        }
      } catch (e) {
        log("Error parsing commission preview: $e");
      }
    }

    // Fallback if preview API fails but we have fallbackData from Popup 1
    if (fallbackData != null && fallbackData.isNotEmpty) {
      final num totalFare = (fallbackData['total_fare'] as num?) ?? 0;
      final num commissionPercent = (fallbackData['commission_percent'] as num?) ?? 10;
      final num commissionAmount = (fallbackData['commission_amount'] as num?) ??
          ((commissionPercent > 0 && totalFare > 0) ? ((totalFare * commissionPercent) / 100).round() : 0);
      final num walletBalance = 0;

      showCommissionPaymentDialog(
        requestId: requestId,
        bookingId: (fallbackData['booking_id'] ?? '').toString(),
        tripType: (fallbackData['trip_type'] ?? 'Trip').toString(),
        pickupAddress: (fallbackData['pickup_address'] ?? 'N/A').toString(),
        dropAddress: (fallbackData['drop_address'] ?? 'N/A').toString(),
        totalFare: totalFare,
        commissionPercent: commissionPercent,
        commissionAmount: commissionAmount,
        pendingCommission: 0,
        totalCommissionToPay: commissionAmount,
        walletBalance: walletBalance,
        canPayWallet: false,
      );
      return;
    }

    Utility.showMessage('Failed to load commission details. Please try again.', MessageType.error, null, 'OK');
  }

  /// Perform ride acceptance after commission payment (or directly for company driver)
  Future<void> _performAcceptRide(
    String requestId, {
    String paymentMethod = "Wallet",
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    AudioService.stopRingtone();

    // Ensure all dialogs and bottom sheets are dismissed
    while (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    }

    Utility.showLoader();
    final res = await tripPresenter.acceptRideRequest(
      requestId,
      paymentMethod: paymentMethod,
      razorpayPaymentId: razorpayPaymentId,
      razorpayOrderId: razorpayOrderId,
      razorpaySignature: razorpaySignature,
    );
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
          final currentTripId = tripDetails?['_id']?.toString() ?? tripDetails?['booking']?['_id']?.toString();
          if (currentTripId == bookingId) {
            // Already viewing this trip's details, reload data in-place
            await fetchTripDetails(bookingId);
          } else {
            if (loginType == 'individual') {
              RouteManagement.gotoTripDetilesScreen(
                isComplectTrip: false,
                tripId: bookingId,
              );
            } else {
              if (bookingId.isNotEmpty) {
                startRide(bookingId);
              }
              RouteManagement.gotoTriptrackingScreen(
                isStartTrip: true,
                tripId: bookingId,
              );
            }
          }
        }
      } catch (e) {
        log("Error navigating after acceptance: $e");
        await fetchAssignedTrips();
      }
    }

    update();
  }

  /// Online payment for commission via Razorpay
  Future<void> _payCommissionOnline(String requestId, num commissionAmount) async {
    while (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    }
    Utility.showLoader();
    final res = await tripPresenter.createCommissionOrder(requestId);
    Utility.closeLoader();

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to create commission payment order',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage('Failed to create payment order', MessageType.error, null, 'OK');
      }
      return;
    }

    try {
      final body = jsonDecode(res.data);
      final data = body['Data'];
      final String orderId = data['order_id']?.toString() ?? '';
      final int amountInPaise = (data['amount_in_paise'] as num?)?.toInt() ?? ((commissionAmount * 100).toInt());
      final String key = data['key']?.toString() ?? razorPayKey;

      _isCommissionPayment = true;
      _pendingCommissionRequestId = requestId;

      var options = {
        'key': key,
        'amount': amountInPaise,
        'name': 'BamBam Cabs',
        'description': 'Ride Commission Payment',
        'order_id': orderId,
        'prefill': {
          'contact': '',
          'email': '',
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay.open(options);
    } catch (e) {
      Utility.showMessage("Error launching payment gateway: $e", MessageType.error, null, "OK");
    }
  }

  /// 💰 Extra Commission Popup — shown at trip end if final bill > start bill
  void showExtraCommissionDialog({
    required String vendorRequestId,
    required num extraCommission,
    required num initialCommission,
    required num finalCommission,
    required num finalFare,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 26),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Extra Commission Due',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Final bill became higher due to extra KM / charges. Please pay the difference in BamBam commission.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              _extraRow('Final Trip Fare', '₹${finalFare.toStringAsFixed(0)}'),
              _extraRow('Commission paid at start', '₹${initialCommission.toStringAsFixed(0)}'),
              _extraRow('Commission on final bill', '₹${finalCommission.toStringAsFixed(0)}'),
              const Divider(),
              _extraRow('Extra Commission', '₹${extraCommission.toStringAsFixed(0)}', bold: true),
              const SizedBox(height: 8),
              Text(
                'If you pay later, this amount will be added to your next trip commission.',
                style: TextStyle(fontSize: 12, color: Colors.red.shade400),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Pay Later'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsValue.bulycolorsCB,
                      ),
                      onPressed: () {
                        _showExtraCommissionPaymentOptionsBottomSheet(
                          vendorRequestId: vendorRequestId,
                          extraCommission: extraCommission,
                        );
                      },
                      child: const Text(
                        'Pay Now',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Bottom sheet presenting "Pay from Wallet" & "Pay Online"
  void _showExtraCommissionPaymentOptionsBottomSheet({
    required String vendorRequestId,
    required num extraCommission,
  }) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const Text(
                'Choose Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Amount to pay: ₹${extraCommission.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 20),
              // Option 1: Pay from Wallet
              InkWell(
                onTap: () async {
                  Get.back(); // close bottom sheet
                  while (Get.isDialogOpen == true) {
                    Get.back();
                  }
                  Utility.showLoader();
                  final res = await tripPresenter.payExtraCommission(
                    vendorRequestId: vendorRequestId,
                    paymentMethod: 'Wallet',
                  );
                  Utility.closeLoader();
                  String msg = 'Payment failed';
                  bool ok = false;
                  try {
                    final b = jsonDecode(res.data);
                    ok = !res.hasError && b['IsSuccess'] == true;
                    msg = b['Message']?.toString() ?? msg;
                  } catch (_) {}
                  Utility.showMessage(
                    ok ? 'Extra commission paid successfully' : msg,
                    ok ? MessageType.success : MessageType.error,
                    null,
                    'OK',
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ColorsValue.bulycolorsCB.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet,
                            color: Colors.black87, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay from Wallet',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Deduct from driver wallet balance',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Option 2: Pay Online
              InkWell(
                onTap: () {
                  Get.back(); // close bottom sheet
                  _payExtraCommissionOnline(vendorRequestId, extraCommission);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorsValue.bulycolorsCB),
                    borderRadius: BorderRadius.circular(12),
                    color: ColorsValue.bulycolorsCB.withOpacity(0.06),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ColorsValue.bulycolorsCB.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.credit_card,
                            color: Colors.black87, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay Online',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'UPI, Cards, Net Banking via Razorpay',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
    );
  }

  /// Online payment for extra commission via Razorpay
  Future<void> _payExtraCommissionOnline(
    String vendorRequestId,
    num extraCommission,
  ) async {
    while (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    }
    Utility.showLoader();
    final res = await tripPresenter.createExtraCommissionOrder(
      vendorRequestId: vendorRequestId,
    );
    Utility.closeLoader();

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        Utility.showMessage(
          body['Message'] ?? 'Failed to create payment order',
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage('Failed to create payment order', MessageType.error, null, 'OK');
      }
      return;
    }

    try {
      final body = jsonDecode(res.data);
      final data = body['Data'];
      final String orderId = data['order_id']?.toString() ?? '';
      final int amountInPaise = (data['amount_in_paise'] as num?)?.toInt() ??
          ((extraCommission * 100).toInt());
      final String key = data['key']?.toString() ?? razorPayKey;

      _isExtraCommissionPayment = true;
      _pendingExtraCommissionVendorRequestId = vendorRequestId;

      var options = {
        'key': key,
        'amount': amountInPaise,
        'name': 'BamBam Cabs',
        'description': 'Extra Commission Payment',
        'order_id': orderId,
        'prefill': {
          'contact': '',
          'email': '',
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay.open(options);
    } catch (e) {
      Utility.showMessage("Error launching payment gateway: $e", MessageType.error, null, "OK");
    }
  }

  Future<void> _completeExtraCommissionPayment(
    String vendorRequestId, {
    String? razorpayPaymentId,
  }) async {
    Utility.showLoader();
    final res = await tripPresenter.payExtraCommission(
      vendorRequestId: vendorRequestId,
      paymentMethod: 'Online',
      razorpayPaymentId: razorpayPaymentId,
    );
    Utility.closeLoader();

    bool ok = false;
    String msg = 'Payment failed';
    try {
      final b = jsonDecode(res.data);
      ok = !res.hasError && b['IsSuccess'] == true;
      msg = b['Message']?.toString() ?? msg;
    } catch (_) {}

    Utility.showMessage(
      ok ? 'Extra commission paid successfully' : msg,
      ok ? MessageType.success : MessageType.error,
      null,
      'OK',
    );
  }

  Widget _extraRow(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
          ],
        ),
      );

  /// Show Commission Payment Bottom Sheet
  void showCommissionPaymentDialog({
    required String requestId,
    required String bookingId,
    required String tripType,
    required String pickupAddress,
    required String dropAddress,
    required num totalFare,
    required num commissionPercent,
    required num commissionAmount,
    num pendingCommission = 0,
    num? totalCommissionToPay,
    required num walletBalance,
    required bool canPayWallet,
  }) {
    final num normalComm = (commissionPercent > 0 && totalFare > 0)
        ? ((totalFare * commissionPercent) / 100).round()
        : commissionAmount;
    final num effectiveCommission = totalCommissionToPay ?? (normalComm + pendingCommission);
    final bool effectiveCanPayWallet = walletBalance >= effectiveCommission && effectiveCommission > 0;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Drag handle
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

              // Title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.account_balance_wallet, color: Colors.green.shade700, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Commission Payment",
                        style: Styles.txtBlackColorW60018.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Trip details card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Booking #$bookingId",
                          style: Styles.txtBlackColorW60014.copyWith(color: ColorsValue.appColor),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Text(
                            tripType,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (pickupAddress.isNotEmpty && pickupAddress != "N/A") ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, color: Colors.green, size: 10),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pickupAddress,
                              style: Styles.txtBlackColorW40012.copyWith(color: Colors.grey.shade700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (dropAddress.isNotEmpty && dropAddress != "N/A") ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 12),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dropAddress,
                              style: Styles.txtBlackColorW40012.copyWith(color: Colors.grey.shade700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Financial breakdown card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Trip Fare", style: Styles.txtG5ColorsW40014),
                        Text("₹${totalFare.toStringAsFixed(0)}", style: Styles.txtBlackColorW60014),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("BamBam Commission Rate", style: Styles.txtG5ColorsW40014),
                        Text("${commissionPercent.toStringAsFixed(0)}%", style: Styles.txtBlackColorW60014),
                      ],
                    ),
                    if (pendingCommission > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Ride Commission", style: Styles.txtG5ColorsW40014),
                          Text("₹${normalComm.toStringAsFixed(0)}", style: Styles.txtBlackColorW60014),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Pending Commission",
                                style: Styles.txtG5ColorsW40014.copyWith(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              Text("(Previous)", style: TextStyle(fontSize: 10, color: Colors.red.shade400)),
                            ],
                          ),
                          Text(
                            "+₹${pendingCommission.toStringAsFixed(0)}",
                            style: Styles.txtBlackColorW60014.copyWith(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pendingCommission > 0 ? "Total Commission to Pay" : "Commission to Pay Admin",
                          style: Styles.txtBlackColorW60014.copyWith(color: Colors.grey.shade900),
                        ),
                        Text(
                          "₹${effectiveCommission.toStringAsFixed(0)}",
                          style: Styles.txtBlackColorW70020.copyWith(color: Colors.orange.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Your Net Earning",
                          style: Styles.txtBlackColorW60014.copyWith(color: Colors.green.shade800),
                        ),
                        Text(
                          "₹${(totalFare - normalComm).clamp(0, double.infinity).toStringAsFixed(0)}",
                          style: Styles.txtBlackColorW70020.copyWith(color: Colors.green.shade700, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Driver Wallet Balance
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: effectiveCanPayWallet ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                effectiveCanPayWallet ? Icons.check_circle : Icons.warning_amber_rounded,
                                size: 16,
                                color: effectiveCanPayWallet ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Your Wallet Balance:",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: effectiveCanPayWallet ? Colors.green.shade900 : Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "₹${walletBalance.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: effectiveCanPayWallet ? Colors.green.shade900 : Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              if (effectiveCanPayWallet) ...[
                // Wallet payment button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _performAcceptRide(requestId, paymentMethod: "Wallet");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      "Pay ₹${effectiveCommission.toStringAsFixed(0)} from Wallet & Accept",
                      style: Styles.whiteColorW60016.copyWith(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Online payment button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                      _payCommissionOnline(requestId, effectiveCommission);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Pay Online (Razorpay / UPI)",
                      style: Styles.txtBlackColorW50014.copyWith(color: ColorsValue.appColor),
                    ),
                  ),
                ),
              ] else ...[
                // Insufficient wallet balance: Pay Online primary, Top-up secondary
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _payCommissionOnline(requestId, effectiveCommission);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      "Pay ₹${effectiveCommission.toStringAsFixed(0)} Online & Accept",
                      style: Styles.whiteColorW60016.copyWith(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                      RouteManagement.gotoTopUpWalletScreen();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Top Up Wallet",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    ),
    barrierDismissible: true,
  );
  }

  /// Reject a ride request
  Future<void> rejectRideRequest(String requestId) async {
    AudioService.stopRingtone();
    Utility.showLoader();

    // Optimistically remove from local rideRequests list
    rideRequests.removeWhere((r) {
      final reqId = (r['request_id'] ?? r['_id'] ?? '').toString();
      final booking = r['booking_details'] is Map
          ? r['booking_details']
          : (r['booking'] is Map ? r['booking'] : r);
      final rawBid = booking is Map ? booking['booking_id'] : null;
      final bId = (rawBid is Map
              ? (rawBid['booking_id'] ?? rawBid['_id'])
              : (rawBid ?? (booking is Map ? booking['_id'] : null) ?? ''))
          .toString();
      return reqId == requestId || bId == requestId;
    });
    update();

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
    }

    // Refresh list from server
    await fetchRideRequests();

    // Also update HomeController badge count if registered
    if (Get.isRegistered<HomeController>()) {
      final homeCtrl = Get.find<HomeController>();
      homeCtrl.newRequests = rideRequests.length;
      homeCtrl.update();
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

  /// End trip - call endTrip API with multipart (end_km_photo) and additional charges proof slips
  Future<void> endTrip({
    required String vendorRequestId,
    required String endKm,
    required double lat,
    required double lon,
  }) async {
    if (vehicleMeterImage == null) {
      Utility.showMessage('Please click vehicle meter photo first', MessageType.error, null, 'OK');
      return;
    }
    String? photoPath = vehicleMeterImage?.path;

    // Collect and validate selected additional charges
    final List<Map<String, dynamic>> selectedChargesDetails = [];
    final Map<String, String> proofImagePaths = {};

    for (int i = 0; i < driverAdditionalCharges.length; i++) {
      final item = driverAdditionalCharges[i];
      if (item['is_selected'] == true) {
        final ctrl = item['amount_controller'] as TextEditingController?;
        final amountText = ctrl?.text.trim() ?? '';
        final amountNum = double.tryParse(amountText) ?? 0.0;
        final proofFile = item['proof_image'] as File?;

        if (amountNum <= 0) {
          Utility.showMessage(
            'Please enter valid amount for ${item['title']}',
            MessageType.error,
            null,
            'OK',
          );
          return;
        }

        if (proofFile == null) {
          Utility.showMessage(
            'Please upload receipt/slip photo for ${item['title']}',
            MessageType.error,
            null,
            'OK',
          );
          return;
        }

        final fieldName = 'proof_$i';
        selectedChargesDetails.add({
          'charge_id': item['charge_id'],
          'title': item['title'],
          'amount': amountNum,
          'fieldname': fieldName,
        });

        proofImagePaths[fieldName] = proofFile.path;
      }
    }

    final String? chargesJson = selectedChargesDetails.isNotEmpty
        ? jsonEncode(selectedChargesDetails)
        : null;

    final res = await tripPresenter.endTrip(
      vendorRequestId: vendorRequestId,
      endKm: endKm,
      lat: lat,
      lon: lon,
      endKmPhotoPath: photoPath,
      additionalChargesDetailsJson: chargesJson,
      proofImagePaths: proofImagePaths.isNotEmpty ? proofImagePaths : null,
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

        // 💰 Extra commission popup (individual driver) when final fare > start fare
        try {
          final data = body['Data'];
          if (data is Map && data['show_extra_commission_popup'] == true) {
            final num extra = num.tryParse('${data['extra_commission_amount'] ?? 0}') ?? 0;
            final num initialComm = num.tryParse('${data['initial_commission_amount'] ?? 0}') ?? 0;
            final num finalComm = num.tryParse('${data['final_commission_amount'] ?? 0}') ?? 0;
            final num finalFare = num.tryParse('${data['final_trip_fare'] ?? 0}') ?? 0;
            if (extra > 0) {
              Future.delayed(const Duration(milliseconds: 600), () {
                showExtraCommissionDialog(
                  vendorRequestId: vendorRequestId,
                  extraCommission: extra,
                  initialCommission: initialComm,
                  finalCommission: finalComm,
                  finalFare: finalFare,
                );
              });
            }
          }
        } catch (_) {}
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
    // Check if this payment was for Extra Commission
    if (_isExtraCommissionPayment) {
      _isExtraCommissionPayment = false;
      final vrId = _pendingExtraCommissionVendorRequestId;
      _pendingExtraCommissionVendorRequestId = null;
      if (vrId != null && vrId.isNotEmpty) {
        _completeExtraCommissionPayment(
          vrId,
          razorpayPaymentId: response.paymentId,
        );
      }
      return;
    }

    // Check if this payment was for Ride Acceptance Commission
    if (_isCommissionPayment) {
      _isCommissionPayment = false;
      final reqId = _pendingCommissionRequestId;
      _pendingCommissionRequestId = null;
      if (reqId != null) {
        _performAcceptRide(
          reqId,
          paymentMethod: 'Online',
          razorpayPaymentId: response.paymentId,
          razorpayOrderId: response.orderId,
          razorpaySignature: response.signature,
        );
      }
      return;
    }

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
    if (_isExtraCommissionPayment) {
      _isExtraCommissionPayment = false;
      _pendingExtraCommissionVendorRequestId = null;
    }
    if (_isCommissionPayment) {
      _isCommissionPayment = false;
      _pendingCommissionRequestId = null;
    }
    Utility.showMessage(
      'Payment failed: ${response.message ?? 'Unknown error'}',
      MessageType.error,
      null,
      'OK',
    );
  }

  /// Handle Razorpay external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    if (_isExtraCommissionPayment) {
      _isExtraCommissionPayment = false;
      _pendingExtraCommissionVendorRequestId = null;
    }
    if (_isCommissionPayment) {
      _isCommissionPayment = false;
      _pendingCommissionRequestId = null;
    }
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

  Future<void> startRide(String tripId) async {
    if (tripId.isEmpty) return;
    try {
      await tripPresenter.startRide(tripId: tripId);
    } catch (e) {
      debugPrint("startRide API error: $e");
    }
  }

  Future<void> notifyDriverArrived(String vendorRequestId, {String? bookingId}) async {
    isPerformingTripAction = true;
    update();

    final bId = bookingId ??
        (tripDetails?['booking_id'] is Map
            ? tripDetails?['booking_id']?['_id']?.toString()
            : tripDetails?['booking_id']?.toString());

    final res = await tripPresenter.driverArrived(
      vendorRequestId: vendorRequestId,
      bookingId: bId,
    );

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