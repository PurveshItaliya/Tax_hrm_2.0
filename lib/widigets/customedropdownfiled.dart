// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

Widget commonDropDownField({size, borderColor, fillColors, onChanged,List<String>? listName,selectedValue,hintextString}) {
  return Container(
    height: size.height * 0.07,
    decoration: BoxDecoration(
      color: fillColors ?? ColorConst.transparent,
      border: Border.all(
        color: borderColor ?? ColorConst.textBorder,
        width: 1.3,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(4.0)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        items: listName!
            .map(
              (String item) => DropdownItem<String>(
                value: item,
                child: Text(
                  LanguageProvider.translate(item, item),
                  style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold,color: ColorConst.black,),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        hint: Text(selectedValue != null ? LanguageProvider.translate(selectedValue, selectedValue) : hintextString,style: TextStyle(color: selectedValue != null ? ColorConst.black : ColorConst.hintextColor,fontFamily: fontInterMediumString,fontSize: 15,),),
        onChanged: onChanged,
        isExpanded: true,
        
        iconStyleData: IconStyleData(
          icon: const Icon(Icons.arrow_drop_down_sharp),
          iconSize: 25,
          iconEnabledColor: ColorConst.passwordColor,
          iconDisabledColor: ColorConst.grey,
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            color: ColorConst.white,
          ),
        ),
      ),
    ),
  );
}
