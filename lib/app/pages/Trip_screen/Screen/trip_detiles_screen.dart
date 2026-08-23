import 'dart:developer';

import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
            trip['ride_status']?.toString().toLowerCase() == 'completed';
        final bool hasReview = booking['review'] != null && 
            (booking['review']['comments'] != null || booking['review']['rating'] != null);
        final bool showReviewSection = (isTripCompletedStatus || isComplectTrip) && hasReview;

        return Scaffold(
          appBar: AppBarWidget(onTapBack: () => Get.back(), title: "Details "),
          backgroundColor: ColorsValue.appBg,
          // --- BOTTOM NAVIGATION BAR -----------------------
          bottomNavigationBar: !isComplectTrip
              ? Padding(
                  padding: Dimens.edgeInsets20_30_20_30,
                  child: Builder(
                    builder: (_) {
                      // determine ride status
                      final isRideCompleted =
                          (trip['ride_status']?.toString().toLowerCase() ==
                          'completed');
                      print(
                        'isRideCompleteddddddddddd: ${trip['ride_status']}',
                      );
                      if (isRideCompleted) {
                        // ✅ CASE 1: Ride Completed — show only "Ride Completed"
                        return Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                onPressed: null, // disabled
                                text: "Ride Completed",
                                backgroundColor: ColorsValue.bulycolorsCB,
                                textStyle: Styles.txtBlackColorW60016,
                              ),
                            ),
                          ],
                        );
                      } else if (isVendorConfirmed) {
                        // ✅ CASE 2: Vendor Confirmed — show only "End Trip"
                        return Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                onPressed: () {
                                  final vendorId =
                                      trip['_id']?.toString() ?? '';
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
                      } else {
                        // ✅ CASE 3: Default — show "Start Trip" and "Cancel Trip"
                        return Row(
                          spacing: Dimens.twenty,
                          children: [
                            Expanded(
                              child: CustomButton(
                                onPressed: () {
                                  final tId = trip['_id']?.toString() ?? '';
                                  RouteManagement.gotoTriptrackingScreen(
                                    isStartTrip: true,
                                  );
                                },
                                text: "Start Trip",
                                backgroundColor: ColorsValue.appColor,
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
                        );
                      }
                    },
                  ),
                )
              : null,

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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                AssetConstants.ic_location,
                                height: Dimens.twentyFour,
                              ),
                              Padding(
                                padding: Dimens.edgeInsets8,
                                child: Dash(
                                  direction: Axis.vertical,
                                  length: 60,
                                  dashLength: 5,
                                  dashColor: ColorsValue.appColor,
                                ),
                              ),
                              Image.asset(
                                AssetConstants.ic_location,
                                height: Dimens.twentyFour,
                              ),
                            ],
                          ),
                          Dimens.boxWidth12,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pickup Address",
                                  style: Styles.txtG5ColorsW40014,
                                ),
                                Dimens.boxHeight4,
                                Text(
                                  pickupAddress,
                                  style: Styles.txtBlackColorW50016,
                                ),
                                Dimens.boxHeight4,
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_outlined,
                                      color: ColorsValue.appColor,
                                    ),
                                    Dimens.boxWidth8,
                                    Text(
                                      pickupDate,
                                      style: Styles.txtG6ColorW40014,
                                    ),
                                    Dimens.boxWidth16,
                                    SvgPicture.asset(
                                      AssetConstants.ic_clcok,
                                      color: ColorsValue.appColor,
                                      height: Dimens.twenty,
                                    ),
                                    Dimens.boxWidth8,
                                    Text(
                                      pickupTime,
                                      style: Styles.txtG6ColorW40014,
                                    ),
                                  ],
                                ),
                                Dimens.boxHeight30,
                                if (tripType.toString().toLowerCase().contains('local')) ...[
                                  Text(
                                    "Package",
                                    style: Styles.txtG5ColorsW40014,
                                  ),
                                  Dimens.boxHeight4,
                                  Text(
                                    (travel['package'] ?? booking['package'] ?? 'N/A').toString(),
                                    style: Styles.txtBlackColorW50016,
                                  ),
                                ] else ...[
                                  Text(
                                    "Drop Address",
                                    style: Styles.txtG5ColorsW40014,
                                  ),
                                  Dimens.boxHeight4,
                                  Text(
                                    dropAddress,
                                    style: Styles.txtBlackColorW50016,
                                  ),
                                  if (tripType.toString().toLowerCase().contains('round')) ...[
                                    Dimens.boxHeight8,
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month_outlined,
                                          color: ColorsValue.appColor,
                                        ),
                                        Dimens.boxWidth8,
                                        Text(
                                          (travel['return_date'] != null) ? DateFormat('dd-MM-yyyy').format(DateTime.parse(travel['return_date'].toString())) : '',
                                          style: Styles.txtG6ColorW40014,
                                        ),
                                        Dimens.boxWidth16,
                                        SvgPicture.asset(
                                          AssetConstants.ic_clcok,
                                          color: ColorsValue.appColor,
                                          height: Dimens.twenty,
                                        ),
                                        Dimens.boxWidth8,
                                        Text(
                                          travel['return_time']?.toString() ?? '',
                                          style: Styles.txtG6ColorW40014,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (trip['vehicle_id'] != null &&
                                        trip['vehicle_id']['vehicle_type'] !=
                                            null)
                                    ? (trip['vehicle_id']['vehicle_type']['name'] ??
                                          'Vehicle')
                                    : 'Vehicle',
                                style: Styles.txtG7Colors40014,
                              ),
                              Dimens.boxHeight3,
                              Text(
                                (trip['vehicle_id'] != null)
                                    ? (trip['vehicle_id']['brand_name'] ??
                                          'Unknown')
                                    : 'Unknown',
                                style: Styles.txtBlackColorW60016,
                              ),
                              Dimens.boxHeight3,
                              if (trip['vehicle_id'] != null && trip['vehicle_id']['vehicle_number'] != null)
                                Text(
                                  trip['vehicle_id']['vehicle_number'].toString(),
                                  style: Styles.txtG7Colors40014,
                                ),
                            ],
                          ),
                          // vehicle image (if provided)
                          if (trip['vehicle_id'] != null &&
                              trip['vehicle_id']['vehicle_type'] != null &&
                              trip['vehicle_id']['vehicle_type']['vehicle_photo'] !=
                                  null)
                            Image.network(
                              trip['vehicle_id']['vehicle_type']['vehicle_photo']
                                  .toString(),
                              height: Dimens.fourtyEight,
                              width: Dimens.fourtyEight,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => SizedBox(
                                height: Dimens.fourtyEight,
                                width: Dimens.fourtyEight,
                              ),
                            ),
                        ],
                      ),
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
                      Text("Pickup Address", style: Styles.txtG6ColorW40014),
                      Dimens.boxHeight2,
                      Text(pickupAddress, style: Styles.txtBlackColorW50016),
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
}
