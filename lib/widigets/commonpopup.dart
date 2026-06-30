// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

employeStatusPopBox(context,size,Function ontapAll, Function onTapActive, Function onTapInActive){

showMenu(
      context: context,
      color: ColorConst.white,
      position: RelativeRect.fromLTRB(size.width * 0.09, size.height * 0.1, 0, 0),
      items: [
        PopupMenuItem(
          value: 1,
          onTap: () {
            
            ontapAll();
          },
          // row has two child icon and text.
          child:  Row(
            children: [
           const  Icon(Icons.person_outline,color: Colors.black,),
              const SizedBox(
                // sized box with width 10
                width: 10,
              ),
              Text("All", style: normalHeadingText(size),)
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          onTap: () {
         onTapActive();
          },
          // row has two child icon and text
          child: Row(
            children: [
               Icon(Icons.person_4,color: Colors.black),
              const SizedBox(
                // sized box with width 10
                width: 10,
              ),
              Text("Active", style: normalHeadingText(size),)
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          onTap: () {
         onTapInActive();
          },
          // row has two child icon and text
          child: Row(
            children: [
               Icon(Icons.person_4,color: Colors.red),
              const SizedBox(
                // sized box with width 10
                width: 10,
              ),
              Text("In Active", style: normalHeadingText(size),)
            ],
          ),
        ),
       
      ],
  );

}