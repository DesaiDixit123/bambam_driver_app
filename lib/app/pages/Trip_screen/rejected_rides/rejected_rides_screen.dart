import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/rejected_rides/rejected_rides_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class RejectedRidesScreen extends StatelessWidget {
  const RejectedRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<RejectedRidesController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: controller.onBack,
            title: "Rejected Rides",
          ),
          body: controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : controller.rejectedRides.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.not_interested, 
                               size: 64, 
                               color: Colors.grey.withOpacity(0.5)),
                          Dimens.boxHeight16,
                          Text(
                            "No rejected rides found.",
                            style: Styles.txtG5ColorsW40016,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: controller.rejectedRides.length,
                      padding: Dimens.edgeInsets20,
                      itemBuilder: (context, index) {
                        final ride = controller.rejectedRides[index];
                        return _buildRejectedRideCard(ride, controller);
                      },
                    ),
        );
      },
    );
  }

  Widget _buildRejectedRideCard(var ride, RejectedRidesController controller) {
    final booking = ride['booking_id'] ?? {};
    final travel = booking['travelDetailsId'] ?? {};
    
    final String tripType = travel['trip_type'] ?? '—';
    final String bookingId = booking['booking_id'] ?? '—';
    final String pickup = travel['from'] ?? '—';
    final String drop = (travel['to'] is List && travel['to'].isNotEmpty)
        ? (travel['to'] as List).join(' ➞ ')
        : '—';
    
    final pickupDateRaw = travel['date'] ?? '';
    final String pickupDate = (pickupDateRaw != null && pickupDateRaw.toString().isNotEmpty)
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(pickupDateRaw.toString()))
        : '—';
    final String pickupTime = travel['pickup_time'] ?? '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: Get.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimens.twelve),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => controller.gotoTripDetails(ride),
          borderRadius: BorderRadius.circular(Dimens.twelve),
          child: Padding(
            padding: Dimens.edgeInsets20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "REJECTED",
                        style: Styles.txtBlackColorW50014.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      bookingId,
                      style: Styles.txtG6ColorW40014,
                    ),
                  ],
                ),
                Dimens.boxHeight16,
                _buildRouteInfo(tripType, pickup, drop, pickupDate, pickupTime),
                Dimens.boxHeight16,
                Divider(color: Colors.grey.shade200),
                Dimens.boxHeight8,
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text("View Details", style: Styles.txtBlackColorW50014.copyWith(color: ColorsValue.appColor)),
                     Icon(Icons.arrow_forward_ios, size: 14, color: ColorsValue.appColor),
                   ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfo(String tripType, String pickup, String drop, String date, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.circle_outlined, color: Colors.green, size: 16),
            if (tripType != "Local Rental Trip") ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Dash(
                  direction: Axis.vertical,
                  length: 30,
                  dashLength: 3,
                  dashColor: Colors.grey.shade300,
                ),
              ),
              const Icon(Icons.location_on, color: Colors.red, size: 16),
            ],
          ],
        ),
        Dimens.boxWidth12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pickup, 
                   style: Styles.txtBlackColorW50016, 
                   maxLines: 2, 
                   overflow: TextOverflow.ellipsis),
              Dimens.boxHeight4,
              Row(
                children: [
                  Icon(Icons.calendar_month, size: 14, color: Colors.grey.shade500),
                  Dimens.boxWidth4,
                  Text("$date | $time", style: Styles.txtG5ColorsW40012),
                ],
              ),
              if (tripType != "Local Rental Trip") ...[
                Dimens.boxHeight20,
                Text(drop, 
                     style: Styles.txtBlackColorW50016, 
                     maxLines: 2, 
                     overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

