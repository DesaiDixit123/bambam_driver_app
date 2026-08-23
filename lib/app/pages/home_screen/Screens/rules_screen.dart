import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "Guidelines & Platform Rules",
          ),
          backgroundColor: ColorsValue.appBg,
          body: ListView(
            padding: Dimens.edgeInsets20,
            children: [
              showRules(
                rules: "Rule 1: Maintain Clean Vehicles",
                dep:
                    "All vehicles must be clean inside and out before starting each ride.",
              ),
              showRules(
                rules: "Rule 2: Be On Time",
                dep:
                    "Always reach the pickup location 10–15 minutes early. Punctuality is essential.",
              ),
              showRules(
                rules: "Rule 3: Use App to Update Status",
                dep:
                    "Mark your arrival, trip start, and trip end accurately via the app.",
              ),
              showRules(
                rules: "Rule 4: Respect All Customers",
                dep:
                    "Polite, professional behavior is mandatory. No rude language or misconduct will be tolerated.",
              ),
              showRules(
                rules: "Rule 5: Don’t Cancel Frequently",
                dep:
                    "Avoid last-minute cancellations. It affects customer experience and may lead to penalties.",
              ),
              showRules(
                rules: "Rule 6: Follow All Traffic Laws",
                dep:
                    "Drive safely, wear seat belts, and avoid phone usage while driving.",
              ),
              showRules(
                rules: "Rule 7: Keep Documents Updated",
                dep:
                    "Ensure your license, RC, insurance, and permits are valid and uploaded in the app.",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget showRules({required String rules, required String dep}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(rules, style: Styles.txtBlackColorW50016),
        Dimens.boxHeight6,
        Text(dep, style: Styles.txtG5ColorsW40014),
        Dimens.boxHeight12,
      ],
    );
  }
}
