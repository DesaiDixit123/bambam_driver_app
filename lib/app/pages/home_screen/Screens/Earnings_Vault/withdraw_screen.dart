import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.l3,
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "Withdraw",
          ),
          bottomNavigationBar: Padding(
            padding: Dimens.edgeInsets20_30_20_30,
            child: CustomButton(
              onPressed: controller.isWithdrawLoading
                  ? null
                  : () {
                      final text = controller.withdrawAmountController.text.trim();
                      final amount = int.tryParse(text) ?? 0;
                      if (amount <= 0) {
                        Utility.showMessage("Please enter a valid amount", MessageType.error, null, "OK");
                        return;
                      }
                      if (amount > controller.walletBalance) {
                        Utility.showMessage(
                          "Amount cannot exceed your wallet balance (₹${controller.walletBalance.toStringAsFixed(0)})",
                          MessageType.error,
                          null,
                          "OK",
                        );
                        return;
                      }
                      if (controller.selectedWithdrawMethod == "UPI") {
                        final upi = controller.withdrawUpiController.text.trim();
                        if (upi.isEmpty || !upi.contains('@')) {
                          Utility.showMessage("Please enter a valid UPI ID (e.g. name@bank)", MessageType.error, null, "OK");
                          return;
                        }
                      }
                      controller.withdrawEarningsController(
                        amount,
                        method: controller.selectedWithdrawMethod,
                        upiId: controller.selectedWithdrawMethod == "UPI"
                            ? controller.withdrawUpiController.text.trim()
                            : null,
                      );
                    },
              text: controller.isWithdrawLoading ? "Processing..." : "Proceed to Withdraw",
              backgroundColor: ColorsValue.appColor,
            ),
          ),
          body: ListView(
            padding: Dimens.edgeInsets20,
            physics: const BouncingScrollPhysics(),
            children: [
              Text(
                "Available Balance: ₹${controller.walletBalance.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(
                  fontSize: Dimens.fourteen,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              if (controller.walletBalance <= 0) ...[
                Dimens.boxHeight10,
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Your balance is ₹0. Please top-up or complete trips before requesting a withdrawal.",
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Dimens.boxHeight16,
              Row(
                children: [
                  _presetButton(controller, "500"),
                  Dimens.boxWidth8,
                  _presetButton(controller, "1000"),
                ],
              ),
              Dimens.boxHeight8,
              Row(
                children: [
                  _presetButton(controller, "2000"),
                  Dimens.boxWidth8,
                  _presetButton(controller, "5000"),
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
                textEditingController: controller.withdrawAmountController,
                onChanged: (value) {
                  controller.update();
                },
                title: "Enter Amount to Withdraw".tr,
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
              Dimens.boxHeight20,
              Text(
                "Select Payout Method",
                style: GoogleFonts.poppins(
                  fontSize: Dimens.fourteen,
                  fontWeight: FontWeight.w600,
                  color: ColorsValue.txtBlackColor,
                ),
              ),
              Dimens.boxHeight10,
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        controller.selectedWithdrawMethod = "Bank";
                        controller.update();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: controller.selectedWithdrawMethod == "Bank"
                              ? ColorsValue.appColor.withOpacity(0.1)
                              : ColorsValue.whiteColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: controller.selectedWithdrawMethod == "Bank"
                                ? ColorsValue.appColor
                                : ColorsValue.borderColors,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_outlined,
                              color: controller.selectedWithdrawMethod == "Bank"
                                  ? ColorsValue.appColor
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Bank Account",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: controller.selectedWithdrawMethod == "Bank"
                                    ? ColorsValue.appColor
                                    : ColorsValue.txtBlackColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Dimens.boxWidth8,
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        controller.selectedWithdrawMethod = "UPI";
                        controller.update();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: controller.selectedWithdrawMethod == "UPI"
                              ? ColorsValue.appColor.withOpacity(0.1)
                              : ColorsValue.whiteColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: controller.selectedWithdrawMethod == "UPI"
                                ? ColorsValue.appColor
                                : ColorsValue.borderColors,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              color: controller.selectedWithdrawMethod == "UPI"
                                  ? ColorsValue.appColor
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "UPI ID",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: controller.selectedWithdrawMethod == "UPI"
                                    ? ColorsValue.appColor
                                    : ColorsValue.txtBlackColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (controller.selectedWithdrawMethod == "UPI") ...[
                Dimens.boxHeight16,
                CustomTextFormField(
                  filled: true,
                  fillColor: ColorsValue.whiteColor,
                  isBorder: true,
                  isCompulsory: true,
                  isTitle: true,
                  textEditingController: controller.withdrawUpiController,
                  title: "Enter UPI ID",
                  hintText: "e.g. mobile@upi, name@okaxis",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: Dimens.twelve,
                    color: ColorsValue.txtG7Color,
                  ),
                  titleStyle: GoogleFonts.poppins(
                    fontSize: Dimens.fourteen,
                    fontWeight: FontWeight.w600,
                    color: ColorsValue.txtBlackColor,
                  ),
                ),
              ] else ...[
                Dimens.boxHeight12,
                Text(
                  "ℹ️ Withdrawal will be credited to your registered bank account.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: ColorsValue.txtG7Color,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _presetButton(HomeController controller, String amount) {
    final bool isSelected = controller.withdrawAmountController.text == amount;
    return Expanded(
      child: InkWell(
        onTap: () {
          controller.withdrawAmountController.text = amount;
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
