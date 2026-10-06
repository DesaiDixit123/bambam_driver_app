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
        final startKmVal = (trip['start_km'] ?? '0').toString();
        final endKmVal = (trip['end_km'] ?? '0').toString();

        final double startKmNum = double.tryParse(startKmVal) ?? 0.0;
        final double endKmNum = double.tryParse(endKmVal) ?? 0.0;

        // Actual Traveled Distance
        double actualKmNum = double.tryParse((trip['actual_distance_km'] ?? trip['traveled_km'] ?? fareBreakdown['total_distance_km'] ?? fareBreakdown['actual_distance_km'])?.toString() ?? '') ?? 0.0;
        if (actualKmNum <= 0.0 && endKmNum > startKmNum) {
          actualKmNum = endKmNum - startKmNum;
        }
        final actualDistance = (actualKmNum > 0) ? actualKmNum.toStringAsFixed(0) : (trip['actual_distance_km']?.toString() ?? '0');

        // Included KM (Package Distance) - MUST come from package included_km (e.g. 287 km)
        final bookedKmVal = (fareBreakdown['included_km'] ??
                trip['upto_km'] ??
                travel['fare_summary']?['included_km'] ??
                travel['km_included'] ??
                travel['included_kms'] ??
                travel['included_km'] ??
                booking['booked_kms'] ??
                '287')
            .toString();
        final double bookedKmNum = double.tryParse(bookedKmVal) ?? 287.0;

        // Per KM Rate
        final perKmRateVal = (fareBreakdown['per_km_price'] ??
                travel['fare_summary']?['per_km_price'] ??
                travel['extra_km_price'] ??
                travel['per_km_price'] ??
                trip['per_km_price'] ??
                booking['per_km_price'] ??
                '11')
            .toString();
        final double perKmRateNum = double.tryParse(perKmRateVal) ?? 11.0;

        // Extra KM
        final double backendExtraKm = double.tryParse(fareBreakdown['extra_km']?.toString() ?? trip['extra_km']?.toString() ?? '') ?? -1.0;
        final double extraKmNum = (backendExtraKm >= 0)
            ? backendExtraKm
            : ((actualKmNum > bookedKmNum) ? (actualKmNum - bookedKmNum) : 0.0);
        final String extraKmVal = extraKmNum.toStringAsFixed(0);

        // Extra KM Charge
        final double backendExtraFare = double.tryParse(fareBreakdown['extra_km_charge']?.toString() ?? trip['extra_fare']?.toString() ?? '') ?? -1.0;
        final double extraKmCharge = (backendExtraFare >= 0)
            ? backendExtraFare
            : ((extraKmNum > 0) ? (extraKmNum * perKmRateNum) : 0.0);

        // Base Fare
        final double baseFare = double.tryParse(fareBreakdown['base_fare']?.toString() ?? '') ??
            double.tryParse(travel['fare_summary']?['base_fare']?.toString() ?? '') ??
            double.tryParse(booking['payment_summary']?['base_price_before_tax']?.toString() ?? '') ??
            3500.0;

        // Special Services
        double specialServicesPrice = double.tryParse(fareBreakdown['special_services']?.toString() ?? '') ??
            double.tryParse(fareBreakdown['special_services_charge']?.toString() ?? '') ??
            double.tryParse(travel['fare_summary']?['special_services']?.toString() ?? '') ??
            double.tryParse(booking['amount']?['specialServicesPrice']?.toString() ?? '') ??
            0.0;

        final List<Map<String, dynamic>> servicesList = [];
        final dynamic rawServicesList = fareBreakdown['special_services_list'] ??
            travel['special_services'] ??
            booking['specialServicesDetails'];

        if (rawServicesList is List) {
          for (final item in rawServicesList) {
            if (item is Map) {
              final title = item['description']?.toString() ?? item['name']?.toString() ?? 'Special Service';
              final amt = double.tryParse(item['amount']?.toString() ?? '') ?? 0.0;
              servicesList.add({'name': title, 'amount': amt});
            }
          }
        }

        if (specialServicesPrice == 0.0 && servicesList.isNotEmpty) {
          specialServicesPrice = servicesList.fold(0.0, (sum, s) => sum + (s['amount'] as double));
        }

        // Waiting Charge
        final double waitingCharge = double.tryParse(fareBreakdown['waiting_charge']?.toString() ?? '') ??
            double.tryParse(trip['waiting_charge']?.toString() ?? '') ??
            double.tryParse(booking['waiting_charge']?.toString() ?? '') ??
            0.0;
        final int waitingMinutes = int.tryParse((trip['total_waiting_minutes'] ?? trip['waiting_minutes'] ?? booking['total_waiting_minutes'] ?? 0).toString()) ?? 0;

        // Coupon Discount
        final double discountAmount = double.tryParse(fareBreakdown['discount_amount']?.toString() ?? '') ??
            double.tryParse(fareBreakdown['promo_code_discount']?.toString() ?? '') ??
            double.tryParse(travel['fare_summary']?['coupon_discount']?.toString() ?? '') ??
            0.0;

        // Total Fare (Before Tax) = Base + Extra KM + Special Services + Waiting - Discount
        final double totalFareBeforeTax = double.tryParse(fareBreakdown['total_fare_before_tax']?.toString() ?? '') ??
            double.tryParse(fareBreakdown['final_base_fare']?.toString() ?? '') ??
            (baseFare + extraKmCharge + specialServicesPrice + waitingCharge - discountAmount);

        // GST
        final double gstPct = double.tryParse(fareBreakdown['gst_percent']?.toString() ?? '') ??
            double.tryParse(travel['fare_summary']?['gst_percent']?.toString() ?? '') ??
            double.tryParse(booking['payment_summary']?['gst_applied']?['gst_percent']?.toString() ?? '') ??
            5.0;

        final double gstAmount = double.tryParse(fareBreakdown['gst_amount']?.toString() ?? '') ??
            (gstPct > 0 ? ((totalFareBeforeTax * gstPct) / 100) : 0.0);

        // Toll, Parking & Additional Charges
        final double tollCharges = double.tryParse(fareBreakdown['toll_charges']?.toString() ?? '') ??
            double.tryParse(trip['toll_charges']?.toString() ?? '') ?? 0.0;
        final double parkingCharges = double.tryParse(fareBreakdown['parking_charges']?.toString() ?? '') ??
            double.tryParse(trip['parking_charges']?.toString() ?? '') ?? 0.0;
        final double additionalCharges = double.tryParse(fareBreakdown['additional_service_charges']?.toString() ?? '') ??
            double.tryParse(trip['additional_charges']?.toString() ?? '') ?? 0.0;

        // Final Payable Amount
        final double finalPayableAmount = double.tryParse(trip['collect_cash_amount']?.toString() ?? '') ??
            double.tryParse(fareBreakdown['final_payable_amount']?.toString() ?? '') ??
            (totalFareBeforeTax + gstAmount + tollCharges + parkingCharges + additionalCharges);

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
                      _buildSummaryRow("Start Meter", "$startKmVal km"),
                      _buildSummaryRow("End Meter", "$endKmVal km"),
                      _buildSummaryRow("Total Distance", "$actualDistance km"),
                      if (bookedKmVal.isNotEmpty && bookedKmVal != '—' && bookedKmVal != '0')
                        _buildSummaryRow("Included KMs", "$bookedKmVal km"),
                      if (extraKmNum > 0) ...[
                        _buildSummaryRow("Extra Distance", "$extraKmVal km"),
                        if (perKmRateVal.isNotEmpty && perKmRateVal != '—' && perKmRateVal != '0')
                          _buildSummaryRow("Per KM Charge", "₹$perKmRateVal/km"),
                        _buildSummaryRow("Extra Distance Fare", "₹${extraKmCharge.toStringAsFixed(2)}"),
                      ],
                      if (specialServicesPrice > 0)
                        _buildSummaryRow("Special Services", "₹${specialServicesPrice.toStringAsFixed(2)}"),
                      if (waitingCharge > 0)
                        _buildSummaryRow(
                          "Waiting Charge${waitingMinutes > 0 ? ' ($waitingMinutes mins)' : ''}",
                          "₹${waitingCharge.toStringAsFixed(2)}",
                        ),
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
                        _buildInvoiceRow(
                          "Extra KMs Charge (₹${perKmRateNum.toStringAsFixed(0)}/KM)",
                          "₹${extraKmCharge.toStringAsFixed(2)}",
                        ),

                      // Special Services & Sub-breakdown (matching user side)
                      if (specialServicesPrice > 0 || servicesList.isNotEmpty) ...[
                        _buildInvoiceRow(
                          "Special Services",
                          "₹${specialServicesPrice.toStringAsFixed(2)}",
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
                                  "₹${(s['amount'] as double).toStringAsFixed(2)}",
                                  style: Styles.txtG6ColorW40014.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],

                      // Waiting Charges (placed BEFORE Total Fare Before Tax)
                      if (waitingCharge > 0)
                        _buildInvoiceRow(
                          "Waiting Charges${waitingMinutes > 0 ? ' ($waitingMinutes mins)' : ''}",
                          "₹${waitingCharge.toStringAsFixed(2)}",
                        ),

                      // Coupon Discount
                      if (discountAmount > 0)
                        _buildInvoiceRow(
                          "Coupon Discount",
                          "-₹${discountAmount.toStringAsFixed(2)}",
                          valueColor: ColorsValue.txtGreenColor,
                        ),

                      // Total Fare (Before Tax)
                      const SizedBox(height: 6),
                      Divider(height: 1, thickness: 1, color: ColorsValue.borderColors),
                      const SizedBox(height: 6),
                      _buildInvoiceRow(
                        "Total Fare (Before Tax)",
                        "₹${totalFareBeforeTax.toStringAsFixed(2)}",
                        isBold: true,
                        valueColor: ColorsValue.appColor,
                      ),

                      // GST
                      if (gstAmount > 0)
                        _buildInvoiceRow(
                          "GST (${gstPct.toStringAsFixed(0)}%)",
                          "₹${gstAmount.toStringAsFixed(2)}",
                        ),

                      // Toll & Parking
                      if (tollCharges > 0)
                        _buildInvoiceRow("Toll Charges", "₹${tollCharges.toStringAsFixed(2)}"),
                      if (parkingCharges > 0)
                        _buildInvoiceRow("Parking Charges", "₹${parkingCharges.toStringAsFixed(2)}"),

                      // Additional Charges
                      if (fareBreakdown['additional_charges_details'] is List &&
                          (fareBreakdown['additional_charges_details'] as List).isNotEmpty) ...[
                        for (final ch in (fareBreakdown['additional_charges_details'] as List))
                          if (ch is Map && (ch['amount'] != null))
                            _buildInvoiceRow(
                              ch['title']?.toString() ?? 'Additional Charge',
                              "₹${(double.tryParse(ch['amount'].toString()) ?? 0.0).toStringAsFixed(2)}",
                            ),
                      ] else if (additionalCharges > 0)
                        _buildInvoiceRow(
                          "Additional Charges",
                          "₹${additionalCharges.toStringAsFixed(2)}",
                        ),

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
                                "Total Amount",
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

  Widget _buildInvoiceRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? Styles.txtBlackColorW60016.copyWith(fontSize: 13)
                : Styles.txtG7Colors50016.copyWith(fontSize: 13, color: ColorsValue.txtG5Colors),
          ),
          Text(
            value,
            style: Styles.txtBlackColorW50014.copyWith(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? ColorsValue.txtBlackColor,
            ),
          ),
        ],
      ),
    );
  }
}
