import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:bam_bam_driver/domain/services/audio_service.dart';
import 'package:bam_bam_driver/domain/services/native_overlay_service.dart';
import 'package:bam_bam_driver/app/pages/home_screen/home_controller.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_controller.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_binding.dart';
import 'package:bam_bam_driver/app/pages/home_screen/Screens/new_ride_popup.dart';

/// Dedicated reusable alert card for INDIVIDUAL Drivers.
/// Features dynamic data from Firebase / Socket, accurate fare calculation
/// (Total Fare ₹3779, Commission 20% ₹756, Net Earning ₹3023),
/// and clean Ola/Uber-style layout.
class IndividualRideAlertCard extends StatefulWidget {
  final Map<String, dynamic> rideData;
  final String requestId;

  const IndividualRideAlertCard({
    super.key,
    required this.rideData,
    required this.requestId,
  });

  @override
  State<IndividualRideAlertCard> createState() => _IndividualRideAlertCardState();
}

class _IndividualRideAlertCardState extends State<IndividualRideAlertCard> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 30 seconds if driver takes no action
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        print("🕒 [DEBUG] IndividualRideAlertCard auto-dismissing after 30s: ${widget.requestId}");
        AudioService.stopRingtone();
        NativeOverlayService.disableLockScreenAlert();
        if (Get.isDialogOpen == true) Get.back();
      }
    });
  }

  @override
  void dispose() {
    final String bookingId = widget.rideData['_id']?.toString() ??
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
    AudioService.stopRingtone();
    NativeOverlayService.disableLockScreenAlert();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── 1. Extract & Resolve Ride Data ──────────────────────────────────────
    Map<String, dynamic> resolvedData = Map<String, dynamic>.from(widget.rideData);
    if (resolvedData.containsKey('booking_details') && resolvedData['booking_details'] is Map) {
      resolvedData = Map<String, dynamic>.from(resolvedData['booking_details']);
    } else if (resolvedData.containsKey('rideDetails') && resolvedData['rideDetails'] is Map) {
      resolvedData = Map<String, dynamic>.from(resolvedData['rideDetails']);
    } else if (resolvedData.containsKey('booking') && resolvedData['booking'] is Map) {
      resolvedData = Map<String, dynamic>.from(resolvedData['booking']);
    }

    final travel = (resolvedData['travelDetailsId'] != null && resolvedData['travelDetailsId'] is Map)
        ? Map<String, dynamic>.from(resolvedData['travelDetailsId'])
        : (resolvedData['travel_details'] != null && resolvedData['travel_details'] is Map)
            ? Map<String, dynamic>.from(resolvedData['travel_details'])
            : resolvedData;

    // ── 2. Trip Type & Package ──────────────────────────────────────────────
    final String tripType = (travel['trip_type'] ??
            resolvedData['trip_type'] ??
            resolvedData['tripType'] ??
            "Oneway")
        .toString();

    final String packageStr = (travel['package'] ??
            resolvedData['package'] ??
            resolvedData['rental_package'] ??
            "N/A")
        .toString();

    // ── 3. Pickup & Drop Addresses ──────────────────────────────────────────
    String source = (travel['pickup_address'] ??
            resolvedData['pickup_address'] ??
            resolvedData['source'] ??
            resolvedData['pickup'] ??
            "N/A")
        .toString();

    String destination = "N/A";
    dynamic rawDrop = travel['drop_address'] ??
        resolvedData['drop_address'] ??
        resolvedData['destination'] ??
        resolvedData['drop'];
    if (rawDrop is List && rawDrop.isNotEmpty) {
      destination = rawDrop.join(" -> ");
    } else if (rawDrop != null) {
      destination = rawDrop.toString();
    }

    // ── 4. Date & Time ──────────────────────────────────────────────────────
    final String date = (travel['pickup_date'] ??
            travel['date'] ??
            resolvedData['pickup_date'] ??
            resolvedData['date'] ??
            "")
        .toString();

    final String time = (travel['pickup_time'] ??
            travel['time'] ??
            resolvedData['pickup_time'] ??
            resolvedData['time'] ??
            "")
        .toString();

    String formattedDate = date;
    if (date.isNotEmpty && date != "null" && date != "N/A") {
      try {
        DateTime parsedDate = DateTime.parse(date);
        formattedDate = DateFormat("dd MMM yyyy").format(parsedDate);
      } catch (_) {
        formattedDate = date;
      }
    }

    String formattedTime = time;
    if (time.isNotEmpty && time != "null" && time != "N/A") {
      try {
        if (time.toLowerCase().contains("am") || time.toLowerCase().contains("pm")) {
          formattedTime = time;
        } else {
          final parts = time.split(":");
          if (parts.length >= 2) {
            final h = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            if (h != null && m != null) {
              final now = DateTime.now();
              final dt = DateTime(now.year, now.month, now.day, h, m);
              formattedTime = DateFormat("hh:mm a").format(dt);
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

    // ── 5. Accurate Fare & Commission Calculation ───────────────────────────
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

    // Commission Percentage (Default 20% for Individual drivers)
    num commissionPercent = num.tryParse(
      (resolvedData['payment_summary']?['commission_percent'] ??
       resolvedData['bambam_commission_percent'] ??
       resolvedData['commission_percent'] ??
       20).toString(),
    ) ?? 20;

    // Commission Amount
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

    // Guard: If fareVal was accidentally mapped to driver net earnings (e.g. 3023), restore total fare = net + commission
    if (driverNet > 0 && commissionAmount > 0 && fareVal <= driverNet) {
      fareVal = driverNet + commissionAmount;
    } else if (fareVal > 0 && commissionAmount <= 0) {
      commissionAmount = ((fareVal * commissionPercent) / 100).round();
    }

    // Always ensure Net Earning = fareVal - commissionAmount (e.g. 3779 - 756 = 3023)
    if (fareVal > 0 && commissionAmount > 0) {
      driverNet = (fareVal - commissionAmount).clamp(0, double.infinity);
    } else if (driverNet <= 0 && fareVal > 0) {
      driverNet = (fareVal - commissionAmount).clamp(0, double.infinity);
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
      } else if (storedLoginType.isEmpty) {
        final userDetailsStr = repo.getStringValue(LocalKeys.userDetails);
        if (userDetailsStr.isNotEmpty) {
          final ud = jsonDecode(userDetailsStr);
          if (ud is Map && ud['login_type']?.toString().toLowerCase().trim() == 'company') {
            isCompanyDriver = true;
          }
        }
      }
      if (!isCompanyDriver && Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        if (homeCtrl.loginType.toLowerCase().trim() == 'company' || !homeCtrl.isIndividual) {
          isCompanyDriver = true;
        }
      }
      if (!isCompanyDriver && Get.isRegistered<TripController>()) {
        final tripCtrl = Get.find<TripController>();
        if (tripCtrl.isCompany || tripCtrl.loginType.toLowerCase().trim() == 'company') {
          isCompanyDriver = true;
        }
      }
      if (!isCompanyDriver && storedLoginType != 'individual') {
        if (resolvedData['login_type']?.toString().toLowerCase().trim() == 'company' ||
            resolvedData['is_company_driver'] == true ||
            resolvedData['is_assigned_by_vendor'] == true ||
            (resolvedData['vendor_id'] != null && resolvedData['vendor_id'].toString().isNotEmpty && resolvedData['vendor_id'].toString() != 'null')) {
          isCompanyDriver = true;
        }
      }
    } catch (_) {}

    // ── 6. UI Card Dialog ───────────────────────────────────────────────────
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      elevation: 16,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Row ──────────────────────────────────────────────
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
                        onTap: () {
                          AudioService.stopRingtone();
                          NativeOverlayService.disableLockScreenAlert();
                          Get.back();
                        },
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

              // ── Route Information Card ────────────────────────────────────
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
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 16, color: ColorsValue.appColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateStr.isNotEmpty ? dateStr : "Immediate departure",
                            style: Styles.txtBlackColorW50014.copyWith(
                              fontSize: 12,
                              color: Colors.black87,
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

              // ── Fare Display Card ───────────
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
                // ── BamBam Commission & Net Earning Breakdown Card (Only for Individual Drivers) ──
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
                          Text("BamBam Commission (${commissionPercent.toStringAsFixed(0)}%)", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
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

              // ── Action Buttons Row (Dismiss, Details, Accept) ───────────────
              Row(
                children: [
                  // Dismiss button
                  Expanded(
                    flex: 3,
                    child: OutlinedButton(
                      onPressed: () {
                        AudioService.stopRingtone();
                        NativeOverlayService.disableLockScreenAlert();
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

                        AudioService.stopRingtone();
                        NativeOverlayService.disableLockScreenAlert();
                        Get.back(closeOverlays: true);
                        final String bookingId = resolvedData['_id']?.toString() ??
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

                        AudioService.stopRingtone();
                        NativeOverlayService.disableLockScreenAlert();
                        Get.back();

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
                            'driver_net_earnings': driverNet,
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
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color dotColor = Colors.grey,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: dotColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Styles.txtBlackColorW50014.copyWith(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
