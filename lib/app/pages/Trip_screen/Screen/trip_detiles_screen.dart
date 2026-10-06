import 'dart:developer';

import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/Screen/trip_invoice_screen.dart';

class TripDetilesScreen extends StatelessWidget {
  const TripDetilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // read args (set by RouteManagement.gotoTripDetilesScreen)
    final args = (Get.arguments is Map)
        ? Map<String, dynamic>.from(Get.arguments)
        : <String, dynamic>{};
    final bool isComplectTrip =
        args['isComplectTrip'] ?? args['isCompleteTrip'] ?? false;
    // accept both keys for safety
    final String? tripId =
        (args['trip_id'] ?? args['tripId'] ?? args['tripIdString'])?.toString();

    return GetBuilder<TripController>(
      initState: (_) {
        // schedule fetch after first frame to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (tripId != null && tripId.isNotEmpty) {
            final ctrl = Get.find<TripController>();
            if (isComplectTrip) {
              ctrl.fetchHistoryDetail(tripId);
            } else {
              ctrl.fetchTripDetails(tripId);
            }
          }
        });
      },
      builder: (controller) {
        // show loader if details are being fetched
        if (controller.isLoadingDetails) {
          return Scaffold(
            appBar: AppBarWidget(onTapBack: null, title: "Details "),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final trip = controller.tripDetails ?? <String, dynamic>{};
        log(controller.tripDetails.toString());
        final booking = trip['booking_id'] ?? {};
        final travel = booking['travelDetailsId'] ?? {};
        //  final confirm = trip['booking_id']['vendor_status'] ?? {};
        final tripType = travel['trip_type'] ?? '';
        final bookingId =
            booking['booking_id'] ?? (booking['booking_id'] ?? '');
        final pickup = travel['from'] ?? '';
        final drop = (travel['to'] is List && travel['to'].isNotEmpty)
            ? travel['to'][0]
            : '';

        final pickupDateRaw = travel['date'] ?? '';
        final pickupDate =
            (pickupDateRaw != null && pickupDateRaw.toString().isNotEmpty)
            ? DateFormat(
                'dd-MM-yyyy',
              ).format(DateTime.parse(pickupDateRaw.toString()))
            : '—';
        final pickupTime = travel['pickup_time'] ?? '—';

        // traveler/user info fallback
        // traveler/user info fallback
        final dynamic userRaw =
            booking['userId'] ??
            booking['traveler'] ??
            booking['traveler_info'];

        // Ensure user is a Map to avoid String indexing errors
        final Map user = (userRaw is Map) ? userRaw : {};

        String travelerName = '—';
        if (user['full_name'] != null &&
            user['full_name'].toString().isNotEmpty) {
          travelerName = user['full_name'].toString();
        } else if (booking['traveler_name'] != null &&
            booking['traveler_name'].toString().isNotEmpty) {
          travelerName = booking['traveler_name'].toString();
        } else if (travel['traveler_name'] != null &&
            travel['traveler_name'].toString().isNotEmpty) {
          travelerName = travel['traveler_name'].toString();
        }

        // Deep search / extra fallback
        if (travelerName == '—' || travelerName.isEmpty) {
          // Check inside travelDetailsId if it exists in booking
          final td = booking['travelDetailsId'];
          if (td is Map && td['traveler_name'] != null) {
            travelerName = td['traveler_name'].toString();
          }
        }

        String travelerMobile = '—';
        if (user['phone_no'] != null &&
            user['phone_no'].toString().isNotEmpty) {
          travelerMobile = user['phone_no'].toString();
        } else if (booking['traveler_mobile'] != null &&
            booking['traveler_mobile'].toString().isNotEmpty) {
          travelerMobile = booking['traveler_mobile'].toString();
        } else if (travel['traveler_mobile'] != null &&
            travel['traveler_mobile'].toString().isNotEmpty) {
          travelerMobile = travel['traveler_mobile'].toString();
        }

        // Deep search / extra fallback for mobile
        if (travelerMobile == '—' || travelerMobile.isEmpty) {
          final td = booking['travelDetailsId'];
          if (td is Map && td['traveler_mobile'] != null) {
            travelerMobile = td['traveler_mobile'].toString();
          }
        }

        log(
          "TripDetailsScreen: travelerName=$travelerName, mobile=$travelerMobile",
        );
        log("Booking Keys: ${booking.keys.toList()}");

        final pickupAddress =
            booking['pickup_address'] ?? travel['pickup_address'] ?? pickup;
        String dropAddress = pickup; // final fallback

        if (booking['drop_address'] != null &&
            booking['drop_address'].toString().isNotEmpty) {
          dropAddress = booking['drop_address'].toString();
        } else if (travel['drop_address'] is List &&
            (travel['drop_address'] as List).isNotEmpty) {
          dropAddress = (travel['drop_address'] as List).first.toString();
        } else if (travel['drop_address'] != null &&
            travel['drop_address'] is String &&
            travel['drop_address'].toString().isNotEmpty) {
          dropAddress = travel['drop_address'].toString();
        }

        final isVendorConfirmed =
            trip['ride_status']?.toString().toLowerCase() == 'confirmed';

        final bool isTripCompletedStatus =
            trip['ride_status']?.toString().toLowerCase() == 'completed' ||
            trip['status']?.toString().toLowerCase() == 'completed';
        final bool hasReview = booking['review'] != null && 
            (booking['review']['comments'] != null || booking['review']['rating'] != null);
        final bool showReviewSection = (isTripCompletedStatus || isComplectTrip) && hasReview;

        final startKm = (trip['start_km'] ?? '').toString();
        final endKm = (trip['end_km'] ?? '').toString();
        final double startKmNum = double.tryParse(startKm) ?? 0.0;
        final double endKmNum = double.tryParse(endKm) ?? 0.0;
        double actualKmNum = double.tryParse((trip['actual_distance_km'] ?? trip['traveled_km'] ?? trip['total_distance_km'])?.toString() ?? '') ?? 0.0;
        if (actualKmNum <= 0.0 && endKmNum > startKmNum) {
          actualKmNum = endKmNum - startKmNum;
        }
        final actualDistance = (actualKmNum > 0) ? actualKmNum.toStringAsFixed(0) : (trip['actual_distance_km']?.toString() ?? '');
        final hasRideDistance = (startKmNum > 0) || (endKmNum > 0) || (actualKmNum > 0) || isComplectTrip || isTripCompletedStatus;

        final statusStr = (trip['ride_status'] ?? trip['status'] ?? '').toString().toLowerCase().trim();
        final bool isOngoing = (statusStr == 'ongoing' || statusStr == 'started');
        final bool isPending = (statusStr == 'pending');
        final bool isRideCompleted = (statusStr == 'completed') || isComplectTrip || isTripCompletedStatus;

        return Scaffold(
          appBar: AppBarWidget(onTapBack: () => Get.back(), title: "Details "),
          backgroundColor: ColorsValue.appBg,
          // --- BOTTOM NAVIGATION BAR -----------------------
          bottomNavigationBar: Padding(
            padding: Dimens.edgeInsets20_30_20_30,
            child: Builder(
              builder: (_) {
                print('TripDetilesScreen status: $statusStr, isOngoing: $isOngoing, isPending: $isPending, isCompleted: $isRideCompleted');

                if (isRideCompleted) {
                  return const SizedBox.shrink();
                } else if (isOngoing) {
                        // ✅ CASE 2: Ongoing Trip — show "End Trip"
                        return Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                onPressed: () {
                                  RouteManagement.gotoVehicalMiterScreen(
                                    isStartTrip: false,
                                  );
                                },
                                text: "End Trip",
                                backgroundColor: ColorsValue.appColor,
                                textStyle: Styles.txtBlackColorW60016,
                              ),
                            ),
                          ],
                        );
                      } else if (isPending) {
                        // ✅ CASE 3: Pending Ride Request — show "Reject" and "Accept & Pay"
                        final reqId = (args['request_id'] ?? args['requestId'] ?? trip['request_id'] ?? '').toString();
                        return Row(
                          spacing: Dimens.twenty,
                          children: [
                            Expanded(
                              child: CustomButton(
                                onPressed: () {
                                  if (reqId.isNotEmpty) {
                                    controller.rejectRideRequest(reqId);
                                  } else {
                                    Get.back();
                                  }
                                },
                                text: "Reject",
                                backgroundColor: Colors.red.shade100,
                                textStyle: Styles.txtBlackColorW60016.copyWith(color: Colors.red.shade700),
                              ),
                            ),
                            Expanded(
                              child: CustomButton(
                                onPressed: () {
                                  if (reqId.isNotEmpty) {
                                    controller.acceptRideRequest(reqId);
                                  } else {
                                    Utility.showMessage("Request ID not found", MessageType.error, null, "OK");
                                  }
                                },
                                text: "Accept & Pay",
                                backgroundColor: Colors.green.shade700,
                                textStyle: Styles.whiteColorW60016,
                              ),
                            ),
                          ],
                        );
                      } else {
                        // ✅ CASE 4: Assigned / Confirmed / D & V Allocated (Not Started)
                        final bool canStart = _isStartTripAllowed(pickupDateRaw, pickupTime);

                        // If Individual Driver: hide "Cancel Trip" and only show "Start Trip"
                        bool isDriverIndividual = controller.isIndividual;
                        try {
                          final storedType = Get.find<Repository>()
                              .getStringValue(LocalKeys.loginType)
                              .toLowerCase()
                              .trim();
                          if (storedType == 'individual') isDriverIndividual = true;
                          if (storedType == 'company') isDriverIndividual = false;
                        } catch (_) {}

                        if (isDriverIndividual) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!canStart)
                                _buildStartTripRestrictionNote(pickupTime, pickupDate),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      onPressed: canStart
                                          ? () {
                                              final tId = trip['_id']?.toString() ?? '';
                                              if (tId.isNotEmpty) {
                                                controller.startRide(tId);
                                              }
                                              RouteManagement.gotoTriptrackingScreen(
                                                isStartTrip: true,
                                                tripId: tId,
                                              );
                                            }
                                          : () {
                                              Utility.showMessage(
                                                "Trip can only be started 5 minutes before scheduled pickup time ($pickupTime).",
                                                MessageType.information,
                                                null,
                                                "OK",
                                              );
                                            },
                                      text: "Start Trip",
                                      backgroundColor: canStart
                                          ? ColorsValue.appColor
                                          : Colors.grey.shade400,
                                      textStyle: Styles.txtBlackColorW60016,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }

                        // For Company Driver: show both "Start Trip" and "Cancel Trip"
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!canStart)
                              _buildStartTripRestrictionNote(pickupTime, pickupDate),
                            Row(
                              spacing: Dimens.twenty,
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    onPressed: canStart
                                        ? () {
                                            final tId = trip['_id']?.toString() ?? '';
                                            if (tId.isNotEmpty) {
                                              controller.startRide(tId);
                                            }
                                            RouteManagement.gotoTriptrackingScreen(
                                              isStartTrip: true,
                                              tripId: tId,
                                            );
                                          }
                                        : () {
                                            Utility.showMessage(
                                              "Trip can only be started 5 minutes before scheduled pickup time ($pickupTime).",
                                              MessageType.information,
                                              null,
                                              "OK",
                                            );
                                          },
                                    text: "Start Trip",
                                    backgroundColor: canStart
                                        ? ColorsValue.appColor
                                        : Colors.grey.shade400,
                                    textStyle: Styles.txtBlackColorW60016,
                                  ),
                                ),
                                Expanded(
                                  child: CustomButton(
                                    onPressed: () async {
                                  Utility.showLoader();
                                  await controller.fetchCancellationReasons();
                                  Utility.closeLoader();

                                  if (context.mounted) {
                                    String selectedReasonId = '';
                                    final TextEditingController descController = TextEditingController();

                                    showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (BuildContext sheetCtx) {
                                        return StatefulBuilder(
                                          builder: (BuildContext builderCtx, StateSetter setSheetState) {
                                            return GestureDetector(
                                              onTap: () => FocusScope.of(builderCtx).unfocus(),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: ColorsValue.whiteColor,
                                                  borderRadius: const BorderRadius.only(
                                                    topLeft: Radius.circular(20),
                                                    topRight: Radius.circular(20),
                                                  ),
                                                ),
                                                child: SingleChildScrollView(
                                                  physics: const BouncingScrollPhysics(),
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom: MediaQuery.of(builderCtx).viewInsets.bottom + 20,
                                                      left: 20,
                                                      right: 20,
                                                      top: 20,
                                                    ),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "Cancel Trip".tr,
                                                          style: Styles.txtBlackColorW70020,
                                                        ),
                                                        Dimens.boxHeight10,
                                                        Text(
                                                          "Please select a reason for cancelling this trip.".tr,
                                                          style: Styles.txtG5ColorsW40014,
                                                        ),
                                                        Dimens.boxHeight20,
                                                        if (controller.isLoadingReasons)
                                                          const Center(
                                                            child: CircularProgressIndicator(),
                                                          )
                                                        else if (controller.cancellationReasons.isEmpty)
                                                          Text(
                                                            "No cancellation reasons available.".tr,
                                                            style: Styles.txtG6ColorW40014,
                                                          )
                                                        else
                                                          Container(
                                                            constraints: const BoxConstraints(maxHeight: 200),
                                                            child: ListView.builder(
                                                              shrinkWrap: true,
                                                              itemCount: controller.cancellationReasons.length,
                                                              itemBuilder: (context, index) {
                                                                final reason = controller.cancellationReasons[index];
                                                                final id = reason['_id']?.toString() ?? '';
                                                                final text = reason['cancellation_reason']?.toString() ?? '';

                                                                return RadioListTile<String>(
                                                                  title: Text(
                                                                    text.tr,
                                                                    style: Styles.txtBlackColorW50016,
                                                                  ),
                                                                  value: id,
                                                                  groupValue: selectedReasonId,
                                                                  activeColor: ColorsValue.redColor,
                                                                  contentPadding: EdgeInsets.zero,
                                                                  onChanged: (String? value) {
                                                                    setSheetState(() {
                                                                      selectedReasonId = value ?? '';
                                                                    });
                                                                  },
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        Dimens.boxHeight20,
                                                        CustomTextFormField(
                                                          style: Styles.txtBlackColorW50016,
                                                          hintText: "Enter details here...".tr,
                                                          isBorder: true,
                                                          isTitle: true,
                                                          maxLines: 3,
                                                          textEditingController: descController,
                                                          title: "Additional Notes".tr,
                                                          hintStyle: Styles.txtG7Colors40014,
                                                          titleStyle: Styles.txtG6ColorW40014,
                                                        ),
                                                        Dimens.boxHeight20,
                                                        Row(
                                                          spacing: Dimens.ten,
                                                          children: [
                                                            Expanded(
                                                              child: CustomButton(
                                                                onPressed: () => Navigator.pop(builderCtx),
                                                                text: "Go Back".tr,
                                                                isColor: false,
                                                                isBorder: true,
                                                                textStyle: Styles.txtBlackColorW50016,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: CustomButton(
                                                                onPressed: selectedReasonId.isEmpty
                                                                    ? null
                                                                    : () async {
                                                                        final success = await controller.cancelTrip(
                                                                          vendorRequestId: trip['_id']?.toString() ?? '',
                                                                          cancellationReasonId: selectedReasonId,
                                                                          description: descController.text,
                                                                        );
                                                                        if (success) {
                                                                          if (builderCtx.mounted) {
                                                                            Navigator.pop(builderCtx); // Close sheet
                                                                          }
                                                                          // Refresh data and go home
                                                                          controller.fetchAssignedTrips();
                                                                          controller.fetchRideRequests();
                                                                          RouteManagement.gotoHomeScreen(); // Go home
                                                                        }
                                                                      },
                                                                text: "Confirm Cancel".tr,
                                                                backgroundColor: selectedReasonId.isEmpty
                                                                    ? ColorsValue.borderColors
                                                                    : ColorsValue.redColor,
                                                                textStyle: selectedReasonId.isEmpty
                                                                    ? Styles.txtBlackColorW50016.copyWith(color: ColorsValue.txtG7Color)
                                                                    : Styles.whiteColorW60016,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Dimens.boxHeight20,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  }
                                },
                                text: "Cancel Trip",
                                backgroundColor: ColorsValue.redColor,
                                textStyle: Styles.whiteColorW60016,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

          // ------------
          body: ListView(
            padding: Dimens.edgeInsets20,
            physics: const BouncingScrollPhysics(),
            children: [
              Text("Trip Details", style: Styles.txtBlackColorW60016),
              Dimens.boxHeight16,
              Container(
                width: Get.width,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  color: ColorsValue.l4CB,
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                ),
                child: Padding(
                  padding: Dimens.edgeInsets20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            spacing: Dimens.two,
                            children: [
                              Text("Trip Type", style: Styles.txtG6ColorW40014),
                              Text(tripType, style: Styles.txtBlackColorW50016),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            spacing: Dimens.two,
                            children: [
                              Text(
                                "Booking ID",
                                style: Styles.txtG6ColorW40014,
                              ),
                              Text(
                                bookingId,
                                style: Styles.txtBlackColorW50016,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Dimens.boxHeight20,
                      (() {
                        final bool isLocal = tripType.toString().toLowerCase().contains('local');
                        final bool isRoundTrip = tripType.toString().toLowerCase().contains('round');
                        final String returnDate = _resolveReturnDate(booking, travel);
                        final String returnTime = _resolveReturnTime(booking, travel);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // From Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(AssetConstants.ic_location, height: Dimens.twentyFour),
                                Dimens.boxWidth12,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text("Pickup Address", style: Styles.txtG5ColorsW40014),
                                          _buildOpenMapButton(pickupAddress),
                                        ],
                                      ),
                                      Dimens.boxHeight4,
                                      Text(pickupAddress, style: Styles.txtBlackColorW50016),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Vertical Dash Connecting From -> To
                            Padding(
                              padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
                              child: Dash(
                                direction: Axis.vertical,
                                length: 24,
                                dashLength: 4,
                                dashColor: ColorsValue.appColor,
                              ),
                            ),

                            // To (or Package for Local)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(AssetConstants.ic_location, height: Dimens.twentyFour),
                                Dimens.boxWidth12,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(isLocal ? "Package" : "Drop Address", style: Styles.txtG5ColorsW40014),
                                          if (!isLocal) _buildOpenMapButton(dropAddress),
                                        ],
                                      ),
                                      Dimens.boxHeight4,
                                      Text(
                                        isLocal ? _resolvePackage(booking, travel) : dropAddress,
                                        style: Styles.txtBlackColorW50016,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Date and Time (brought BELOW "To")
                            Dimens.boxHeight14,
                            Padding(
                              padding: const EdgeInsets.only(left: 36),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Pickup Date & Time
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        color: ColorsValue.appColor,
                                        size: Dimens.twenty,
                                      ),
                                      Dimens.boxWidth8,
                                      Text(pickupDate, style: Styles.txtG6ColorW40014),
                                      Dimens.boxWidth16,
                                      SvgPicture.asset(
                                        AssetConstants.ic_clcok,
                                        colorFilter: ColorFilter.mode(
                                          ColorsValue.appColor,
                                          BlendMode.srcIn,
                                        ),
                                        height: Dimens.twenty,
                                      ),
                                      Dimens.boxWidth8,
                                      Text(pickupTime, style: Styles.txtG6ColorW40014),
                                    ],
                                  ),

                                  // Return Date & Time for Round Trip
                                  if (isRoundTrip && (returnDate.isNotEmpty || returnTime.isNotEmpty)) ...[
                                    Dimens.boxHeight8,
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.event_repeat_rounded,
                                          color: ColorsValue.appColor,
                                          size: Dimens.twenty,
                                        ),
                                        Dimens.boxWidth8,
                                        Text(
                                          returnDate.isNotEmpty ? "Return: $returnDate" : "Return: $pickupDate",
                                          style: Styles.txtG6ColorW40014,
                                        ),
                                        if (returnTime.isNotEmpty) ...[
                                          Dimens.boxWidth16,
                                          SvgPicture.asset(
                                            AssetConstants.ic_clcok,
                                            colorFilter: ColorFilter.mode(
                                              ColorsValue.appColor,
                                              BlendMode.srcIn,
                                            ),
                                            height: Dimens.twenty,
                                          ),
                                          Dimens.boxWidth8,
                                          Text(returnTime, style: Styles.txtG6ColorW40014),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      })(),
                      Dimens.boxHeight15,
                    ],
                  ),
                ),
              ),

              Dimens.boxHeight20,
              Text("Car Details", style: Styles.txtBlackColorW60016),
              Dimens.boxHeight16,
              // Example: show vehicle brand / type if available
              Container(
                decoration: BoxDecoration(
                  color: ColorsValue.l4CB,
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: Dimens.edgeInsets20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Dimens.two,
                    children: [
                      (() {
                        final Map<String, dynamic> vehicleObj = (trip['vehicle_id'] is Map)
                            ? Map<String, dynamic>.from(trip['vehicle_id'])
                            : ((booking['vehicle_id'] is Map)
                                ? Map<String, dynamic>.from(booking['vehicle_id'])
                                : ((travel['vehicleId'] is Map)
                                    ? Map<String, dynamic>.from(travel['vehicleId'])
                                    : ((trip['vehicle_details'] is Map)
                                        ? Map<String, dynamic>.from(trip['vehicle_details'])
                                        : <String, dynamic>{})));

                        String vehicleCategory = 'Vehicle';
                        if (vehicleObj['vehicle_type'] is Map) {
                          vehicleCategory = vehicleObj['vehicle_type']['name']?.toString() ?? 'Vehicle';
                        } else if (vehicleObj['vehicle_type'] != null && vehicleObj['vehicle_type'].toString().isNotEmpty) {
                          vehicleCategory = vehicleObj['vehicle_type'].toString();
                        } else if (travel['exploreId'] is Map && travel['exploreId']['name'] != null) {
                          vehicleCategory = travel['exploreId']['name'].toString();
                        } else if (travel['vehicle_name'] != null && travel['vehicle_name'].toString().isNotEmpty) {
                          vehicleCategory = travel['vehicle_name'].toString();
                        } else if (travel['vehicleName'] != null && travel['vehicleName'].toString().isNotEmpty) {
                          vehicleCategory = travel['vehicleName'].toString();
                        }

                        String brandName = (vehicleObj['brand_name'] ??
                                vehicleObj['make'] ??
                                vehicleObj['model'] ??
                                travel['vehicle_name'] ??
                                travel['vehicleName'] ??
                                '')
                            .toString()
                            .trim();

                        if (brandName.isEmpty || brandName.toLowerCase() == 'unknown' || brandName.toLowerCase() == 'null') {
                          brandName = vehicleCategory != 'Vehicle' ? vehicleCategory : 'Standard Cab';
                        }

                        final String vehiclePlate = (vehicleObj['vehicle_number'] ??
                                vehicleObj['registration_number'] ??
                                '')
                            .toString()
                            .trim();

                        final String? vehiclePhoto = (vehicleObj['vehicle_type'] is Map)
                            ? vehicleObj['vehicle_type']['vehicle_photo']?.toString()
                            : (vehicleObj['front_image']?.toString() ?? vehicleObj['front_photo']?.toString());

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicleCategory,
                                    style: Styles.txtG7Colors40014,
                                  ),
                                  Dimens.boxHeight3,
                                  Text(
                                    brandName,
                                    style: Styles.txtBlackColorW60016,
                                  ),
                                  if (vehiclePlate.isNotEmpty && vehiclePlate != 'null') ...[
                                    Dimens.boxHeight3,
                                    Text(
                                      vehiclePlate,
                                      style: Styles.txtG7Colors40014,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (vehiclePhoto != null && vehiclePhoto.isNotEmpty && vehiclePhoto != 'null')
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  vehiclePhoto,
                                  height: Dimens.fourtyEight,
                                  width: Dimens.fourtyEight,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(),
                                ),
                              ),
                          ],
                        );
                      })(),
                      Dimens.boxHeight8,
                    ],
                  ),
                ),
              ),

              Dimens.boxHeight20,
              Text("Traveler Details", style: Styles.txtBlackColorW60016),
              Dimens.boxHeight16,
              Container(
                decoration: BoxDecoration(
                  color: ColorsValue.l4CB,
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: Dimens.edgeInsets20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isOngoing) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("Pickup Address", style: Styles.txtG6ColorW40014),
                            _buildOpenMapButton(pickupAddress),
                          ],
                        ),
                        Dimens.boxHeight4,
                        Text(pickupAddress, style: Styles.txtBlackColorW50016),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("Drop Address", style: Styles.txtG6ColorW40014),
                            _buildOpenMapButton(dropAddress),
                          ],
                        ),
                        Dimens.boxHeight4,
                        Text(dropAddress, style: Styles.txtBlackColorW50016),
                        Dimens.boxHeight12,
                        Text("Pickup Address", style: Styles.txtG6ColorW40014),
                        Dimens.boxHeight2,
                        Text(pickupAddress, style: Styles.txtBlackColorW50016),
                      ],
                      Dimens.boxHeight16,
                      Text("Name", style: Styles.txtG6ColorW40014),
                      Dimens.boxHeight2,
                      Row(
                        children: [
                          Image.asset(
                            AssetConstants.person,
                            height: Dimens.twentyFour,
                          ),
                          Dimens.boxWidth8,
                          Text(travelerName, style: Styles.txtBlackColorW50016),
                        ],
                      ),
                      Dimens.boxHeight16,
                      Text("Mobile No.", style: Styles.txtG6ColorW40014),
                      Dimens.boxHeight2,
                      Text(travelerMobile, style: Styles.txtBlackColorW50016),
                    ],
                  ),
                ),
              ),

              if (hasRideDistance) ...[
                Dimens.boxHeight20,
                Text("Ride Distance & Meter", style: Styles.txtBlackColorW60016),
                Dimens.boxHeight16,
                Container(
                  decoration: BoxDecoration(
                    color: ColorsValue.l4CB,
                    borderRadius: BorderRadius.circular(Dimens.twelve),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: Dimens.edgeInsets20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (startKmNum > 0) ...[
                          Text("Start Meter", style: Styles.txtG6ColorW40014),
                          Dimens.boxHeight2,
                          Text("$startKm km", style: Styles.txtBlackColorW50016),
                          Dimens.boxHeight16,
                        ],
                        if (endKmNum > 0) ...[
                          Text("End Meter", style: Styles.txtG6ColorW40014),
                          Dimens.boxHeight2,
                          Text("$endKm km", style: Styles.txtBlackColorW50016),
                          Dimens.boxHeight16,
                        ],
                        Text("Total Distance", style: Styles.txtG6ColorW40014),
                        Dimens.boxHeight2,
                        Text(
                          actualDistance.isNotEmpty ? "$actualDistance km" : "—",
                          style: Styles.txtBlackColorW60016.copyWith(color: ColorsValue.appColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // ✅ TRIP FARE SUMMARY & BAMBAM COMMISSION BREAKDOWN
              if (isComplectTrip || isTripCompletedStatus || hasRideDistance) ...[
                Dimens.boxHeight20,
                _buildTripFareSummaryAndCommission(context, trip),
              ],

              if (showReviewSection) ...[
                Dimens.boxHeight20,
                Text(
                  "Your Review",
                  style: Styles.txtBlackColorW60016.copyWith(
                    color: ColorsValue.appColor,
                  ),
                ),
                Dimens.boxHeight16,
                // Review card (if review exists inside booking)
                Container(
                  decoration: BoxDecoration(
                    color: ColorsValue.l4CB,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(Dimens.twelve),
                  ),
                  child: Padding(
                    padding: Dimens.edgeInsets20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              AssetConstants.usera,
                              height: Dimens.twentyFour,
                            ),
                            Dimens.boxWidth8,
                            Text(
                              travelerName,
                              style: Styles.txtBlackColorW50016,
                            ),
                          ],
                        ),
                        Dimens.boxHeight8,
                        Text(
                          (booking['review'] != null &&
                                  booking['review']['comments'] != null)
                              ? booking['review']['comments'].toString()
                              : 'No reviews yet',
                          style: Styles.txtG6ColorW40014.copyWith(
                            fontSize: Dimens.twelve,
                          ),
                        ),
                        Dimens.boxHeight8,
                        Row(
                          spacing: Dimens.three,
                          children: List.generate(
                            5,
                            (i) => Icon(
                              Icons.star_purple500_outlined,
                              color: ColorsValue.appColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              Dimens.boxHeight30,
            ],
          ),
        );
      },
    );
  }

  Widget buildVehicleImage(Map vehicle) {
    final String? imageUrl = vehicle['vehicle_type']?['vehicle_photo']
        ?.toString();

    if (imageUrl == null || imageUrl.isEmpty) {
      return SizedBox(height: Dimens.fourtyEight, width: Dimens.fourtyEight);
    }

    return Image.network(
      imageUrl,
      height: Dimens.fourtyEight,
      width: Dimens.fourtyEight,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          SizedBox(height: Dimens.fourtyEight, width: Dimens.fourtyEight),
    );
  }

  Widget _buildTripFareSummaryAndCommission(
    BuildContext context,
    Map<String, dynamic> trip,
  ) {
    final booking = trip['booking_id'] is Map ? trip['booking_id'] : {};
    final travel = booking['travelDetailsId'] is Map
        ? booking['travelDetailsId']
        : (trip['travelDetailsId'] is Map ? trip['travelDetailsId'] : {});
    final payment = booking['payment_summary'] is Map
        ? booking['payment_summary']
        : (trip['payment_summary'] is Map ? trip['payment_summary'] : {});
    final fareBreakdown = booking['fare_breakdown'] is Map
        ? booking['fare_breakdown']
        : (trip['fare_breakdown'] is Map
            ? trip['fare_breakdown']
            : (travel['fare_summary'] is Map ? travel['fare_summary'] : {}));

    String formatP(dynamic val) {
      if (val == null) return "0.00";
      final numVal = double.tryParse(val.toString()) ?? 0.0;
      return numVal.toStringAsFixed(2);
    }

    final double baseFare = double.tryParse((fareBreakdown['base_fare'] ??
                travel['fare_summary']?['base_fare'] ??
                travel['final_price'] ??
                0)
            .toString()) ??
        0.0;
    final double perKmRate = double.tryParse(
            (fareBreakdown['per_km_price'] ?? travel['per_km_price'] ?? trip['per_km_price'] ?? booking['per_km_price'] ?? 0)
                .toString()) ??
        0.0;
    final double extraKmCharge = double.tryParse(
            (fareBreakdown['extra_km_charge'] ?? trip['extra_fare'] ?? 0).toString()) ??
        0.0;
    double extraKm =
        double.tryParse((fareBreakdown['extra_km'] ?? trip['extra_km'] ?? 0).toString()) ?? 0.0;
    if (extraKm <= 0 && extraKmCharge > 0 && perKmRate > 0) {
      extraKm = extraKmCharge / perKmRate;
    }
    final double waitingCharge = double.tryParse((fareBreakdown['waiting_charge'] ??
                booking['waiting_charge'] ??
                trip['waiting_charge'] ??
                0)
            .toString()) ??
        0.0;
    final int waitingMins = int.tryParse((fareBreakdown['waiting_minutes'] ??
                booking['total_waiting_minutes'] ??
                trip['total_waiting_minutes'] ??
                0)
            .toString()) ??
        0;

    // Special services (Carrier, Pet, etc.)
    double specialServicesTotal = 0.0;
    final List<Map<String, dynamic>> servicesList = [];
    if (travel['special_services'] is List &&
        (travel['special_services'] as List).isNotEmpty) {
      for (final s in (travel['special_services'] as List)) {
        if (s is Map) {
          final amt =
              double.tryParse((s['price'] ?? s['amount'] ?? 0).toString()) ??
                  0.0;
          specialServicesTotal += amt;
          servicesList.add({
            'name': s['service_name'] ?? s['name'] ?? 'Extra Service',
            'amount': amt,
          });
        }
      }
    }
    if (specialServicesTotal <= 0 &&
        fareBreakdown['special_services_charge'] != null) {
      specialServicesTotal = double.tryParse(
              fareBreakdown['special_services_charge'].toString()) ??
          0.0;
    }

    final double discount = double.tryParse((fareBreakdown['discount_amount'] ??
                travel['fare_summary']?['coupon_discount'] ??
                payment['discount'] ??
                0)
            .toString()) ??
        0.0;
    final double gstAmount = double.tryParse((fareBreakdown['gst_amount'] ??
                travel['fare_summary']?['gst_amount'] ??
                payment['gst_applied']?['gst_amount'] ??
                booking['gst_amount'] ??
                0)
            .toString()) ??
        0.0;
    final double tollCharges = double.tryParse(
            (fareBreakdown['toll_charges'] ?? 0).toString()) ??
        0.0;
    final double parkingCharges = double.tryParse(
            (fareBreakdown['parking_charges'] ?? 0).toString()) ??
        0.0;
    final double additionalCharges = double.tryParse(
            (fareBreakdown['additional_charges'] ?? 0).toString()) ??
        0.0;

    // Total Fare
    double totalFare = double.tryParse((fareBreakdown['final_payable_amount'] ??
                payment['total_booking_price'] ??
                payment['total_fare'] ??
                payment['total_payment'] ??
                travel['fare_summary']?['total_fare'] ??
                0)
            .toString()) ??
        0.0;
    if (totalFare <= 0) {
      totalFare = baseFare +
          extraKmCharge +
          specialServicesTotal +
          waitingCharge +
          tollCharges +
          parkingCharges +
          additionalCharges +
          gstAmount -
          discount;
    }

    // Commission: Individual driver receives 20% deduction for BamBam
    double commissionAmount = 0.0;
    double commissionPercent = 20.0;

    if (payment['commission_amount'] != null &&
        double.tryParse(payment['commission_amount'].toString()) != null &&
        (double.tryParse(payment['commission_amount'].toString()) ?? 0.0) > 0) {
      commissionAmount =
          double.tryParse(payment['commission_amount'].toString()) ?? 0.0;
      if (totalFare > 0) {
        commissionPercent = (commissionAmount / totalFare) * 100;
      }
    } else if (payment['commission_percent'] != null &&
        double.tryParse(payment['commission_percent'].toString()) != null &&
        (double.tryParse(payment['commission_percent'].toString()) ?? 0.0) > 0) {
      commissionPercent =
          double.tryParse(payment['commission_percent'].toString()) ?? 20.0;
      commissionAmount = (totalFare * commissionPercent) / 100.0;
    } else {
      commissionAmount = totalFare * 0.20;
    }

    final bool extraCommPaid = trip['extra_commission_paid'] == true ||
        booking['extra_commission_paid'] == true ||
        payment['extra_commission_paid'] == true;
    if (extraCommPaid && (trip['final_commission_amount'] != null || booking['final_commission_amount'] != null || payment['final_commission_amount'] != null)) {
      final finalComm = double.tryParse((trip['final_commission_amount'] ?? booking['final_commission_amount'] ?? payment['final_commission_amount']).toString()) ?? 0.0;
      if (finalComm > 0) {
        commissionAmount = finalComm;
        if (totalFare > 0) {
          commissionPercent = (commissionAmount / totalFare) * 100;
        }
      }
    }

    // Driver Net Fare (Your Net Earning)
    double driverNetFare = totalFare - commissionAmount;
    if (driverNetFare < 0) driverNetFare = 0.0;

    final double advancePaid = double.tryParse(
            (payment['advance_paid'] ?? 0).toString()) ??
        0.0;
    final double amountToCollect = double.tryParse(
            (payment['amount_collect_from_customer'] ?? 0).toString()) ??
        0.0;
    final String paymentMode =
        (payment['payment_mode'] ?? booking['payment_mode'] ?? 'Cash')
            .toString();

    final String bookingMongoId =
        (booking['_id'] ?? trip['booking_id'] ?? trip['_id'] ?? '').toString();

    // Total Fare (Before Tax)
    double totalFareBeforeTax = baseFare + extraKmCharge + specialServicesTotal + waitingCharge;
    if (totalFareBeforeTax <= 0) {
      totalFareBeforeTax = totalFare - gstAmount - additionalCharges - tollCharges - parkingCharges;
      if (totalFareBeforeTax <= 0) totalFareBeforeTax = totalFare;
    }

    double gstPercent = 5.0;
    if (fareBreakdown['gst_percentage'] != null &&
        double.tryParse(fareBreakdown['gst_percentage'].toString()) != null &&
        (double.tryParse(fareBreakdown['gst_percentage'].toString()) ?? 0) > 0) {
      gstPercent = double.tryParse(fareBreakdown['gst_percentage'].toString()) ?? 5.0;
    } else if (booking['gst_percentage'] != null &&
        double.tryParse(booking['gst_percentage'].toString()) != null &&
        (double.tryParse(booking['gst_percentage'].toString()) ?? 0) > 0) {
      gstPercent = double.tryParse(booking['gst_percentage'].toString()) ?? 5.0;
    }

    // Additional charges details list (e.g. ABC, night charge, state tax, etc.)
    final List<Map<String, dynamic>> additionalDetailsList = [];
    final rawAddDetails = fareBreakdown['additional_charges_details'] ??
        booking['additional_charges_details'] ??
        trip['additional_charges_details'] ??
        fareBreakdown['extra_charges_details'] ??
        booking['extra_charges_details'];

    if (rawAddDetails is List && rawAddDetails.isNotEmpty) {
      for (final item in rawAddDetails) {
        if (item is Map) {
          final title = (item['title'] ?? item['name'] ?? item['reason'] ?? 'Additional Charge').toString();
          final amt = double.tryParse((item['amount'] ?? item['price'] ?? 0).toString()) ?? 0.0;
          if (amt > 0) {
            additionalDetailsList.add({
              'title': title,
              'amount': amt,
            });
          }
        }
      }
    }

    // Determine login type (Company Driver vs Individual Driver)
    final String storedLoginType = Get.find<Repository>()
        .getStringValue(LocalKeys.loginType)
        .toLowerCase()
        .trim();
    final bool isCompany = storedLoginType == 'company' ||
        (Get.isRegistered<TripController>() &&
            (Get.find<TripController>().isCompany ||
                Get.find<TripController>().loginType.toLowerCase().trim() == 'company'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. TRIP FARE SUMMARY (Detailed Invoice Card matching Image 2) ──
        Text("Trip Fare Summary", style: Styles.txtBlackColorW60016),
        Dimens.boxHeight16,
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: ColorsValue.whiteColor,
            border: Border.all(color: ColorsValue.borderColors),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: ColorsValue.appColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Detailed Invoice",
                      style: Styles.txtBlackColorW60016.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 12),

                _buildFareRow("Base Fare", "₹${formatP(baseFare)}"),
                if (extraKmCharge > 0 || extraKm > 0)
                  _buildFareRow(
                    extraKm > 0 && perKmRate > 0
                        ? "Extra KMs (${extraKm.toStringAsFixed(0)} km @ ₹${perKmRate.toStringAsFixed(0)}/km)"
                        : (extraKm > 0
                            ? "Extra KMs (${extraKm.toStringAsFixed(0)} km)"
                            : (perKmRate > 0
                                ? "Extra KMs Charge (₹${perKmRate.toStringAsFixed(0)}/KM)"
                                : "Extra KMs Charge")),
                    "₹${formatP(extraKmCharge)}",
                  ),

                // Special Services & Sub-breakdown (matching Image 2)
                if (specialServicesTotal > 0 || servicesList.isNotEmpty) ...[
                  _buildFareRow(
                    "Special Services",
                    "₹${formatP(specialServicesTotal)}",
                    isBold: true,
                  ),
                  for (final s in servicesList)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "➔ ${s['name']}",
                            style: Styles.txtG6ColorW40014.copyWith(fontSize: 12),
                          ),
                          Text(
                            "₹${formatP(s['amount'])}",
                            style: Styles.txtG6ColorW40014.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],

                // Waiting Charges (placed BEFORE Total Fare Before Tax)
                if (waitingCharge > 0)
                  _buildFareRow(
                    "Waiting Charges${waitingMins > 0 ? ' ($waitingMins mins)' : ''}",
                    "₹${formatP(waitingCharge)}",
                  ),

                // Coupon Discount
                if (discount > 0)
                  _buildFareRow(
                    "Coupon Discount",
                    "-₹${formatP(discount)}",
                    valueColor: ColorsValue.txtGreenColor,
                  ),

                // Total Fare (Before Tax)
                const SizedBox(height: 6),
                Divider(height: 1, thickness: 1, color: ColorsValue.borderColors),
                const SizedBox(height: 6),
                _buildFareRow(
                  "Total Fare (Before Tax)",
                  "₹${formatP(totalFareBeforeTax)}",
                  isBold: true,
                  valueColor: ColorsValue.appColor,
                ),

                // GST
                if (gstAmount > 0)
                  _buildFareRow(
                    "GST (${gstPercent.toStringAsFixed(0)}%)",
                    "₹${formatP(gstAmount)}",
                  ),

                // Toll & Parking
                if (tollCharges > 0)
                  _buildFareRow("Toll Charges", "₹${formatP(tollCharges)}"),
                if (parkingCharges > 0)
                  _buildFareRow("Parking Charges", "₹${formatP(parkingCharges)}"),

                // Additional Charges (detailed breakdown)
                if (additionalDetailsList.isNotEmpty) ...[
                  for (final ch in additionalDetailsList)
                    _buildFareRow(
                      ch['title'].toString(),
                      "₹${formatP(ch['amount'])}",
                    ),
                ] else if (additionalCharges > 0)
                  _buildFareRow(
                    "Additional Charges",
                    "₹${formatP(additionalCharges)}",
                  ),

                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 15),

                // Total Amount Highlight Card (matching Image 2 with "Total Amount")
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorsValue.yellocolorsCB,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Total Amount",
                          style: Styles.txtBlackColorW70018.copyWith(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "₹${formatP(totalFare)}",
                        style: Styles.txtBlackColorW70020.copyWith(
                          color: ColorsValue.txtGreenColor,
                          fontSize: 19,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Dimens.boxHeight20,

        // ── 2. BAMBAM COMMISSION & DRIVER EARNING CARD (ONLY FOR INDIVIDUAL DRIVER) ──
        if (!isCompany) ...[
          Text("Commission & Your Earning", style: Styles.txtBlackColorW60016),
          Dimens.boxHeight16,
          Container(
            decoration: BoxDecoration(
              color: ColorsValue.l4CB,
              borderRadius: BorderRadius.circular(Dimens.twelve),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: Dimens.edgeInsets20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFareRow(
                    "BamBam Commission (${commissionPercent.toStringAsFixed(0)}%)",
                    "-₹${formatP(commissionAmount)}",
                    isBold: true,
                    valueColor: Colors.red.shade700,
                  ),

                  const SizedBox(height: 10),

                  // Net Earning Highlight Card (ONLY "Your Net Earning")
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade400, width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Your Net Earning",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        Text(
                          "₹${formatP(driverNetFare)}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (advancePaid > 0 || amountToCollect > 0) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 6),
                    if (advancePaid > 0)
                      _buildFareRow("Advance Paid by Customer", "₹${formatP(advancePaid)}"),
                    if (amountToCollect > 0)
                      _buildFareRow(
                        "Cash to Collect from Customer",
                        "₹${formatP(amountToCollect)}",
                        valueColor: Colors.deepOrange,
                      ),
                    _buildFareRow("Payment Mode", paymentMode),
                  ],
                ],
              ),
            ),
          ),
          Dimens.boxHeight20,
        ],

        // ── 3. DOWNLOAD INVOICE BUTTON (Visible for both Company and Individual drivers) ──
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE85923),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
            label: const Text(
              "Download Invoice",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              final idToUse = bookingMongoId.isNotEmpty
                  ? bookingMongoId
                  : (booking['booking_id'] ?? trip['_id'] ?? '').toString();
              final pdfUrl =
                  "https://apis.bambamcabs.com/driver/application/booking/invoice/$idToUse";
              Utility.showMessage(
                "Opening invoice download in browser...",
                MessageType.information,
                null,
                "OK",
              );
              Utility.launchLinkURL(pdfUrl);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFareRow(
    String label,
    String value, {
    bool isBold = false,
    bool isHighlight = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: isBold
                  ? Styles.txtBlackColorW70016
                  : (isHighlight
                      ? Styles.txtBlackColorW60014
                      : Styles.txtG6ColorW40014),
            ),
          ),
          Text(
            value,
            style: isBold
                ? Styles.txtBlackColorW70018.copyWith(
                    color: valueColor ?? ColorsValue.appColor)
                : Styles.txtBlackColorW50016.copyWith(
                    color: valueColor ?? Colors.black87),
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

  String _resolveReturnDate(
    dynamic bookingRaw,
    dynamic travelRaw,
  ) {
    final Map<String, dynamic> booking =
        (bookingRaw is Map) ? Map<String, dynamic>.from(bookingRaw) : {};
    final Map<String, dynamic> travel =
        (travelRaw is Map) ? Map<String, dynamic>.from(travelRaw) : {};

    final returnDateRaw = travel['return_date'] ?? booking['return_date'];
    if (returnDateRaw == null || returnDateRaw.toString().isEmpty) {
      return '';
    }

    try {
      return DateFormat(
        'dd-MM-yyyy',
      ).format(DateTime.parse(returnDateRaw.toString()));
    } catch (_) {
      return returnDateRaw.toString();
    }
  }

  String _resolveReturnTime(
    dynamic bookingRaw,
    dynamic travelRaw,
  ) {
    final Map<String, dynamic> booking =
        (bookingRaw is Map) ? Map<String, dynamic>.from(bookingRaw) : {};
    final Map<String, dynamic> travel =
        (travelRaw is Map) ? Map<String, dynamic>.from(travelRaw) : {};

    final returnTimeRaw = travel['return_time'] ?? booking['return_time'];
    if (returnTimeRaw == null || returnTimeRaw.toString().isEmpty) {
      return '';
    }
    return returnTimeRaw.toString();
  }

  Widget _buildOpenMapButton(String address) {
    return InkWell(
      onTap: () => Utility.openMap(address),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: ColorsValue.appColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions, size: 14, color: Colors.black),
            SizedBox(width: 4),
            Text(
              "Open Map",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Determines whether Start Trip is allowed (at most 5 minutes before scheduled pickup time)
  bool _isStartTripAllowed(dynamic dateRaw, dynamic timeRaw) {
    if (dateRaw == null || dateRaw.toString().isEmpty || dateRaw.toString() == '—') return true;
    try {
      DateTime datePart = DateTime.parse(dateRaw.toString());
      int h = 0;
      int m = 0;
      if (timeRaw != null && timeRaw.toString().isNotEmpty && timeRaw.toString() != '—') {
        final timeStr = timeRaw.toString().trim();
        final match = RegExp(r'(\d+):(\d+)\s*(am|pm)?', caseSensitive: false).firstMatch(timeStr);
        if (match != null) {
          h = int.parse(match.group(1)!);
          m = int.parse(match.group(2)!);
          final mod = match.group(3)?.toLowerCase();
          if (mod == 'pm' && h < 12) h += 12;
          if (mod == 'am' && h == 12) h = 0;
        }
      }
      final pickupDateTime = DateTime(datePart.year, datePart.month, datePart.day, h, m);
      final allowedTime = pickupDateTime.subtract(const Duration(minutes: 5));
      final now = DateTime.now();
      return !now.isBefore(allowedTime);
    } catch (_) {
      return true;
    }
  }

  /// Displays an informational banner above the Start Trip button when trip cannot be started yet
  Widget _buildStartTripRestrictionNote(String pickupTime, String pickupDate) {
    final timeStr = (pickupTime.isNotEmpty && pickupTime != '—') ? pickupTime : '';
    final dateStr = (pickupDate.isNotEmpty && pickupDate != '—') ? ' on $pickupDate' : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD180)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE65100), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Note: You can start this trip only 5 minutes before the scheduled pickup time ($timeStr$dateStr).",
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB7410E),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
