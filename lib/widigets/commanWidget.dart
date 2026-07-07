// ignore_for_file: strict_top_level_inference, file_names, use_build_context_synchronously

import 'package:tax_hrm/widigets/app_searchable_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/company/getallcompany.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/provider/documentprovider.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/provider/notesprovider.dart';
import 'package:tax_hrm/provider/setting_provider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/utils/validation.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/spacer.dart';
import 'package:image_picker/image_picker.dart';

// all button design 
Widget btnDesign(Size size,{width, height, bgColor, alignments, titles, textColors, fontSizes, VoidCallback? onTap,borderColors, bool? isgradient,borderRadiused, borderWidth}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: height ?? size.width * 0.15,
      width: width ?? size.width,
      alignment: alignments ?? Alignment.center,
      decoration: BoxDecoration(
        border: BoxBorder.all(color: borderColors?? ColorConst.transparent,width: borderWidth ?? 1.5),
        gradient: LinearGradient(colors: isgradient == true ? [ColorConst.themeColor, ColorConst.darkGreenColor] : [ColorConst.white, ColorConst.white], begin: Alignment.topCenter,end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(borderRadiused??4),
      ),
     child: Text(
        titles,
        style: TextStyle(
          fontSize: fontSizes ?? size.height * 0.025,
          fontFamily: fontInterBoldString,
          color: textColors ?? ColorConst.white,
        ),
      ),
    ),
  );
}

// leave Comman Box
Widget leaveCommanBoxDesign(Size size,titles,subtitles,{titletextColors,subtitletextColors,fontSize,fontFamily}) {
  return Row(
    children: [
      Expanded(
        child: Text(titles,style: TextStyle(color: titletextColors??ColorConst.leaveTextColor, fontSize: fontSize??14,fontFamily: fontFamily??fontInterSemiBoldString)),
      ),
      widthSpacer(size.width*0.02),
      Text(subtitles,style: TextStyle(color: subtitletextColors??ColorConst.leaveTextColor, fontSize: fontSize??14,fontFamily: fontFamily??fontInterSemiBoldString)),
    ],
  );
}

// icon With Text Btn Design
Widget iconWithTextBtnDesign(size,titles,{iconNames,isIcon,onTap, bool? isgradient,isImage}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isgradient == true ? [ColorConst.themeColor, ColorConst.darkGreenColor] : [ColorConst.white, ColorConst.white], begin: Alignment.topCenter,end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(isIcon)...[
            Icon(iconNames, color: ColorConst.white),
            SizedBox(width: 10),
          ],
          if(isImage)...[
            Image.asset(iconNames, color: ColorConst.white,height: size.width * 0.055,),
            SizedBox(width: 10),
          ],
          
          Text(titles, style: TextStyle(color: ColorConst.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

// no dataFounds
Widget noDataFoundsDesign(Size size,titles,images,{width}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(images,width: width ?? size.width*0.75,),
      heightSpacer(size.height*0.015),
      Text(titles,style: TextStyle(fontFamily: fontInterSemiBoldString,fontSize: 24,fontWeight: FontWeight.w600,color: ColorConst.nodataTitleColors),),
    ],
  );
}

// Custom Doted Border Design
class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  DottedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.dashLength = 6,
    this.gapLength = 4,
    this.radius = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;

    double distance = 0;
    while (distance < metrics.length) {
      canvas.drawPath(
        metrics.extractPath(distance, distance + dashLength),
        paint,
      );
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Only For attendance Counting
Widget summaryTile(BuildContext context, Size size, String title, String value, Color color, {bgColors,onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: bgColors??ColorConst.greyOpicityColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          widthSpacer(size.width * 0.02),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style:  TextStyle( fontSize: size.width * 0.035, color: Colors.grey, fontFamily: fontInterMediumString, fontWeight: FontWeight.w500)),
              num.tryParse(value) != null 
                  ? AnimatedCountText(value: num.parse(value), style: TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.w700, fontFamily: fontInterBoldString))
                  : Text(value, style: TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.w700, fontFamily: fontInterBoldString)),
            ],
          )
        ],
      ),
    ),
  );
}

class AnimatedCountText extends StatelessWidget {
  final num value;
  final TextStyle style;
  final Duration duration;

  const AnimatedCountText({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: duration,
      builder: (context, val, child) {
        final textValue = value == value.roundToDouble()
            ? val.round().toString()
            : val.toStringAsFixed(1);
        return Text(
          textValue,
          style: style,
        );
      },
    );
  }
}

// setting Screen
Widget selectListViewDesign(size,image,title,ontap) {
  return Column(
    children: [
      Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.all(size.height*0.012),
          leading: Container(height: size.width*0.15,width: size.width*0.15,decoration: BoxDecoration(color: ColorConst.themeColor.withOpacity(0.09),borderRadius: BorderRadius.circular(12),),child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(image, color: ColorConst.themeColor,),
          ),),
          title: Text(title,style: const TextStyle(fontSize: 16,fontFamily: fontInterSemiBoldString, fontWeight: FontWeight.w600),),
          trailing: Icon(Icons.arrow_forward_rounded,color: ColorConst.settingIconsColors,size: size.width*0.07,),
          onTap: ontap,
        ),
      ),
    ],
  );
}

// Salary Slip Chart Custom
class DonutChartPainter extends CustomPainter {
  final double earning;
  final double deduction;

  DonutChartPainter({
    required this.earning,
    required this.deduction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = earning + deduction;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // If both are zero, draw empty circle
    if (total == 0) {
      final paint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, 0, 360 * 3.14159 / 180, false, paint);
      return;
    }

    // Calculate angles
    final earningAngle = (earning / total) * 360;
    final deductionAngle = (deduction / total) * 360;

    // Draw Earnings (Purple)
    final earningPaint = Paint()
      ..color = const Color(0xFFA7A1FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -90 * 3.14159 / 180,
      earningAngle * 3.14159 / 180,
      false,
      earningPaint,
    );

    // Draw Deductions (Orange)
    final deductionPaint = Paint()
      ..color = const Color(0xFFF28C18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      (-90 + earningAngle) * 3.14159 / 180,
      deductionAngle * 3.14159 / 180,
      false,
      deductionPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.earning != earning || oldDelegate.deduction != deduction;
  }
}

Widget dot(Color color,  Size size) {
  return Container(
    width: size.width * 0.04,
    height: size.width * 0.04,
    margin: EdgeInsets.only(top: size.height * 0.004),
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
    ),
  );
}

infoBox({size, title, color}) {
  return Container(
    padding: EdgeInsets.all(size.width * 0.02),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(
          size.width * 0.01),
    ),
    child: Text(
      title,
      style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: size.width * 0.035),
    ),
  );
}

class AttendancTypeContainer extends StatelessWidget {
 final Size size;
  final String setType;
final Color setBackColor;
  const AttendancTypeContainer(this.size,this.setType,this.setBackColor,{
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration( borderRadius: BorderRadius.circular(50),color: setBackColor.withOpacity(0.8),),
      child: Padding(
        padding:  EdgeInsets.symmetric(horizontal: size.height * 0.025,vertical: size.height * 0.0035),
        child: Text(setType,style: TextStyle(color: ColorConst.white,fontSize: size.height * 0.02),),
      ));
  }
}

class ColorMenuListClass{
  final Color color;
  final String title;
  ColorMenuListClass({required this.color, required this.title});
}

// ppoupmenu design
PopupMenuItem<int> popupMenuDesign({
  required int value,
  required IconData icon,
  required String title,
  required Size size,
}) {
  return PopupMenuItem<int>(
    value: value,
    height: 0, // ✅ removes default height
    padding: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon,),
          SizedBox(width: size.width * 0.02),
          Text(title,style: normalHeadingText(size),),
        ],
      ),
    ),
  );
}

// delete dialog box 
void showDeleteDialog(BuildContext context,Size size,{noOnTap,yesOntap}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: ColorConst.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorConst.themeColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      fontSize: 40,
                      color: ColorConst.themeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                areYouSureString,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                deleteDecString,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: ColorConst.grey,
                ),
              ),

              const SizedBox(height: 25),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: btnDesign(size,titles: yesDeleteString,onTap: yesOntap, isgradient: true,fontSizes: 12.0,),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: btnDesign(size,titles: noCancelString,bgColor: Colors.transparent,borderColors: ColorConst.themeColor,textColors: ColorConst.themeColor,onTap: noOnTap,fontSizes: 12.0,), 
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

// add document 
void showAddDialog(BuildContext context,{size,imageOntap,}) {
  showDialog(
    context: context,
    builder: (context) {
      return Consumer<DocumentsProvider>(
        builder: (context, documentproviders, child) {      
          return Dialog(
            backgroundColor: ColorConst.transparent,
            insetPadding: EdgeInsets.symmetric(vertical: size.height * 0.2, horizontal: size.width * 0.08),
            child: Container(
              width: size.width,
              padding:  EdgeInsets.all(size.width * 0.03),
              decoration: BoxDecoration(
                color: ColorConst.white,
                borderRadius: BorderRadius.circular(30)
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(addFileString, style: TextStyle(fontWeight: FontWeight.w600, fontFamily: fontInterSemiBoldString, color: ColorConst.themeColor, fontSize: size.width * 0.055)),
                    CommonTextField(controller: documentproviders.documentCategorey, hintText: 'Enter Document Category', showHeading: 'Document Category',),
                    heightSpacer(size.height *0.015),
                    CustomPaint(
                      painter: DottedBorderPainter(color: ColorConst.black, dashLength: 6, gapLength: 5, radius: 0),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Image.asset(uploadFileImageString, height: size.width *0.08, width: size.width *0.1),
                            heightSpacer(size.height * 0.02),
                            Text(dragAnddropString,style: TextStyle(fontSize: 11, color: ColorConst.black, fontWeight: FontWeight.w500, fontFamily: fontInterMediumString)),
                            heightSpacer(size.height * 0.01),
                            Text(orString,style: TextStyle(fontSize: 10, color: ColorConst.black, fontWeight: FontWeight.w500, fontFamily: fontInterMediumString)),
                            heightSpacer(size.height * 0.012),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: BorderSide(color: ColorConst.themeColor),
                              ),
                              onPressed: imageOntap,
                              child: Text(browseFileString,style: TextStyle(color: ColorConst.themeColor, fontWeight: FontWeight.w500, fontFamily: fontInterMediumString)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    heightSpacer(size.height *0.005),
                    documentproviders.selectedFiles.isEmpty ?SizedBox():Container(
                      height: size.width * 0.28,
                      margin: EdgeInsets.symmetric(
                        horizontal: size.width * 0.01,
                      ),
                      child: ListView.builder(
                        itemCount: documentproviders.selectedFiles.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return Container(
                            height: size.width * 0.25,
                            width: size.width * 0.25,
                            margin: EdgeInsets.symmetric(horizontal: size.width * 0.01,vertical: size.height * 0.01,),
                            alignment: Alignment.topRight,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(size.width * 0.03,),),
                            child: Stack(
                              children: [
                                if (documentproviders.isImageFile(documentproviders.selectedFiles[index].path.toString().split("/").last.split(".").last))...[
                                  ClipRRect(borderRadius: BorderRadius.circular(size.width * 0.03),child: Image.file(documentproviders.selectedFiles[index],width: double.infinity,height: double.infinity,fit: BoxFit.cover,),),
                                ],
                                if (documentproviders.isPdfFile(documentproviders.selectedFiles[index].path.toString().split("/").last.split(".").last))...[
                                  Padding(padding: const EdgeInsets.all(10),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.picture_as_pdf,size: size.width * 0.1,color: Colors.red,),
                                        heightSpacer(6),
                                        Text(documentproviders.selectedFiles[index].path.toString().split("/").last.split(".").first,maxLines: 2,overflow: TextOverflow.ellipsis,textAlign: TextAlign.center,style: TextStyle(fontSize: 8,fontWeight: FontWeight.w500,color: ColorConst.black,),),
                                      ],
                                    ),
                                  ),
                                ],
                                GestureDetector(
                                  onTap: () { documentproviders.removeFile(index); },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: ColorConst.white,
                                      borderRadius: const BorderRadius.only( topRight: Radius.circular(10,), bottomLeft: Radius.circular(10),),
                                    ),
                                    child: Icon( Icons.close, color: ColorConst.black,),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Center(child: iconWithTextBtnDesign(size,uploadFileString, isIcon: false,isImage: false, isgradient: true, onTap: () {documentproviders.addDocumentImage(context);})),
                  ],
                ),
              ),
            ),
          );
        }
      );
    },
  );
}

// Only For Punch In and Out Button
Widget punchButtonsView({size, buttonName, ontapPunch, isgradient, isIcon, isImage, iconNames}) {
  return GestureDetector(
    onTap: (){
      ontapPunch();
    },
    child: Container(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.018),
      decoration: isgradient ? BoxDecoration(
        gradient: LinearGradient(colors:  [ColorConst.themeColor, ColorConst.darkGreenColor], begin: Alignment.topCenter,end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(30),
      ) : BoxDecoration(
        color: ColorConst.red,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if(isIcon)...[
            Icon(iconNames, color: ColorConst.white),
            SizedBox(width: 10),
          ],
          if(isImage)...[
            Image.asset(iconNames, color: ColorConst.white,height: size.width * 0.055,),
            SizedBox(width: 10),
          ],
          
          Text(buttonName, style: TextStyle(color: ColorConst.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

// add notes design 
void showAddNotesDialog(BuildContext context,{size,}) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
      return Consumer<NotesProviders>(
        builder: (context, notesProvidersData, child) {      
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              decoration: BoxDecoration(
                color: ColorConst.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Form(
                key: notesProvidersData.userNotesFormKey,
                autovalidateMode: notesProvidersData.autovalidateMode,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Title
                    Text(
                      addNoteString,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: fontInterSemiBoldString,
                        color: ColorConst.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    heightSpacer(12),
                    CommonTextField(
                      controller: notesProvidersData.txtNotesDecController,
                      maxLines: 3,
                      fillColors: ColorConst.notesCommandTitlesColors,
                      hintText: enterNoteString,
                      validator: (p0) => allValidation(p0!),
                    ),
                    heightSpacer(14),

                    /// Upload Photo Box
                    GestureDetector(
                      onTap: () {
                        _showImageSourceDialog(context, notesProvidersData);
                      },
                      child: CustomPaint(
                        painter: DottedBorderPainter(
                          color: ColorConst.textBorder,
                          dashLength: 6,
                          gapLength: 5,
                          radius: 12,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: ColorConst.notesCommandTitlesColors,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file,
                                size: 28,
                                color: ColorConst.iconsColors,
                              ),
                              SizedBox(height: 10),
                              Text(
                                tapToUploadPhotoString,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: fontInterSemiBoldString,
                                  color: ColorConst.addNoteImageColors,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    heightSpacer(18),
                    if (notesProvidersData.images != null)
                      Stack(
                        children: [
                          Image.file(
                            notesProvidersData.images!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          GestureDetector(
                            onTap: () {notesProvidersData.submitNotImage();},
                            child: Container(
                              decoration: BoxDecoration(
                                color: ColorConst.white,
                                borderRadius: const BorderRadius.only( topRight: Radius.circular(10,), bottomLeft: Radius.circular(10),),
                              ),
                              child: Icon( Icons.close, color: ColorConst.black,),
                            ),
                          ),
                        ],
                      ),
                    heightSpacer(18),
                    btnDesign(
                      MediaQuery.of(context).size,
                      titles: submitString,
                      onTap: () {
                        notesProvidersData.addNotesHandleSubmit(context);
                      },
                      borderRadiused: 30.0,
                      isgradient: true,
                    ),
                    heightSpacer(10),
                  ],
                ),
              ),
            ),
          );
        }
      );
    },
  );
}

// selectcompany design 
void showCompanySelectDialog(BuildContext context,{size,}) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
      return Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {      
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              width: size.width,
              height: size.height * 0.6,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              decoration: BoxDecoration(
                color: ColorConst.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectCompanyString,style: TextStyle(color: ColorConst.black,fontSize: 20,fontFamily: fontInterSemiBoldString,fontWeight: FontWeight.w600),),
                  heightSpacer(size.height *0.01),
                  Expanded(
                    child: ListView.builder(
                      itemCount: getAllCompany.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {homeProvider.selectCompanyOntap(getAllCompany[index],context);},
                              child: Row(
                                children: [
                                  IgnorePointer(child: Radio<GetCompanyData>(value: getAllCompany[index],groupValue: selectedcurentcompany,activeColor: ColorConst.themeColor,onChanged: (value) {},)),
                                  heightSpacer(size.height*0.01),
                                  Expanded(
                                    child: Text(getAllCompany[index].companyName.toString(),style: TextStyle(color: selectedcurentcompany == getAllCompany[index] ?ColorConst.themeColor : ColorConst.black,fontSize: 11.5,fontFamily: fontInterMediumString,fontWeight: FontWeight.w500,),),
                                  ),
                                ],
                              ),
                            ),
                            Divider(color: ColorConst.grey,height: 0,thickness: 1,),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              )
            ),
          );
        }
      );
    },
  );
}

// select Role Rights Dialog
void showRoleRightsSelectDialog(BuildContext context,{size,}) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
      return Consumer<SettingProvider>(
        builder: (context, settingProvider, child) {      
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              width: size.width,
              height: size.height * 0.6,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              decoration: BoxDecoration(
                color: ColorConst.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Form(
                key: settingProvider.settingFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(roleRightsString,style: TextStyle(color: ColorConst.black,fontSize: 20,fontFamily: fontInterSemiBoldString,fontWeight: FontWeight.w600),)),
                        widthSpacer(size.width *0.02),
                        IconButton(onPressed: () {Navigator.pop(context);}, icon: Icon(Icons.close,color: ColorConst.black,)),
                      ],
                    ),
                    heightSpacer(size.height *0.01),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric( vertical: size.height * 0.01, ),
                            decoration: BoxDecoration( color: ColorConst.white, border: Border.all(color: ColorConst.grey), borderRadius: BorderRadius.circular(10),),
                            child: Center(
                              child: Text(subAdminAccessControlString, style: normalHeadingText(size)),
                            ),
                          ),
                          heightSpacer(size.height *0.015),
                          Text(firstNameString.toString().split(" ").last, style: TextStyle(color: ColorConst.themeColor,fontSize: size.height*0.019,fontFamily: fontInterSemiBoldString,fontWeight: FontWeight.w600)),
                          heightSpacer(size.height *0.01),
                          AppSearchableDropdown<Employeelists>(
                            dropdownKey: ValueKey(settingProvider.selectedEmployeeList),
                            initialItem: settingProvider.selectedEmployeeList,
                            futureRequest: (value) async {
                              return await Future.delayed(const Duration(seconds: 1), () {
                                  return Provider.of<EmployeMastServices>(context, listen: false).employesSubAdminDataList.where((e) {
                                    return e.firstName.toString().toLowerCase().contains(value.toLowerCase());
                                  }).toList();
                                },
                              );
                            },
                            onChanged: (value) async {
                              await settingProvider.getselectUserAdmin(value!);
                            },
                            hintText: selectSubAdminString,
                            items: Provider.of<EmployeMastServices>(context, listen: false).employesSubAdminDataList,
                            itemAsString: (item) => '${item.firstName} ${item.lastName}',
                            headerBuilder: (context, selectedItem, enabled) {
                              return Text('${selectedItem.firstName} ${selectedItem.lastName}');
                            },
                            validator: (value) {
                              if (value == null) {
                                return pleaseSelectSubAdminString;
                              }
                              return null;
                            },
                          ),
                          heightSpacer(size.height *0.015),
                          Text(userRightsString, style: TextStyle(color: ColorConst.themeColor,fontSize: size.height*0.019,fontFamily: fontInterSemiBoldString,fontWeight: FontWeight.w600)),
                          heightSpacer(size.height *0.01),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(asUserString, style: normalHeadingText(size)),
                                    Switch(value: settingProvider.isUser,activeColor: ColorConst.themeColor,onChanged: (value) { settingProvider.userRightsValue(value,true); },),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(asAdminString, style: normalHeadingText(size)),
                                    Switch( value: settingProvider.isAdmin, activeColor: ColorConst.themeColor, onChanged: (value) { settingProvider.userRightsValue(value,false); },),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    heightSpacer(size.height *0.02),
                    Row(
                      children: [
                        Expanded(child: btnDesign(size,titles: saveString,onTap: () async { if (settingProvider.settingFormKey.currentState!.validate()) {await settingProvider.createMenuSettings(context);}}, isgradient: true,),),
                        widthSpacer(size.width*0.02),
                        Expanded(child: btnDesign(size,titles: cancelString,bgColor: Colors.transparent,borderColors: ColorConst.themeColor,textColors: ColorConst.themeColor,onTap: () {Navigator.pop(context);},),),
                      ],
                    )
                  ],
                ),
              )
            ),
          );
        }
      );
    },
  );
}

// imageAnd title Module
Widget departmentImageandTitle(size,title,image,ontap) {
  return GestureDetector(
    onTap: ontap,
    child: Container(
      height: size.height*0.20,
      decoration: BoxDecoration(border: Border.all(color: ColorConst.themeColor,width: 3),borderRadius: BorderRadius.circular(15),),
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(image,height: size.height*0.06,color: ColorConst.themeColor,),
          heightSpacer(size.height*0.015),
          Text(title,textAlign: TextAlign.center,style: TextStyle(color: ColorConst.themeColor,fontSize: 16,fontFamily: fontInterBoldString,fontWeight: FontWeight.w600),),
        ],
      ),
    ),
  );
}

// active and inactive design
Widget activeAnmdInactiveDesign(size,groupNameValue,onchangeValue) {
  return Row(
    children: [
      Transform.scale(
        scale: 1.1,
        child: Radio(
          value: 'true',
          groupValue: groupNameValue,
          onChanged: onchangeValue,
          activeColor: ColorConst.themeColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
      Text(activeString,style: normalHeadingText(size),),
      widthSpacer(size.width*0.02),
      Transform.scale(
        scale: 1.1,
        child: Radio(
          value: 'false',
          groupValue: groupNameValue,
          onChanged: onchangeValue,
          activeColor: ColorConst.themeColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
      Text(inActiveString,style: normalHeadingText(size),),
    ],
  );
}

// refresh indicator
Widget refreshIndicatorDesign({
  required Future<void> Function() onRefreshOntap,
  required Widget widgetDesign,
}) {
  return RefreshIndicator(
    color: ColorConst.white, // Color of the spinner
    backgroundColor: ColorConst.themeColor, // Background behind the spinner
    strokeWidth: 2.0, // Thickness of the spinner
    onRefresh: onRefreshOntap,
    child: widgetDesign,
  );
}

// Show All Employee Attendance Data Option
Widget commonAttendanceDataOptions({onTap, size, icons, isImage, image}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: size.width * 0.09,
      width: size.width * 0.09,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColorConst.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorConst.grey),
      ),
      child: isImage ? Image.asset(image, height: size.height * 0.022) : Icon(icons, size: 20),
    ),
  );
}

Widget ritchTextDesign({titles,heading,headingColor,titlesSize,headingSize,textAligmnment}) {
  return RichText(
    textAlign: textAligmnment??TextAlign.center,
    text: TextSpan(
      children: [
        TextSpan(
          text: heading,
          style: TextStyle(
            fontSize: headingSize??11,
            color: headingColor ?? ColorConst.black,
            fontFamily: fontInterBoldString
          ),
        ),
        TextSpan(
          text: titles,
          style: TextStyle(
            fontSize: titlesSize?? 11,
            fontFamily: fontInterMediumString,
            fontWeight: FontWeight.w300,
            color: ColorConst.black,
          ),
        ),
      ],
    ),
  );
}

Widget addIconSetData(size,addontap,{iconsName,bgColor,borderColors,iconsColor}) {
  return GestureDetector(
    onTap: addontap,
    child: Container(
      height: size.width*0.16,
      width: size.width*0.14,
      decoration: BoxDecoration(
        color: bgColor??ColorConst.white,
        border:Border.all(color: borderColors??ColorConst.grey),
        borderRadius: BorderRadius.circular(4.0)
      ),
      child: Icon(iconsName??Icons.menu,color: iconsColor??ColorConst.black,),
    ),
  );
}

void _showImageSourceDialog(BuildContext context, NotesProviders notesProvider) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Image Source',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close,
                      color: ColorConst.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        notesProvider.getImage(ImageSource.camera);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.photo_camera_rounded,
                              size: 32,
                              color: ColorConst.themeColor,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Camera',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        notesProvider.getImage(ImageSource.gallery);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              size: 32,
                              color: ColorConst.themeColor,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Gallery',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}