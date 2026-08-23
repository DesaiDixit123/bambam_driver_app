import 'package:bam_bam_driver/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,

          body: ListView(
            //padding: Dimens.edgeInsets20,
            children: [
              Dimens.boxHeight30,
              Center(
                child: Stack(
                  children: [
                    SvgPicture.asset(
                      AssetConstants.ic_user2,
                      height: Dimens.hundred,
                      width: Dimens.hundred,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: SvgPicture.asset(AssetConstants.ic_edit_Imge),
                    ),
                  ],
                ),
              ),
              Dimens.boxHeight60,
              ListTile(
                title: Text(
                  "personal_information".tr,
                  style: Styles.txtBlackColorW60016,
                ),
                onTap: () {
                  RouteManagement.gotoPersonalDetilesScreen();
                },
                leading: SvgPicture.asset(AssetConstants.User),

                trailing: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: Dimens.seventeen,
                ),
              ),
              //     Divider(color: ColorsValue.borderColors, height: Dimens.one),
              ListTile(
                title: Text(
                  "privacy_policy".tr,
                  style: Styles.txtBlackColorW60016,
                ),
                onTap: () {
                  RouteManagement.gotoPrivcyPolicyScreen();
                },
                leading: SvgPicture.asset(AssetConstants.ic_privacy),

                trailing: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: Dimens.seventeen,
                ),
              ),
              //     Divider(color: ColorsValue.borderColors, height: Dimens.one),
              ListTile(
                title: Text(
                  "terms_condition".tr,
                  style: Styles.txtBlackColorW60016,
                ),
                onTap: () {
                  RouteManagement.gotoTermsConditionsScreen();
                },
                leading: SvgPicture.asset(AssetConstants.ic_terms),

                trailing: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: Dimens.seventeen,
                ),
              ),
              //      Divider(color: ColorsValue.borderColors, height: Dimens.one),
              ListTile(
                title: Text(
                  "support_feedback".tr,
                  style: Styles.txtBlackColorW60016,
                ),
                onTap: () {
                  RouteManagement.gotoMyTicketlistScreen();
                },
                leading: SvgPicture.asset(AssetConstants.ic_Headphones),

                trailing: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: Dimens.seventeen,
                ),
              ),

              //     Divider(color: ColorsValue.borderColors, height: Dimens.one),
              Dimens.boxHeight200,
              // Padding(
              //   padding: Dimens.edgeInsets20,
              //   child: CustomButton(
              //     backgroundColor: ColorsValue.redColor,
              //     isBorder: false,

              //     onPressed: () {
              //       // RouteManagement.gotoLoginScreen();
              //       controller.showLogoutDelog(context);
              //     },
              //     text: "Logout",
              //     textStyle: Styles.whiteColorW60016,
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }
}
