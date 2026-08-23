
import 'dart:io';

import 'package:bam_bam_driver/app/widgets/custom_button.dart';
import 'package:bam_bam_driver/app/widgets/custom_text_form_field.dart';
import 'package:bam_bam_driver/app/widgets/droup_down_widgets.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:bam_bam_driver/app/pages/profile_screen/profile_controller.dart';
import 'package:bam_bam_driver/app/theme/colors_value.dart';
import 'package:bam_bam_driver/app/theme/dimens.dart';
import 'package:bam_bam_driver/app/theme/styles.dart';

import 'package:bam_bam_driver/app/widgets/app_bar_widgets.dart';


import 'package:dotted_border/dotted_border.dart';

import 'package:image_picker/image_picker.dart';


class CreatTicketScreen extends StatelessWidget {
  const CreatTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "Submit a Support Request",
          ),
          body: ListView(
            padding: Dimens.edgeInsets20,
            children: [
              DroupDownButtonWigeat<String>(
                hintText: "Select".tr,
                isTitle: true,
                borderRadius: BorderRadius.circular(Dimens.twelve),
                items: controller.issueList,
                value: controller.selectedIssue,
                onChanged: (newValue) {
                  controller.selectedIssue = newValue ?? "";
                  controller.update();
                },
                textStyle: Styles.txtBlackColorW50016,
                isCompulsory: true,
                title: "What is your issue about?".tr,
                hintStyle: Styles.txtG7Colors50016,
                titleStyle: Styles.txtG6ColorW40014,
                isBorder: true,
              ),
              Dimens.boxHeight16,
              CustomTextFormField(
                style: Styles.txtBlackColorW50016,
                hintText: "Enter Booking ID".tr,
                isBorder: true,
                isTitle: true,
                isCompulsory: true,
                textEditingController: controller.bookingIDController,
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
                textEditingController: controller.ticketsDateController,

                style: Styles.txtBlackColorW50016,
                isBorder: true,
                hintText: "select".tr,
                hintStyle: Styles.txtG7Colors50016,
                isTitle: true,
                readOnly: true,
                suffixIcon: IconButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2050),
                    );
                    if (picked != null) {
                      controller.ticketsDateController.text = DateFormat(
                        'dd-MM-yyyy',
                      ).format(picked);
                    }
                  },
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    color: ColorsValue.txtBlackColor,
                  ),
                ),
                title: 'Date'.tr,
                isCompulsory: true,
                titleStyle: Styles.txtG6ColorW40014,

                validator: (value) {
                  if (value?.isEmpty == true) {
                    return "Select date";
                  }
                  return null;
                },
              ),
              Dimens.boxHeight16,
              CustomTextFormField(
                style: Styles.txtBlackColorW50016,
                hintText: "Enter Here".tr,
                isBorder: true,
                isTitle: true,
                isCompulsory: true,
                maxLines: 3,
                textEditingController: controller.ticketDepController,
                onChanged: (vaule) {
                  controller.update();
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Enter Here".tr;
                  }
                  return null;
                },
                title: "Share Your Thoughts Below!".tr,
                hintStyle: Styles.txtG7Colors40014,
                titleStyle: Styles.txtG6ColorW40014,
              ),

              Dimens.boxHeight17,
              Text(
                "Attach Screenshot or Photo",
                style: Styles.txtG6ColorW40014,
              ),
              Dimens.boxHeight10,
              DottedBorder(
                color: ColorsValue.borderColors,
                strokeWidth: 1,
                dashPattern: [6, 3],
                borderType: BorderType.RRect,
                radius: Radius.circular(Dimens.twelve),
                child: Container(
                  padding: Dimens.edgeInsets20,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: Dimens.ten,
                        children: [
                        // inside the DottedBorder child replace Row with InkWell to pick image
                      InkWell(
                        onTap: () async {
                         // final allowed = await Utility.imagePermissionCheack(context);
                      
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                          if (picked != null) {
                            controller.setAttachment(File(picked.path));
                          }
                        },
                        child: Container(
                          padding: Dimens.edgeInsets20,
                          child: controller.ticketAttachment == null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_search_rounded, size: Dimens.twentyFour),
                                    SizedBox(width: Dimens.ten),
                                    Text("Upload", style: Styles.txtBlackColorW50016),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Text(controller.ticketAttachment!.path.split('/').last),
                                    Dimens.boxHeight8,
                                    Image.file(controller.ticketAttachment!, height: 120, fit: BoxFit.cover),
                                  ],
                                ),
                        ),
                      ),
                      Dimens.boxHeight30,
                      
                      // Submit button
                      
                      
                        ],
                      ),
                  CustomButton(
  text: "Submit",
  backgroundColor: ColorsValue.appColor,
  textStyle: Styles.txtBlackColorW50016,
  onPressed: () {
    controller.createTicket();
  },
),  ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
