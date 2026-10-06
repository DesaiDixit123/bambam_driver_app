import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/services/socket_connection.dart';
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
        ctrl.fetchRideRequests();
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
          final bId = _resolveBookingId(r, booking);
          if (bId.isNotEmpty && bId != '—' && !seenReqBookings.contains(bId)) {
            seenReqBookings.add(bId);
            uniqueRequests.add(r);
          } else if (bId.isEmpty || bId == '—') {
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
          body: RefreshIndicator(
            onRefresh: () async {
              await controller.fetchAssignedTrips();
              await controller.fetchRideRequests();
            },
            child: allItems.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: const Center(
                          child: Text(
                            "No trips found.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: allItems.length,
                    padding: Dimens.edgeInsets20,
                    itemBuilder: (context, index) {
                    final wrapper = allItems[index];
                    final item = (wrapper['item'] is Map)
                        ? Map<String, dynamic>.from(wrapper['item'] as Map)
                        : <String, dynamic>{};
                    final bool isRequest = wrapper['isRequest'] == true;

                    final booking = _extractBooking(item);
                    final travel = _extractTravel(booking);

                    final String id = isRequest
                        ? (item['request_id']?.toString().isNotEmpty == true
                            ? item['request_id'].toString()
                            : (item['_id']?.toString().isNotEmpty == true
                                ? item['_id'].toString()
                                : (booking['_id']?.toString() ?? '')))
                        : (item['_id']?.toString() ?? '');

                    final pickup = _resolvePickup(booking, travel);
                    final drop = _resolveDrop(booking, travel);
                    final String tripType = (travel['trip_type'] ??
                            booking['trip_type'] ??
                            '—')
                        .toString();
                    final String bookingId = _resolveBookingId(item, booking);
                    final String pickupDate = _resolvePickupDate(booking, travel);
                    final String pickupTime = (travel['pickup_time'] ??
                            booking['pickup_time'] ??
                            '—')
                        .toString();

                        final num fareVal = num.tryParse((item['total_fare'] ?? item['total_payment'] ?? booking['total_fare'] ?? booking['total_payment'] ?? 0).toString()) ?? 0;
                        final num commissionPercent = num.tryParse((item['bambam_commission_percent'] ?? item['commission_percent'] ?? booking['bambam_commission_percent'] ?? booking['commission_percent'] ?? 0).toString()) ?? 0;
                        final num commissionAmount = num.tryParse((item['bambam_commission_amount'] ?? item['commission_amount'] ?? booking['bambam_commission_amount'] ?? booking['commission_amount'] ?? 0).toString()) ?? 0;
                        final num netEarning = num.tryParse((item['driver_net_earnings'] ?? booking['driver_net_earnings'] ?? 0).toString()) ?? (fareVal > 0 && commissionAmount > 0 ? fareVal - commissionAmount : fareVal);

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
                                allItems[index - 1]['isRequest'] != true) ...[
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
                                allItems[index - 1]['isRequest'] == true) ...[
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
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isRequest ? () => SocketConnection.showRidePopup(item) : null,
                                    borderRadius: BorderRadius.circular(Dimens.twelve),
                                    child: Container(
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
                                            if (isRequest && fareVal > 0) ...[
                                              Dimens.boxHeight12,
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.orange.shade200),
                                                ),
                                                child: controller.isCompany
                                                    ? Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text("Total Fare", style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                                          Text("₹${fareVal.toStringAsFixed(0)}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                        ],
                                                      )
                                                    : Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text("Total Fare", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                                              Text("₹${fareVal.toStringAsFixed(0)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                          if (commissionPercent > 0)
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                Text("Commission (${commissionPercent.toStringAsFixed(0)}%)", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                                                Text("-₹${commissionAmount.toStringAsFixed(0)}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                                                              ],
                                                            ),
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            children: [
                                                              Text("Net Earning", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                                              Text("₹${netEarning.toStringAsFixed(0)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ],
                                            if (isRequest)
                                              Dimens.boxHeight40
                                            else
                                              Dimens.boxHeight20,
                                          ],
                                        ),
                                      ),
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
                                            () => controller.acceptRideRequest(id, fallbackData: item),
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
                  Text("From", style: Styles.txtG5ColorsW40014),
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
                  Text(isLocal ? "Package" : "To", style: Styles.txtG5ColorsW40014),
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
                  Text(date, style: Styles.txtG6ColorW40014),
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
                  Text(time, style: Styles.txtG6ColorW40014),
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
                      returnDate.isNotEmpty ? "Return: $returnDate" : "Return: $date",
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

  String _resolveBookingId(Map<String, dynamic> item, Map<String, dynamic> booking) {
    dynamic bId = booking['booking_id'];
    if (bId is Map) {
      bId = bId['booking_id'] ?? bId['_id'];
    }
    if (bId == null || bId.toString().isEmpty || bId.toString() == 'null') {
      bId = item['booking_id'];
      if (bId is Map) {
        bId = bId['booking_id'] ?? bId['_id'];
      }
    }
    if (bId == null || bId.toString().isEmpty || bId.toString() == 'null') {
      bId = booking['_id'] ?? item['request_id'] ?? item['_id'];
    }
    final res = bId?.toString().trim() ?? '—';
    return res.isEmpty ? '—' : res;
  }

  Map<String, dynamic> _extractBooking(Map<String, dynamic> item) {
    if (item['booking'] is Map) {
      final b = Map<String, dynamic>.from(item['booking'] as Map);
      if (b['booking_id'] is Map) {
        return Map<String, dynamic>.from(b['booking_id'] as Map);
      }
      return b;
    }
    if (item['rideDetails'] is Map) {
      final b = Map<String, dynamic>.from(item['rideDetails'] as Map);
      if (b['booking_id'] is Map) {
        return Map<String, dynamic>.from(b['booking_id'] as Map);
      }
      return b;
    }
    final booking = item['booking_id'];
    if (booking is Map) {
      return Map<String, dynamic>.from(booking as Map);
    }
    final bookingDetails = item['booking_details'];
    if (bookingDetails is Map) {
      final b = Map<String, dynamic>.from(bookingDetails as Map);
      if (b['booking_id'] is Map) {
        return Map<String, dynamic>.from(b['booking_id'] as Map);
      }
      return b;
    }
    return item;
  }

  Map<String, dynamic> _extractTravel(Map<String, dynamic> booking) {
    final travel = booking['travelDetailsId'] ?? booking['travel_details'] ?? booking['travel'];
    if (travel is Map) {
      return Map<String, dynamic>.from(travel as Map);
    }
    return const <String, dynamic>{};
  }

  String _resolvePickup(
    Map<String, dynamic> booking,
    Map<String, dynamic> travel,
  ) {
    final fromVal = travel['from'] ??
        travel['pickup_address'] ??
        booking['pickup_address'] ??
        booking['from'];
    if (fromVal is Map) {
      return (fromVal['address'] ?? fromVal['name'] ?? fromVal['city'] ?? fromVal.values.firstOrNull ?? '—').toString();
    }
    if (fromVal is List && fromVal.isNotEmpty) {
      final first = fromVal.first;
      if (first is Map) {
        return (first['address'] ?? first['name'] ?? first.toString()).toString();
      }
      return first.toString();
    }
    return fromVal?.toString() ?? '—';
  }

  String _resolveDrop(
    Map<String, dynamic> booking,
    Map<String, dynamic> travel,
  ) {
    // 1. Try travel['to']
    final toVal = travel['to'];
    if (toVal is List && toVal.isNotEmpty) {
      return toVal.map((e) => e is Map ? (e['address'] ?? e['name'] ?? e.toString()) : e.toString()).join(' ➞ ');
    } else if (toVal is Map) {
      return (toVal['address'] ?? toVal['name'] ?? toVal.toString()).toString();
    } else if (toVal != null && toVal.toString().isNotEmpty && toVal.toString() != '[]') {
      return toVal.toString();
    }

    // 2. Try travel['drop_address']
    final dropAddr = travel['drop_address'];
    if (dropAddr is List && dropAddr.isNotEmpty) {
      return dropAddr.map((e) => e is Map ? (e['address'] ?? e['name'] ?? e.toString()) : e.toString()).join(' ➞ ');
    } else if (dropAddr is Map) {
      return (dropAddr['address'] ?? dropAddr['name'] ?? dropAddr.toString()).toString();
    } else if (dropAddr != null && dropAddr.toString().isNotEmpty && dropAddr.toString() != '[]') {
      return dropAddr.toString();
    }

    // 3. Try booking['drop_address']
    final bookingDrop = booking['drop_address'];
    if (bookingDrop is List && bookingDrop.isNotEmpty) {
      return bookingDrop.map((e) => e is Map ? (e['address'] ?? e['name'] ?? e.toString()) : e.toString()).join(' ➞ ');
    } else if (bookingDrop is Map) {
      return (bookingDrop['address'] ?? bookingDrop['name'] ?? bookingDrop.toString()).toString();
    } else if (bookingDrop != null && bookingDrop.toString().isNotEmpty && bookingDrop.toString() != '[]') {
      return bookingDrop.toString();
    }

    return '—';
  }

  String _resolvePickupDate(
    Map<String, dynamic> booking,
    Map<String, dynamic> travel,
  ) {
    final pickupDateRaw = travel['date'] ?? booking['pickup_date'] ?? booking['date'];
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

  String _resolvePackage(dynamic bookingRaw, dynamic travelRaw) {
    final Map<String, dynamic> booking =
        (bookingRaw is Map) ? Map<String, dynamic>.from(bookingRaw) : {};
    final Map<String, dynamic> travel =
        (travelRaw is Map) ? Map<String, dynamic>.from(travelRaw) : {};

    final pkg = travel['package'] ?? booking['package'];
    if (pkg != null &&
        pkg is! Map &&
        pkg.toString().isNotEmpty &&
        pkg.toString() != 'N/A' &&
        pkg.toString() != 'null') {
      return pkg.toString();
    }

    final hours = (travel['selected_hours'] ??
        booking['selected_hours'] ??
        travel['per_hour_price'] ??
        booking['per_hour_price'])?.toString();
    final km = (travel['selected_km'] ??
        booking['selected_km'] ??
        travel['upto_km'] ??
        booking['upto_km'] ??
        travel['km_included'] ??
        booking['km_included'])?.toString();

    if (hours != null &&
        km != null &&
        hours.isNotEmpty &&
        km.isNotEmpty &&
        hours != '0' &&
        km != '0' &&
        hours != 'null' &&
        km != 'null') {
      return "${hours} hr / ${km} km";
    }

    if (travel['exploreId'] is Map) {
      final exp = Map<String, dynamic>.from(travel['exploreId'] as Map);
      final expHours = exp['per_hour_price']?.toString();
      final expKm = exp['upto_km']?.toString();
      if (expHours != null &&
          expKm != null &&
          expHours.isNotEmpty &&
          expKm.isNotEmpty) {
        return "${expHours} hr / ${expKm} km";
      }
    }

    if (booking['exploreId'] is Map) {
      final exp = Map<String, dynamic>.from(booking['exploreId'] as Map);
      final expHours = exp['per_hour_price']?.toString();
      final expKm = exp['upto_km']?.toString();
      if (expHours != null &&
          expKm != null &&
          expHours.isNotEmpty &&
          expKm.isNotEmpty) {
        return "${expHours} hr / ${expKm} km";
      }
    }

    if (travel['fare_summary'] is Map) {
      final fs = Map<String, dynamic>.from(travel['fare_summary'] as Map);
      final incKm = fs['included_km']?.toString();
      if (hours != null && incKm != null) {
        return "${hours} hr / ${incKm} km";
      }
    }

    if (km != null &&
        km.isNotEmpty &&
        km != '0' &&
        km != 'null') {
      return "${km} km";
    }

    return 'N/A';
  }
}
