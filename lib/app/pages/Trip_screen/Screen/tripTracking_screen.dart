import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TriptrackingScreen extends StatelessWidget {
  const TriptrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments is Map)
        ? Map<String, dynamic>.from(Get.arguments)
        : null;

    final bool isStartTripArg = args != null
        ? (args['isStartTrip'] ?? args['isStart'] ?? false) as bool
        : (Get.arguments is bool ? Get.arguments as bool : false);
    final String? tripIdArg = args != null
        ? (args['trip_id']?.toString() ?? args['tripId']?.toString())
        : null;

    return GetBuilder<TripController>(
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctrl = Get.find<TripController>();

          // If explicit trip_id passed in args, fetch that
          if (tripIdArg != null && tripIdArg.isNotEmpty) {
            ctrl.fetchTripDetails(tripIdArg);
            return;
          }

          // If opened for "Start Trip" flow
          if (isStartTripArg) {
            if (ctrl.tripDetails == null && ctrl.assignedTrips.isNotEmpty) {
              final first = ctrl.assignedTrips.first;
              final id = (first['_id'] ?? '').toString();
              if (id.isNotEmpty) ctrl.fetchTripDetails(id);
            }
            return;
          }

          // If opened from Home screen (ongoing trip)
          ctrl.fetchOngoingTrip();
        });
      },
      builder: (controller) {
        final bool isStartTrip = isStartTripArg;

        // --- 1️⃣ Show loader while fetching ---
        if (controller.isLoadingDetails) {
          return Scaffold(
            appBar: AppBarWidget(
              onTapBack: () => Get.back(),
              title: "Trip Tracking",
            ),
            backgroundColor: ColorsValue.appBg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // --- 2️⃣ Handle No Data Case ---
        if (controller.tripDetails == null ||
            controller.tripDetails!.isEmpty ||
            controller.tripDetails!['booking_id'] == null) {
          return Scaffold(
            appBar: AppBarWidget(
              onTapBack: () => Get.offAll(() => const HomeScreen()),
              title: "Trip Tracking",
            ),
            backgroundColor: ColorsValue.appBg,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_filled_rounded,
                    size: 80,
                    color: ColorsValue.appColor.withOpacity(0.7),
                  ),
                  Dimens.boxHeight16,
                  Text(
                    "No Trip Data Available",
                    style: Styles.txtBlackColorW60016.copyWith(
                      color: ColorsValue.blackColor.withOpacity(0.8),
                    ),
                  ),
                  Dimens.boxHeight8,
                  Text(
                    "You have no ongoing or assigned trip right now.",
                    textAlign: TextAlign.center,
                    style: Styles.txtG6ColorW40014,
                  ),
                  Dimens.boxHeight40,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: CustomButton(
                      text: "Back to Home",
                      backgroundColor: ColorsValue.appColor,
                      textStyle: Styles.txtBlackColorW60016,
                      onPressed: () => Get.offAll(() => const HomeScreen()),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // --- 3️⃣ Extract trip data safely ---
        final trip = controller.tripDetails ?? <String, dynamic>{};
        final booking = trip['booking_id'] ?? {};
        final travel = booking['travelDetailsId'] ?? {};

        final tripType = travel['trip_type'] ?? 'One Way';
        final bookingId = booking['booking_id'] ?? '—';
        final pickup = travel['from'] ?? booking['pickup_address'] ?? '—';
        final drop = (travel['to'] is List && travel['to'].isNotEmpty)
            ? travel['to'][0]
            : (booking['drop_address'] is List &&
                      booking['drop_address'].isNotEmpty
                  ? booking['drop_address'][0]
                  : '—');

        String pickupDate = '—';
        try {
          final pickupDateRaw = travel['date'];
          if (pickupDateRaw != null && pickupDateRaw.toString().isNotEmpty) {
            pickupDate = DateFormat(
              'dd-MM-yyyy',
            ).format(DateTime.parse(pickupDateRaw.toString()));
          }
        } catch (_) {}

        final pickupTime = travel['pickup_time'] ?? '—';

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
        final pickupAddress =
            booking['pickup_address'] ?? travel['pickup_address'] ?? pickup;

        String dropAddress = '';
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
        } else {
          dropAddress = drop.toString();
        }

        // --- 4️⃣ Build Trip UI ---
        return Scaffold(
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "Trip Tracking",
          ),
          backgroundColor: ColorsValue.appBg,
          body: ListView(
            padding: Dimens.edgeInsets20,
            physics: const BouncingScrollPhysics(),
            children: [
              if (trip['ride_status'] == 'Driver Arrived') ...[
                _waitingTimerCard(controller),
              ],
              Text("Trip Details", style: Styles.txtBlackColorW60016),
              Dimens.boxHeight16,
              _tripDetailsCard(
                tripType,
                bookingId.toString(),
                pickupAddress,
                dropAddress,
                pickupDate,
                pickupTime,
                travel,
                booking,
              ),
              Dimens.boxHeight20,
              Text("Traveler Details", style: Styles.txtBlackColorW60016),
              Dimens.boxHeight16,
              _travelerCard(travelerName, travelerMobile, pickupAddress),
              Dimens.boxHeight40,
              _actionButtons(controller, isStartTrip, travelerMobile, trip),
            ],
          ),
        );
      },
    );
  }

  Widget _waitingTimerCard(TripController controller) {
    final int elapsed = controller.elapsedSeconds;
    final int freeLimit = controller.freeWaitingSeconds;
    final double charges = controller.accumulatedWaitingCharge;

    String formatSecs(int totalSecs) {
      final int mins = totalSecs ~/ 60;
      final int secs = totalSecs % 60;
      return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    }

    final bool isFreeActive = elapsed <= freeLimit;
    final int freeRemaining = isFreeActive ? (freeLimit - elapsed) : 0;
    final int extraSeconds = !isFreeActive ? (elapsed - freeLimit) : 0;
    final double rate = controller.waitingChargePerMinute > 0
        ? controller.waitingChargePerMinute
        : (double.tryParse((controller.tripDetails?['charge_per_minute'] ??
                    controller.tripDetails?['waiting_charge_per_minute'] ??
                    0)
                .toString()) ??
            0.0);

    return Container(
      width: Get.width,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EF),
        border: Border.all(color: ColorsValue.appColor, width: 1.5),
        borderRadius: BorderRadius.circular(Dimens.twelve),
      ),
      padding: Dimens.edgeInsets16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ColorsValue.appColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "Driver Arrived - Waiting Timer",
                        style: Styles.txtBlackColorW60016.copyWith(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (rate > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorsValue.appColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ColorsValue.appColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "₹${rate.toStringAsFixed(0)}/min",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ColorsValue.appColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Free Time Left", style: Styles.txtG6ColorW40014),
                    const SizedBox(height: 2),
                    Text(
                      isFreeActive ? formatSecs(freeRemaining) : "00:00",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isFreeActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Exceeded Time", style: Styles.txtG6ColorW40014),
                    const SizedBox(height: 2),
                    Text(
                      !isFreeActive ? formatSecs(extraSeconds) : "00:00",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: !isFreeActive ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Wait Charges", style: Styles.txtG6ColorW40014),
                  const SizedBox(height: 2),
                  Text(
                    "₹${charges.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorsValue.appColor,
                    ),
                  ),
                  if (rate > 0)
                    Text(
                      "(₹${rate.toStringAsFixed(0)}/min)",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// --- Trip Details Card ---
  Widget _tripDetailsCard(
    String tripType,
    String bookingId,
    String pickupAddress,
    String dropAddress,
    String pickupDate,
    String pickupTime,
    Map travel,
    Map booking,
  ) {
    return Container(
      width: Get.width,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Dimens.two,
                  children: [
                    Text("Trip Type", style: Styles.txtG6ColorW40014),
                    Text(tripType, style: Styles.txtBlackColorW50016),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: Dimens.two,
                  children: [
                    Text("Booking ID", style: Styles.txtG6ColorW40014),
                    Text(bookingId, style: Styles.txtBlackColorW50016),
                  ],
                ),
              ],
            ),
            Dimens.boxHeight20,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Image.asset(
                      AssetConstants.ic_location,
                      height: Dimens.twentyFour,
                    ),
                    if (!tripType.toString().toLowerCase().contains('local')) ...[
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
                  ],
                ),
                Dimens.boxWidth12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pickup Address", style: Styles.txtG5ColorsW40014),
                      Text(pickupAddress, style: Styles.txtBlackColorW50016),
                      Dimens.boxHeight4,
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: ColorsValue.appColor,
                            size: 18,
                          ),
                          Dimens.boxWidth8,
                          Text(pickupDate, style: Styles.txtG6ColorW40014),
                          Dimens.boxWidth16,
                          SvgPicture.asset(
                            AssetConstants.ic_clcok,
                            color: ColorsValue.appColor,
                            height: Dimens.twenty,
                          ),
                          Dimens.boxWidth8,
                          Text(pickupTime, style: Styles.txtG6ColorW40014),
                        ],
                      ),
                      if (tripType.toString().toLowerCase().contains('local')) ...[
                        Dimens.boxHeight30,
                        Text("Package", style: Styles.txtG5ColorsW40014),
                        Text((travel['package'] ?? booking['package'] ?? 'N/A').toString(), style: Styles.txtBlackColorW50016),
                      ] else ...[
                        Dimens.boxHeight20,
                        Text("Drop Address", style: Styles.txtG5ColorsW40014),
                        Text(dropAddress, style: Styles.txtBlackColorW50016),
                        if (tripType.toString().toLowerCase().contains('round')) ...[
                          Dimens.boxHeight8,
                          Row(
                            children: [
                              Icon(Icons.calendar_month_outlined, color: ColorsValue.appColor, size: 18),
                              Dimens.boxWidth8,
                              Text((travel['return_date'] != null) ? DateFormat('dd-MM-yyyy').format(DateTime.parse(travel['return_date'].toString())) : '', style: Styles.txtG6ColorW40014),
                              Dimens.boxWidth16,
                              SvgPicture.asset(
                                AssetConstants.ic_clcok,
                                color: ColorsValue.appColor,
                                height: Dimens.twenty,
                              ),
                              Dimens.boxWidth8,
                              Text(travel['return_time']?.toString() ?? '', style: Styles.txtG6ColorW40014),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// --- Traveler Details Card ---
  Widget _travelerCard(String name, String mobile, String pickupAddress) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsValue.l4CB,
        borderRadius: BorderRadius.circular(Dimens.twelve),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
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
            Text(pickupAddress, style: Styles.txtBlackColorW50016),
            Dimens.boxHeight16,
            Text("Name", style: Styles.txtG6ColorW40014),
            Row(
              children: [
                Image.asset(AssetConstants.person, height: Dimens.twentyFour),
                Dimens.boxWidth8,
                Text(name, style: Styles.txtBlackColorW50016),
              ],
            ),
            Dimens.boxHeight16,
            Text("Mobile No.", style: Styles.txtG6ColorW40014),
            Text(mobile, style: Styles.txtBlackColorW50016),
          ],
        ),
      ),
    );
  }

  /// --- Action Buttons (Call + Start/End Trip) ---
  Widget _actionButtons(
    TripController controller,
    bool isStartTrip,
    String travelerMobile,
    Map trip,
  ) {
    final booking = trip['booking_id'] ?? {};
    final vendorRequestId =
        trip['_id']?.toString() ?? booking['_id']?.toString() ?? '';
    final rideStatus = trip['ride_status']?.toString() ?? '';

    final bool showArriveButton = isStartTrip && rideStatus != 'Driver Arrived';

    return Column(
      children: [
        CustomButton(
          onPressed: () {
            final mobile = travelerMobile.toString();
            if (mobile.isEmpty || mobile == '—') {
              Utility.showMessage(
                'Customer mobile not available',
                MessageType.error,
                null,
                'OK',
              );
              return;
            }

            final Uri dialUri = Uri(scheme: 'tel', path: mobile);
            launchUrl(dialUri);
          },
          text: "Call Customer",
          textStyle: Styles.txtBlackColorW50016,
          backgroundColor: ColorsValue.appBg,
          isBorder: true,
          leading: Icon(Icons.call, color: ColorsValue.blackColor),
        ),
        Dimens.boxHeight12,
        if (showArriveButton)
          CustomButton(
            onPressed: () async {
              if (vendorRequestId.isEmpty) {
                Utility.showMessage(
                  'Trip details not available',
                  MessageType.error,
                  null,
                  'OK',
                );
                return;
              }
              controller.notifyDriverArrived(vendorRequestId);
            },
            text: "I Have Arrived",
            textStyle: Styles.txtBlackColorW50016,
            backgroundColor: ColorsValue.appColor,
          )
        else
          CustomButton(
            onPressed: () async {
              String phone = (travelerMobile == '—') ? '' : travelerMobile;

              if (phone.isEmpty) {
                phone = controller.latestTravelerMobile ?? '';
              }

              if (vendorRequestId.isEmpty || (isStartTrip && phone.isEmpty)) {
                Utility.showMessage(
                  'Trip or phone not available',
                  MessageType.error,
                  null,
                  'OK',
                );
                return;
              }

              isStartTrip
                  ? RouteManagement.gotoOtpScreen()
                  : RouteManagement.gotoVehicalMiterScreen(isStartTrip: false);
            },
            text: isStartTrip ? "Pick-up Customer" : "End Trip",
            textStyle: Styles.txtBlackColorW50016,
            backgroundColor: ColorsValue.appColor,
          ),
      ],
    );
  }
}
