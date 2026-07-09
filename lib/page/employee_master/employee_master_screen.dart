// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:tax_hrm/page/employee_master/employee_add_edit_screen.dart';
import 'package:tax_hrm/page/employee_master/employee_pdf_csv.dart';
import 'package:tax_hrm/provider/employee_master_provider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/pagniation.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/common_user_limit_dialog.dart';
import 'package:tax_hrm/widigets/commonpaginator.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';

class EmployeeMasterScreen extends StatefulWidget {
  const EmployeeMasterScreen({super.key});

  @override
  State<EmployeeMasterScreen> createState() => _EmployeeMasterScreenState();
}

class _EmployeeMasterScreenState extends State<EmployeeMasterScreen>
    with SingleTickerProviderStateMixin {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    final employeeProvider = Provider.of<EmployeeMasterProvider>(context, listen: false);
    employeeProvider.clearData();
    await employeeProvider.loadAllEmployeeData(context);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final employeeMProvider = Provider.of<EmployeeMasterProvider>(context);
    final appPaginationController = Provider.of<AppPaginationProvider>(context);
    
    final employeeStartIndex = appPaginationController.startIndextoShow > employeeMProvider.emplists.length
        ? employeeMProvider.emplists.length
        : appPaginationController.startIndextoShow;
    final employeeEndIndex = appPaginationController.endIndexShow > employeeMProvider.emplists.length
        ? employeeMProvider.emplists.length
        : appPaginationController.endIndexShow;
    final employeePageItemCount = employeeEndIndex - employeeStartIndex;
    
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              appBar: showCustomAppbarWithPagination(
                employeeMaster,
                size,
                titleColors: ColorConst.appbarTextColor,
                iconsOntap: () { backScreen(context); },
                onTapaActiveData: () {
                  employeeMProvider.showActiveOnly = true;
                  employeeMProvider.showInactiveOnly = false;
                  employeeMProvider.filterEmployeeData();
                  appPaginationController.countPaginationPage(employeeMProvider.emplists, 0);
                },
                onTapaAllData: () {
                  employeeMProvider.showActiveOnly = false;
                  employeeMProvider.showInactiveOnly = false;
                  employeeMProvider.filterEmployeeData();
                  appPaginationController.countPaginationPage(employeeMProvider.emplists, 0);
                },
                onTapInActiveData: () {
                  employeeMProvider.showInactiveOnly = true;
                  employeeMProvider.showActiveOnly = false;
                  employeeMProvider.filterEmployeeData();
                  appPaginationController.countPaginationPage(employeeMProvider.emplists, 0);
                },
                usedListFilters: employeeMProvider.emplists,
                ontapserchs: () {
                  employeeMProvider.toggleSearch();
                },
                onTapExcel: () {
                  generateEmployeeCsvFile(employeeMProvider.emplists, 'Employee');
                },
                onTapPdf: () {
                  generateEmployeePrintFile(getEmployeeList: employeeMProvider.emplists, length: employeeMProvider.emplists.length, title: 'Employee', type: 'PDF');
                },
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.04),
                child: iconWithTextBtnDesign(
                  size,
                  addEmployee,
                  isIcon: false,
                  onTap: () {
                    bool userLimit = false;
                    for (var e in employeeMProvider.getTotalUserList) {
                      if (employeeMProvider.emplists.length == e.permitUsers || employeeMProvider.emplists.length > e.permitUsers) {
                        userLimit = true;
                      }
                    }
                    if (userLimit) {
                      showUserLimitDialog(context, size, employeeMProvider.getTotalUserList.first.permitUsers, employeeMProvider.getTotalUserList.first.totalUser);
                    } else {
                      nextScreen(context, EmployeeMasterAddEditScreen(flag: 'A'), onthenValue: (value) {});
                    }
                  },
                  isgradient: true,
                  isImage: false,
                ),
              ),
              body: refreshIndicatorDesign(
                onRefreshOntap: () {
                  return _loadAllData();
                },
                widgetDesign: Column(
                  children: [
                    if (employeeMProvider.showserch == true)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CommonTextField(
                          hintText: searchEmployeeHintString,
                          controller: employeeMProvider.searchController,
                          onChanged: (value) {
                            employeeMProvider.searchEmployee(value);
                            appPaginationController.countPaginationPage(employeeMProvider.emplists, 0);
                          },
                        ),
                      ),
                    
                    /// SHIMMER LOADING STATE - Using provider's isLoading
                    if (employeeMProvider.islodering)
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: 5,
                          itemBuilder: (context, index) => _buildShimmerItem(),
                        ),
                      )
                    else if (employeeMProvider.emplists.isEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: size.width,
                            height: size.height * 0.65,
                            child: noDataFoundsDesign(
                              size,
                              noDataFoundsString,
                              nodataFoundsImagString,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: employeePageItemCount,
                          itemBuilder: (context, index) {
                            final employeeIndex = employeeStartIndex + index;
                            final empProvider = employeeMProvider.emplists[employeeIndex];
                            final bool isExpanded = employeeMProvider.expandedIndex == employeeIndex;
                            
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: ColorConst.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(
                                  color: empProvider.isActive == true
                                      ? ColorConst.greenColor
                                      : ColorConst.red
                                ),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: ColorConst.grey,
                                ),
                                child: ExpansionTile(
                                  key: Key(employeeIndex.toString()),
                                  initiallyExpanded: isExpanded,
                                  onExpansionChanged: (value) {
                                    employeeMProvider.toggleExpansion(employeeIndex);
                                  },
                                  childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 5),
                                  iconColor: Colors.teal,
                                  collapsedIconColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  collapsedShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage: empProvider.img == null
                                            ? const AssetImage('assets/images/empprofile.jpg') as ImageProvider
                                            : NetworkImage('${apibaseurl}UploadFiles/Emp/${empProvider.img}'),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              empProvider.firstName.toString(),
                                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              empProvider.role.toString(),
                                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _actionButton(
                                        icon: Icons.edit_outlined,
                                        color: Colors.teal,
                                        onTap: () {
                                          nextScreen(
                                            context,
                                            EmployeeMasterAddEditScreen(
                                              flag: 'U',
                                              selectedemp: empProvider,
                                            ),
                                            onthenValue: (value) {}
                                          );
                                        },
                                      ),
                                      if(empProvider.role != "Admin")...[
                                        const SizedBox(width: 8),
                                        _actionButton(
                                          icon: Icons.delete_outline,
                                          color: Colors.red,
                                          onTap: () {
                                            showDeleteDialog(
                                              context,
                                              size,
                                              yesOntap: () {
                                                employeeMProvider.deleteEmployes(empProvider.id, context);
                                                Navigator.pop(context);
                                              },
                                              noOnTap: () {
                                                Navigator.pop(context);
                                              }
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                  children: [
                                    Divider(color: ColorConst.grey),
                                    const SizedBox(height: 10),
                                    _infoTile(
                                      Icons.email_outlined,
                                      "Email",
                                      empProvider.email ?? "-",
                                    ),
                                    const SizedBox(height: 14),
                                    _infoTile(
                                      Icons.phone_outlined,
                                      "Phone",
                                      empProvider.mobile1 ?? "-",
                                    ),
                                    const SizedBox(height: 14),
                                    _infoTile(
                                      Icons.apartment_outlined,
                                      "Department",
                                      empProvider.departmentName ?? "-",
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    if (!employeeMProvider.islodering && employeeMProvider.emplists.isNotEmpty)
                      CommonPagination(
                        appPaginationController.setSelectedPaginationPage,
                        appPaginationController.setTotalPaginationPage,
                        (int index) {
                          appPaginationController.countPaginationPage(employeeMProvider.emplists, index);
                        },
                      ),
                  ],
                ),
              ),
            );
  }

  /// SHIMMER ITEM WIDGET
  Widget _buildShimmerItem() {
    return Shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            /// Profile Image Shimmer
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            
            /// Name & Role Shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            
            /// Action Buttons Shimmer
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// INFO TILE
  Widget _infoTile(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.teal),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}