
import 'package:bam_bam_driver/app/app.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddFineScreen extends StatelessWidget {
  const AddFineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBarWidget(onTapBack: () => Get.back(), title: "Add Fine"),
          backgroundColor: ColorsValue.appBg,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: Dimens.edgeInsets20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "Enter Booking ID".tr,
                      isBorder: true,
                      isTitle: true,
                      isCompulsory: true,
                      textEditingController: controller.bookindIdController,
                      onChanged: (vaule) {
                        controller.update();
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Enter Booking ID".tr;
                        }
                        return null;
                      },
                      title: "Booking ID".tr,
                      hintStyle: Styles.txtG7Colors40014,
                      titleStyle: Styles.txtG6ColorW40014,
                    ),
                    Dimens.boxHeight16,
                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "Enter Vehicle No.".tr,
                      isBorder: true,
                      isTitle: true,
                      isCompulsory: true,
                      textEditingController: controller.vehicalNumberController,
                      onChanged: (vaule) {
                        controller.update();
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Enter Vehicle No.".tr;
                        }
                        return null;
                      },
                      title: "Vehicle No.".tr,
                      hintStyle: Styles.txtG7Colors40014,
                      titleStyle: Styles.txtG6ColorW40014,
                    ),
                    Dimens.boxHeight16,
                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "Enter Penalty Amount".tr,
                      isBorder: true,
                      isTitle: true,
                      isCompulsory: true,
                      textEditingController: controller.penaltyAmountController,
                      onChanged: (vaule) {
                        controller.update();
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Enter Penalty Amount".tr;
                        }
                        return null;
                      },
                      title: "Penalty Amount ".tr,
                      hintStyle: Styles.txtG7Colors40014,
                      titleStyle: Styles.txtG6ColorW40014,
                    ),
                    Dimens.boxHeight16,
                    CustomTextFormField(
                      style: Styles.txtBlackColorW50016,
                      hintText: "Enter Here".tr,
                      isBorder: true,
                      isTitle: true,
                      maxLines: 4,
                      textEditingController: controller.penaltyDescriptionController,
                      onChanged: (vaule) {
                        controller.update();
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Enter Here".tr;
                        }
                        return null;
                      },
                      title: "Penalty Description".tr,
                      hintStyle: Styles.txtG7Colors40014,
                      titleStyle: Styles.txtG6ColorW40014,
                    ),
                    Dimens.boxHeight16,
                    Dimens.boxHeight17,
                    Text(
                      "Attach Screenshot or Photo",
                      style: Styles.txtG6ColorW40014,
                    ),
                    Dimens.boxHeight10,
                    InkWell(
                      onTap: () async {
                        showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: ColorsValue.whiteColor,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) {
                            return SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Drag handle indicator
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      "Choose Attachment Source",
                                      style: Styles.txtBlackColorW60016.copyWith(fontSize: 18),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Camera Option
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              Get.back();
                                              controller.pickPenaltyPhoto(fromCamera: true);
                                            },
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 20),
                                              decoration: BoxDecoration(
                                                color: ColorsValue.whiteColor,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: ColorsValue.borderColors, width: 1),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.04),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: ColorsValue.appColor.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.camera_alt_rounded,
                                                      color: ColorsValue.appColor,
                                                      size: 28,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    "Camera",
                                                    style: Styles.txtBlackColorW50014.copyWith(fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Gallery Option
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              Get.back();
                                              controller.pickPenaltyPhoto(fromCamera: false);
                                            },
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 20),
                                              decoration: BoxDecoration(
                                                color: ColorsValue.whiteColor,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: ColorsValue.borderColors, width: 1),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.04),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.photo_library_rounded,
                                                      color: Colors.blue,
                                                      size: 28,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    "Gallery",
                                                    style: Styles.txtBlackColorW50014.copyWith(fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: DottedBorder(
                        color: ColorsValue.borderColors,
                        strokeWidth: 1,
                        dashPattern: [6, 3],
                        borderType: BorderType.RRect,
                        radius: Radius.circular(Dimens.twelve),
                        child: Container(
                          padding: Dimens.edgeInsets20,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: Dimens.ten,
                            children: [
                              Icon(
                                Icons.image_search_rounded,
                                size: Dimens.twentyFour,
                              ),
                              Text(
                                controller.penaltyPhoto == null ? "Upload" : "Change Photo",
                                style: Styles.txtBlackColorW50016,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Dimens.boxHeight12,
                    // show preview/filename when selected
                    if (controller.penaltyPhoto != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Selected file:", style: Styles.txtG6ColorW40014),
                          Dimens.boxHeight8,
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: ColorsValue.whiteColor,
                                  image: DecorationImage(
                                    image: FileImage(controller.penaltyPhoto!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Dimens.boxWidth12,
                              Expanded(
                                child: Text(
                                  controller.penaltyPhoto!.path.split('/').last,
                                  style: Styles.txtBlackColorW50016,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  controller.penaltyPhoto = null;
                                  controller.update();
                                },
                                icon: Icon(Icons.clear),
                              ),
                            ],
                          ),
                          Dimens.boxHeight12,
                        ],
                      ),
                    ],
                    Dimens.boxHeight32,
                    controller.isSubmittingFine
                        ? Container(
                            height: Dimens.fifty,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: ColorsValue.appColor,
                              borderRadius: BorderRadius.circular(Dimens.twelve),
                            ),
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : CustomButton(
                            text: "Submit Fine",
                            textStyle: Styles.whiteColorW60016,
                            backgroundColor: ColorsValue.appColor,
                            onPressed: () {
                              controller.submitFine();
                            },
                          ),
                    Dimens.boxHeight24,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
