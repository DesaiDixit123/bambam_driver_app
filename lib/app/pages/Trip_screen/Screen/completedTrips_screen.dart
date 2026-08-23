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
                                          Row(
                                            spacing: Dimens.twelve,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Image.asset(AssetConstants.ic_location, height: Dimens.twentyFour),
                                                  Padding(
                                                    padding: Dimens.edgeInsets8,
                                                    child: Dash(direction: Axis.vertical, length: 60, dashLength: 5, dashColor: ColorsValue.appColor),
                                                  ),
                                                  Image.asset(AssetConstants.ic_location, height: Dimens.twentyFour),
                                                ],
                                              ),
                                              Dimens.boxWidth12,
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text("Pickup Address", style: Styles.txtG5ColorsW40014),
                                                    Dimens.boxHeight4,
                                                    Text(pickup, style: Styles.txtBlackColorW50016),
                                                    Dimens.boxHeight8,
                                                    Row(
                                                      children: [
                                                        Icon(Icons.calendar_month_outlined, color: ColorsValue.appColor),
                                                        Dimens.boxWidth8,
                                                        Text(pickupDate, style: Styles.txtG6ColorW40014),
                                                        Dimens.boxWidth16,
                                                        SvgPicture.asset(AssetConstants.ic_clcok, color: ColorsValue.appColor, height: Dimens.twenty),
                                                        Dimens.boxWidth8,
                                                        Text(pickupTime, style: Styles.txtG6ColorW40014),
                                                      ],
                                                    ),
                                                    Dimens.boxHeight30,
                                                    if (tripType.toString().toLowerCase().contains('local')) ...[
                                                      Text("Package", style: Styles.txtG5ColorsW40014),
                                                      Dimens.boxHeight4,
                                                      Text((travel['package'] ?? booking['package'] ?? 'N/A').toString(), style: Styles.txtBlackColorW50016),
                                                    ] else ...[
                                                      Text("Drop Address", style: Styles.txtG5ColorsW40014),
                                                      Dimens.boxHeight4,
                                                      Text(drop, style: Styles.txtBlackColorW50016),
                                                      if (tripType.toString().toLowerCase().contains('round')) ...[
                                                        Dimens.boxHeight8,
                                                        Row(
                                                          children: [
                                                            Icon(Icons.calendar_month_outlined, color: ColorsValue.appColor),
                                                            Dimens.boxWidth8,
                                                            Text((travel['return_date'] != null) ? DateFormat('dd-MM-yyyy').format(DateTime.parse(travel['return_date'].toString())) : '', style: Styles.txtG6ColorW40014),
                                                            Dimens.boxWidth16,
                                                            SvgPicture.asset(AssetConstants.ic_clcok, color: ColorsValue.appColor, height: Dimens.twenty),
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
}
