import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentQrScreen extends StatelessWidget {
  const PaymentQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TripController>(
      builder: (controller) {
        final collectAmount = controller.tripDetails?['collect_cash_amount']?.toString() ?? '0';
        final double amountVal = double.tryParse(collectAmount) ?? 0;
        final upiUrl = "upi://pay?pa=9274453826@okbizaxis&pn=Bam%20Bam%20Mobility&am=${amountVal.toStringAsFixed(2)}&cu=INR";

        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "Online Payment QR",
          ),
          body: SafeArea(
            child: ListView(
              padding: Dimens.edgeInsets20,
              physics: const BouncingScrollPhysics(),
              children: [
                Dimens.boxHeight24,
                Text(
                  "Scan & Pay",
                  style: Styles.txtBlackColorW70020,
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight10,
                Text(
                  "Bam Bam Mobility",
                  style: Styles.appColorw50014.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight5,
                Text(
                  "UPI ID: 9274453826@okbizaxis",
                  style: Styles.txtG7Colors50016.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight30,
                
                // QR Code Container
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: upiUrl,
                      version: QrVersions.auto,
                      size: 240.0,
                      gapless: false,
                      errorStateBuilder: (cxt, err) {
                        return const Center(
                          child: Text(
                            "QR Generation Failed",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                Dimens.boxHeight24,
                Text(
                  "₹${amountVal.toStringAsFixed(2)}",
                  style: Styles.txtBlackColorW70020.copyWith(
                    fontSize: 28,
                    color: ColorsValue.txtGreenColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight20,
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Scan this QR using Google Pay, PhonePe, Paytm, BHIM, or any UPI app to complete payment.",
                    style: Styles.txtG7Colors50016.copyWith(
                      fontSize: 13,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Dimens.boxHeight40,
                
                // Action Buttons
                CustomButton(
                  onPressed: () {
                    controller.confirmOnlinePaymentReceipt();
                  },
                  text: "Payment Received",
                  textStyle: Styles.txtBlackColorW60016,
                  backgroundColor: ColorsValue.txtGreenColor,
                ),
                Dimens.boxHeight15,
                CustomButton(
                  onPressed: () {
                    Get.back();
                  },
                  text: "Cancel Payment",
                  textStyle: Styles.txtG7Colors50016.copyWith(color: ColorsValue.redColor),
                  backgroundColor: Colors.transparent,
                  isBorder: true,
                  bordercolors: ColorsValue.redColor,
                ),
                Dimens.boxHeight24,
              ],
            ),
          ),
        );
      },
    );
  }
}
