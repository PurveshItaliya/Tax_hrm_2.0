// ignore_for_file: strict_top_level_inference, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class CommonTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int? maxLines;
  final String? errortext;
  final List<TextInputFormatter>? inputformat;
  final List<AutofillHints>? autofillHint;
  final bool? readOnly;
  final TextStyle? hintStyles;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Color? borderColor;
  final Color? fillColors;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final void Function()? onTap;
  final int? maxLength;
  final String? fontFamilys;
  final String? showHeading;
  final Color? hintColor;
  final heightValue;
  final TextStyle? showTextStyle;
  final double? borderRadius;

  const CommonTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly,
    this.maxLength,
    this.inputformat,
    this.autofillHint,
    this.fillColors,
    this.hintStyles,
    this.errortext,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.borderColor,
    this.onChanged,
    this.onEditingComplete,
    this.onTap,
    this.showHeading,
    this.fontFamilys,
    this.hintColor,
    this.showTextStyle,
    this.heightValue,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(showHeading != null)...[
          Text(showHeading ?? '', style: showTextStyle ?? TextStyle(fontFamily: fontFamilys??fontInterBoldString)),
          showHeading != '' ? heightSpacer(heightValue??size.height * 0.015) : Container(),
        ],
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onTap: onTap,
          cursorColor: ColorConst.black,
          textAlignVertical: TextAlignVertical.top,
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          readOnly: readOnly ?? false,
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: inputformat,
          style: TextStyle(color: ColorConst.black,fontFamily: fontInterRegularString,fontSize:  15,),
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            errorMaxLines: 2,
            errorText: errortext,
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: borderColor ?? ColorConst.red,
                width: 1.3,
              ),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 4.0)),
            ),
            contentPadding: EdgeInsets.all(15),
            hintStyle:
                hintStyles ??
                TextStyle(color: hintColor??ColorConst.hintextColor,fontFamily: fontInterMediumString,fontSize: 14,),
            prefixIcon: prefixIcon,
            prefixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
            suffixIcon: suffixIcon,
            suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: borderColor ?? ColorConst.textBorder,
                width: 1.3,
              ),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 4.0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: borderColor ?? ColorConst.textBorder,
                width: 1.3,
              ),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 4.0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: borderColor ?? ColorConst.textBorder,
                width: 1.3,
              ),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 4.0)),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: borderColor ?? ColorConst.textBorder,
                width: 1.3,
              ),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 4.0)),
            ),
            filled: true,
            fillColor: fillColors ?? ColorConst.transparent,
          ),
          onEditingComplete:
              onEditingComplete ??
              () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
          onChanged: onChanged,
        ),
      ],
    );
  }
}

//------------------------------------ Phone Number Textfiled ------------------------------------------------\\

class PhoneNumberTextFiled extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? errortext;
  final List<TextInputFormatter>? inputformat;
  final List<AutofillHints>? autofillHint;
  final bool? readOnly;
  final TextStyle? hintStyles;
  final String? Function(PhoneNumber?)? validator;
  final Color? borderColor;
  final Color? fillColors;
  final void Function(PhoneNumber)? onChanged;
  final void Function()? onTap;
  final String? fontFamilys;
  final String? showHeading;
  final String? getcodes;
  final Color? hintColor;
  final double? borderRadius;

  const PhoneNumberTextFiled({
    super.key,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly,
    this.inputformat,
    this.autofillHint,
    this.fillColors,
    this.hintStyles,
    this.errortext,
    this.obscureText = false,
    this.validator,
    this.borderColor,
    this.onChanged,
    this.onTap,
    this.showHeading,
    this.fontFamilys,
    this.hintColor,
    this.getcodes,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(showHeading != null)...[
          Text(showHeading ?? '', style: TextStyle(fontFamily: fontFamilys??fontInterBoldString)),
          showHeading != '' ? heightSpacer(size.height * 0.015) : Container(),
        ],
        IntlPhoneField(
          onTap: onTap,
          cursorColor: ColorConst.black,
          textAlignVertical: TextAlignVertical.top,
          controller: controller,
          validator: validator,
          readOnly: readOnly ?? false,
          enabled: !(readOnly ?? false),
          obscureText: obscureText,
          showCursor: !(readOnly ?? false),
          inputFormatters: inputformat,
          dropdownIconPosition: IconPosition.trailing,
          style: TextStyle(color: ColorConst.black,fontFamily: fontInterRegularString,fontSize: 17,),
          initialCountryCode: getcodes,
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            errorMaxLines: 2,
            errorText: errortext,
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: borderColor ?? ColorConst.red,
                width: 1.3,
              ),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 4.0)),
            ),
            contentPadding: EdgeInsets.all(15),
            hintStyle:
                hintStyles ??
                TextStyle(color: hintColor??ColorConst.hintextColor,fontFamily: fontInterMediumString,fontSize: 14,),
            prefixIcon: prefixIcon,
            prefixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
            suffixIcon: suffixIcon,
            suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
            counterText: '',
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: borderColor ?? ColorConst.textBorder,
                width: 1.3,
              ),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 4.0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: borderColor ?? ColorConst.textBorder,
                width: 1.3,
              ),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 4.0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: borderColor ?? ColorConst.textBorder,
                width: 1.3,
              ),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 4.0)),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: borderColor ?? ColorConst.textBorder,
                width: 1.3,
              ),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 4.0)),
            ),
            filled: true,
            fillColor: fillColors ?? ColorConst.transparent,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}


// ==========================================================================================================================================================================//