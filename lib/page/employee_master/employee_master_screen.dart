// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/page/employee_master/employee_add_edit_screen.dart';
import 'package:tax_hrm/page/employee_master/employee_pdf_csv.dart';
import 'package:tax_hrm/provider/employee_master_provider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/pagniation.dart';
import 'package:tax_hrm/provider/position_provider.dart';
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
  String? _selectedDesignation;

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
    if (!mounted) return;
    await Provider.of<PositionMasterService>(context, listen: false).getpositionfiles();
    if (!mounted) return;
    
    setState(() {
      _selectedDesignation = null;
    });

    final appPaginationController = Provider.of<AppPaginationProvider>(context, listen: false);
    appPaginationController.countPaginationPage(employeeProvider.emplists, 0);
  }

  List<Employeelists> _getFilteredList(List<Employeelists> list) {
    if (_selectedDesignation == null) return list;
    return list.where((emp) {
      return (emp.positionName ?? '').trim().toLowerCase() == _selectedDesignation!.trim().toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final employeeMProvider = Provider.of<EmployeeMasterProvider>(context);
    final appPaginationController = Provider.of<AppPaginationProvider>(context);
    Provider.of<LanguageProvider>(context);

    final filteredEmployees = _getFilteredList(employeeMProvider.emplists);
    
    final employeeStartIndex = appPaginationController.startIndextoShow > filteredEmployees.length
        ? filteredEmployees.length
        : appPaginationController.startIndextoShow;
    final employeeEndIndex = appPaginationController.endIndexShow > filteredEmployees.length
        ? filteredEmployees.length
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
                  appPaginationController.countPaginationPage(_getFilteredList(employeeMProvider.emplists), 0);
                },
                onTapaAllData: () {
                  employeeMProvider.showActiveOnly = false;
                  employeeMProvider.showInactiveOnly = false;
                  employeeMProvider.filterEmployeeData();
                  appPaginationController.countPaginationPage(_getFilteredList(employeeMProvider.emplists), 0);
                },
                onTapInActiveData: () {
                  employeeMProvider.showInactiveOnly = true;
                  employeeMProvider.showActiveOnly = false;
                  employeeMProvider.filterEmployeeData();
                  appPaginationController.countPaginationPage(_getFilteredList(employeeMProvider.emplists), 0);
                },
                usedListFilters: filteredEmployees,
                ontapserchs: () {
                  employeeMProvider.toggleSearch();
                },
                onTapExcel: () {
                  generateEmployeeCsvFile(filteredEmployees, 'Employee');
                },
                onTapPdf: () {
                  generateEmployeePrintFile(getEmployeeList: filteredEmployees, length: filteredEmployees.length, title: 'Employee', type: 'PDF');
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
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        child: CommonTextField(
                          hintText: searchEmployeeHintString,
                          controller: employeeMProvider.searchController,
                          onChanged: (value) {
                            employeeMProvider.searchEmployee(value);
                            appPaginationController.countPaginationPage(_getFilteredList(employeeMProvider.emplists), 0);
                          },
                        ),
                      ),
                    
                    // Designation Filter
                    _buildDesignationFilter(context, appPaginationController),
                    
                    /// SHIMMER LOADING STATE - Using provider's isLoading
                    if (employeeMProvider.islodering)
                      Expanded(
                        child: ListView.builder(physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: 5,
                          itemBuilder: (context, index) => _buildShimmerItem(),
                        ),
                      )
                    else if (filteredEmployees.isEmpty)
                      Expanded(
                        child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),
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
                        child: ListView.builder(physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                          itemCount: employeePageItemCount,
                          itemBuilder: (context, index) {
                            final employeeIndex = employeeStartIndex + index;
                            final empProvider = filteredEmployees[employeeIndex];
                            final bool isExpanded = employeeMProvider.expandedIndex == employeeIndex;
                            
                            return _buildEmployeeCard(
                              emp: empProvider,
                              index: employeeIndex,
                              isExpanded: isExpanded,
                              onToggleExpansion: () {
                                employeeMProvider.toggleExpansion(employeeIndex);
                              },
                              onEdit: () {
                                nextScreen(
                                  context,
                                  EmployeeMasterAddEditScreen(
                                    flag: 'U',
                                    selectedemp: empProvider,
                                  ),
                                  onthenValue: (value) {}
                                );
                              },
                              onDelete: () {
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
                              size: size,
                            );
                          },
                        ),
                      ),
                    
                    if (!employeeMProvider.islodering && filteredEmployees.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 0, top: 8),
                        child: CommonPagination(
                          appPaginationController.setSelectedPaginationPage,
                          appPaginationController.setTotalPaginationPage,
                          (int index) {
                            appPaginationController.countPaginationPage(filteredEmployees, index);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
  }

  Widget _buildDesignationFilter(BuildContext context, AppPaginationProvider appPaginationController) {
    final positionProvider = Provider.of<PositionMasterService>(context);
    final designations = positionProvider.positionlistt
        .map((e) => e.positionName ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();
        
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: designations.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final name = isAll ? 'All' : designations[index - 1];
          final isSelected = isAll ? (_selectedDesignation == null) : (_selectedDesignation == name);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                name,
                style: TextStyle(
                  color: isSelected ? ColorConst.white : ColorConst.black,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: ColorConst.themeColor,
              backgroundColor: ColorConst.greyOpicityColor,
              checkmarkColor: ColorConst.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? ColorConst.themeColor : Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedDesignation = isAll ? null : name;
                });
                final employeeMProvider = Provider.of<EmployeeMasterProvider>(context, listen: false);
                appPaginationController.countPaginationPage(_getFilteredList(employeeMProvider.emplists), 0);
              },
            ),
          );
        },
      ),
    );
  }

  String? _getEmployeeImageUrl(dynamic imgName) {
    final name = imgName?.toString().trim();
    if (name == null || name.isEmpty || name.toLowerCase() == 'null') {
      return null;
    }
    if (name.startsWith('http://') || name.startsWith('https://')) {
      return name;
    }
    if (name.startsWith('UploadFiles/')) {
      return Uri.parse(apibaseurl).resolve(name).toString();
    }
    return Uri.parse(apibaseurl).resolve('UploadFiles/Emp/$name').toString();
  }

  Widget _buildAvatar(Employeelists emp) {
    final imgUrl = _getEmployeeImageUrl(emp.img);
    final initials = (emp.firstName ?? '').isNotEmpty 
        ? emp.firstName![0].toUpperCase() 
        : '';
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: ColorConst.themeColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: imgUrl != null
            ? Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: ColorConst.themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: ColorConst.themeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEmployeeCard({
    required Employeelists emp,
    required int index,
    required bool isExpanded,
    required VoidCallback onToggleExpansion,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required Size size,
  }) {
    final fullName = '${emp.firstName ?? ''} ${emp.lastName ?? ''}'.trim();
    final displayName = fullName.isNotEmpty ? fullName : 'No Name';
    final roleOrPosition = (emp.positionName ?? emp.role ?? 'Employee').trim();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: ColorConst.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.5),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  color: emp.isActive == true ? ColorConst.greenColor : ColorConst.red,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                _buildAvatar(emp),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: emp.isActive == true ? ColorConst.greenColor : ColorConst.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ColorConst.themeColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      roleOrPosition,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: ColorConst.themeColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: ColorConst.themeColor, size: 20),
                                  onPressed: onEdit,
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                ),
                                if (emp.role != "Admin") ...[
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: ColorConst.red, size: 20),
                                    onPressed: onDelete,
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (emp.mobile1 != null && emp.mobile1!.trim().isNotEmpty && emp.mobile1!.trim() != '-')
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          emp.mobile1!,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                  if (emp.email != null && emp.email!.trim().isNotEmpty && emp.email!.trim() != '-')
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          emp.email!,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: onToggleExpansion,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (isExpanded) ...[
                        () {
                          final hasDept = emp.departmentName != null && emp.departmentName!.trim().isNotEmpty && emp.departmentName!.trim() != '-';
                          final hasWorkType = emp.workType != null && emp.workType!.trim().isNotEmpty && emp.workType!.trim() != '-';
                          final hasLoc = emp.officeLocation != null && emp.officeLocation!.trim().isNotEmpty && emp.officeLocation!.trim() != '-';
                          final hasDoj = emp.dOJ != null && emp.dOJ.toString().trim().isNotEmpty && emp.dOJ.toString().trim() != '-';
                          
                          if (hasDept || hasWorkType || hasLoc || hasDoj) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              alignment: Alignment.topLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 12, thickness: 1, color: Color(0xFFF5F5F5)),
                                  const SizedBox(height: 4),
                                  if (hasDept) ...[
                                    _detailRow(Icons.business_outlined, 'Department', emp.departmentName!),
                                    const SizedBox(height: 8),
                                  ],
                                  if (hasWorkType) ...[
                                    _detailRow(Icons.work_outline, 'Work Type', emp.workType!),
                                    const SizedBox(height: 8),
                                  ],
                                  if (hasLoc) ...[
                                    _detailRow(Icons.location_on_outlined, 'Office Location', emp.officeLocation!),
                                    const SizedBox(height: 8),
                                  ],
                                  if (hasDoj)
                                    _detailRow(Icons.calendar_today_outlined, 'Date of Joining', Provider.of<EmployeeMasterProvider>(context, listen: false).displayEmployeeDate(emp.dOJ)),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }



  /// SHIMMER ITEM WIDGET
  Widget _buildShimmerItem() {
    return Shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            /// Profile Image Shimmer
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            
            /// Name & Role Shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            
            /// Action Buttons Shimmer
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}