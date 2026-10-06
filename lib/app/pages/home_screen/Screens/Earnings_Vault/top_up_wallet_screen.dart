import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TopUpWalletScreen extends StatelessWidget {
  const TopUpWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.l3,
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "Top-Up Wallet",
          ),
          bottomNavigationBar: Padding(
            padding: Dimens.edgeInsets20_30_20_30,
            child: CustomButton(
              onPressed: controller.isTopUpLoading
                  ? null
                  : () {
                      if (controller.topUpAmountController.text.isEmpty) {
                        Utility.showMessage("Please enter an amount", MessageType.error, null, "OK");
                        return;
                      }
                      final amount = int.tryParse(controller.topUpAmountController.text.trim());
                      if (amount == null || amount <= 0) {
                        Utility.showMessage("Please enter a valid amount", MessageType.error, null, "OK");
                        return;
                      }
                      controller.initiateWalletTopUp(amount);
                    },
              text: controller.isTopUpLoading ? "Initiating Payment..." : "Proceed to Pay",
              backgroundColor: ColorsValue.appColor,
            ),
          ),
          body: ListView(
            padding: Dimens.edgeInsets20,
            physics: const BouncingScrollPhysics(),
            children: [
              Text(
                "Current Balance: ₹${controller.walletBalance.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(
                  fontSize: Dimens.fourteen,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              Dimens.boxHeight16,
              Row(
                children: [
                  _amountPreset(controller, "500"),
                  Dimens.boxWidth8,
                  _amountPreset(controller, "1000"),
                ],
              ),
              Dimens.boxHeight8,
              Row(
                children: [
                  _amountPreset(controller, "2000"),
                  Dimens.boxWidth8,
                  _amountPreset(controller, "5000"),
                ],
              ),
              Dimens.boxHeight20,
              CustomTextFormField(
                filled: true,
                fillColor: ColorsValue.whiteColor,
                isBorder: true,
                isCompulsory: true,
                isTitle: true,
                keyboardType: TextInputType.number,
                textEditingController: controller.topUpAmountController,
                onChanged: (value) {
                  controller.update();
                },
                title: "Enter Amount to Add".tr,
                hintStyle: GoogleFonts.poppins(
                  fontSize: Dimens.twelve,
                  color: ColorsValue.txtG7Color,
                ),
                titleStyle: GoogleFonts.poppins(
                  fontSize: Dimens.fourteen,
                  fontWeight: FontWeight.w600,
                  color: ColorsValue.txtBlackColor,
                ),
                preIocns: true,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "₹",
                    style: GoogleFonts.poppins(
                      fontSize: Dimens.twenty,
                      fontWeight: FontWeight.w600,
                      color: ColorsValue.txtBlackColor,
                    ),
                  ),
                ),
              ),
              Dimens.boxHeight16,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Secured via Razorpay. Topped-up balance is added to your wallet instantly.",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _amountPreset(HomeController controller, String amount) {
    final bool isSelected = controller.topUpAmountController.text == amount;
    return Expanded(
      child: InkWell(
        onTap: () {
          controller.topUpAmountController.text = amount;
          controller.update();
        },
        borderRadius: BorderRadius.circular(Dimens.fifteen),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? ColorsValue.appColor.withOpacity(0.1) : ColorsValue.whiteColor,
            borderRadius: BorderRadius.circular(Dimens.fifteen),
            border: Border.all(
              color: isSelected ? ColorsValue.appColor : ColorsValue.borderColors,
            ),
          ),
          child: Padding(
            padding: Dimens.edgeInsets12,
            child: Text(
              "₹$amount",
              style: GoogleFonts.poppins(
                fontSize: Dimens.sixteen,
                fontWeight: FontWeight.w600,
                color: isSelected ? ColorsValue.appColor : ColorsValue.txtBlackColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
