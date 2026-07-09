// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/salaryslip/reportview.dart';
import 'package:tax_hrm/page/salaryslip/salary_slip_design.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/salaryStructures.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class SalaryPayslipScreen extends StatefulWidget {
  const SalaryPayslipScreen({super.key});

  @override
  State<SalaryPayslipScreen> createState() => _SalaryPayslipScreenState();
}

class _SalaryPayslipScreenState extends State<SalaryPayslipScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final salaryProvider = Provider.of<SalaryStructureProvider>(context, listen: false);
      salaryProvider.initializeData();
    });
  }
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final salaryStructureProvider = Provider.of<SalaryStructureProvider>(context);
    Provider.of<LanguageProvider>(context);
    return checkInterNetConnection.connectionType == 0 ? const NoInternetViewPage() :  Scaffold(
        backgroundColor: ColorConst.scaffoldColor,
        appBar: showCustomeAppBar(salarySlipString, size, titleColors: ColorConst.appbarTextColor, iconsOntap: () {
            backScreen(context);
          },
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.all(size.width * 0.03),
          child: Row(
            children: [
              Expanded(child: btnDesign(size, height: size.height * 0.06, titles: downloadSlipString,onTap: salaryStructureProvider.showPaySlips.isEmpty ? null : () {
                if (salaryStructureProvider.showPaySlips.isNotEmpty) {
                  final payslip = salaryStructureProvider.showPaySlips.first;
                  String  useUrls = 'https://report.taxfile.co.in/Report/PaySlip?CompanyID=${selectedcurentcompany!.companyId}&ReportMode=VIEW&custid=${selectedcurentcompany!.custId}&Month=${salaryStructureProvider.currentMonth.month}&Year=${salaryStructureProvider.currentMonth.year}&EmpId=${curentUser['Role'] == 'Admin' ? (salaryStructureProvider.selectedEmploye != null ? salaryStructureProvider.selectedEmploye!.id.toString()  : 0) : curentUser['Id']}';
                  salaryStructureProvider.downloadAndSavePDF(useUrls, 'payslip_${payslip.salaryMonth}_${payslip.salaryYear}');
                }
              },borderRadiused: 30.0,isgradient: salaryStructureProvider.showPaySlips.isNotEmpty, bgColor: salaryStructureProvider.showPaySlips.isEmpty ? Colors.grey : null, fontSizes: size.width * 0.04)),
              widthSpacer(size.width * 0.04),
              Expanded(child: btnDesign(size, height: size.height * 0.06,titles: viewSlipString,onTap: salaryStructureProvider.showPaySlips.isEmpty ? null : () {
                if (salaryStructureProvider.showPaySlips.isNotEmpty) {
                  String  useUrls = 'https://report.taxfile.co.in/Report/PaySlip?CompanyID=${selectedcurentcompany!.companyId}&ReportMode=VIEW&custid=${selectedcurentcompany!.custId}&Month=${salaryStructureProvider.currentMonth.month}&Year=${salaryStructureProvider.currentMonth.year}&EmpId=${curentUser['Role'] == 'Admin' ? (salaryStructureProvider.selectedEmploye != null ? salaryStructureProvider.selectedEmploye!.id.toString()  : 0) : curentUser['Id']}';
                  nextScreen(context, ReportView(url: useUrls),onthenValue: (value) {});
                }
              },borderRadiused: 30.0, bgColor: ColorConst.white, borderColors: salaryStructureProvider.showPaySlips.isEmpty ? Colors.grey : ColorConst.themeColor, textColors: salaryStructureProvider.showPaySlips.isEmpty ? Colors.grey : ColorConst.darkGreenColor, fontSizes: size.width * 0.04,  borderWidth: 2.5)),
            ],
          ),
        ),
        body: salaryStructureProvider.isloderings ? buildShimmerSalaryContent(size) : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(size.width * 0.02),
                      decoration: BoxDecoration(
                        color: ColorConst.white,
                        boxShadow: [
                          BoxShadow(color: ColorConst.grey, spreadRadius: 1.1, blurRadius: 0.8),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  salaryStructureProvider.previousMonth();
                                },
                                child: Icon(Icons.arrow_back_ios_new, size: size.width * 0.05),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  salaryStructureProvider.selectMonthYear(context);
                                },
                                child: Text(
                                  dateFormatMMMyyyy(salaryStructureProvider.currentMonth),
                                  style:  TextStyle(fontSize: size.width * 0.045, fontWeight: FontWeight.w700, color: ColorConst.textgrey),
                                ),
                              ),
                              GestureDetector(
                                onTap: salaryStructureProvider.currentMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month)) ? () {
                                    salaryStructureProvider.nextMonth();
                                } : null,
                                child: Icon(Icons.arrow_forward_ios_outlined, size: size.width * 0.05, color: salaryStructureProvider.currentMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month)) ? ColorConst.black : ColorConst.grey),
                              ),
                            ],
                          ),
                      
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: size.height * 0.05),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding:  EdgeInsets.symmetric(horizontal: size.width * 0.06),
                                  child: CustomPaint(
                                    size: Size(size.width * 0.25, size.width * 0.25),
                                    painter: DonutChartPainter(
                                      earning: salaryStructureProvider.showPaySlips.isNotEmpty ? (salaryStructureProvider.showPaySlips.first.grossEarnings ?? 0) : 0,
                                      deduction: salaryStructureProvider.showPaySlips.isNotEmpty ? (salaryStructureProvider.showPaySlips.first.totalDeductions ?? 0) : 0
                                    ),
                                  ),
                                ),
                            
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(DateFormat('MMMM, yyyy').format(salaryStructureProvider.currentMonth), style: TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.w700, fontFamily: fontInterBoldString, color: ColorConst.black)),
                            
                                    heightSpacer(size.height * 0.025),
                            
                                    Row(
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            dot(const Color(0xFFA7A1FF), size),
                                            widthSpacer(size.width * 0.03),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  salaryStructureProvider.showPaySlips.isNotEmpty 
                                                    ? '₹ ${salaryStructureProvider.showPaySlips.first.grossEarnings?.toStringAsFixed(0) ?? '0.00'}'
                                                    : '₹ 0.00',
                                                  style: TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.w600, fontFamily: fontInterSemiBoldString, color: ColorConst.black)
                                                ),
                                                widthSpacer(size.width * 0.03),
                                                Text(earningString, style: TextStyle(fontSize: size.width * 0.03, fontWeight: FontWeight.w500, fontFamily: fontInterMediumString, color: ColorConst.grey)),
                                              ],
                                            ),
                                          ],
                                        ),
                                
                                        widthSpacer(size.width * 0.05),
                              
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            dot(const Color(0xFFF28C18), size),
                                            widthSpacer(size.width * 0.03),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  salaryStructureProvider.showPaySlips.isNotEmpty 
                                                    ? '₹ ${salaryStructureProvider.showPaySlips.first.totalDeductions?.toStringAsFixed(0) ?? '0.00'}'
                                                    : '₹ 0.00',
                                                  style: TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.w600, fontFamily: fontInterSemiBoldString, color: ColorConst.black)
                                                ),
                                                widthSpacer(size.width * 0.03),
                                                Text(deductionString, style: TextStyle(fontSize: size.width * 0.03, fontWeight: FontWeight.w500, fontFamily: fontInterMediumString, color: ColorConst.grey)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    buildWorkingHoursCard(size, salaryStructureProvider),
                    
                    Container(
                      margin: EdgeInsets.all(size.width * 0.04),
                      padding: EdgeInsets.only(bottom: size.height * 0.005),
                      decoration: BoxDecoration(
                        color: ColorConst.white,
                      ),
                      child: Column(
                        children: [
                          if (salaryStructureProvider.showPaySlips.isNotEmpty) ...[
                            paySlipTextDesign(size: size, title: basicSalaryString, value: '₹ ${double.parse(salaryStructureProvider.showPaySlips.first.basicSalary.toString()).toStringAsFixed(2)}'),
                            paySlipTextDesign(size: size, title: pfString, value: '₹ ${salaryStructureProvider.showPaySlips.first.pF?.toStringAsFixed(1) ?? '0.0'}'),
                            paySlipTextDesign(size: size, title: esicString, value: '₹ ${salaryStructureProvider.showPaySlips.first.eSIC?.toStringAsFixed(1) ?? '0.0'}'),
                            paySlipTextDesign(size: size, title: convenienceString, value: '₹ ${salaryStructureProvider.showPaySlips.first.conveyance?.toStringAsFixed(1) ?? '0.0'}'),
                            paySlipTextDesign(size: size, title: hraString, value: '₹ ${salaryStructureProvider.showPaySlips.first.hRA?.toStringAsFixed(1) ?? '0.0'}'),
                            Divider(),
                            paySlipTextDesign(size: size, title: payoutAmtString, value: '₹ ${salaryStructureProvider.showPaySlips.first.finaleAmt?.toStringAsFixed(2) ?? '0.0'}', color: ColorConst.blueColors),
                          ] else ...[
                            paySlipTextDesign(size: size, title: basicSalaryString, value: '₹ 0.0'),
                            paySlipTextDesign(size: size, title: pfString, value: '₹ 0.0'),
                            paySlipTextDesign(size: size, title: esicString, value: '₹ 0.0'),
                            paySlipTextDesign(size: size, title: convenienceString, value: '₹ 0.0'),
                            paySlipTextDesign(size: size, title: hraString, value: '₹ 0.0'),
                            Divider(),
                            paySlipTextDesign(size: size, title: payoutAmtString, value: '₹ 0.0', color: ColorConst.blueColors),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }  
}