import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/data/helpers/api_wrapper.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TripInvoiceScreen extends StatelessWidget {
  const TripInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data =
        Get.arguments is Map<String, dynamic> ? Get.arguments : {};
    final booking = data['booking_id'] is Map ? data['booking_id'] : {};
    final travel = booking['travelDetailsId'] is Map
        ? booking['travelDetailsId']
        : (data['travelDetailsId'] is Map ? data['travelDetailsId'] : {});
    final payment = booking['payment_summary'] is Map
        ? booking['payment_summary']
        : (data['payment_summary'] is Map ? data['payment_summary'] : {});
    final driver = booking['driver_id'] is Map
        ? booking['driver_id']
        : (data['driver_id'] is Map ? data['driver_id'] : {});
    final user = booking['userId'] is Map
        ? booking['userId']
        : (data['userId'] is Map ? data['userId'] : {});
    final fareBreakdown = booking['fare_breakdown'] is Map
        ? booking['fare_breakdown']
        : (data['fare_breakdown'] is Map
            ? data['fare_breakdown']
            : (travel['fare_summary'] is Map ? travel['fare_summary'] : {}));

    // Amounts & calculations
    final double baseFare = double.tryParse((fareBreakdown['base_fare'] ??
                travel['fare_summary']?['base_fare'] ??
                travel['final_price'] ??
                0)
            .toString()) ??
        0.0;
    final double extraKmCharge = double.tryParse(
            (fareBreakdown['extra_km_charge'] ?? 0).toString()) ??
        0.0;
    final double extraKm =
        double.tryParse((fareBreakdown['extra_km'] ?? 0).toString()) ?? 0.0;
    final double perKmPrice = double.tryParse(
            (fareBreakdown['per_km_price'] ?? travel['per_km_price'] ?? 0)
                .toString()) ??
        0.0;
    final double waitingCharge = double.tryParse(
            (fareBreakdown['waiting_charge'] ??
                    booking['waiting_charge'] ??
                    data['waiting_charge'] ??
                    0)
                .toString()) ??
        0.0;
    final int waitingMins = int.tryParse(
            (fareBreakdown['waiting_minutes'] ??
                    booking['total_waiting_minutes'] ??
                    data['total_waiting_minutes'] ??
                    0)
                .toString()) ??
        0;

    // Special services
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

    // Commission (BamBam Commission)
    double commissionAmount = 0.0;
    double commissionPercent = 20.0;

    if (payment['commission_amount'] != null &&
        double.tryParse(payment['commission_amount'].toString()) != null &&
        (double.tryParse(payment['commission_amount'].toString()) ?? 0.0) > 0) {
      commissionAmount =
          double.tryParse(payment['commission_amount'].toString()) ?? 0.0;
    } else if (payment['commission_percent'] != null &&
        double.tryParse(payment['commission_percent'].toString()) != null &&
        (double.tryParse(payment['commission_percent'].toString()) ?? 0.0) > 0) {
      commissionPercent =
          double.tryParse(payment['commission_percent'].toString()) ?? 20.0;
      commissionAmount = (totalFare * commissionPercent) / 100.0;
    } else {
      commissionAmount = totalFare * 0.20;
    }

    final bool extraCommPaid = data['extra_commission_paid'] == true ||
        booking['extra_commission_paid'] == true ||
        payment['extra_commission_paid'] == true;
    if (extraCommPaid && (data['final_commission_amount'] != null || booking['final_commission_amount'] != null || payment['final_commission_amount'] != null)) {
      final finalComm = double.tryParse((data['final_commission_amount'] ?? booking['final_commission_amount'] ?? payment['final_commission_amount']).toString()) ?? 0.0;
      if (finalComm > 0) {
        commissionAmount = finalComm;
      }
    }

    if (commissionAmount > 0 && totalFare > 0) {
      commissionPercent = (commissionAmount / totalFare) * 100;
    }

    // Net Driver Earning
    double driverNetFare = totalFare - commissionAmount;
    if (driverNetFare < 0) driverNetFare = 0.0;

    final String bId = (booking['booking_id'] ??
            booking['_id'] ??
            data['_id'] ??
            'BBM')
        .toString();
    final String bookingMongoId =
        (booking['_id'] ?? data['booking_id'] ?? data['_id'] ?? '').toString();

    final String storedLoginType = Get.find<Repository>()
        .getStringValue(LocalKeys.loginType)
        .toLowerCase()
        .trim();
    final bool isCompany = storedLoginType == 'company' ||
        (Get.isRegistered<TripController>() &&
            (Get.find<TripController>().isCompany ||
                Get.find<TripController>().loginType.toLowerCase().trim() == 'company'));

    return Scaffold(
      backgroundColor: ColorsValue.whiteColor,
      appBar: AppBarWidget(
        onTapBack: () => Get.back(),
        title: "Trip Invoice",
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "BAMBAM CABS",
                          style: Styles.txtBlackColorW70020.copyWith(
                            color: ColorsValue.appColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "Official Trip Invoice",
                          style: Styles.txtG6ColorW40014.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ColorsValue.appColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: ColorsValue.appColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        "INVOICE",
                        style: Styles.txtBlackColorW70014.copyWith(
                          color: ColorsValue.appColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Meta row: Invoice No & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Invoice No:", style: Styles.txtG6ColorW40014),
                        const SizedBox(height: 2),
                        Text("#$bId", style: Styles.txtBlackColorW60014),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Date:", style: Styles.txtG6ColorW40014),
                        const SizedBox(height: 2),
                        Text(
                          Utility.getFormatedTime(
                            booking['createdAt']?.toString() ??
                                DateTime.now().toString(),
                            'dd/MM/yyyy',
                          ),
                          style: Styles.txtBlackColorW60014,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Customer info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Customer Details",
                          style: Styles.txtBlackColorW60014),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            user['full_name'] ??
                                booking['traveler_name'] ??
                                'Customer',
                            style: Styles.txtBlackColorW50014,
                          ),
                        ],
                      ),
                      if (user['phone_no'] != null ||
                          booking['traveler_mobile'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              "${user['phone_no'] ?? booking['traveler_mobile']}",
                              style: Styles.txtG6ColorW40014,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Route Info
                Text("Route Information", style: Styles.txtBlackColorW60014),
                const SizedBox(height: 8),
                _routeItem(
                  icon: Icons.trip_origin,
                  iconColor: Colors.green,
                  label: "Pickup",
                  value: travel['pickup_address'] ??
                      booking['pickup_address'] ??
                      '—',
                ),
                const SizedBox(height: 8),
                _routeItem(
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  label: "Drop",
                  value: (travel['drop_address'] is List &&
                          (travel['drop_address'] as List).isNotEmpty)
                      ? (travel['drop_address'] as List).first.toString()
                      : (travel['drop_address'] ??
                          booking['drop_address'] ??
                          '—'),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Detailed Fare Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Trip Fare Breakdown",
                        style: Styles.txtBlackColorW70016),
                    Text("Amount (₹)",
                        style: Styles.txtG6ColorW40014.copyWith(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),

                _invoiceRow("Base Fare", "₹${baseFare.toStringAsFixed(2)}"),

                if (extraKmCharge > 0)
                  _invoiceRow(
                    "Extra KMs (${extraKm.toStringAsFixed(0)} km @ ₹${perKmPrice.toStringAsFixed(0)}/km)",
                    "₹${extraKmCharge.toStringAsFixed(2)}",
                  ),

                // Special services breakdown
                if (specialServicesTotal > 0 || servicesList.isNotEmpty) ...[
                  _invoiceRow(
                    "Special Services",
                    "₹${specialServicesTotal.toStringAsFixed(2)}",
                    isSubHeader: true,
                  ),
                  for (final s in servicesList)
                    Padding(
                      padding: const EdgeInsets.only(left: 14, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("• ${s['name']}",
                              style: Styles.txtG6ColorW40014
                                  .copyWith(fontSize: 12)),
                          Text(
                            "₹${(s['amount'] as double).toStringAsFixed(2)}",
                            style: Styles.txtG6ColorW40014
                                .copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],

                if (waitingCharge > 0)
                  _invoiceRow(
                    "Waiting Charges${waitingMins > 0 ? ' ($waitingMins mins)' : ''}",
                    "₹${waitingCharge.toStringAsFixed(2)}",
                  ),

                if (tollCharges > 0)
                  _invoiceRow(
                      "Toll Charges", "₹${tollCharges.toStringAsFixed(2)}"),
                if (parkingCharges > 0)
                  _invoiceRow("Parking Charges",
                      "₹${parkingCharges.toStringAsFixed(2)}"),
                if (additionalCharges > 0)
                  _invoiceRow("Additional Charges",
                      "₹${additionalCharges.toStringAsFixed(2)}"),

                if (discount > 0)
                  _invoiceRow(
                    "Coupon Discount",
                    "-₹${discount.toStringAsFixed(2)}",
                    valueColor: Colors.green,
                  ),

                if (gstAmount > 0)
                  _invoiceRow(
                      "GST (Tax)", "₹${gstAmount.toStringAsFixed(2)}"),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // Total Fare
                _invoiceRow(
                  "Total Trip Fare",
                  "₹${totalFare.toStringAsFixed(2)}",
                  isBold: true,
                  valueColor: ColorsValue.appColor,
                ),

                if (!isCompany) ...[
                  const SizedBox(height: 12),
                  // BamBam Commission & Net Earnings Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "BamBam Commission (${commissionPercent.toStringAsFixed(0)}%)",
                              style: Styles.txtBlackColorW50014.copyWith(
                                color: Colors.deepOrange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "-₹${commissionAmount.toStringAsFixed(2)}",
                              style: Styles.txtBlackColorW60014.copyWith(
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Your Net Earning",
                              style: Styles.txtBlackColorW70014.copyWith(
                                color: Colors.green.shade800,
                              ),
                            ),
                            Text(
                              "₹${driverNetFare.toStringAsFixed(2)}",
                              style: Styles.txtBlackColorW70016.copyWith(
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Payment Mode: ${payment['payment_mode'] ?? booking['payment_mode'] ?? 'Cash'}",
                      style: Styles.txtG6ColorW40014.copyWith(fontSize: 12),
                    ),
                    Text(
                      "Status: ${data['ride_status'] ?? booking['booking_status'] ?? 'Completed'}",
                      style: Styles.txtBlackColorW60014.copyWith(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Download PDF Invoice Button
          CustomButton(
            text: "Download PDF Invoice",
            onPressed: () {
              final idToUse = bookingMongoId.isNotEmpty ? bookingMongoId : bId;
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
            backgroundColor: ColorsValue.appColor,
            radius: 12,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _invoiceRow(
    String title,
    String value, {
    bool isBold = false,
    bool isSubHeader = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: isBold
                ? Styles.txtBlackColorW70016
                : (isSubHeader
                    ? Styles.txtBlackColorW60014
                    : Styles.txtG6ColorW40014),
          ),
          Text(
            value,
            style: isBold
                ? Styles.txtBlackColorW70018.copyWith(
                    color: valueColor ?? ColorsValue.appColor)
                : Styles.txtBlackColorW60014
                    .copyWith(color: valueColor ?? Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _routeItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Styles.txtG6ColorW40014.copyWith(fontSize: 11)),
              Text(
                value,
                style: Styles.txtBlackColorW50014.copyWith(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
