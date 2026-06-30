// ignore_for_file: file_names, strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

class FixText extends StatelessWidget {
  final String dataName;
  final double textSize;
  final Color colors;
  final FontWeight? fontWeight;
  final TextAlign? textalign;
  final TextOverflow? overflow;

  const FixText({
    required this.dataName,
    required this.textSize,
    this.fontWeight,
    super.key,
    required this.colors,
    this.textalign, 
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      dataName,
      textAlign: textalign,
      style: TextStyle(

          fontSize: textSize,
           overflow: TextOverflow.ellipsis,
          fontWeight: fontWeight,
          color: colors,
      ),
    );
  }
}

normalHeadingText(Size size,{fontFamilys,fontSizes,textColor}){
  return TextStyle(color: textColor ?? ColorConst.black,fontWeight: FontWeight.bold,fontSize: fontSizes??size.height*0.017,fontFamily: fontFamilys?? fontInterRegularString);
}


normalGrayHeadingText(Size size,{fontFamilys}){
  return TextStyle(color: ColorConst.grey,fontWeight: FontWeight.bold,fontSize: size.height*0.015,fontFamily: fontFamilys?? fontInterRegularString);
}


customeHeadingTextsize(Size size,double fontSizes,{fontFamilys}){
  return TextStyle(color: ColorConst.black,fontWeight: FontWeight.bold,fontSize: fontSizes,fontFamily: fontFamilys?? fontInterRegularString);
}


boxSizeDataText({required double setboxWidth,required String showData,required TextStyle useStyle,required int useMaxline}){
  return SizedBox(
    width: setboxWidth,
    child: Text(showData,style: useStyle,maxLines: useMaxline,overflow: TextOverflow.ellipsis,),
  );
}


boxDataText({required String showData, required Size size}){
  return Text(showData,style: normalHeadingText(size),overflow: TextOverflow.ellipsis,);
}

appbarTextStyles(Size size,{titleColors}){
  return  TextStyle(fontSize: size.height * 0.025,fontFamily: fontInterSemiBoldString,color: titleColors ?? ColorConst.appBarTitleColor);
}

TextStyle useDefaultTextStyle = TextStyle(
  color: ColorConst.black,
  fontWeight: FontWeight.bold,
  fontSize: 20,
  fontFamily: fontInterRegularString
);