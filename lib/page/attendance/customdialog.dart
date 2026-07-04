// ignore_for_file: unused_local_variable, strict_top_level_inference, must_be_immutable

import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class CustomDialogView extends StatefulWidget {
  final String title;
  final Widget monthStatus;
  final String? breakStatus;
  final String? image;
  final String? paidLeaveHours;
  final String? holidayCount;
  final String? totalBreak;
  const CustomDialogView({super.key, required this.title, this.image,  required this.monthStatus, this.breakStatus, this.paidLeaveHours, this.holidayCount, this.totalBreak});

  @override
  State<CustomDialogView> createState() => _CustomDialogViewState();
}

class _CustomDialogViewState extends State<CustomDialogView> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Dialog(
      // constraints: BoxConstraints(maxHeight: size.height *0.3, minHeight: size.height * 0.03),
      insetAnimationCurve: Curves.fastEaseInToSlowEaseOut,
      
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      elevation: 0.0,
    
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  dialogContent(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: ColorConst.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // To make the card compact
            children: <Widget>[
              heightSpacer(size.height * 0.09),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16.0),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding:  EdgeInsets.symmetric(horizontal: size.width * 0.03),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.paidLeaveHours == null || widget.paidLeaveHours == '0 : 0' ? Container() :   Row(
                        children: [
                          Icon(Icons.access_time_filled, color: Colors.blueGrey, size: 20),
                          widthSpacer(size.width * 0.02),
                          Text('Paid Leave Hours : ', style: normalHeadingText(size)),
                          widthSpacer(size.width * 0.03),
                          Text(
                            widget.paidLeaveHours ?? '',
                            style: customeHeadingTextsize(size, size.height * 0.020),
                          ),
                        ],
                      ),
                      widget.holidayCount == null || widget.holidayCount == '0 : 0' ? Container() : Row(
                        children: [
                          Icon(Icons.beach_access, color: ColorConst.themeColor, size: 20),
                          widthSpacer(size.width * 0.02),
                          Text('Holiday Hours : ', style: normalHeadingText(size)),
                          widthSpacer(size.width * 0.03),
                          Text(
                            widget.holidayCount ?? '',
                            style: customeHeadingTextsize(size, size.height * 0.020),
                          ),
                        ],
                      ),
                      widget.totalBreak == null || widget.totalBreak == '0 : 0' ? Container() : Row(
                        children: [
                          Icon(Icons.free_breakfast, color: Colors.orange, size: 20),
                          widthSpacer(size.width * 0.02),
                          Text('Total Break : ', style: normalHeadingText(size)),
                          widthSpacer(size.width * 0.03),
                          Text(
                            widget.totalBreak ?? '',
                            style: customeHeadingTextsize(size, size.height * 0.020),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.green, size: 20),
                          widthSpacer(size.width * 0.02),
                          Text(
                            'This month : ',
                            textAlign: TextAlign.center,
                            style: normalHeadingText(size),
                          ),
                          widthSpacer(size.width* 0.03),
                          widget.monthStatus,
                        ],
                      ),
                      heightSpacer(size.height *0.01),
                    widget.breakStatus == null? Container():  Row(
                        children: [
                          Icon(Icons.timer, color: ColorConst.red, size: 20),
                          widthSpacer(size.width * 0.02),
                          Text(
                            'Break Time : ',
                            textAlign: TextAlign.center,
                            style: normalHeadingText(size),
                          ),
                          widthSpacer(size.width* 0.03),
                          Text(widget.breakStatus.toString(), style:   customeHeadingTextsize(
                              size,
                              size.height *
                                  0.020),),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              heightSpacer(size.height *0.02),
            ],
          ),
        ),

        Positioned(
          left: size.width * 0.25,
          right: size.width * 0.25,
          top: -30,
          child: Container(
            height: size.height * 0.12,
            width: size.width * 0.12,
            decoration: BoxDecoration(
              color: ColorConst.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset(widget.image.toString()),
          ),
        ),

        Positioned(
          right: 5,
          top: 15,
          child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.close, color: ColorConst.black, size: 25,)),
        ),
      ],
    );
  }
}

///
class SelectionView extends StatelessWidget {
  String selectionType;
  Color  setbackcolor,setTextColor; 
  final Function ontapButtons;
  SelectionView(this.selectionType,this.setbackcolor,this.setTextColor,this.ontapButtons,{super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return  GestureDetector(
      onTap: (){
        ontapButtons();
      },
      child: Container(
        decoration: BoxDecoration(
         color: setbackcolor,
        borderRadius: BorderRadius.circular(10),
          border: Border.all(color:setTextColor,width: size.width *0.005)
        ),
        child: Padding(
          padding:  EdgeInsets.symmetric(
            horizontal:   size.height *0.02,
            vertical: size.width*0.02
          ),
          child: Text(selectionType.toString(),style: TextStyle(color: setTextColor,fontWeight: FontWeight.bold,fontSize: size.height *0.015),),
        ),
      ),
    );
  }
}