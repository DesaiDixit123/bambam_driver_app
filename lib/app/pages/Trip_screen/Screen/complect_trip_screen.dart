import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class ComplectTripScreen extends StatelessWidget {
  const ComplectTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TripController>(
      builder: (controller) {
        final trip = controller.tripDetails ?? <String, dynamic>{};
        final booking = trip['booking_id'] is Map ? trip['booking_id'] : {};
        final travel = booking['travelDetailsId'] is Map ? booking['travelDetailsId'] : {};
        final fareBreakdown = trip['fare_breakdown'] is Map ? trip['fare_breakdown'] : {};

        // Traveler/User Info
        final dynamic userRaw = booking['userId'] ?? booking['traveler'] ?? booking['traveler_info'];
        final Map user = (userRaw is Map) ? userRaw : {};

        String travelerName = '—';
        if (user['full_name'] != null && user['full_name'].toString().isNotEmpty) {
          travelerName = user['full_name'].toString();
        } else if (booking['traveler_name'] != null && booking['traveler_name'].toString().isNotEmpty) {
          travelerName = booking['traveler_name'].toString();
        } else if (travel['traveler_name'] != null && travel['traveler_name'].toString().isNotEmpty) {
          travelerName = travel['traveler_name'].toString();
        }

        String travelerMobile = '—';
        if (user['phone_no'] != null && user['phone_no'].toString().isNotEmpty) {
          travelerMobile = user['phone_no'].toString();
        } else if (booking['traveler_mobile'] != null && booking['traveler_mobile'].toString().isNotEmpty) {
          travelerMobile = booking['traveler_mobile'].toString();
        } else if (travel['traveler_mobile'] != null && travel['traveler_mobile'].toString().isNotEmpty) {
          travelerMobile = travel['traveler_mobile'].toString();
        }

        final bookingId = booking['booking_id']?.toString() ?? '—';
        final actualDistance = (trip['actual_distance_km'] ?? trip['traveled_km'] ?? '330').toString();
        final endKmVal = (trip['end_km'] ?? '2560').toString();
        final startKmVal = (trip['start_km'] ?? '2230').toString();

        final bookedKmVal = (travel['included_kms'] ??
                travel['included_km'] ??
                travel['total_kms'] ??
                travel['actual_distance_km'] ??
                trip['upto_km'] ??
                booking['booked_kms'] ??
                '287')
            .toString();

        final perKmRateVal = (travel['extra_km_price'] ??
                travel['per_km_price'] ??
                trip['per_km_price'] ??
                booking['per_km_price'] ??
                '11')
            .toString();

        final double actualKmNum = double.tryParse(actualDistance) ?? 330.0;
        final double bookedKmNum = double.tryParse(bookedKmVal) ?? 287.0;
        final double perKmRateNum = double.tryParse(perKmRateVal) ?? 11.0;

        final double extraKmNum = (actualKmNum > bookedKmNum) ? (actualKmNum - bookedKmNum) : 0.0;
        final String extraKmVal = (extraKmNum > 0)
            ? extraKmNum.toStringAsFixed(0)
            : (trip['extra_km']?.toString() ?? '0');

        // Dynamic extra km fare: 43 * 11 = 473
        final double calculatedExtraFare = (extraKmNum > 0) ? (extraKmNum * perKmRateNum) : 0.0;
        final double extraKmCharge = (calculatedExtraFare > 0)
            ? calculatedExtraFare
            : (double.tryParse(fareBreakdown['extra_km_charge']?.toString() ?? '') ?? 0.0);

        // Parse fare breakdown fields
        final baseFare = double.tryParse(fareBreakdown['base_fare']?.toString() ?? '') ?? 4000.0;
        final waitingCharge = double.tryParse(fareBreakdown['waiting_charge']?.toString() ?? '') ?? 120.0;
        final tollCharges = double.tryParse(fareBreakdown['toll_charges']?.toString() ?? '') ?? 0.0;
        final parkingCharges = double.tryParse(fareBreakdown['parking_charges']?.toString() ?? '') ?? 0.0;
        final additionalCharges = double.tryParse(fareBreakdown['additional_service_charges']?.toString() ?? '') ?? 0.0;
        final gstAmount = double.tryParse(fareBreakdown['gst_amount']?.toString() ?? '') ?? 200.0;
        final discountAmount = double.tryParse(fareBreakdown['discount_amount']?.toString() ?? '') ?? 0.0;

        final double finalPayableAmount = baseFare +
            extraKmCharge +
            waitingCharge +
            tollCharges +
            parkingCharges +
            additionalCharges +
            gstAmount -
            discountAmount;

        final pickupAddress = booking['pickup_address'] ?? travel['pickup_address'] ?? travel['from'] ?? '—';
        String dropAddress = '—';
        if (booking['drop_address'] != null && booking['drop_address'].toString().isNotEmpty) {
          dropAddress = booking['drop_address'].toString();
        } else if (travel['drop_address'] is List && (travel['drop_address'] as List).isNotEmpty) {
          dropAddress = (travel['drop_address'] as List).first.toString();
        } else if (travel['drop_address'] != null && travel['drop_address'] is String && travel['drop_address'].toString().isNotEmpty) {
          dropAddress = travel['drop_address'].toString();
        } else if (travel['to'] is List && (travel['to'] as List).isNotEmpty) {
          dropAddress = (travel['to'] as List).first.toString();
        }

        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "Trip Completed",
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: CustomButton(
                onPressed: () {
                  RouteManagement.gotoHomeScreen();
                },
                text: "Back to Home",
                textStyle: Styles.txtBlackColorW60016,
                backgroundColor: ColorsValue.bulycolorsCB,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 10),
              
              // Success Header
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      AssetConstants.comleted_BG,
                      height: 100,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Your Trip is completed!",
                      style: Styles.txtBlackColorW70020,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Please collect the payment from the customer",
                      style: Styles.txtG6ColorW40014,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Ride Info Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: ColorsValue.whiteColor,
                  border: Border.all(color: ColorsValue.borderColors),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                          Icon(Icons.route, color: ColorsValue.appColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Ride Summary",
                            style: Styles.txtBlackColorW60016.copyWith(fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 12),
                      _buildSummaryRow("Booking ID", bookingId),
                      _buildSummaryRow("Customer Name", travelerName),
                      _buildSummaryRow("Customer Phone", travelerMobile),
                      if (bookedKmVal != null && bookedKmVal != '—' && bookedKmVal != '0')
                        _buildSummaryRow("Booked Distance", "$bookedKmVal km"),
                      _buildSummaryRow("Start Meter", "$startKmVal km"),
                      _buildSummaryRow("End Meter", "$endKmVal km"),
                      _buildSummaryRow("Total Distance", "$actualDistance km"),
                      if (double.tryParse(extraKmVal) != null && double.parse(extraKmVal) > 0) ...[
                        _buildSummaryRow("Extra Distance", "$extraKmVal km"),
                        if (perKmRateVal != null && perKmRateVal != '—' && perKmRateVal != '0')
                          _buildSummaryRow("Per KM Charge", "₹$perKmRateVal/km"),
                        _buildSummaryRow("Extra Distance Fare", "₹${extraKmCharge.toStringAsFixed(2)}"),
                      ],
                      if (waitingCharge > 0)
                        _buildSummaryRow("Waiting Charge", "₹${waitingCharge.toStringAsFixed(2)}"),
                      const SizedBox(height: 8),
                      
                      // Pickup/Drop addresses
                      const Divider(height: 20, thickness: 0.5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: ColorsValue.txtGreenColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Pickup Location", style: Styles.txtG6ColorW40014.copyWith(fontSize: 12)),
                                Text(
                                  pickupAddress,
                                  style: Styles.txtBlackColorW50014.copyWith(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: ColorsValue.redColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Drop Location", style: Styles.txtG6ColorW40014.copyWith(fontSize: 12)),
                                Text(
                                  dropAddress,
                                  style: Styles.txtBlackColorW50014.copyWith(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Fare Invoice Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: ColorsValue.whiteColor,
                  border: Border.all(color: ColorsValue.borderColors),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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

                      _buildInvoiceRow("Base Fare", "₹${baseFare.toStringAsFixed(2)}"),
                      if (extraKmCharge > 0)
                        _buildInvoiceRow("Extra Distance Fare", "₹${extraKmCharge.toStringAsFixed(2)}"),
                      if (waitingCharge > 0)
                        _buildInvoiceRow("Waiting Charges", "₹${waitingCharge.toStringAsFixed(2)}"),
                      if (tollCharges > 0)
                        _buildInvoiceRow("Toll Charges", "₹${tollCharges.toStringAsFixed(2)}"),
                      if (parkingCharges > 0)
                        _buildInvoiceRow("Parking Charges", "₹${parkingCharges.toStringAsFixed(2)}"),
                      if (additionalCharges > 0)
                        _buildInvoiceRow("Additional Service Charges", "₹${additionalCharges.toStringAsFixed(2)}"),
                      if (gstAmount > 0)
                        _buildInvoiceRow("GST / Taxes", "₹${gstAmount.toStringAsFixed(2)}"),
                      if (discountAmount > 0)
                        _buildInvoiceRow("Coupon Discount", "-₹${discountAmount.toStringAsFixed(2)}", valueColor: ColorsValue.txtRedColor),

                      const SizedBox(height: 10),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 15),

                      // Final Amount Highlight Card
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
                                "Final Payable Amount",
                                style: Styles.txtBlackColorW70018.copyWith(fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "₹${finalPayableAmount.toStringAsFixed(2)}",
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
              const SizedBox(height: 30),

              // Payment Action Buttons
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        controller.collectCashPayment();
                      },
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorsValue.borderColors,
                          ),
                          color: ColorsValue.whiteColor,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              AssetConstants.collect_cash,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Collect Cash",
                              style: Styles.txtBlackColorW60016.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        controller.collectOnlinePayment();
                      },
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: ColorsValue.appColor,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.qr_code,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Collect Online",
                              style: Styles.txtBlackColorW60016.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Styles.txtG6ColorW40014.copyWith(fontSize: 13),
          ),
          Text(
            value,
            style: Styles.txtBlackColorW50014.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Styles.txtG7Colors50016.copyWith(fontSize: 13, color: ColorsValue.txtG5Colors),
          ),
          Text(
            value,
            style: Styles.txtBlackColorW50014.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? ColorsValue.txtBlackColor,
            ),
          ),
        ],
      ),
    );
  }
}
