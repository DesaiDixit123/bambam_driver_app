import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/app/pages/profile_screen/profile_controller.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:bam_bam_driver/domain/repositories/local_storage_keys.dart';
import 'package:bam_bam_driver/domain/repositories/repository.dart';
import 'package:bam_bam_driver/domain/usecases/home_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bam_bam_driver/domain/services/audio_service.dart';
import 'package:bam_bam_driver/domain/services/socket_connection.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bam_bam_driver/domain/services/native_overlay_service.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_controller.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_binding.dart';
import 'package:bam_bam_driver/app/pages/home_screen/Screens/new_ride_popup.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
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
  bool isOnline = false;
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

  // 💰 Earnings Vault State
  bool isIndividual = false;
  double walletBalance = 0.0;
  Map<String, dynamic>? earningsData;
  bool isEarningsLoading = false;
  bool isWithdrawLoading = false;
  bool isTopUpLoading = false;
  String selectedWithdrawMethod = "Bank";
  final TextEditingController withdrawUpiController = TextEditingController();
  int selectedIndexEarn = -1;
  final TextEditingController withdrawAmountController = TextEditingController();
  final TextEditingController topUpAmountController = TextEditingController();
  late Razorpay _razorpay;
  String? currentRazorpayOrderId;

  // 📍 Location State & Properties
  double? currentLat;
  double? currentLng;
  String currentLocationDisplay = "";
  String currentFullAddress = "";
  bool isFetchingLocation = false;
  bool isLocationDisabled = false;
  bool isTogglingStatus = false;

  @override
  void onInit() {
    super.onInit();
    final repo = Get.find<Repository>();
    loginType = repo.getStringValue(LocalKeys.loginType);
    if (loginType.isEmpty) loginType = 'individual';
    isIndividual = loginType == 'individual';

    final driverId = SocketConnection.getDriverId();
    if (driverId.isNotEmpty) {
      SocketConnection.updateChannelId(driverId);
    }

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndFetchCurrentLocation(showPopupIfDisabled: true);
      checkOverlayPermission();
      checkPendingAction();
    });

    update();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _razorpay.clear();
    withdrawAmountController.dispose();
    withdrawUpiController.dispose();
    topUpAmountController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkPendingAction();
      if (isLocationDisabled || currentLocationDisplay.isEmpty) {
        checkAndFetchCurrentLocation(showPopupIfDisabled: false);
      }
      fetchDashboardSafe(showLoader: false);
    }
  }

  /// Checks if a ride was accepted via native RideAlertActivity (e.g. from lockscreen)
  Future<void> checkPendingAction() async {
    try {
      final actionData = await NativeOverlayService.getPendingAction();
      if (actionData != null && actionData['action'] == 'accept_ride') {
        final reqId = (actionData['request_id'] ?? '').toString();
        if (reqId.isNotEmpty) {
          if (!Get.isRegistered<TripController>()) {
            TripBinding().dependencies();
          }
          final tripCtrl = Get.find<TripController>();
          tripCtrl.acceptRideRequest(reqId, fallbackData: actionData);
        }
      }
    } catch (e) {
      print("Error checking pending action in HomeController: $e");
    }
  }

  /// Check GPS status, permission, and fetch current coordinates + reverse geocode
  Future<void> checkAndFetchCurrentLocation({
    bool forcePrompt = false,
    bool showPopupIfDisabled = true,
  }) async {
    try {
      isFetchingLocation = true;
      update();

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isLocationDisabled = true;
        isFetchingLocation = false;
        if (currentLocationDisplay.isEmpty || currentLocationDisplay.contains("Location")) {
          currentLocationDisplay = "Location Disabled (Tap to enable)";
        }
        update();
        if (showPopupIfDisabled || forcePrompt) {
          showLocationOffDialog();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        isLocationDisabled = true;
        isFetchingLocation = false;
        if (currentLocationDisplay.isEmpty || currentLocationDisplay.contains("Location")) {
          currentLocationDisplay = "Permission Denied (Tap to grant)";
        }
        update();
        if (showPopupIfDisabled || forcePrompt) {
          showLocationPermissionDialog(isPermanentlyDenied: false);
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        isLocationDisabled = true;
        isFetchingLocation = false;
        if (currentLocationDisplay.isEmpty || currentLocationDisplay.contains("Location")) {
          currentLocationDisplay = "Permission Denied (Tap to grant)";
        }
        update();
        if (showPopupIfDisabled || forcePrompt) {
          showLocationPermissionDialog(isPermanentlyDenied: true);
        }
        return;
      }

      // If we reach here, location service is enabled and permission is granted!
      isLocationDisabled = false;
      update();

      // Dismiss dialog if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      currentLat = position.latitude;
      currentLng = position.longitude;

      // Sync driver coordinates with backend database
      homeUsecases.updateDriverLocation(
        lat: position.latitude,
        lng: position.longitude,
      );

      // 1️⃣ Direct Google Maps Geocoding API on UI side
      try {
        final googleUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${StringConstants.placeSearchKey}',
        );
        final gResponse = await ApiWrapper.client
            .get(googleUrl)
            .timeout(const Duration(seconds: 8));

        if (gResponse.statusCode == 200 && gResponse.body.isNotEmpty) {
          final resData = jsonDecode(gResponse.body);
          if (resData['status'] == 'OK' &&
              resData['results'] is List &&
              (resData['results'] as List).isNotEmpty) {
            final firstResult = resData['results'][0];
            final comps = firstResult['address_components'] as List? ?? [];

            String getComp(List<String> types) {
              final found = comps.firstWhereOrNull(
                (c) =>
                    c is Map &&
                    (c['types'] as List?)?.any((t) => types.contains(t)) == true,
              );
              return found != null ? (found['long_name']?.toString() ?? '') : '';
            }

            final sublocality1 = getComp(['sublocality_level_1']);
            final sublocality2 = getComp(['sublocality_level_2']);
            final sublocality = getComp(['sublocality']);
            final neighborhood = getComp(['neighborhood']);
            final route = getComp(['route']);

            final area = [sublocality1, sublocality2, sublocality, neighborhood, route]
                .firstWhere((s) => s.isNotEmpty, orElse: () => '');
            final city = getComp(['locality']).isNotEmpty
                ? getComp(['locality'])
                : getComp(['administrative_area_level_2']);
            final formatted = firstResult['formatted_address']?.toString() ?? '';

            currentFullAddress = formatted;

            if (area.isNotEmpty && city.isNotEmpty) {
              if (!area.toLowerCase().contains(city.toLowerCase())) {
                currentLocationDisplay = "$area, $city";
              } else {
                currentLocationDisplay = area;
              }
            } else if (area.isNotEmpty) {
              currentLocationDisplay = area;
            } else if (city.isNotEmpty) {
              currentLocationDisplay = city;
            } else if (formatted.isNotEmpty) {
              final parts = formatted.split(',');
              currentLocationDisplay = parts.isNotEmpty ? parts[0].trim() : formatted;
            }
            update();
            return;
          }
        }
      } catch (gErr) {
        log("Driver direct Google Geocoding UI error: $gErr");
      }

      // 2️⃣ Fallback: Reverse geocode via backend API
      final res = await homeUsecases.reverseGeocode(
        lat: position.latitude,
        lng: position.longitude,
      );

      if (!res.hasError && res.data.isNotEmpty) {
        try {
          final body = jsonDecode(res.data);
          if (body is Map && body.containsKey('Data') && body['Data'] != null) {
            final data = body['Data'];
            final formatted = data['formatted_address']?.toString() ?? "";
            final area = data['area']?.toString().trim() ?? "";
            final city = data['city']?.toString().trim() ?? "";
            currentFullAddress = formatted;

            if (area.isNotEmpty) {
              if (city.isNotEmpty && !area.toLowerCase().contains(city.toLowerCase())) {
                currentLocationDisplay = "$area, $city";
              } else {
                currentLocationDisplay = area;
              }
            } else if (formatted.isNotEmpty) {
              final parts = formatted.split(',');
              if (parts.isNotEmpty) {
                final firstPart = parts[0].trim();
                if (city.isNotEmpty && !firstPart.toLowerCase().contains(city.toLowerCase())) {
                  currentLocationDisplay = "$firstPart, $city";
                } else if (parts.length >= 2) {
                  currentLocationDisplay = "${parts[0].trim()}, ${parts[1].trim()}";
                } else {
                  currentLocationDisplay = firstPart;
                }
              } else {
                currentLocationDisplay = city.isNotEmpty ? city : formatted;
              }
            } else if (city.isNotEmpty) {
              currentLocationDisplay = city;
            } else {
              currentLocationDisplay = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
            }
          } else {
            currentLocationDisplay = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
          }
        } catch (_) {
          currentLocationDisplay = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
        }
      } else {
        currentLocationDisplay = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
      }
    } catch (e) {
      log("Error fetching location: $e");
      if (currentLocationDisplay.isEmpty) {
        currentLocationDisplay = "Tap to refresh location";
      }
    } finally {
      isFetchingLocation = false;
      update();
    }
  }

  /// Show popup dialog when device location service is OFF
  void showLocationOffDialog() {
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: Icon(Icons.location_off_rounded, color: Colors.red.shade600, size: 34),
              ),
              const SizedBox(height: 18),
              const Text(
                "Choose Your Current Location",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Your mobile GPS / Location is turned OFF. Please enable location so BamBam Cabs can find your current location and send trip requests.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsValue.appColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Get.back();
                    await Geolocator.openLocationSettings();
                  },
                  icon: const Icon(Icons.location_on_rounded, size: 20),
                  label: const Text(
                    "Turn On Location",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Get.back();
                    await checkAndFetchCurrentLocation(forcePrompt: true);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    "Retry",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

  bool _hasPromptedOverlay = false;

  /// Check if "Display over other apps" is granted, and prompt if not
  Future<void> checkOverlayPermission() async {
    if (_hasPromptedOverlay) return;
    try {
      final isGranted = await NativeOverlayService.checkOverlayPermission();
      if (!isGranted) {
        _hasPromptedOverlay = true;
        Future.delayed(const Duration(seconds: 1), () {
          showOverlayPermissionDialog();
        });
      }
    } catch (_) {}
  }

  void showOverlayPermissionDialog() {
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange.shade200, width: 2),
                ),
                child: Icon(Icons.layers_outlined, color: Colors.orange.shade700, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                "Display Over Other Apps",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Enable 'Display over other apps' so ride popups and alerts appear instantly on your screen even when using other apps or on the home screen.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => Get.back(),
                      child: Text("Later", style: TextStyle(color: Colors.grey.shade700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        Get.back();
                        await NativeOverlayService.requestOverlayPermission();
                      },
                      child: const Text("Enable", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Show popup dialog when location permission is needed
  void showLocationPermissionDialog({bool isPermanentlyDenied = false}) {
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange.shade200, width: 2),
                ),
                child: Icon(Icons.my_location_rounded, color: Colors.orange.shade700, size: 34),
              ),
              const SizedBox(height: 18),
              const Text(
                "Location Permission Needed",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "BamBam Cabs needs location access to detect where you are and dispatch nearby trips to you.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsValue.appColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Get.back();
                    if (isPermanentlyDenied) {
                      await Geolocator.openAppSettings();
                    } else {
                      await Geolocator.requestPermission();
                      await checkAndFetchCurrentLocation(forcePrompt: true);
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    isPermanentlyDenied ? "Open Settings" : "Grant Permission",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Get.back();
                    await checkAndFetchCurrentLocation(forcePrompt: true);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    "Retry",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

  /// Show popup dialog when profile is not completed
  void showCompleteProfileDialog() {
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade200, width: 2),
                ),
                child: Icon(Icons.assignment_late_rounded, color: Colors.amber.shade800, size: 34),
              ),
              const SizedBox(height: 18),
              const Text(
                "Please Complete Your Profile",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Complete your 6-step profile details and submit your documents for verification to start receiving ride requests.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsValue.appColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Get.back();
                    RouteManagement.gotoPersonalDetilesScreen();
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text(
                    "Complete Profile",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    "Later",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Show popup dialog when profile is under admin review
  void showPendingApprovalDialog() {
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: Icon(Icons.pending_actions_rounded, color: Colors.blue.shade700, size: 34),
              ),
              const SizedBox(height: 18),
              const Text(
                "Profile Under Review",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Your registration documents have been submitted and are currently under verification by BamBam Cabs Admin. You will receive a notification and can turn Online once approved.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
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
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    "Understood",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Show popup dialog when profile verification was rejected
  void showRejectedProfileDialog(String reason) {
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: Icon(Icons.cancel_rounded, color: Colors.red.shade700, size: 34),
              ),
              const SizedBox(height: 18),
              const Text(
                "Verification Rejected",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Reason from Admin:",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reason.isNotEmpty ? reason : "Please correct your profile details and re-upload clear document copies.",
                      style: TextStyle(fontSize: 13, color: Colors.red.shade800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Please update your profile details and resubmit for verification.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsValue.appColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Get.back();
                    RouteManagement.gotoPersonalDetilesScreen();
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text(
                    "Edit Profile & Resubmit",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    "Close",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Toggle online status and call backend
  Future<void> toggleOnlineStatus(bool value) async {
    if (isTogglingStatus) return;
    stopRingtone();

    if (value == true && (loginType == 'individual' || isIndividual)) {
      ProfileController? pCtrl = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;
      if (pCtrl != null) {
        final prof = pCtrl.profile;
        final bool isProfileCompleted = prof?['is_profile_completed'] == true;
        final String approvalStatus = (prof?['approval_status'] ?? '').toString().toLowerCase();

        if (!isProfileCompleted) {
          isOnline = false;
          update();
          showCompleteProfileDialog();
          return;
        }

        if (approvalStatus == 'pending' || approvalStatus == 'draft' || approvalStatus.isEmpty) {
          isOnline = false;
          update();
          showPendingApprovalDialog();
          return;
        }

        if (approvalStatus == 'rejected') {
          isOnline = false;
          update();
          final reason = (prof?['rejected_reason'] ?? 'Documents rejected by Admin').toString();
          showRejectedProfileDialog(reason);
          return;
        }
      }
    }

    isTogglingStatus = true;
    isOnline = value;
    if (value == true) {
      isLeave = false; // Turn off leave if coming online
    }
    update();

    try {
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
        await fetchDashboardSafe(showLoader: false);
        update();
        Utility.showMessage(
          value ? 'You are now Online' : 'You are now Offline',
          MessageType.success,
          null,
          'OK',
        );
      }
    } finally {
      isTogglingStatus = false;
      update();
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
      await fetchDashboardSafe(showLoader: false);
      update();
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
        walletBalance = (data['wallet_balance'] is num)
            ? (data['wallet_balance'] as num).toDouble()
            : double.tryParse('${data['wallet_balance']}') ?? 0.0;
        if (data['isIndividual'] != null) {
          isIndividual = data['isIndividual'] == true;
        }
        if (data['login_type'] != null && data['login_type'].toString().isNotEmpty) {
          loginType = data['login_type'].toString();
        }

        // Auto-show ride alert if pending ride exists and no ride popup is currently open
        if (newRequests > 0 && NewRidePopup.activeBookingIds.isEmpty && Get.isDialogOpen != true) {
          _checkAndShowPendingRide();
        }
      } else {
        ongoingTrip = 0;
        assignedTrip = 0;
        tripHistory = 0;
        newRequests = 0;
        rejectedRides = 0;
        walletBalance = 0.0;
      }
    } catch (e) {
      Utility.showMessage('Failed to load dashboard', MessageType.error, null, 'OK');
    } finally {
      isLoadingDashboard = false;
      update();
    }
  }

  Future<void> _checkAndShowPendingRide() async {
    try {
      if (NewRidePopup.activeBookingIds.isNotEmpty || Get.isDialogOpen == true) {
        return;
      }
      if (!Get.isRegistered<TripController>()) {
        TripBinding().dependencies();
      }
      final tripCtrl = Get.find<TripController>();
      final res = await tripCtrl.tripPresenter.getRideRequestList();
      if (!res.hasError) {
        final body = jsonDecode(res.data);
        if (body['IsSuccess'] == true && body['Data'] is List && (body['Data'] as List).isNotEmpty) {
          final firstItem = (body['Data'] as List).first;
          if (firstItem is Map) {
            final b = firstItem['booking_details'] ?? firstItem['booking'] ?? firstItem['rideDetails'] ?? firstItem;
            final String bId = (b is Map ? (b['booking_id'] ?? b['_id']) : null)?.toString() ?? '';
            final String mId = (b is Map ? (b['_id'] ?? b['booking_id']) : null)?.toString() ?? '';
            final String bNum = (b is Map ? (b['booking_id'] ?? '') : '')?.toString() ?? '';
            final String reqId = (firstItem['request_id'] ?? firstItem['_id'])?.toString() ?? '';

            // If this ride popup was already shown or dismissed by the driver, NEVER pop it up again on refresh!
            if (NewRidePopup.dismissedOrSeenBookingIds.contains(bId) ||
                NewRidePopup.dismissedOrSeenBookingIds.contains(mId) ||
                (bNum.isNotEmpty && NewRidePopup.dismissedOrSeenBookingIds.contains(bNum)) ||
                NewRidePopup.dismissedOrSeenBookingIds.contains(reqId)) {
              return;
            }

            if (bId.isNotEmpty &&
                !NewRidePopup.activeBookingIds.contains(bId) &&
                !NewRidePopup.activeBookingIds.contains(reqId) &&
                Get.isDialogOpen != true) {
              SocketConnection.showRidePopup(firstItem);
            }
          }
        }
      }
    } catch (e) {
      print("HomeController._checkAndShowPendingRide error: $e");
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

  // ===========================================================================
  // 💰 EARNINGS VAULT (For Individual Drivers)
  // ===========================================================================

  /// Fetch Earnings Vault Data
  Future<void> fetchEarningsVaultData({
    String? startDate,
    String? endDate,
    String? tripType,
    int page = 1,
    int limit = 10,
  }) async {
    isEarningsLoading = true;
    update();

    try {
      final response = await homeUsecases.getEarningsVaultData(
        startDate: startDate,
        endDate: endDate,
        tripType: tripType,
        page: page,
        limit: limit,
        showLoader: false,
      );

      log("Driver Earnings Vault Response: ${response.data}");

      if (!response.hasError) {
        final decoded = jsonDecode(response.data);
        if (decoded['IsSuccess'] == true || decoded['isSuccess'] == true) {
          earningsData = decoded['Data'] as Map<String, dynamic>?;
          if (earningsData != null && earningsData!['wallet_balance'] != null) {
            walletBalance = (earningsData!['wallet_balance'] is num)
                ? (earningsData!['wallet_balance'] as num).toDouble()
                : double.tryParse('${earningsData!['wallet_balance']}') ?? 0.0;
          }
        } else {
          Utility.showMessage(
            decoded['Message'] ?? "Failed to fetch earnings vault",
            MessageType.error,
            null,
            "OK",
          );
        }
      } else {
        try {
          final decoded = jsonDecode(response.data);
          Utility.showMessage(
            decoded['Message'] ?? decoded['message'] ?? "API Call Failed",
            MessageType.error,
            null,
            "OK",
          );
        } catch (_) {
          Utility.showMessage("Failed to load earnings vault", MessageType.error, null, "OK");
        }
      }
    } catch (e) {
      log("Error fetching earnings vault: $e");
    } finally {
      isEarningsLoading = false;
      update();
    }
  }

  /// Driver Earnings Withdrawal
  Future<void> withdrawEarningsController(
    int amount, {
    String method = "Bank",
    Map<String, dynamic>? bankDetails,
    String? upiId,
  }) async {
    if (amount <= 0) {
      Utility.showMessage("Please enter a valid amount", MessageType.error, null, "OK");
      return;
    }

    final double availableBalance = walletBalance;
    if (amount > availableBalance) {
      Utility.showMessage(
        "Amount cannot exceed your wallet balance (₹${availableBalance.toStringAsFixed(0)})",
        MessageType.error,
        null,
        "OK",
      );
      return;
    }

    isWithdrawLoading = true;
    update();

    try {
      final response = await homeUsecases.withdrawEarnings(
        amount: amount,
        method: method,
        bankDetails: bankDetails,
        upiId: upiId,
        showLoader: true,
      );

      isWithdrawLoading = false;
      update();

      if (!response.hasError) {
        final decoded = jsonDecode(response.data);
        if (decoded['IsSuccess'] == true || decoded['isSuccess'] == true) {
          withdrawAmountController.clear();
          withdrawUpiController.clear();
          Get.back(); // close withdraw screen
          await fetchEarningsVaultData(); // refresh
          fetchDashboardSafe(showLoader: false);
          Utility.showMessage(
            decoded['Message'] ?? "Withdrawal request submitted successfully",
            MessageType.success,
            null,
            "OK",
          );
        } else {
          Utility.showMessage(
            decoded['Message'] ?? decoded['message'] ?? "Failed to process withdrawal",
            MessageType.error,
            null,
            "OK",
          );
        }
      } else {
        try {
          final decoded = jsonDecode(response.data);
          Utility.showMessage(
            decoded['Message'] ?? decoded['message'] ?? "Withdrawal failed",
            MessageType.error,
            null,
            "OK",
          );
        } catch (_) {
          Utility.showMessage("Withdrawal failed", MessageType.error, null, "OK");
        }
      }
    } catch (e) {
      isWithdrawLoading = false;
      update();
      Utility.showMessage("Something went wrong. Please try again.", MessageType.error, null, "OK");
    }
  }

  /// Initiate Driver Wallet Top-Up
  Future<void> initiateWalletTopUp(int amount) async {
    if (amount <= 0) {
      Utility.showMessage("Please enter a valid amount", MessageType.error, null, "OK");
      return;
    }

    isTopUpLoading = true;
    update();

    try {
      final response = await homeUsecases.createTopUpOrder(
        amount: amount,
        showLoader: true,
      );

      log("TopUp Order Response: ${response.data}");

      if (!response.hasError) {
        final decoded = jsonDecode(response.data);
        if (decoded['IsSuccess'] == true || decoded['isSuccess'] == true) {
          final dataMap = decoded['Data'] ?? decoded['data'];
          final orderData = dataMap != null ? dataMap['order'] : null;
          if (orderData != null) {
            final String orderId = orderData['id'];
            final int orderAmount = orderData['amount'];

            _openTopUpCheckout(orderId, orderAmount);
            return;
          }
        }
        isTopUpLoading = false;
        update();
        Utility.showMessage(
          decoded['Message'] ?? decoded['message'] ?? "Failed to create order",
          MessageType.error,
          null,
          "OK",
        );
      } else {
        isTopUpLoading = false;
        update();
        try {
          final decoded = jsonDecode(response.data);
          Utility.showMessage(
            decoded['Message'] ?? decoded['message'] ?? "Failed to initiate top-up",
            MessageType.error,
            null,
            "OK",
          );
        } catch (_) {
          Utility.showMessage("Failed to initiate top-up", MessageType.error, null, "OK");
        }
      }
    } catch (e) {
      isTopUpLoading = false;
      update();
      Utility.showMessage("Error initiating top-up: $e", MessageType.error, null, "OK");
    }
  }

  void _openTopUpCheckout(String orderId, int amountInPaise) {
    currentRazorpayOrderId = orderId;
    isTopUpLoading = false;
    update();

    final repo = Get.find<Repository>();
    final userDetails = repo.getStringValue(LocalKeys.userDetails);
    String mobile = "";
    String email = "";
    if (userDetails.isNotEmpty) {
      try {
        final parsed = jsonDecode(userDetails);
        mobile = parsed['driver_mobile'] ?? parsed['mobile'] ?? "";
        email = parsed['email'] ?? "";
      } catch (_) {}
    }

    var options = {
      'key': StringConstants.razorPayKey,
      'amount': amountInPaise,
      'name': 'Bam Bam Cabs',
      'description': 'Driver Wallet Top-Up',
      'order_id': orderId,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': mobile,
        'email': email,
      },
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      Utility.showMessage("Error opening payment: $e", MessageType.error, null, "OK");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    log("Payment Success: ${response.paymentId}, order: ${response.orderId}");

    final effectiveOrderId = (response.orderId != null && response.orderId!.isNotEmpty)
        ? response.orderId!
        : (currentRazorpayOrderId ?? "");

    final apiResponse = await homeUsecases.verifyTopUpPayment(
      razorpayOrderId: effectiveOrderId,
      razorpayPaymentId: response.paymentId ?? "",
      razorpaySignature: response.signature ?? "",
      showLoader: true,
    );

    log("TopUp Verify Response: ${apiResponse.data}");

    if (!apiResponse.hasError) {
      final decoded = jsonDecode(apiResponse.data);
      if (decoded['IsSuccess'] == true || decoded['isSuccess'] == true) {
        topUpAmountController.clear();
        await fetchEarningsVaultData();
        fetchDashboardSafe(showLoader: false);
        Get.back(); // Return from topup screen
        Utility.showMessage("Wallet Top-up Successful!", MessageType.success, null, "OK");
      } else {
        Utility.showMessage(
          decoded['Message'] ?? decoded['message'] ?? "Payment Verification Failed",
          MessageType.error,
          null,
          "OK",
        );
      }
    } else {
      Utility.showMessage("Payment verification failed on server", MessageType.error, null, "OK");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    log("Payment Error: code ${response.code}, message: ${response.message}");
    Utility.showMessage(
      "Payment Failed: ${response.message ?? 'Unknown error'}",
      MessageType.error,
      null,
      "OK",
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    log("External Wallet: ${response.walletName}");
  }
}
