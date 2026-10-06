import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CompletedtripsScreen extends StatelessWidget {
  const CompletedtripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TripController>(
      initState: (_) {
        // Fetch default completed history on screen open
        final ctrl = Get.find<TripController>();
        // default start date uses controller helper (2025-04-01 fallback). You may prefill controller.fromDateController if needed.
        ctrl.fetchTripHistory();
      },
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            actions: [
              Container(
                width: Dimens.hundredThirty,
                height: Dimens.thirtyEight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: ColorsValue.borderColors),
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                ),
                child: Padding(
                  padding: Dimens.edgeInsets10_00_10_00,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.fromDateController.text.isNotEmpty
                            ? controller.fromDateController.text
                            : "select date",
                      ),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2050),
                          );
                          if (picked != null) {
                            controller.fromDateController.text = DateFormat('dd-MM-yyyy').format(picked);
                            controller.update();

                            // convert and call fetch
                            final s = DateFormat('yyyy-MM-dd').format(picked);
                            final e = DateFormat('yyyy-MM-dd').format(DateTime.now());
                            await controller.fetchTripHistory(status: 'Completed',);
                          }
                        },
                        child: Icon(
                          Icons.calendar_month_outlined,
                          color: ColorsValue.txtBlackColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Dimens.boxWidth20,
            ],
            title: "Completed Trip",
          ),
          body: controller.isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : controller.historyTrips.isEmpty
                  ? const Center(
                      child: Text("No completed trips found.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: controller.historyTrips.length,
                      padding: Dimens.edgeInsets20,
                      itemBuilder: (context, index) {
                        final trip = controller.historyTrips[index];
                        final booking = trip['booking_id'] ?? {};
                        final travel = booking['travelDetailsId'] ?? {};
                        final String pickup = travel['pickup_address'] ?? booking['pickup_address'] ?? travel['from'] ?? '—';
                        
                        String drop = '—';
                        if (travel['drop_address'] is List && (travel['drop_address'] as List).isNotEmpty) {
                          drop = (travel['drop_address'] as List).first.toString();
                        } else if (travel['drop_address'] != null && travel['drop_address'].toString().isNotEmpty) {
                          drop = travel['drop_address'].toString();
                        } else if (booking['drop_address'] != null && booking['drop_address'].toString().isNotEmpty) {
                          drop = booking['drop_address'].toString();
                        } else if (travel['to'] is List && (travel['to'] as List).isNotEmpty) {
                          drop = (travel['to'] as List).first.toString();
                        } else if (travel['to'] != null && travel['to'].toString().isNotEmpty) {
                          drop = travel['to'].toString();
                        }
                        final tripType = travel['trip_type'] ?? '—';
                        final bookingId = booking['booking_id'] ?? '—';
                        final pickupDateRaw = travel['date'] ?? '';
                        final pickupDate = (pickupDateRaw != null && pickupDateRaw.toString().isNotEmpty)
                            ? DateFormat('dd-MM-yyyy').format(DateTime.parse(pickupDateRaw.toString()))
                            : '—';
                        final pickupTime = travel['pickup_time'] ?? '—';
                        final bool isLocal = tripType.toString().toLowerCase().contains('local');
                        final bool isRoundTrip = tripType.toString().toLowerCase().contains('round');
                        final String returnDate = _resolveReturnDate(booking, travel);
                        final String returnTime = _resolveReturnTime(booking, travel);

                        return Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(Dimens.twelve),
                                  onTap: () async {
                                    final tId = trip['_id']?.toString() ?? '';
                                    if (tId.isEmpty) {
                                      Utility.showMessage('Trip id missing', MessageType.error, null, 'OK');
                                      return;
                                    }
                                    // fetch history detail and navigate
                                    final ctrl = Get.find<TripController>();
                                    await ctrl.fetchHistoryDetail(tId);
                                    RouteManagement.gotoTripDetilesScreen(isComplectTrip: true, tripId: tId);
                                  },
                                  child: Container(
                                    width: Get.width,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2)),
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
                                                  Text("Booking ID", style: Styles.txtG6ColorW40014),
                                                  Text(bookingId, style: Styles.txtBlackColorW50016),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Dimens.boxHeight20,
                                          Column(
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
                                                        Text("Pickup Address", style: Styles.txtG5ColorsW40014),
                                                        Dimens.boxHeight4,
                                                        Text(pickup, style: Styles.txtBlackColorW50016),
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
                                                        Text(isLocal ? "Package" : "Drop Address", style: Styles.txtG5ColorsW40014),
                                                        Dimens.boxHeight4,
                                                        Text(
                                                          isLocal ? _resolvePackage(booking, travel) : drop,
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
                                          ),
                                          Dimens.boxHeight15,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Dimens.boxHeight20,
                          ],
                        );
                      },
                    ),
        );
      },
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
}
