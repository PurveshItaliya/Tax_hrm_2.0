// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/leave/leave_page_design.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/leave_user_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/utils/validation.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class ApplyLeavePage extends StatefulWidget {
   final bool isEdit;
  final dynamic leaveData;
  const ApplyLeavePage({super.key, required this.isEdit, required this.leaveData});

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  
  // Local state for leave days display
  String _leaveDays = '0';
  final bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<LeaveUserProvider>(context, listen: false);
      await provider.loadLeaveData(context,isEdit: widget.isEdit, leaveData: widget.leaveData);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final leaveUserProvider = Provider.of<LeaveUserProvider>(context);
    final empProvider = Provider.of<EmployeMastServices>(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    
    // Calculate leave days whenever dates or selection changes
    _calculateLeaveDays(leaveUserProvider);
    
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            backgroundColor: ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(
              applyLeaveString, 
              size,
              titleColors: ColorConst.appbarTextColor,
              iconsOntap: () {
                leaveUserProvider.resetForm();
                backScreen(context);
              }
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.03),
              child: leaveUserProvider.islodering || _isLoading
                  ? buildShimmerButton(size)
                  : iconWithTextBtnDesign(
                      size,
                      applyLeaveString,
                      isIcon: false,
                      onTap: () => widget.isEdit ? leaveUserProvider.updateHandleSubmit(context, _formKey): leaveUserProvider.addHandleSubmit(context, _formKey),
                      isgradient: true,
                      isImage: false,
                    ),
            ),
            body: _isLoading || leaveUserProvider.islodering
                ? buildShimmerBody(size)
                : Padding(
                    padding: EdgeInsets.all(size.width * 0.03),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              autovalidateMode: leaveUserProvider.autovalidateMode,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  
                                  // Leave Duration Selection Chips
                                  buildLeaveTypeChips(size, leaveUserProvider),
                                  heightSpacer(size.height * 0.02),
                                  
                                  if(curentUser['Role'] == 'Admin')...[
                                    buildEmployeeDropdown(size, leaveUserProvider, empProvider),
                                    heightSpacer(size.height * 0.02),
                                  ],

                                  // Start Date
                                  buildDateField(
                                    controller: leaveUserProvider.txtLeaveStartDate,
                                    hintText: leaveStartDateString,
                                    onPressed: () => leaveUserProvider.pickStartDate(context, size, true),
                                    validator: (p0) => allValidation(p0!),
                                  ),
                                  heightSpacer(size.height * 0.02),
                                  
                                  // End Date
                                  buildDateField(
                                    controller: leaveUserProvider.txtLeaveEndDate,
                                    hintText: leaveEndDateString,
                                    onPressed: () => leaveUserProvider.pickStartDate(context, size, false),
                                    validator: (p0) => allValidation(p0!),
                                  ),
                                  heightSpacer(size.height * 0.02),
                                  
                                  // Leave Type Dropdown
                                  buildLeaveTypeDropdown(size, leaveUserProvider),
                                  heightSpacer(size.height * 0.02),
                                  
                                  // Reason
                                  CommonTextField(
                                    controller: leaveUserProvider.txtReason,
                                    hintText: enterReasonString,
                                    validator: (p0) => allValidation(p0!),
                                    maxLines: 3,
                                  ),
                                  heightSpacer(size.height * 0.02),
                                  
                                  // Eligible Leave Info
                                  if (leaveUserProvider.selectedLeaveTypeData != null)...[
                                    buildEligibleInfo(size, leaveUserProvider),
                                    heightSpacer(size.height * 0.02),
                                  ],

                                  if(curentUser['Role'] == 'Admin')...[
                                    // Leave Status Dropdown
                                    buildLeaveStatusDropdown(size, leaveUserProvider),
                                    heightSpacer(size.height * 0.02),
                                  ],
                                  
                                  // Leave Duration Display
                                  buildLeaveDurationDisplay(size, _leaveDays),
                                  heightSpacer(size.height * 0.02),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          );
  }

  // Calculate Leave Days
  void _calculateLeaveDays(LeaveUserProvider provider) {
    if (provider.selectedFromDate == provider.selectedToDate) {
      if (provider.isFullDay) {
        _leaveDays = '1';
      } else {
        _leaveDays = '0.5';
      }
    } else {
      int days = provider.selectedToDate.difference(provider.selectedFromDate).inDays + 1;
      if (provider.isFullDay) {
        _leaveDays = days.toString();
      } else {
        _leaveDays = (days / 2).toString();
      }
    }
  }
}