// ignore_for_file: strict_top_level_inference, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/payrool/viewPayroll.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/payslipprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';

class ViewPaySlipScreen extends StatefulWidget {
  final PaySlipView getPaySlipData;
  const ViewPaySlipScreen({super.key,required this.getPaySlipData});

  @override
  State<ViewPaySlipScreen> createState() => _ViewPaySlipScreenState();
}

class _ViewPaySlipScreenState extends State<ViewPaySlipScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final paySlipProviders = Provider.of<PaySlipProviders>(context);
    safeAreaBgAndTextColor(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            backgroundColor: ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(viewPaySlipString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
            floatingActionButton:FloatingActionButton(
              onPressed: () {
                paySlipProviders.downloadPdf("https://report.taxfile.co.in/Report/PaySlip?CompanyID=${selectedcurentcompany!.companyId}&ReportMode=VIEW&custid=${selectedcurentcompany!.custId}&Month=${paySlipProviders.paySlipcurrentMonth.month}&Year=${paySlipProviders.paySlipcurrentMonth.year}&EmpId=${widget.getPaySlipData.empId}","${widget.getPaySlipData.empName}_${paySlipProviders.paySlipcurrentMonth.year}_${paySlipProviders.paySlipcurrentMonth.month.toString()}");
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                decoration:  BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors:[ColorConst.themeColor, ColorConst.darkGreenColor], begin: Alignment.topCenter,end: Alignment.bottomCenter),
                ),
                constraints: BoxConstraints.expand(),
                child: Icon(
                  Icons.download,
                  color: ColorConst.white,
                ),
              ),
            ),
            body: paySlipProviders.isloderings ? payrollMasterShimmer(size) 
              : Padding(
                padding: EdgeInsets.all(size.height*0.02),
                child: SfPdfViewer.network("https://report.taxfile.co.in/Report/PaySlip?CompanyID=${selectedcurentcompany!.companyId}&ReportMode=VIEW&custid=${selectedcurentcompany!.custId}&Month=${paySlipProviders.paySlipcurrentMonth.month}&Year=${paySlipProviders.paySlipcurrentMonth.year}&EmpId=${widget.getPaySlipData.empId}",onDocumentLoadFailed: (details) {},),
              ),
          );
  }
}
