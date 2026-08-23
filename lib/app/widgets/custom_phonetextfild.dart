import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../app.dart';

// ignore: must_be_immutable
class CustomInternationalPhoneFild extends StatefulWidget {
  CustomInternationalPhoneFild({
    super.key,
    required this.text,
    this.validation,
    required this.hintText,
    this.initialvalue,
    this.keyboardAction,
    this.onInputChanged,
    this.oninitialValidation,
    this.textEditingController,
    this.radius = 5,
    this.hintStyle,
    this.fillColor,
  });
  final String text;
  final String hintText;
  final String? Function(String?)? validation;
  final PhoneNumber? initialvalue;
  final Function(PhoneNumber)? onInputChanged;
  final Function(bool)? oninitialValidation;
  final TextEditingController? textEditingController;
  TextInputAction? keyboardAction;
  double radius;
  Color? fillColor;
  TextStyle? hintStyle;

  @override
  State<CustomInternationalPhoneFild> createState() =>
      _CustomInternationalPhoneFildState();
}

class _CustomInternationalPhoneFildState
    extends State<CustomInternationalPhoneFild> {
  @override
  Widget build(BuildContext context) => InternationalPhoneNumberInput(
    onInputChanged: widget.onInputChanged,
    textStyle: Styles.black50018,
    onInputValidated: widget.oninitialValidation,
    initialValue: widget.initialvalue,
    keyboardAction: widget.keyboardAction,
    selectorConfig: const SelectorConfig(
      selectorType: PhoneInputSelectorType.DROPDOWN,
      setSelectorButtonAsPrefixIcon: true,
      trailingSpace: false,
      showFlags: true,
    ),
    ignoreBlank: false,
    autoValidateMode: AutovalidateMode.onUserInteraction,
    textFieldController: widget.textEditingController,
    formatInput: false,
    keyboardType: const TextInputType.numberWithOptions(
      signed: false,
      decimal: false,
    ),
    inputBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: ColorsValue.borderColors),
    ),
    inputDecoration: InputDecoration(
      contentPadding: Dimens.edgeInsets10,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(width: Dimens.one, style: BorderStyle.none),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(width: Dimens.zero, style: BorderStyle.none),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(width: Dimens.zero, style: BorderStyle.none),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(width: Dimens.zero, style: BorderStyle.none),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(width: Dimens.zero, style: BorderStyle.none),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      hintText: widget.hintText,
      hintStyle: widget.hintStyle,
      filled: true,
      fillColor: widget.fillColor,
    ),
    validator: widget.validation,
  );
}
