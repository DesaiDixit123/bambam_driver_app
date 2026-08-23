import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:bam_bam_driver/app/app.dart';

// ignore: must_be_immutable
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  AppBarWidget({
    super.key,
    required this.onTapBack,
    required this.title,
    this.isVisible = true,
    this.isCenter = false,
    this.actions,
  });

  void Function()? onTapBack;
  String title;
  bool isVisible;
  bool isCenter;
  List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorsValue.appBg,
      centerTitle: isCenter ? true : false,
      automaticallyImplyLeading: false,
      leadingWidth: isVisible ? Dimens.eighty * .95 : Dimens.twenty,
      leading: Row(
        children: [
          Dimens.boxWidth20,
          Visibility(
            visible: isVisible,
            child: InkWell(
              borderRadius: BorderRadius.circular(Dimens.fifty),
              onTap: onTapBack,
              child: Container(
                height: Dimens.thirtyEight,
                width: Dimens.thirtyEight,
                decoration: BoxDecoration(
                  color: ColorsValue.appBg,

                  borderRadius: BorderRadius.circular(Dimens.twenty),
                  border: Border.all(color: ColorsValue.borderColors),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              ),
              // child: SvgPicture.asset(
              //   AssetConstants.ic_backArrow,
              //   height: Dimens.thirtyEight,
              //   width: Dimens.thirtyEight,
              // ),
            ),
          ),
        ],
      ),
      titleSpacing: Dimens.zero,
      title: Text(title, style: Styles.txtBlackColorW70018),
      actions: actions,
    );
  }

  static final _appBar = AppBar();

  @override
  Size get preferredSize => AppBarWidget._appBar.preferredSize;
}
