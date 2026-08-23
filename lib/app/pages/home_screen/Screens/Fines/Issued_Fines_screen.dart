import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IssuedFinesScreen extends StatelessWidget {
  const IssuedFinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      initState: (_) {
        // fetch fines after build to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctrl = Get.find<HomeController>();
          ctrl.fetchAllFines(status: '', startDate: '', endDate: '');
        });
      },
      builder: (controller) {
        return Scaffold(
          bottomSheet: Padding(
            padding: Dimens.edgeInsets20_30_20_30,
            child: CustomButton(
              text: "Add Fine",
              textStyle: Styles.whiteColorW60016,
              backgroundColor: ColorsValue.appColor,
              onPressed: () {
                RouteManagement.gotoAddFineScreen();
              },
            ),
          ),
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "All Issued Fine",
          ),
          backgroundColor: ColorsValue.appBg,
          body: controller.isLoadingFines
              ? const Center(child: CircularProgressIndicator())
              : controller.fines.isEmpty
                  ? const Center(child: Text('No fines found', style: TextStyle(fontSize: 16)))
                  : ListView.separated(
                      padding: Dimens.edgeInsets20,
                      physics: const BouncingScrollPhysics(),
                      separatorBuilder: (_, __) => Dimens.boxHeight16,
                      itemCount: controller.fines.length,
                      itemBuilder: (context, index) {
                        final item = controller.fines[index];
                        final bookingId = item['booking_id']?.toString() ?? '—';
                        final vehicle = item['vehicle_no']?.toString() ?? '—';
                        final amount = item['penalty_amount']?.toString() ?? '—';
                        final status = item['penalty_status']?.toString() ?? 'Pending';
                        final date = item['date']?.toString() ?? '';

                        return InkWell(
                          borderRadius: BorderRadius.circular(Dimens.twelve),
                          onTap: () {
                            // pass fine id to details screen
                         final fineId = item['_id']?.toString() ?? '';
RouteManagement.gotoFineDetilesScreen(fineId: fineId);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorsValue.l4CB,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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
                                      Text(
                                        bookingId,
                                        style: Styles.appcolorsBold16.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                              status.toLowerCase() == 'paid' ? AssetConstants.Green_CN : AssetConstants.Red_CN,
                                            ),
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: Dimens.edgeInsets14_8_14_8,
                                          child: Text(
                                            status,
                                            style: status.toLowerCase() == 'paid' ? Styles.txtGreenColorW60014 : Styles.txtRedColorW60014,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Dimens.boxHeight16,
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          spacing: Dimens.two,
                                          children: [
                                            Text("Vehicle No.", style: Styles.txtG7Colors40014),
                                            Text(vehicle, style: Styles.txtBlackColorW50016),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: Dimens.two,
                                        children: [
                                          Text("Penalty Amount", style: Styles.txtG7Colors40014),
                                          Text("₹$amount", style: Styles.txtBlackColorW50016),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (date.isNotEmpty) ...[
                                    Dimens.boxHeight8,
                                    Text(date, style: Styles.txtG6ColorW40014),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
