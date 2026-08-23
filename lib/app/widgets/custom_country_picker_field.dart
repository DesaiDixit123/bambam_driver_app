// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:bam_bam_driver/app/app.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class CustomCountryPickerField extends StatelessWidget {
  CustomCountryPickerField({
    super.key,
    required this.text,
    this.isTitle,
    this.validation,
    required this.hintText,
    this.initialvalue,
    this.keyboardAction,
    this.onInputChanged,
    this.oninitialValidation,
    this.textEditingController,
    this.prefixIcon,
    this.radius,
    this.isBorder,
    this.titleStyle,
    this.hintStyle,
    this.fillColor,
  });
  bool? isTitle;
  final String text;
  final String hintText;
  final String? Function(String?)? validation;
  final PhoneNumber? initialvalue;
  final Function(PhoneNumber)? onInputChanged;
  final Function(bool)? oninitialValidation;
  final TextEditingController? textEditingController;
  TextInputAction? keyboardAction;
  Widget? prefixIcon;
  double? radius;
  bool? isBorder;
  TextStyle? titleStyle;
  TextStyle? hintStyle;
  Color? fillColor;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      isTitle == true ? Text(text, style: titleStyle) : const SizedBox(),
      Dimens.boxHeight7,
      InternationalPhoneNumberInput(
        textFieldController: textEditingController,
        validator: validation,
        onInputChanged: onInputChanged,
        onInputValidated: oninitialValidation,
        keyboardAction: keyboardAction,
        initialValue: initialvalue,
        autoValidateMode: AutovalidateMode.onUserInteraction,
        ignoreBlank: false,
        formatInput: false,
        selectorConfig: const SelectorConfig(
          selectorType: PhoneInputSelectorType.DROPDOWN,
          setSelectorButtonAsPrefixIcon: true,
          trailingSpace: false,
          showFlags: true,
        ),
        selectorTextStyle: Styles.blackColorW50016,
        textAlign: TextAlign.start,
        keyboardType: const TextInputType.numberWithOptions(
          signed: false,
          decimal: false,
        ),
        inputBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius ?? Dimens.eight),
          borderSide: BorderSide(
            width: Dimens.one,
            color: ColorsValue.appColor,
          ),
        ),
        inputDecoration: InputDecoration(
          contentPadding: Dimens.edgeInsets20_10_20_10,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius ?? Dimens.eight),
            borderSide: isBorder ?? false
                ? BorderSide(width: Dimens.one, color: ColorsValue.appColor)
                : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius ?? Dimens.eight),
            borderSide: isBorder ?? false
                ? BorderSide(width: Dimens.one, color: ColorsValue.appColor)
                : BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius ?? Dimens.eight),
            borderSide: isBorder ?? false
                ? BorderSide(width: Dimens.one, color: ColorsValue.appColor)
                : BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius ?? Dimens.eight),
            borderSide: isBorder ?? false
                ? BorderSide(width: Dimens.one, color: ColorsValue.appColor)
                : BorderSide.none,
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius ?? Dimens.eight),
            borderSide: isBorder ?? false
                ? BorderSide(width: Dimens.one, color: ColorsValue.appColor)
                : BorderSide.none,
          ),
          hintText: hintText,
          hintStyle: hintStyle,
          filled: true,
          fillColor: fillColor ?? ColorsValue.whiteColor,
          prefixIcon: prefixIcon,
        ),
      ),
    ],
  );
}
