import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bam_bam_driver/app/theme/colors_value.dart';
import 'package:bam_bam_driver/app/theme/styles.dart';
import 'package:bam_bam_driver/app/theme/dimens.dart';
import 'package:bam_bam_driver/domain/services/audio_service.dart';
import 'package:bam_bam_driver/domain/services/native_overlay_service.dart';
import 'package:bam_bam_driver/app/pages/home_screen/home_controller.dart';
import 'package:bam_bam_driver/app/utils/utility.dart';
import 'package:bam_bam_driver/app/navigators/routes_management.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_controller.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_binding.dart';

class NewRidePopup extends StatefulWidget {
  final Map<String, dynamic> rideData;
  final String requestId;

  // Global tracker to prevent duplicate popups for the same ride across all services
  static final Set<String> activeBookingIds = {};
  static final Set<String> dismissedOrSeenBookingIds = {};

  const NewRidePopup({
    super.key,
    required this.rideData,
    required this.requestId,
  });

  @override
  State<NewRidePopup> createState() => _NewRidePopupState();
}

class _NewRidePopupState extends State<NewRidePopup> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 30 seconds if still showing
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        print(
          "🕒 [DEBUG] NewRidePopup auto-dismissing after 30s: ${widget.requestId}",
        );
        Get.back();
      }
    });
  }

  @override
  void dispose() {
    // 1. Clean up global tracker & mark as seen/dismissed so it never pops up again on refresh
    final String bookingId =
        widget.rideData['_id']?.toString() ??
        widget.rideData['bookingId']?.toString() ??
        widget.rideData['booking_id']?.toString() ??
        "";
    final String bNum = widget.rideData['booking_id']?.toString() ?? "";
    if (bookingId.isNotEmpty) {
      NewRidePopup.activeBookingIds.remove(bookingId);
      NewRidePopup.dismissedOrSeenBookingIds.add(bookingId);
    }
    if (widget.requestId.isNotEmpty) {
      NewRidePopup.activeBookingIds.remove(widget.requestId);
      NewRidePopup.dismissedOrSeenBookingIds.add(widget.requestId);
    }
    if (bNum.isNotEmpty) {
      NewRidePopup.dismissedOrSeenBookingIds.add(bNum);
    }

    // 2. Ensure sound stops when widget is removed from tree
    AudioService.stopRingtone();
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().stopRingtone();
    }

    // 3. Disable lockscreen alert flags so device stays locked normally
    NativeOverlayService.disableLockScreenAlert();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
      "🚀 [DEBUG] NewRidePopup building for requestId: ${widget.requestId}",
    );

    // 1. Resolve Data - handle nested structures
    Map<String, dynamic> resolvedData = Map<String, dynamic>.from(
      widget.rideData,
    );

    if (resolvedData['rideDetails'] != null) {
      final details = resolvedData['rideDetails'];
      if (details is String) {
        try {
          resolvedData = jsonDecode(details);
        } catch (e) {
          print("Error decoding rideDetails in Popup: $e");
        }
      } else if (details is Map) {
        resolvedData = Map<String, dynamic>.from(details);
      }
    } else if (resolvedData['booking_id'] is Map) {
      resolvedData = Map<String, dynamic>.from(resolvedData['booking_id']);
    } else if (resolvedData['booking_details'] is Map) {
      resolvedData = Map<String, dynamic>.from(resolvedData['booking_details']);
    }

    // 2. Data extraction safely
    final travelData = resolvedData['travelDetailsId'];
    final Map<String, dynamic> travel = (travelData is Map)
        ? Map<String, dynamic>.from(travelData)
        : {};

    final String source =
        travel['pickup_address']?.toString() ??
        resolvedData['source_city']?.toString() ??
        resolvedData['source']?.toString() ??
        resolvedData['pickup_address']?.toString() ??
        "N/A";

    final dynamic dropData =
        travel['drop_address'] ?? resolvedData['drop_address'];
    String destination = "N/A";
    if (dropData is List && dropData.isNotEmpty) {
      destination = dropData[0].toString();
    } else if (dropData != null && dropData is! List) {
      destination = dropData.toString();
    } else if (resolvedData['destination_city'] != null) {
      destination = resolvedData['destination_city'].toString();
    } else if (resolvedData['destination'] != null) {
      destination = resolvedData['destination'].toString();
    }

    final String tripType = (travel['trip_type'] ??
            resolvedData['trip_type'] ??
            'Oneway')
        .toString();
    final String packageStr = _resolvePackage(resolvedData, travel);

    // Vehicle extraction
    String vehicleName = "Standard Cab";
    if (travel['vehicleId'] is Map) {
      final v = travel['vehicleId'] as Map<String, dynamic>;
      vehicleName = (v['brand_name'] ?? v['vehicle_type']?['name'] ?? v['make'] ?? '').toString();
    }
    if (vehicleName.isEmpty && travel['exploreId'] is Map) {
      vehicleName = travel['exploreId']['name']?.toString() ?? '';
    }
    if (vehicleName.isEmpty && travel['vehicle_name'] != null) {
      vehicleName = travel['vehicle_name'].toString();
    }
    if (vehicleName.isEmpty && travel['vehicleName'] != null) {
      vehicleName = travel['vehicleName'].toString();
    }
    if (vehicleName.isEmpty && resolvedData['vehicle_name'] != null) {
      vehicleName = resolvedData['vehicle_name'].toString();
    }
    if (vehicleName.isEmpty || vehicleName == 'null') vehicleName = "Standard Cab";

    // Date extraction and formatting
    String rawDate =
        travel['pickup_date']?.toString() ??
        travel['date']?.toString() ??
        resolvedData['pickup_date']?.toString() ??
        resolvedData['date']?.toString() ??
        "N/A";

    if (rawDate != "N/A" && rawDate.contains("T")) {
      rawDate = rawDate.split("T")[0];
    }
    final String time =
        travel['pickup_time']?.toString() ??
        resolvedData['pickup_time']?.toString() ??
        "";

    String formattedDate = rawDate;
    if (rawDate != "N/A" && rawDate.isNotEmpty) {
      try {
        final parsed = DateTime.tryParse(rawDate);
        if (parsed != null) {
          formattedDate = DateFormat('dd MMM yyyy').format(parsed);
        }
      } catch (_) {
        formattedDate = rawDate;
      }
    }

    String formattedTime = time;
    if (time.isNotEmpty) {
      try {
        if (!time.toLowerCase().contains('am') && !time.toLowerCase().contains('pm')) {
          final timeParts = time.split(':');
          if (timeParts.length >= 2) {
            final hour = int.tryParse(timeParts[0]);
            final minute = int.tryParse(timeParts[1]);
            if (hour != null && minute != null) {
              final dummyDt = DateTime(2026, 1, 1, hour, minute);
              formattedTime = DateFormat('hh:mm a').format(dummyDt);
            }
          }
        }
      } catch (_) {
        formattedTime = time;
      }
    }

    final String dateStr = formattedTime.isNotEmpty
        ? "$formattedDate at $formattedTime"
        : formattedDate;

    // Fare extraction: Prioritize exact customer total fare
    num fareVal = 0;
    if (resolvedData['payment_summary'] != null &&
        resolvedData['payment_summary'] is Map &&
        resolvedData['payment_summary']['total_fare'] != null &&
        (num.tryParse(resolvedData['payment_summary']['total_fare'].toString()) ?? 0) > 0) {
      fareVal = num.tryParse(resolvedData['payment_summary']['total_fare'].toString()) ?? 0;
    } else if (resolvedData['total_fare'] != null &&
        (num.tryParse(resolvedData['total_fare'].toString()) ?? 0) > 0) {
      fareVal = num.tryParse(resolvedData['total_fare'].toString()) ?? 0;
    } else if (resolvedData['total_payment'] != null &&
        (num.tryParse(resolvedData['total_payment'].toString()) ?? 0) > 0) {
      fareVal = num.tryParse(resolvedData['total_payment'].toString()) ?? 0;
    } else if (travel['fare_summary'] != null &&
        travel['fare_summary'] is Map &&
        travel['fare_summary']['total_fare'] != null &&
        (num.tryParse(travel['fare_summary']['total_fare'].toString()) ?? 0) > 0) {
      fareVal = num.tryParse(travel['fare_summary']['total_fare'].toString()) ?? 0;
    } else if (travel['base_fare'] != null) {
      fareVal = num.tryParse(travel['base_fare'].toString()) ?? 0;
    }

    // ✅ Dynamic BamBam Commission extraction (Default: 20%)
    num commissionPercent = num.tryParse(
      (resolvedData['payment_summary']?['commission_percent'] ??
       resolvedData['bambam_commission_percent'] ??
       resolvedData['commission_percent'] ??
       20).toString(),
    ) ?? 20;

    num commissionAmount = num.tryParse(
      (resolvedData['payment_summary']?['commission_amount'] ??
       resolvedData['bambam_commission_amount'] ??
       resolvedData['commission_amount'] ??
       0).toString(),
    ) ?? 0;

    num driverNet = num.tryParse(
      (resolvedData['driver_net_earnings'] ??
       resolvedData['payment_summary']?['final_trip_fare'] ??
       0).toString(),
    ) ?? 0;

    // Guard: If fareVal accidentally held driver net earnings (e.g. 3023), restore total customer fare = net + commission
    if (driverNet > 0 && commissionAmount > 0 && fareVal <= driverNet) {
      fareVal = driverNet + commissionAmount;
    } else if (fareVal > 0 && commissionAmount <= 0) {
      commissionAmount = ((fareVal * commissionPercent) / 100).round();
    }

    if (driverNet <= 0 && fareVal > 0) {
      driverNet = (fareVal - commissionAmount).clamp(0, double.infinity);
    }

    if (fareVal <= 0 && driverNet > 0) {
      fareVal = driverNet + commissionAmount;
    }

    if (commissionPercent <= 0 && fareVal > 0 && commissionAmount > 0) {
      commissionPercent = ((commissionAmount / fareVal) * 100).round();
    }

    final String fare = "₹${fareVal.toStringAsFixed(0)}";

    // Determine if logged in driver is a Company Driver
    bool isCompanyDriver = false;
    try {
      final repo = Get.find<Repository>();
      final String storedLoginType = repo.getStringValue(LocalKeys.loginType).toLowerCase().trim();
      if (storedLoginType == 'company') {
        isCompanyDriver = true;
      }
      if (!isCompanyDriver && Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        if (homeCtrl.loginType.toLowerCase().trim() == 'company') {
          isCompanyDriver = true;
        }
      }
      if (!isCompanyDriver && Get.isRegistered<TripController>()) {
        final tripCtrl = Get.find<TripController>();
        if (tripCtrl.isCompany || tripCtrl.loginType.toLowerCase().trim() == 'company') {
          isCompanyDriver = true;
        }
      }
      if (!isCompanyDriver) {
        final userDetailsStr = repo.getStringValue(LocalKeys.userDetails);
        if (userDetailsStr.isNotEmpty) {
          final ud = jsonDecode(userDetailsStr);
          if (ud is Map && ud['login_type']?.toString().toLowerCase().trim() == 'company') {
            isCompanyDriver = true;
          }
        }
      }
      // If ride is assigned by vendor or specifies company login type (and user is not explicitly marked individual)
      if (!isCompanyDriver && storedLoginType != 'individual') {
        if (resolvedData['login_type']?.toString().toLowerCase().trim() == 'company' ||
            resolvedData['is_company_driver'] == true ||
            resolvedData['is_assigned_by_vendor'] == true ||
            (resolvedData['vendor_id'] != null && resolvedData['vendor_id'].toString().isNotEmpty && resolvedData['vendor_id'].toString() != 'null')) {
          isCompanyDriver = true;
        }
      }
    } catch (e) {
      print("Error detecting driver loginType in NewRidePopup: $e");
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      elevation: 12,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ColorsValue.appColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.local_taxi_rounded,
                              color: ColorsValue.appColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "New Ride Request",
                                style: Styles.txtBlackColorW60016.copyWith(
                                  color: ColorsValue.appColor,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Text(
                                  tripType,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCompanyDriver)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  fare,
                                  style: Styles.txtBlackColorW70020.copyWith(
                                    color: Colors.green.shade700,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  "Total Fare",
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => Get.back(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 18, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Route Card
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
                        _buildInfoRow(
                          Icons.pin_drop,
                          "PICKUP LOCATION",
                          source != "N/A" ? source : "Pickup address available in details",
                          dotColor: Colors.green,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 16,
                              child: VerticalDivider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                            ),
                          ),
                        ),
                        if (tripType.toLowerCase().contains('local'))
                          _buildInfoRow(
                            Icons.access_time_rounded,
                            "RENTAL PACKAGE",
                            packageStr != 'N/A' ? packageStr : (destination != "N/A" ? destination : "Local Rental"),
                            dotColor: Colors.blue,
                          )
                        else
                          _buildInfoRow(
                            Icons.location_on,
                            "DROP LOCATION",
                            destination != "N/A" ? destination : "Drop location available in details",
                            dotColor: Colors.red,
                          ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: ColorsValue.appColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade900,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ✅ Fare Display Card
                  if (isCompanyDriver)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total Trip Fare", style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                          Text("₹${fareVal.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                    )
                  else
                    // Only for Individual Drivers: Show Commission & Net Earning Breakdown
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total Trip Fare", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              Text("₹${fareVal.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text("BamBam Commission (${commissionPercent.toStringAsFixed(0)}%)", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                ],
                              ),
                              Text(
                                "- ₹${commissionAmount.toStringAsFixed(0)}",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Your Net Earning",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green.shade900),
                              ),
                              Text(
                                "₹${driverNet.toStringAsFixed(0)}",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),

                  // Action Buttons: Company Driver -> Reject & Accept | Individual Driver -> Dismiss, Details, Accept
                  if (isCompanyDriver)
                    Row(
                      children: [
                        // Reject button
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () {
                              Get.back();
                              AudioService.stopRingtone();
                              if (!Get.isRegistered<TripController>()) {
                                TripBinding().dependencies();
                              }
                              Get.find<TripController>().rejectRideRequest(widget.requestId);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.red.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Reject",
                              style: Styles.txtBlackColorW50014.copyWith(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Accept button
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: () async {
                              final unlocked = await NativeOverlayService.requestUnlockDevice();
                              if (!unlocked) return;

                              Get.back();
                              AudioService.stopRingtone();
                              if (!Get.isRegistered<TripController>()) {
                                TripBinding().dependencies();
                              }
                              final tripCtrl = Get.find<TripController>();
                              tripCtrl.acceptRideRequest(
                                widget.requestId,
                                fallbackData: {
                                  'booking_id': resolvedData['booking_id'] ?? resolvedData['_id'] ?? '',
                                  'trip_type': tripType,
                                  'pickup_address': source,
                                  'drop_address': destination,
                                  'total_fare': fareVal,
                                  'commission_percent': commissionPercent,
                                  'commission_amount': commissionAmount,
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.green.shade600,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Accept",
                              style: Styles.whiteColorW60016.copyWith(
                                fontSize: Dimens.fourteen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        // Dismiss button
                        Expanded(
                          flex: 3,
                          child: OutlinedButton(
                            onPressed: () {
                              Get.back();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Dismiss",
                              style: Styles.txtG5ColorsW40014,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Details button
                        Expanded(
                          flex: 3,
                          child: OutlinedButton(
                            onPressed: () async {
                              final unlocked = await NativeOverlayService.requestUnlockDevice();
                              if (!unlocked) return;

                              Get.back(closeOverlays: true);
                              final String bookingId =
                                  resolvedData['_id']?.toString() ??
                                  resolvedData['bookingId']?.toString() ??
                                  resolvedData['booking_id']?.toString() ??
                                  "";

                              if (bookingId.isNotEmpty) {
                                RouteManagement.gotoTripDetilesScreen(
                                  isComplectTrip: false,
                                  tripId: bookingId,
                                  requestId: widget.requestId,
                                );
                              } else {
                                Utility.showMessage(
                                  "Trip details not available",
                                  MessageType.error,
                                  null,
                                  'OK',
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: ColorsValue.appColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Details",
                              style: Styles.txtBlackColorW50014.copyWith(
                                color: ColorsValue.appColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Accept button
                        Expanded(
                          flex: 4,
                          child: ElevatedButton(
                            onPressed: () async {
                              final unlocked = await NativeOverlayService.requestUnlockDevice();
                              if (!unlocked) return;

                              Get.back();
                              AudioService.stopRingtone();
                              if (!Get.isRegistered<TripController>()) {
                                TripBinding().dependencies();
                              }
                              final tripCtrl = Get.find<TripController>();
                              tripCtrl.acceptRideRequest(
                                widget.requestId,
                                fallbackData: {
                                  'booking_id': resolvedData['booking_id'] ?? resolvedData['_id'] ?? '',
                                  'trip_type': tripType,
                                  'pickup_address': source,
                                  'drop_address': destination,
                                  'total_fare': fareVal,
                                  'commission_percent': commissionPercent,
                                  'commission_amount': commissionAmount,
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.green.shade600,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Accept",
                              style: Styles.whiteColorW60016.copyWith(
                                fontSize: Dimens.fourteen,
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
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? dotColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: dotColor ?? ColorsValue.appColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolvePackage(dynamic bookingRaw, dynamic travelRaw) {
    final Map<String, dynamic> booking =
        (bookingRaw is Map) ? Map<String, dynamic>.from(bookingRaw) : {};
    final Map<String, dynamic> travel =
        (travelRaw is Map) ? Map<String, dynamic>.from(travelRaw) : {};

    final pkg = travel['package'] ?? booking['package'];
    if (pkg != null &&
        pkg.toString().isNotEmpty &&
        pkg.toString() != 'N/A' &&
        pkg.toString() != 'null') {
      return pkg.toString();
    }

    final hours = travel['selected_hours'] ??
        booking['selected_hours'] ??
        travel['per_hour_price'] ??
        booking['per_hour_price'];
    final km = travel['selected_km'] ??
        booking['selected_km'] ??
        travel['upto_km'] ??
        booking['upto_km'] ??
        travel['km_included'] ??
        booking['km_included'];

    if (hours != null &&
        km != null &&
        hours.toString().isNotEmpty &&
        km.toString().isNotEmpty &&
        hours.toString() != '0' &&
        km.toString() != '0' &&
        hours.toString() != 'null' &&
        km.toString() != 'null') {
      return "${hours} hr / ${km} km";
    }

    if (travel['exploreId'] is Map) {
      final exp = travel['exploreId'] as Map<String, dynamic>;
      final expHours = exp['per_hour_price'];
      final expKm = exp['upto_km'];
      if (expHours != null &&
          expKm != null &&
          expHours.toString().isNotEmpty &&
          expKm.toString().isNotEmpty) {
        return "${expHours} hr / ${expKm} km";
      }
    }

    if (booking['exploreId'] is Map) {
      final exp = booking['exploreId'] as Map<String, dynamic>;
      final expHours = exp['per_hour_price'];
      final expKm = exp['upto_km'];
      if (expHours != null &&
          expKm != null &&
          expHours.toString().isNotEmpty &&
          expKm.toString().isNotEmpty) {
        return "${expHours} hr / ${expKm} km";
      }
    }

    if (travel['fare_summary'] is Map) {
      final fs = travel['fare_summary'] as Map<String, dynamic>;
      final incKm = fs['included_km'];
      if (hours != null && incKm != null) {
        return "${hours} hr / ${incKm} km";
      }
    }

    if (km != null &&
        km.toString().isNotEmpty &&
        km.toString() != '0' &&
        km.toString() != 'null') {
      return "${km} km";
    }

    return 'N/A';
  }
}
