import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivcyPolicyScreen extends StatelessWidget {
  const PrivcyPolicyScreen({super.key});

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
            title: "Privacy Policy",
            onTapBack: () {
              Get.back();
            },
          ),
          body: ListView(
            padding: Dimens.edgeInsets20,
            children: [
              Text("1. Information We Collect", style: headingStyle),
              Dimens.boxHeight6,
              bulletPoint(
                "Personal Information: Name, phone number, email, profile photo, date of birth, emergency contact.",
              ),
              bulletPoint(
                "Identity & Vehicle Documents: Driver’s license, vehicle registration certificate (RC), insurance documents, Aadhar or government-issued ID.",
              ),
              bulletPoint(
                "Device & App Usage Info: Device type, operating system, app version, crash logs, and usage patterns.",
              ),
              Dimens.boxHeight20,
              Text("2. How We Use Your Information", style: headingStyle),
              Dimens.boxHeight6,
              Text(
                "We use your information for the following purposes:",
                style: contentStyle,
              ),
              Dimens.boxHeight3,
              bulletPoint(
                "To verify your identity and eligibility to drive on the platform",
              ),
              bulletPoint(
                "To assign trips and notify you about upcoming bookings",
              ),
              bulletPoint(
                "To process payments, bonuses, and transaction history",
              ),
              bulletPoint("To provide customer support and resolve issues"),
              bulletPoint("To improve app performance and user experience"),
              bulletPoint("To comply with local laws and legal obligations"),
              Dimens.boxHeight20,

              Text("3. Sharing of Information", style: headingStyle),
              Dimens.boxHeight6,
              Text(
                "We may share limited information with:",
                style: contentStyle,
              ),
              Dimens.boxHeight3,
              bulletPoint(
                "Customers: Basic details like name, photo, and vehicle info during an active trip",
              ),
              bulletPoint(
                "Payment Partners: For secure transaction processing",
              ),
              bulletPoint(
                "Government Authorities: When legally required for compliance or investigation",
              ),
              Dimens.boxHeight6,
              Text(
                "We do not sell or rent your personal data to third parties.",
                style: contentStyle,
              ),
              Dimens.boxHeight20,

              Text("4. Data Security", style: headingStyle),
              Dimens.boxHeight6,
              Text(
                "We use industry-standard security practices including encryption, access controls, and secure servers to protect your data. Your data is stored securely and only accessible by authorized personnel.",
                style: contentStyle,
              ),
              Dimens.boxHeight20,

              Text("5. Your Rights & Choices", style: headingStyle),
              Dimens.boxHeight6,
              Text("You may:", style: contentStyle),
              Dimens.boxHeight3,
              bulletPoint(
                "Access or update your personal information in the app",
              ),
              bulletPoint(
                "Request deletion of your account and associated data",
              ),
              bulletPoint("Opt out of non-essential notifications"),
              Dimens.boxHeight20,

              Text("6. Data Retention", style: headingStyle),
              Dimens.boxHeight6,
              Text(
                "We retain your data as long as your account is active and as required by applicable laws. If you deactivate your account, we will delete your data unless retention is legally required.",
                style: contentStyle,
              ),
              Dimens.boxHeight20,

              Text("7. Changes to This Policy", style: headingStyle),
              Dimens.boxHeight6,
              Text(
                "We may update this Privacy Policy occasionally. You will be notified of any major changes via app notification or email.",
                style: contentStyle,
              ),
              Dimens.boxHeight20,

              Text("11. Contact Us", style: headingStyle),
              Dimens.boxHeight6,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("📧 ", style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      "privacy@bambamcarrental.com",
                      style: contentStyle,
                    ),
                  ),
                ],
              ),
              Dimens.boxHeight6,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("📞 ", style: TextStyle(fontSize: 16)),
                  Expanded(child: Text("+91-XXXXXXXXXX", style: contentStyle)),
                ],
              ),
              Dimens.boxHeight30,
            ],
          ),
        );
      },
    );
  }
}
