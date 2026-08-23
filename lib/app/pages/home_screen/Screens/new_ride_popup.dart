import 'dart:convert';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bam_bam_driver/app/theme/colors_value.dart';
import 'package:bam_bam_driver/app/theme/styles.dart';
import 'package:bam_bam_driver/app/theme/dimens.dart';
import 'package:bam_bam_driver/domain/services/audio_service.dart';
import 'package:bam_bam_driver/app/pages/home_screen/home_controller.dart';
import 'package:bam_bam_driver/app/utils/utility.dart';
import 'package:bam_bam_driver/app/navigators/routes_management.dart';
import 'package:bam_bam_driver/domain/domain.dart';

class NewRidePopup extends StatefulWidget {
  final Map<String, dynamic> rideData;
  final String requestId;

  // Global tracker to prevent duplicate popups for the same ride across all services
  static final Set<String> activeBookingIds = {};

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
    // Auto-dismiss after 15 seconds if still showing
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        print(
          "🕒 [DEBUG] NewRidePopup auto-dismissing after 15s: ${widget.requestId}",
        );
        Get.back();
      }
    });
  }

  @override
  void dispose() {
    // 1. Clean up global tracker
    final String bookingId =
        widget.rideData['_id']?.toString() ??
        widget.rideData['bookingId']?.toString() ??
        widget.rideData['booking_id']?.toString() ??
        "";
    if (bookingId.isNotEmpty) {
      NewRidePopup.activeBookingIds.remove(bookingId);
    }

    // 2. Ensure sound stops when widget is removed from tree
    AudioService.stopRingtone();
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

    // Date extraction
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
    final String dateStr = time.isNotEmpty ? "$rawDate at $time" : rawDate;

    // Fare extraction
    String rawFare = '0';
    if (resolvedData['payment_summary'] != null &&
        resolvedData['payment_summary'] is Map &&
        resolvedData['payment_summary']['final_trip_fare'] != null) {
      rawFare = resolvedData['payment_summary']['final_trip_fare'].toString();
    } else if (resolvedData['total_fare'] != null) {
      rawFare = resolvedData['total_fare'].toString();
    } else if (travel['fare_summary'] != null &&
        travel['fare_summary'] is Map &&
        travel['fare_summary']['total_fare'] != null) {
      rawFare = travel['fare_summary']['total_fare'].toString();
    } else if (travel['base_fare'] != null) {
      rawFare = travel['base_fare'].toString();
    }
    final String fare = "₹$rawFare";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, ColorsValue.appColor.withOpacity(0.05)],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorsValue.appColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_taxi_rounded,
                      color: ColorsValue.appColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.green, size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "New Ride Request",
                          style: Styles.txtBlackColorW60016.copyWith(
                            color: ColorsValue.appColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fare,
                        style: Styles.txtBlackColorW70020.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Ride Summary (only show if data is available)
                  if (source != "N/A" || destination != "N/A")
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.pin_drop,
                            "PICKUP",
                            source,
                            dotColor: Colors.green,
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                height: 20,
                                child: VerticalDivider(
                                  color: Colors.grey,
                                  thickness: 1,
                                ),
                              ),
                            ),
                          ),
                          _buildInfoRow(
                            Icons.location_on,
                            "DROP OFF",
                            destination,
                            dotColor: Colors.red,
                          ),
                          const Divider(height: 32),
                          _buildInfoRow(Icons.calendar_today, "DATE", dateStr),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "Incoming Ride Request",
                        style: Styles.txtBlackColorW50016,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back(closeOverlays: true);
                            final String bookingId =
                                resolvedData['_id']?.toString() ??
                                resolvedData['bookingId']?.toString() ??
                                resolvedData['booking_id']?.toString() ??
                                "";

                            final repo = Get.find<Repository>();
                            final currentLoginType =
                                repo.getStringValue(LocalKeys.loginType);

                            if (currentLoginType == 'individual') {
                              RouteManagement.gotoAssignedTripScreen();
                            } else {
                              if (bookingId.isNotEmpty) {
                                RouteManagement.gotoTripDetilesScreen(
                                  isComplectTrip: false,
                                  tripId: bookingId,
                                );
                              } else {
                                Utility.showMessage(
                                  "Trip details not available",
                                  MessageType.error,
                                  null,
                                  'OK',
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: ColorsValue.appColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "View Details",
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
          // Close Button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                Get.back();
              },
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
}
