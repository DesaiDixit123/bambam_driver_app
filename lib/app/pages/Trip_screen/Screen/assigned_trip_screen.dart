import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AssignedTripScreen extends StatelessWidget {
  const AssignedTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TripController>(
      initState: (_) {
        final ctrl = Get.find<TripController>();
        ctrl.fetchAssignedTrips();
      },
      builder: (controller) {
        final arguments = Get.arguments as Map<String, dynamic>?;
        final showOnlyRequests = arguments?['showOnlyRequests'] == true;
        final showOnlyAssigned = arguments?['showOnlyAssigned'] == true;

        if (controller.isLoadingTrips &&
            controller.assignedTrips.isEmpty &&
            controller.rideRequests.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final screenTitle = showOnlyRequests
            ? "New Ride Requests"
            : (showOnlyAssigned ? "Assigned Trips" : "Trips & Requests");

        final seenReqBookings = <String>{};
        final uniqueRequests = <Map<String, dynamic>>[];
        for (final r in controller.rideRequests) {
          final booking = _extractBooking(r);
          final bId = (booking['booking_id'] ?? booking['_id'] ?? r['request_id'] ?? r['_id'] ?? '').toString();
          if (bId.isNotEmpty && !seenReqBookings.contains(bId)) {
            seenReqBookings.add(bId);
            uniqueRequests.add(r);
          } else if (bId.isEmpty) {
            uniqueRequests.add(r);
          }
        }

        final allItems = [
          if (!showOnlyAssigned)
            ...uniqueRequests.map(
              (r) => {'item': r, 'isRequest': true},
            ),
          if (!showOnlyRequests)
            ...controller.assignedTrips.map(
              (t) => {'item': t, 'isRequest': false},
            ),
        ];

        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(onTapBack: Get.back, title: screenTitle),
          body: allItems.isEmpty
              ? const Center(
                  child: Text(
                    "No trips found.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: allItems.length,
                  padding: Dimens.edgeInsets20,
                  itemBuilder: (context, index) {
                    final wrapper = allItems[index];
                    final item = wrapper['item'] as Map<String, dynamic>;
                    final bool isRequest = wrapper['isRequest'] as bool;

                    final String id = isRequest
                        ? (item['request_id']?.toString() ??
                              item['_id']?.toString() ??
                              '')
                        : (item['_id']?.toString() ?? '');
                    final booking = _extractBooking(item);
                    final travel = _extractTravel(booking);

                    final pickup = _resolvePickup(booking, travel);
                    final drop = _resolveDrop(booking, travel);
                    final tripType =
                        travel['trip_type']?.toString() ??
                        booking['trip_type']?.toString() ??
                        '—';
                    final bookingId = booking['booking_id'] ?? '—';
                    final pickupDate = _resolvePickupDate(booking, travel);
                    final pickupTime =
                        travel['pickup_time']?.toString() ??
                        booking['pickup_time']?.toString() ??
                        '—';

                    return Column(
                      children: [
                        if (index == 0 && isRequest && !showOnlyRequests && !showOnlyAssigned) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "New Ride Requests",
                              style: Styles.txtBlackColorW70018,
                            ),
                          ),
                          Dimens.boxHeight16,
                        ],
                        if (index > 0 &&
                            isRequest &&
                            !showOnlyRequests &&
                            !showOnlyAssigned &&
                            !(allItems[index - 1]['isRequest'] as bool)) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "New Ride Requests",
                              style: Styles.txtBlackColorW70018,
                            ),
                          ),
                          Dimens.boxHeight16,
                        ],
                        if (index == 0 && !isRequest && !showOnlyRequests && !showOnlyAssigned) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Assigned Trips",
                              style: Styles.txtBlackColorW70018,
                            ),
                          ),
                          Dimens.boxHeight16,
                        ] else if (index > 0 &&
                            !isRequest &&
                            !showOnlyRequests &&
                            !showOnlyAssigned &&
                            (allItems[index - 1]['isRequest'] as bool)) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Assigned Trips",
                              style: Styles.txtBlackColorW70018,
                            ),
                          ),
                          Dimens.boxHeight16,
                        ],
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: Get.width,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                color: isRequest
                                    ? const Color(0xffFFF4E3)
                                    : ColorsValue.l4CB,
                                borderRadius: BorderRadius.circular(
                                  Dimens.twelve,
                                ),
                              ),
                              child: Padding(
                                padding: Dimens.edgeInsets20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Trip Type",
                                              style: Styles.txtG6ColorW40014,
                                            ),
                                            Text(
                                              tripType,
                                              style: Styles.txtBlackColorW50016,
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
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
                                    _buildRouteInfo(
                                      tripType,
                                      pickup,
                                      drop,
                                      pickupDate,
                                      pickupTime,
                                      travel,
                                      booking,
                                    ),
                                    if (isRequest)
                                      Dimens.boxHeight40
                                    else
                                      Dimens.boxHeight20,
                                  ],
                                ),
                              ),
                            ),
                            if (isRequest)
                              Positioned(
                                bottom: -20,
                                left: 20,
                                right: 20,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _actionButton(
                                        "Reject",
                                        Colors.red.shade400,
                                        () => controller.rejectRideRequest(id),
                                      ),
                                    ),
                                    Dimens.boxWidth16,
                                    Expanded(
                                      child: _actionButton(
                                        "Accept",
                                        Colors.green.shade600,
                                        () => controller.acceptRideRequest(id),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Positioned(
                                bottom: Dimens.twelveNG,
                                right: Dimens.twenty,
                                child: InkWell(
                                  onTap: () =>
                                      RouteManagement.gotoTripDetilesScreen(
                                        isComplectTrip: false,
                                        tripId: id,
                                      ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: ColorsValue.appColor,
                                      borderRadius: BorderRadius.circular(
                                        Dimens.twelve,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: Dimens.edgeInsets16_6_16_6,
                                      child: Text(
                                        "View Details",
                                        style: Styles.txtBlackColorW50014,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Dimens.boxHeight40,
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildRouteInfo(
    String tripType,
    String pickup,
    String drop,
    String date,
    String time,
    Map travel,
    Map booking,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Image.asset(AssetConstants.ic_location, height: Dimens.twentyFour),
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
              Text("From", style: Styles.txtG5ColorsW40014),
              Text(pickup, style: Styles.txtBlackColorW50016),
              Dimens.boxHeight8,
              _buildDateTimeInfo(date, time),
              if (tripType.toString().toLowerCase().contains('local')) ...[
                Dimens.boxHeight30,
                Text("Package", style: Styles.txtG5ColorsW40014),
                Dimens.boxHeight4,
                Text((travel['package'] ?? booking['package'] ?? 'N/A').toString(), style: Styles.txtBlackColorW50016),
              ] else ...[
                Dimens.boxHeight30,
                Text("To", style: Styles.txtG5ColorsW40014),
                Text(drop, style: Styles.txtBlackColorW50016),
                if (tripType.toString().toLowerCase().contains('round')) ...[
                  Dimens.boxHeight8,
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, color: ColorsValue.appColor),
                      Dimens.boxWidth8,
                      Text((travel['return_date'] != null) ? DateFormat('dd-MM-yyyy').format(DateTime.parse(travel['return_date'].toString())) : '', style: Styles.txtG6ColorW40014),
                      Dimens.boxWidth16,
                      SvgPicture.asset(
                        AssetConstants.ic_clcok,
                        colorFilter: ColorFilter.mode(ColorsValue.appColor, BlendMode.srcIn),
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
    );
  }

  Widget _buildDateTimeInfo(String date, String time) {
    return Row(
      children: [
        Icon(Icons.calendar_month_outlined, color: ColorsValue.appColor),
        Dimens.boxWidth8,
        Text(date, style: Styles.txtG6ColorW40014),
        Dimens.boxWidth16,
        SvgPicture.asset(
          AssetConstants.ic_clcok,
          colorFilter: ColorFilter.mode(ColorsValue.appColor, BlendMode.srcIn),
          height: Dimens.twenty,
        ),
        Dimens.boxWidth8,
        Text(time, style: Styles.txtG6ColorW40014),
      ],
    );
  }

  Widget _actionButton(String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(Dimens.twelve),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          title,
          style: Styles.txtBlackColorW50014.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Map<String, dynamic> _extractBooking(Map<String, dynamic> item) {
    final booking = item['booking_id'];
    if (booking is Map<String, dynamic>) {
      return booking;
    }

    final bookingDetails = item['booking_details'];
    if (bookingDetails is Map<String, dynamic>) {
      return bookingDetails;
    }

    return const <String, dynamic>{};
  }

  Map<String, dynamic> _extractTravel(Map<String, dynamic> booking) {
    final travel = booking['travelDetailsId'];
    if (travel is Map<String, dynamic>) {
      return travel;
    }
    return const <String, dynamic>{};
  }

  String _resolvePickup(
    Map<String, dynamic> booking,
    Map<String, dynamic> travel,
  ) {
    return travel['from']?.toString() ??
        travel['pickup_address']?.toString() ??
        booking['pickup_address']?.toString() ??
        '—';
  }

  String _resolveDrop(
    Map<String, dynamic> booking,
    Map<String, dynamic> travel,
  ) {
    // 1. Try travel['to']
    final toVal = travel['to'];
    if (toVal is List && toVal.isNotEmpty) {
      return toVal.join(' ➞ ');
    } else if (toVal != null && toVal is! List && toVal.toString().isNotEmpty && toVal.toString() != '[]') {
      return toVal.toString();
    }

    // 2. Try travel['drop_address']
    final dropAddr = travel['drop_address'];
    if (dropAddr is List && dropAddr.isNotEmpty) {
      return dropAddr.join(' ➞ ');
    } else if (dropAddr != null && dropAddr is! List && dropAddr.toString().isNotEmpty && dropAddr.toString() != '[]') {
      return dropAddr.toString();
    }

    // 3. Try booking['drop_address']
    final bookingDrop = booking['drop_address'];
    if (bookingDrop is List && bookingDrop.isNotEmpty) {
      return bookingDrop.join(' ➞ ');
    } else if (bookingDrop != null && bookingDrop is! List && bookingDrop.toString().isNotEmpty && bookingDrop.toString() != '[]') {
      return bookingDrop.toString();
    }

    return '—';
  }

  String _resolvePickupDate(
    Map<String, dynamic> booking,
    Map<String, dynamic> travel,
  ) {
    final pickupDateRaw = travel['date'] ?? booking['pickup_date'];
    if (pickupDateRaw == null || pickupDateRaw.toString().isEmpty) {
      return '—';
    }

    try {
      return DateFormat(
        'dd-MM-yyyy',
      ).format(DateTime.parse(pickupDateRaw.toString()));
    } catch (_) {
      return pickupDateRaw.toString();
    }
  }
}
