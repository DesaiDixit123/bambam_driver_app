import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class EarningsVaultScreen extends StatelessWidget {
  const EarningsVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.find<HomeController>().fetchEarningsVaultData();
        });
      },
      builder: (controller) {
        final data = controller.earningsData ?? {};
        final missRides = data['miss_rides_loss'] ?? {};
        final bookingSummary = data['execute_booking_summary'] ?? {};
        final summaryStats = bookingSummary['summary'] ?? {};
        final bookings = bookingSummary['bookings']?['data'] as List? ?? [];

        return Scaffold(
          backgroundColor: ColorsValue.l3,
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "Earnings Vault",
          ),
          body: controller.isEarningsLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await controller.fetchEarningsVaultData();
                  },
                  child: ListView(
                    padding: Dimens.edgeInsets20,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      /// Earnings Summary Label
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          "Earnings Summary",
                          style: GoogleFonts.poppins(
                            fontSize: Dimens.sixteen,
                            fontWeight: FontWeight.w600,
                            color: ColorsValue.txtBlackColor,
                          ),
                        ),
                      ),
                      Dimens.boxHeight16,

                      /// Wallet Balance Card
                      Container(
                        decoration: BoxDecoration(
                          color: ColorsValue.whiteColor,
                          borderRadius: BorderRadius.circular(Dimens.twelve),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: Dimens.edgeInsets16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Wallet Balance",
                                  style: GoogleFonts.poppins(
                                    fontSize: Dimens.fourteen,
                                    fontWeight: FontWeight.w400,
                                    color: ColorsValue.txtG7Color,
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: () {
                                    RouteManagement.gotoTransactionHistoryScreen();
                                  },
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        AssetConstants.ic_history,
                                        height: 18,
                                        width: 18,
                                      ),
                                      Dimens.boxWidth5,
                                      Text(
                                        "History",
                                        style: GoogleFonts.poppins(
                                          fontSize: Dimens.fourteen,
                                          fontWeight: FontWeight.w500,
                                          color: ColorsValue.appColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Dimens.boxHeight10,
                            Text(
                              "₹${data['wallet_balance'] ?? controller.walletBalance.toStringAsFixed(0)}",
                              style: GoogleFonts.poppins(
                                color: Colors.green,
                                fontSize: Dimens.twentyFour,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Dimens.boxHeight20,
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      RouteManagement.gotoWithdrawScreen();
                                    },
                                    child: _actionButton(
                                      "Withdraw",
                                      AssetConstants.ic_wallet,
                                    ),
                                  ),
                                ),
                                Dimens.boxWidth16,
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      RouteManagement.gotoTopUpWalletScreen();
                                    },
                                    child: _actionButton(
                                      "Top-Up",
                                      AssetConstants.ic_topup,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Dimens.boxHeight16,

                      /// Missed Ride Loss Card
                      Container(
                        padding: Dimens.edgeInsets16,
                        decoration: BoxDecoration(
                          color: ColorsValue.whiteColor,
                          borderRadius: BorderRadius.circular(Dimens.twelve),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Miss Rides Loss",
                              style: GoogleFonts.poppins(
                                fontSize: Dimens.fourteen,
                                fontWeight: FontWeight.w400,
                                color: ColorsValue.txtG7Color,
                              ),
                            ),
                            Dimens.boxHeight12,
                            Row(
                              children: [
                                Text(
                                  "${missRides['count'] ?? 0} Rides",
                                  style: GoogleFonts.poppins(
                                    fontSize: Dimens.eighteen,
                                    fontWeight: FontWeight.w600,
                                    color: ColorsValue.redColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "₹${missRides['amount'] ?? 0}",
                                  style: GoogleFonts.poppins(
                                    fontSize: Dimens.twentyFour,
                                    fontWeight: FontWeight.w700,
                                    color: ColorsValue.redColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Dimens.boxHeight16,

                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              "Driver’s Collection Pending",
                              "₹${data['drivers_collection_pending'] ?? 0}",
                              "",
                              Colors.red,
                            ),
                          ),
                          Dimens.boxWidth16,
                          Expanded(
                            child: _summaryCard(
                              "Total Earnings",
                              "₹${data['net_total_earnings'] ?? 0}",
                              "",
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Dimens.boxHeight16,
                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              "Paid By Bam Bam",
                              "₹${data['paid_by_bambam'] ?? 0}",
                              "",
                              ColorsValue.txtBlackColor,
                            ),
                          ),
                          Dimens.boxWidth16,
                          Expanded(
                            child: _summaryCard(
                              "Bam Bam Outstanding",
                              "₹${data['bambam_outstanding'] ?? 0}",
                              "",
                              Colors.red,
                            ),
                          ),
                        ],
                      ),

                      Dimens.boxHeight20,

                      /// Execute Booking Summary Table
                      Container(
                        decoration: BoxDecoration(
                          color: ColorsValue.whiteColor,
                          borderRadius: BorderRadius.circular(Dimens.twelve),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: ColorsValue.l2,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(Dimens.twelve),
                                  topRight: Radius.circular(Dimens.twelve),
                                ),
                              ),
                              child: Padding(
                                padding: Dimens.edgeInsets10,
                                child: Text(
                                  "Execute Booking Summary",
                                  style: GoogleFonts.poppins(
                                    fontSize: Dimens.sixteen,
                                    fontWeight: FontWeight.w600,
                                    color: ColorsValue.txtBlackColor,
                                  ),
                                ),
                              ),
                            ),
                            Dimens.boxHeight16,
                            _bookingSummaryTable(summaryStats),
                            Dimens.boxHeight10,
                          ],
                        ),
                      ),

                      Dimens.boxHeight20,

                      /// Section header for bookings
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          "Bookings Details",
                          style: GoogleFonts.poppins(
                            fontSize: Dimens.sixteen,
                            fontWeight: FontWeight.w600,
                            color: ColorsValue.txtBlackColor,
                          ),
                        ),
                      ),

                      /// Expandable booking cards
                      if (bookings.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              "No bookings found",
                              style: GoogleFonts.poppins(
                                color: ColorsValue.txtG5Colors,
                                fontSize: Dimens.fourteen,
                              ),
                            ),
                          ),
                        )
                      else
                        ...List.generate(bookings.length, (index) {
                          final booking = bookings[index];
                          final isOpen = controller.selectedIndexEarn == index;
                          return Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  controller.selectedIndexEarn = isOpen ? -1 : index;
                                  controller.update();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: ColorsValue.whiteColor,
                                    borderRadius: isOpen
                                        ? BorderRadius.only(
                                            topLeft: Radius.circular(Dimens.twelve),
                                            topRight: Radius.circular(Dimens.twelve),
                                          )
                                        : BorderRadius.circular(Dimens.twelve),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: Dimens.edgeInsets16,
                                  child: Row(
                                    children: [
                                      Text(
                                        "Booking ID: ",
                                        style: GoogleFonts.poppins(
                                          fontSize: Dimens.fourteen,
                                          color: ColorsValue.txtG7Color,
                                        ),
                                      ),
                                      Text(
                                        booking['booking_id'] ?? "",
                                        style: GoogleFonts.poppins(
                                          fontSize: Dimens.fourteen,
                                          fontWeight: FontWeight.w600,
                                          color: ColorsValue.txtBlackColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        isOpen
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        color: ColorsValue.txtG5Colors,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              /// Expanded section
                              if (isOpen)
                                Container(
                                  decoration: BoxDecoration(
                                    color: ColorsValue.whiteColor,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(Dimens.twelve),
                                      bottomRight: Radius.circular(Dimens.twelve),
                                    ),
                                    border: Border(
                                      top: BorderSide(color: ColorsValue.l2),
                                    ),
                                  ),
                                  padding: Dimens.edgeInsets16,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: const AssetImage(AssetConstants.person),
                                            radius: 20,
                                          ),
                                          Dimens.boxWidth12,
                                          Text(
                                            booking['user_name'] ?? "Unknown",
                                            style: GoogleFonts.poppins(
                                              fontSize: Dimens.sixteen,
                                              fontWeight: FontWeight.w600,
                                              color: ColorsValue.txtBlackColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Dimens.boxHeight16,
                                      _detailRow("Trip Type", booking['trip_type'] ?? "N/A"),
                                      _detailRow("Trip Fare", "₹${booking['trip_fare'] ?? 0}"),
                                      _detailRow("Paid Amount", "₹${booking['paid_amount'] ?? 0}"),
                                      _detailRow("Pending Amount", "₹${booking['pending_amount'] ?? 0}"),
                                      _detailRow("Commission Amount", "₹${booking['commission_amount'] ?? 0}"),
                                      _detailRow("Payment Mode", booking['payment_mode'] ?? "N/A"),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Payment Status",
                                            style: GoogleFonts.poppins(
                                              fontSize: Dimens.fourteen,
                                              color: ColorsValue.txtG7Color,
                                            ),
                                          ),
                                          _statusTag(
                                            booking['payment_status'] ?? "Pending",
                                            booking['payment_status'] == 'Paid'
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ],
                                      ),
                                      Dimens.boxHeight10,
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Trip Status",
                                            style: GoogleFonts.poppins(
                                              fontSize: Dimens.fourteen,
                                              color: ColorsValue.txtG7Color,
                                            ),
                                          ),
                                          _statusTag(
                                            booking['trip_status'] ?? "N/A",
                                            Colors.orange,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                              Dimens.boxHeight12,
                            ],
                          );
                        }),
                    ],
                  ),
                ),
        );
      },
    );
  }

  /// Action buttons
  Widget _actionButton(String text, String icon) {
    return Container(
      height: Dimens.fourtyFive,
      decoration: BoxDecoration(
        color: ColorsValue.appColor,
        borderRadius: BorderRadius.circular(Dimens.twenty),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(icon, height: 20, width: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
          Dimens.boxWidth8,
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: Dimens.fourteen,
              fontWeight: FontWeight.w600,
              color: ColorsValue.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Small summary cards
  Widget _summaryCard(String title, String value, String sub, Color color) {
    return Container(
      padding: Dimens.edgeInsets16,
      decoration: BoxDecoration(
        color: ColorsValue.whiteColor,
        borderRadius: BorderRadius.circular(Dimens.twelve),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            style: GoogleFonts.poppins(
              fontSize: Dimens.fourteen,
              fontWeight: FontWeight.w400,
              color: ColorsValue.txtG7Color,
            ),
          ),
          Dimens.boxHeight12,
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: Dimens.twenty,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (sub.isNotEmpty) ...[
            Dimens.boxHeight8,
            Text(
              sub,
              style: GoogleFonts.poppins(
                fontSize: Dimens.twelve,
                color: ColorsValue.txtG5Colors,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Booking Summary Table
  Widget _bookingSummaryTable(Map summaryStats) {
    final total = summaryStats['total_booking'] ?? {};
    final billed = summaryStats['partner_billed'] ?? {};
    final unbilled = summaryStats['partner_unbilled'] ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.0),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1.4),
          3: FlexColumnWidth(1.4),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: ColorsValue.l2, width: 1.5)),
            ),
            children: [
              _tableCell("Category", isHeader: true),
              _tableCell("Total", isHeader: true),
              _tableCell("Billed", isHeader: true),
              _tableCell("Unbilled", isHeader: true),
            ],
          ),
          _tableRow("All", "${total['all'] ?? 0}", "₹${billed['all'] ?? 0}", "₹${unbilled['all'] ?? 0}"),
          _tableRow("Oneway", "${total['oneway'] ?? 0}", "₹${billed['oneway'] ?? 0}", "₹${unbilled['oneway'] ?? 0}"),
          _tableRow("Round Trip", "${total['roundtrip'] ?? 0}", "₹${billed['roundtrip'] ?? 0}", "₹${unbilled['roundtrip'] ?? 0}"),
          _tableRow("Local", "${total['local'] ?? 0}", "₹${billed['local'] ?? 0}", "₹${unbilled['local'] ?? 0}"),
          _tableRow("Airport", "${total['airport'] ?? 0}", "₹${billed['airport'] ?? 0}", "₹${unbilled['airport'] ?? 0}"),
        ],
      ),
    );
  }

  TableRow _tableRow(String cat, String tot, String bill, String unbill) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ColorsValue.l2.withOpacity(0.5))),
      ),
      children: [
        _tableCell(cat),
        _tableCell(tot),
        _tableCell(bill),
        _tableCell(unbill),
      ],
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: isHeader ? Dimens.thirteen : Dimens.twelve,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
          color: isHeader ? ColorsValue.txtBlackColor : ColorsValue.txtG5Colors,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: Dimens.fourteen,
              color: ColorsValue.txtG7Color,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: Dimens.fourteen,
              fontWeight: FontWeight.w600,
              color: ColorsValue.txtBlackColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(Dimens.twelve),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: Dimens.twelve,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
