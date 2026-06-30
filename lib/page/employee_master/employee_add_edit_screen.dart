// ignore_for_file: invalid_use_of_visible_for_testing_member, prefer_typing_uninitialized_variables, strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/employee_master/employee_add_edit_design.dart';
import 'package:tax_hrm/provider/address_provider.dart';
import 'package:tax_hrm/provider/department_provider.dart';
import 'package:tax_hrm/provider/employee_master_provider.dart';
import 'package:tax_hrm/provider/ifsc_provider.dart';
import 'package:tax_hrm/provider/position_provider.dart';
import 'package:tax_hrm/provider/role_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class EmployeeMasterAddEditScreen extends StatefulWidget {
  final String flag;
  final selectedemp;
  const EmployeeMasterAddEditScreen({super.key, required this.flag, this.selectedemp});

  @override
  State<EmployeeMasterAddEditScreen> createState() =>
      _EmployeeMasterAddEditScreenState();
}

class _EmployeeMasterAddEditScreenState
    extends State<EmployeeMasterAddEditScreen>
    with TickerProviderStateMixin {
  late EmployeeMasterProvider provider;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<EmployeeMasterProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.init(this);
      if (widget.flag == 'A') {
        provider.clearEmployeeForm();
      }
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    provider.setloading(true);
    await Future.wait([
      Provider.of<DepartmentServices>(context, listen: false)
          .getDepartmentMasterData(),
      Provider.of<PositionMasterService>(context, listen: false)
          .getpositionfiles(),
      Provider.of<RoleMstServices>(context, listen: false).getAllRoleTypes(),
      Provider.of<AddresProviders>(context, listen: false).getallStat(),
      Provider.of<IfscMastServices>(context, listen: false).getifscData(),
      provider.getAllTypesFilterList(),
    ]);

    if (!mounted) return;

    if (widget.flag == 'U' && widget.selectedemp != null) {
      provider.populateEmployeeData(widget.selectedemp, context);
    }
    provider.setloading(false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeMasterProvider>(
      builder: (context, provider, child) {
        final size = MediaQuery.of(context).size;
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: showBottomAppBar(employeeAddEdit, size, centerTitles: false),
          body: SafeArea(
            child: provider.islodering
              ? Center(
                  child: CircularProgressIndicator(
                    color: ColorConst.themeColor,
                  ),
                )
              : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        buildProfileCard(size),
                        const SizedBox(height: 20),
                        buildExpandableSections(provider, size, context),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
                // Bottom Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorConst.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 15,
                        color: Colors.black.withOpacity(.08),
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: btnDesign(
                          size,
                          titles: saveString,
                          onTap: () async {
                            // Pass the flag and selected employee for update
                            await provider.saveEmployee(
                              context, 
                              widget.flag,
                              selectedEmployee: widget.selectedemp,
                            );
                          },
                          isgradient: true,
                          height: size.height * 0.055,
                          fontSizes: 14.0,
                        ),
                      ),
                      widthSpacer(size.width * 0.02),
                      Expanded(
                        child: btnDesign(
                          size,
                          titles: cancelString,
                          bgColor: Colors.transparent,
                          borderColors: ColorConst.themeColor,
                          textColors: ColorConst.themeColor,
                          onTap: () {
                            Navigator.pop(context);
                          },
                          height: size.height * 0.055,
                          fontSizes: 14.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
