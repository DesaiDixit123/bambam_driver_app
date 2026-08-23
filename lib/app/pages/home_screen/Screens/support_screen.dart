import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },

            title: "Help & Support",
          ),
          backgroundColor: ColorsValue.appBg,
          body: ListView(
            padding: Dimens.edgeInsets20,
            children: [
              showDetiles(
                helpName: "🚗 Trip Issues",
                helpdep:
                    "Delay, incorrect address, or customer no-show? Report it here.",
                helplink: "Report Trip Issue",
              ),
              showDetiles(
                helpName: "📄 Documents & Profile",
                helpdep:
                    "Trouble uploading documents or updating your profile?",
                helplink: "Report Issue",
              ),
              showDetiles(
                helpName: "📞 Call Support",
                helpdep: "Talk to our driver support team",
                helplink: "Call 1800 889 5665",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget showDetiles({
    required String helpName,
    required String helpdep,
    required String helplink,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Text(helpName, style: Styles.txtBlackColorW60016),
        Dimens.boxHeight6,
        Text(helpdep, style: Styles.txtG5ColorsW40014),
        Dimens.boxHeight6,
        Row(
          children: [
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Text(
                  helplink.tr,
                  style: Styles.txtRedColorW50014.copyWith(
                    color: ColorsValue.appColor,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    height: 1,
                    width: Dimens
                        .hundredFiftyOne, // or dynamically match text width
                    color: ColorsValue.appColor, // your custom underline color
                  ),
                ),
              ],
            ),
          ],
        ),
        Dimens.boxHeight20,
      ],
    );
  }
}
