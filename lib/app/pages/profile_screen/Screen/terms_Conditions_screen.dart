import 'package:bam_bam_driver/app/app.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle headingStyle = Styles.txtBlackColorW60016;
    TextStyle contentStyle = Styles.txtG7Colors40014;
    TextStyle bulletStyle = Styles.txtG7Colors40014.copyWith(height: 1.5);

    Widget bulletPoint(String text) {
      return Padding(
        padding: EdgeInsets.only(bottom: Dimens.six),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("• ", style: bulletStyle),
            Expanded(child: Text(text, style: bulletStyle)),
          ],
        ),
      );
    }

    return GetBuilder<ProfileController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "Terms & Conditions",
          ),
          body: ListView(
            padding: Dimens.edgeInsets20,
            children: [
              Text("1. Acceptance of Terms", style: headingStyle),
              Dimens.boxHeight8,
              Text(
                "By registering and using the Bam Bam Driver App, you agree to abide by all the terms and conditions outlined here. These terms apply to all drivers who access or use the service.",
                style: contentStyle,
              ),
              Dimens.boxHeight20,

              Text("2. Eligibility", style: headingStyle),
              Dimens.boxHeight8,
              Text(
                "Drivers must be at least 21 years old, hold a valid driver’s license, and have approved documents to use the platform.",
                style: contentStyle,
              ),
              Dimens.boxHeight20,

              Text("3. Driver Responsibilities", style: headingStyle),
              Dimens.boxHeight8,
              bulletPoint("Ensure vehicle cleanliness and punctual service"),
              bulletPoint("Follow all traffic laws"),
              bulletPoint("Use the app only for assigned trips"),
              bulletPoint(
                "Maintain respectful behavior with all customers and staff",
              ),
              Dimens.boxHeight20,

              Text("4. Cancellation Policy", style: headingStyle),
              Dimens.boxHeight8,
              Text(
                "Frequent or last-minute cancellations without valid reasons may result in temporary suspension or penalties.",
                style: contentStyle,
              ),
              Dimens.boxHeight20,

              Text("5. Platform Usage", style: headingStyle),
              Dimens.boxHeight8,
              Text(
                "Drivers shall not share accounts or misuse the platform for activities unrelated to service.",
                style: contentStyle,
              ),
              Dimens.boxHeight20,

              Text("6. Suspension & Termination", style: headingStyle),
              Dimens.boxHeight8,
              Text(
                "The company reserves the right to suspend or terminate access to the app in case of rule violations, fraudulent activity, or customer complaints.",
                style: contentStyle,
              ),
              Dimens.boxHeight20,
              Text("7. Modification of Terms", style: headingStyle),
              Dimens.boxHeight8,
              Text(
                "Bam Bam reserves the right to update these terms. Continued use of the app implies acceptance of any new changes.",
                style: contentStyle,
              ),
              Dimens.boxHeight20,
            ],
          ),
        );
      },
    );
  }
}
