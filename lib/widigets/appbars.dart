// ignore_for_file: use_build_context_synchronously, strict_top_level_inference, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/common_popmenu.dart';
import 'package:tax_hrm/widigets/commonpopup.dart';

// otp screen app bar design
showCustomeAppBar(String apptitle,Size size,{iconsOntap,scaffoldBgColor,elevations,titleColors,List<Widget>? actions}){
  return AppBar(
    leading: IconButton(onPressed: iconsOntap, icon: Icon(Icons.arrow_back_ios_new,color: ColorConst.black,),),
    backgroundColor: scaffoldBgColor ??ColorConst.white,
    surfaceTintColor: ColorConst.transparent,
    elevation: elevations ?? 1.5,
    titleSpacing: 0,
    shadowColor: ColorConst.grey.withOpacity(0.25),
    title: Text(apptitle,style: appbarTextStyles(size,titleColors: titleColors)),
    centerTitle: false,
    actions: actions,
  );
}

// bottombar app bar design
showBottomAppBar(String apptitle,Size size,{centerTitles,elevations,titleColors, List<Widget>? actions, isAdminBack}){
  return AppBar(
    automaticallyImplyLeading: isAdminBack ?? false,
    centerTitle: centerTitles ?? true,
    backgroundColor: ColorConst.white,
    surfaceTintColor: ColorConst.transparent,
    elevation: elevations ?? 1.5,
    shadowColor: ColorConst.grey.withOpacity(0.25),
    title: Text(apptitle, style: TextStyle(color: ColorConst.black, fontFamily: fontInterSemiBoldString, fontWeight: FontWeight.w600, fontSize: size.width * 0.05)),
    actions: actions,
  );
}

PreferredSizeWidget showCustomAppbarWithPagination(
  String apptitle,
  Size size, {
  VoidCallback? iconsOntap,
  Color? scaffoldBgColor,
  double? elevations,
  Color? titleColors,

  // Added callbacks
  VoidCallback? ontapserchs,
  VoidCallback? onTapaAllData,
  VoidCallback? onTapaActiveData,
  VoidCallback? onTapInActiveData,
  VoidCallback? onTapPdf,
  VoidCallback? onTapPrint,
  VoidCallback? onTapExcel,
  // Added list
  List? usedListFilters,
  // Extra actions if needed
  List<Widget>? actions,
}) {
  return AppBar(
    leading: IconButton(
      onPressed: iconsOntap,
      icon: Icon(
        Icons.arrow_back_ios_new,
        color: ColorConst.black,
      ),
    ),

    backgroundColor: scaffoldBgColor ?? ColorConst.white,
    surfaceTintColor: ColorConst.transparent,
    elevation: elevations ?? 1.5,
    titleSpacing: 0,
    shadowColor: ColorConst.grey.withOpacity(0.25),
    title: Text(
      apptitle,
      style: appbarTextStyles(
        size,
        titleColors: titleColors,
      ),
    ),
    centerTitle: false,
    actions: [
      /// Search Button
      IconButton(
        onPressed: () {
          ontapserchs?.call();
        },
        icon: const Icon(Icons.search),
      ),
      /// Popup Menu
      PopupMenuButton<int>(
        shadowColor: Colors.black,
        itemBuilder: (context) => [
          /// Status
          PopupMenuItem(
            value: 1,
            onTap: () {
              Future.delayed(Duration.zero, () {
                employeStatusPopBox(
                  context,
                  size,
                  () {
                    onTapaAllData?.call();
                  },
                  () {
                    onTapaActiveData?.call();
                  },
                  (){
                    onTapInActiveData?.call();
                  }
                );
              });
            },
            child: const Row(
              children: [
                Icon(
                  Icons.switch_account_sharp,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text("Status"),
              ],
            ),
          ),      
          /// Length
          PopupMenuItem(
            value: 3,
            onTap: () {
              Future.delayed(Duration.zero, () {
                showNumberOfData(context,size,usedListFilters ?? [],);
              });
            },
            child: const Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text("Length"),
              ],
            ),
          ),
          ///More
          PopupMenuItem(
            value: 2,
            onTap: () {
                pdfViewsPopMenu(
                  context,
                  size,
                  () {onTapPdf?.call();},
                  () {onTapPrint?.call();},
                  () {onTapExcel?.call();},
              );
            },
            child: const Row(
              children: [
                Icon(
                  Icons.mediation_rounded,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text("More"),
              ],
            ),
          ),
        ],
        offset: const Offset(0, 50),
        color: ColorConst.white,
        surfaceTintColor: ColorConst.white,
        elevation: 2,
      ),
      /// Extra Custom Actions
      ...?actions,
    ],
  );
}

//  PDF Print and CSV pop menu

Future<void> pdfViewsPopMenu(
  BuildContext context,
  Size size,
  Function onTapPDF,
  Function onTapPrint,
  Function onTapCSV,
) async {
  final selected = await showMenu<int>(
    context: context,
    color: ColorConst.white,
    position: RelativeRect.fromLTRB(
      size.width * 0.09,
      size.height * 0.1,
      0,
      0,
    ),
    items: [
      PopupMenuItem<int>(
        value: 1,
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.black),
            const SizedBox(width: 10),
            Text("PDF", style: normalHeadingText(size)),
          ],
        ),
      ),
      PopupMenuItem<int>(
        value: 2,
        child: Row(
          children: [
            const Icon(Icons.print_sharp, color: Colors.black),
            const SizedBox(width: 10),
            Text("Print", style: normalHeadingText(size)),
          ],
        ),
      ),
      PopupMenuItem<int>(
        value: 3,
        child: Row(
          children: [
            const Icon(Icons.table_chart, color: Colors.black),
            const SizedBox(width: 10),
            Text("Excel", style: normalHeadingText(size)),
          ],
        ),
      ),
    ],
  );

  switch (selected) {
    case 1:
      onTapPDF();
      break;
    case 2:
      onTapPrint();
      break;
    case 3:
      onTapCSV();
      break;
  }
}

