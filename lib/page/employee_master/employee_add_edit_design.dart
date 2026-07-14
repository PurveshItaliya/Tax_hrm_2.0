// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:tax_hrm/widigets/app_searchable_dropdown.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:tax_hrm/models/address/citylist_model.dart';
import 'package:tax_hrm/models/address/pincode_model.dart';
import 'package:tax_hrm/models/address/statelist_model.dart';
import 'package:tax_hrm/models/customeclass/simpleclass.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/position.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/departmentdata.dart';
import 'package:tax_hrm/models/master_model.dart';
import 'package:tax_hrm/models/role/get_role_model.dart';
import 'package:tax_hrm/provider/address_provider.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/department_provider.dart';
import 'package:tax_hrm/provider/employee_master_provider.dart';
import 'package:tax_hrm/provider/position_provider.dart';
import 'package:tax_hrm/provider/role_provider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/ifsc_drop_down.dart';

Widget buildProfileCard(Size size) {
  return Consumer<EmployeeMasterProvider>(
    builder: (context, provider, child) {
      final employeeImageUrl = provider.employeeImageUrl;
      final hasImage =
          provider.profileImage != null || employeeImageUrl != null;
      
      // Shimmer for profile card while loading
      if (provider.islodering) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Shimmer(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 150,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        );
      }
      
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => showImagePickerOptions(context,provider),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          ColorConst.themeColor.withOpacity(0.1),
                          ColorConst.themeColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.transparent,
                      backgroundImage: provider.profileImage != null 
                          ? FileImage(provider.profileImage!) 
                          : employeeImageUrl != null
                              ? NetworkImage(employeeImageUrl)
                              : null,
                      child: !hasImage
                          ? Icon(
                              Icons.person_outline,
                              size: 65,
                              color: ColorConst.themeColor,
                            )
                          : null,
                    ),
                  ),
                  if (hasImage)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: ()=> provider.deleteImages(provider.selectedEmploye!.id, context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.shade600,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: ColorConst.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [ColorConst.themeColor, ColorConst.themeColor],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConst.themeColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: ColorConst.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: ColorConst.themeColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                provider.firstNameController.text.isNotEmpty || provider.lastNameController.text.isNotEmpty
                    ? "${provider.firstNameController.text} ${provider.lastNameController.text}".trim()
                    : employessNameString,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w700,
                  color: ColorConst.themeColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.selectedPostions?.positionName ?? positionString,
              style: TextStyle(
                fontSize: 14, 
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    },
  );
}

// =========================================================
// EXPANDABLE SECTIONS (Replaces Tabs)
// =========================================================

Widget buildExpandableSections(
    EmployeeMasterProvider provider,
    Size size,
    BuildContext context,
  ) {
    if (provider.islodering) {
      return Column(
        children: List.generate(5, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: ColorConst.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Shimmer(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      );
    }

    return Form(
      key: provider.formKey1,
      child: Column(
        children: [
          _buildExpandableSection(
            title: accountInformationString,
            icon: Icons.account_circle_outlined,
            child: _accountTab(provider, size, context),
            isExpanded: provider.isAccountSectionExpanded,
            onToggle: () => provider.toggleAccountSection(),
          ),
          const SizedBox(height: 16),
          _buildExpandableSection(
            title: personalInformationString,
            icon: Icons.person_outline,
            child: _personalTab(provider, size, context),
            isExpanded: provider.isPersonalSectionExpanded,
            onToggle: () => provider.togglePersonalSection(),
          ),
          const SizedBox(height: 16),
          _buildExpandableSection(
            title: contactInformationString,
            icon: Icons.contact_phone_outlined,
            child: _contactTab(size, context, provider),
            isExpanded: provider.isContactSectionExpanded,
            onToggle: () => provider.toggleContactSection(),
          ),
          const SizedBox(height: 16),
          _buildExpandableSection(
            title: educationDetailsString,
            icon: Icons.school_outlined,
            child: _educationTab(size, provider),
            isExpanded: provider.isEducationSectionExpanded,
            onToggle: () => provider.toggleEducationSection(),
          ),
          const SizedBox(height: 16),
          _buildExpandableSection(
            title: bankDetailsString,
            icon: Icons.account_balance_outlined,
            child: _bankDetailsTab(size, provider),
            isExpanded: provider.isBankSectionExpanded,
            onToggle: () => provider.toggleBankSection(),
          ),
        ],
      ),
    );
}

Widget _buildExpandableSection({
  required String title,
  required IconData icon,
  required Widget child,
  required bool isExpanded,
  required VoidCallback onToggle,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    decoration: BoxDecoration(
      color: ColorConst.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isExpanded ? ColorConst.themeColor.withOpacity(0.4) : Colors.grey.shade200,
        width: isExpanded ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isExpanded
              ? ColorConst.themeColor.withOpacity(0.06)
              : Colors.black.withOpacity(0.03),
          blurRadius: isExpanded ? 15 : 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? ColorConst.themeColor
                        : ColorConst.themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isExpanded ? ColorConst.white : ColorConst.themeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w600,
                      color: isExpanded ? ColorConst.themeColor : ColorConst.black,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isExpanded ? ColorConst.themeColor : Colors.grey.shade600,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState:
              isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            children: [
              Divider(
                height: 1,
                thickness: 1,
                color: ColorConst.themeColor.withOpacity(0.15),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: child,
              ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

// =========================================================
// ACCOUNT TAB (Renamed but functionality unchanged)
// =========================================================

Widget _accountTab(
    EmployeeMasterProvider provider,
    Size size,
    context
  ) {
    // Shimmer for account tab while loading
    if (provider.islodering) {
      return Column(
        children: List.generate(8, (index) => _buildShimmerField(size)),
      );
    }
    
    return Column(
      children: [
        /// LOGIN CREDENTIALS
        _buildSubSectionHeader(loginCredentialsString, Icons.lock_outline),
        const SizedBox(height: 16),
      
        /// USERNAME & PASSWORD
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                label: userNameString,
                isRequired: true,
                child: CommonTextField(
                  controller: provider.usernameController,
                  borderRadius: 8.0,
                  validator:(value) {
                    if(value == null || value.isEmpty) {
                      return userNameRequiredString;
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledField(
                label: passwordString,
                isRequired: true,
                child: CommonTextField(
                  controller: provider.passwordController,
                  borderRadius: 8.0,
                  obscureText: !provider.isPasswordVisible, 
                  suffixIcon: IconButton(
                    icon: Icon(
                      provider.isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.remove_red_eye_outlined,
                      color: ColorConst.themeColor,
                      size: 20,
                    ),
                    onPressed: provider.togglePasswordVisibility,
                  ),
                  validator:(value) {
                    if(value == null || value.isEmpty) {
                      return passwordRequiredString;
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
      
        const SizedBox(height: 24),
      
        /// ORGANIZATION DETAILS
        _buildSubSectionHeader(organizationDetailsString, Icons.business_center),
        const SizedBox(height: 16),
      
        /// DEPARTMENT & DESIGNATION
        _buildLabeledField(
          label: departmentString,
          isRequired: true,
          child: AppSearchableDropdown<DepartMnetModel>(
            dropdownKey: ValueKey(provider.selectedDepartment),
            initialItem: provider.selectedDepartment,
            hintText: selectDepartmentNameString,
            futureRequest: (value) => provider.getfilterDepartment(value, context),
            items: Provider.of<DepartmentServices>(context, listen: false).alldepartment,
            itemAsString: (item) => item.departmentName.toString(),
            validator: (value) {
              if (value == null) {
                return selectDepartmentNameString;
              }
              return null;
            },
            headerBuilder: (context, selectedItem, enabled) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      provider.selectedDepartment == null
                          ? selectDepartmentNameString
                          : provider.selectedDepartment!.departmentName.toString(),
                    ),
                  ),
                  const Spacer(),
                  if (provider.selectedDepartment != null)
                    GestureDetector(
                      onTap: () {
                        provider.clearDepartment();
                        provider.clearPosition();
                      },
                      child: Icon(Icons.clear_rounded, size: size.height * 0.02, color: Colors.grey),
                    ),
                ],
              );
            },
            onChanged: (vals) {
              provider.selectedDepartment = vals;
              provider.clearPosition();
              provider.setFilterPostions(context);
            },
          ),
        ),
      
        const SizedBox(height: 18),
      
        _buildLabeledField(
          label: positionString,
          isRequired: true,
          child: AppSearchableDropdown<PositionDataL>(
            dropdownKey: ValueKey(provider.selectedPostions),
            initialItem: provider.selectedPostions,
            hintText: selectDesignationNameString,
            futureRequest: (value) => provider.getfiltersPostions(value, context),
            items: Provider.of<PositionMasterService>(context, listen: false).getFiltersPostionList,
            itemAsString: (item) => item.positionName.toString(),
            validator: (value) {
              if (value == null) {
                return selectDesignationNameString;
              }
              return null;
            },
            headerBuilder: (context, selectedItem, enabled) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      provider.selectedPostions == null
                          ? selectDesignationNameString
                          : provider.selectedPostions!.positionName.toString(),
                    ),
                  ),
                  const Spacer(),
                  if (provider.selectedPostions != null)
                    GestureDetector(
                      onTap: () {
                        provider.clearPosition();
                      },
                      child: Icon(Icons.clear_rounded, size: size.height * 0.02, color: Colors.grey),
                    ),
                ],
              );
            },
            onChanged: (vals) {
              provider.selectedPostions = vals;
            },
          ),
        ),
      
        const SizedBox(height: 24),
      
        /// ROLE
        _buildLabeledField(
          label: roleString,
          child: AppSearchableDropdown<Getrolemodel>(
            dropdownKey: ValueKey(provider.selectedRole),
            initialItem: provider.selectedRole,
            hintText: selectRoleString,
            futureRequest: (value) => provider.getroleFilters(value, context),
            items: Provider.of<RoleMstServices>(context, listen: false).getRoleList,
            itemAsString: (item) => item.role.toString(),
            headerBuilder: (context, selectedItem, enabled) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      provider.selectedRole == null
                          ? selectRoleString
                          : provider.selectedRole!.role.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (provider.selectedRole != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        provider.selectedRole = null;
                        provider.notifyListeners();
                      },
                      child: Icon(Icons.clear_rounded, size: size.height * 0.02, color: Colors.grey),
                    ),
                  ],
                ],
              );
            },
            onChanged: (vals) {
              provider.selectedRole = vals;
            },
          ),
        ),

        const SizedBox(height: 24),

        /// OFFICE LOCATION & WORK TYPE
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                label: officeString,
                child: Container(
                  height: 50.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorConst.textBorder, width: 1.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          selectOfficeString,
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorConst.hintextColor,
                          ),
                        ),
                      ),
                      value: provider.selectOfficeLocation.isNotEmpty
                          ? provider.selectOfficeLocation
                          : null,
                      items: provider.officeLocationList.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.toString(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              item.toString(),
                              style: TextStyle(fontSize: 15, color: ColorConst.black),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        provider.updateOfficeLocation(newValue ?? '');
                      },
                      dropdownColor: ColorConst.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledField(
                label: workTypeString,
                child: Container(
                  height: 50.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorConst.textBorder, width: 1.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          selectWorkTypeString,
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorConst.hintextColor,
                          ),
                        ),
                      ),
                      value: provider.selectWorkType.isNotEmpty
                          ? provider.selectWorkType
                          : null,
                      items: provider.workTypeList.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.toString(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              item.toString(),
                              style: TextStyle(fontSize: 15, color: ColorConst.black),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        provider.updateWorkType(newValue ?? '');
                      },
                      dropdownColor: ColorConst.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
      
        /// LOCATION SETTINGS
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                label: fetchLocationString,
                child: Container(
                  height: 50.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorConst.textBorder, width: 1.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Text(
                          provider.isFetchLocation ? enabledString : disabledString,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      Switch(
                        value: provider.isFetchLocation,
                        activeColor: ColorConst.themeColor,
                        onChanged: (value) {
                          provider.setFetchLocation(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledField(
                label: locationRadiusString,
                isRequired: true,
                child: CommonTextField(
                  controller: provider.locationRadiusController,
                  borderRadius: 8.0,
                  keyboardType: TextInputType.number,
                  hintText: egRadiusHintString,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return radiusRequiredString;
                    }
                    if (int.tryParse(value) == null) {
                      return enterValidNumberString;
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
 
        const SizedBox(height: 15),
 
        _buildStatusSection(provider),
      ],
    );
}

// =========================================================
// PERSONAL TAB (Renamed but functionality unchanged)
// =========================================================

Widget _personalTab(
    EmployeeMasterProvider provider,
    Size size,
    BuildContext context,
  ) {
    // Shimmer for personal tab while loading
    if (provider.islodering) {
      return Column(
        children: List.generate(10, (index) => _buildShimmerField(size)),
      );
    }
    
    return Column(
      children: [
        /// PERSONAL INFORMATION
        _buildSubSectionHeader(personalInformationString, Icons.person_outline),
        const SizedBox(height: 16),
      
        /// FIRST NAME & LAST NAME
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                label: firstNameString,
                isRequired: true,
                child: CommonTextField(
                  controller: provider.firstNameController,
                  borderRadius: 8.0,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return firstNameRequiredString;
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledField(
                label: lastNameString,
                isRequired: true,
                child: CommonTextField(
                  controller: provider.lastNameController,
                  borderRadius: 8.0,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return lastNameRequiredString;
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
      
        const SizedBox(height: 18),
      
        /// DOB & JOINING DATE
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                label: dateofBirthString,
                child: CommonTextField(
                  controller: provider.dobController,
                  borderRadius: 8.0,
                  readOnly: true,
                  hintText: selectDOBString,
                  suffixIcon: IgnorePointer(
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.calendar_today_outlined,
                        color: ColorConst.themeColor,
                        size: 20,
                      ),
                    ),
                  ),
                  onTap: () {
                    Provider.of<CommandWidigetsProvider>(
                      context,
                      listen: false,
                    ).pickDate(
                      context,
                      size,
                      provider.selectedFromDate == null
                          ? DateTime.now()
                          : DateTime.parse(provider.selectedFromDate!),
                      null,
                      null,
                      (vals) {
                        provider.selectedFromDate = vals.toString();
                        provider.dobController.text = DateFormat('dd/MM/yyyy').format(
                          DateTime.parse(provider.selectedFromDate!),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledField(
                label: dateOfJoiningString,
                isRequired: true,
                child: CommonTextField(
                  controller: provider.joiningController,
                  borderRadius: 8.0,
                  readOnly: true,
                  hintText: selectJoiningDateString,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return dojRequiredString;
                    }
                    return null;
                  },
                  suffixIcon: IgnorePointer(
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.calendar_today_outlined,
                        color: ColorConst.themeColor,
                        size: 20,
                      ),
                    ),
                  ),
                  onTap: () {
                    Provider.of<CommandWidigetsProvider>(
                      context,
                      listen: false,
                    ).pickDate(
                      context,
                      size,
                      provider.selectedToDate == null
                          ? DateTime.now()
                          : DateTime.parse(provider.selectedToDate!),
                      null,
                      null,
                      (vals) {
                        provider.selectedToDate = vals.toString();
                        provider.joiningController.text = DateFormat('dd/MM/yyyy').format(
                          DateTime.parse(provider.selectedToDate!),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      
        const SizedBox(height: 18),
      
        /// GENDER & MARITAL STATUS
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                label: genderString,
                child: Container(
                  height: 50.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorConst.textBorder, width: 1.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<TypedClass>(
                      isExpanded: true,
                      hint: FixText(
                        dataName: provider.selectGender == null
                            ? genderString
                            : provider.selectGender!.values,
                        textSize: 14,
                        colors: ColorConst.hintextColor,
                      ),
                      items: gendersList.map((TypedClass item) {
                        return DropdownItem<TypedClass>(
                          value: item,
                          child: Text(
                            item.values,
                            style: TextStyle(fontSize: 15, color: ColorConst.black),
                          ),
                        );
                      }).toList(),
                      onChanged: (TypedClass? value) {
                        if (value != null) {
                          provider.setGender(value);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledField(
                label: maritalStatusString,
                child: Container(
                  height: 50.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorConst.textBorder, width: 1.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      isExpanded: true,
                      hint: FixText(
                        dataName: provider.selectedmarital == null
                            ? maritalStatusString
                            : provider.selectedmarital.toString(),
                        textSize: 14,
                        colors: ColorConst.hintextColor,
                      ),
                      items: maritalitem.map((String item) {
                        return DropdownItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: TextStyle(fontSize: 15, color: ColorConst.black),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        provider.setMarital(value);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      
        const SizedBox(height: 24),
      
        /// EMPLOYMENT DETAILS
        _buildSubSectionHeader(employmentDetailsString, Icons.work_outline),
        const SizedBox(height: 16),
      
        /// SALARY TYPE & SALARY
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                label: salaryTypeString,
                child: Container(
                  height: 50.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorConst.textBorder, width: 1.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<TypedClass>(
                      isExpanded: true,
                      hint: FixText(
                        dataName: provider.seselectedSalaryTypesle == null
                            ? salaryTypeString
                            : provider.seselectedSalaryTypesle!.values,
                        textSize: 14,
                        colors: ColorConst.hintextColor,
                      ),
                      items: salaryBaseList.map((TypedClass item) {
                        return DropdownItem<TypedClass>(
                          value: item,
                          child: Text(
                            item.values,
                            style: TextStyle(fontSize: 15, color: ColorConst.black),
                          ),
                        );
                      }).toList(),
                      onChanged: (TypedClass? value) {
                        provider.setSalaryType(value!);
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledField(
                label: salaryAmountString,
                isRequired: true,
                child: CommonTextField(
                  controller: provider.salaryController,
                  borderRadius: 8.0,
                  keyboardType: const TextInputType.numberWithOptions(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return salaryRequiredString;
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
      
        const SizedBox(height: 18),
      
        /// TOTAL HOURS & PAN NO
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                label: totalHoursString,
                isRequired: true,
                child: CommonTextField(
                  controller: provider.totalHoursController,
                  borderRadius: 8.0,
                  keyboardType: const TextInputType.numberWithOptions(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return totalHoursRequiredString;
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledField(
                label: panString,
                child: CommonTextField(
                  controller: provider.panNOController,
                  borderRadius: 8.0,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    // Only validate format if value is provided
                    RegExp panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                    if (!panRegex.hasMatch(value.toUpperCase())) {
                      return invalidPanFormatString;
                    }
                    return null;
                  },
                  onChanged: (value) {
                    provider.panNOController.text = value.toUpperCase();
                    provider.panNOController.selection = TextSelection.fromPosition(
                      TextPosition(offset: provider.panNOController.text.length),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
}

// =========================================================
// CONTACT TAB (Renamed but functionality unchanged)
// =========================================================

Widget _contactTab(Size size, BuildContext context, EmployeeMasterProvider provider) {
  // Shimmer for contact tab while loading
  if (provider.islodering) {
    return Column(
      children: List.generate(8, (index) => _buildShimmerField(size)),
    );
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// ADDRESS INFORMATION
      _buildSubSectionHeader(addressInformationString, Icons.location_on),
      const SizedBox(height: 16),
      
      _buildLabeledField(
        label: address1String,
        child: CommonTextField(
          controller: provider.address1Controller,
          borderRadius: 8.0,
        ),
      ),
      
      const SizedBox(height: 18),
      
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildLabeledField(
              label: address2String,
              child: CommonTextField(
                controller: provider.address2Controller,
                borderRadius: 8.0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildLabeledField(
              label: address3String,
              child: CommonTextField(
                controller: provider.address3Controller,
                borderRadius: 8.0,
              ),
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 24),
      
      /// CONTACT DETAILS
      _buildSubSectionHeader(contactDetailsString, Icons.phone_outlined),
      const SizedBox(height: 16),
      
      _buildLabeledField(
        label: mobile1String,
        isRequired: true,
        child: PhoneNumberTextFiled(
          controller: provider.mobile1Controller,
          borderRadius: 8.0,
          validator: (value) {
            if (value == null || value.number.isEmpty) {
              return phoneRequiredString;
            }
            return null;
          },
          getcodes: provider.countryView,
          onChanged: (value) {
            provider.mobile1Controller.text = value.number;
            provider.countryView = value.countryCode.replaceAll('+', '');
          },
        ),
      ),
      
      const SizedBox(height: 18),
      
      _buildLabeledField(
        label: mobile2String,
        child: PhoneNumberTextFiled(
          controller: provider.mobile2Controller,
          borderRadius: 8.0,
          getcodes: provider.countryView2,
          onChanged: (value) {
            provider.mobile2Controller.text = value.number;
            provider.countryView = value.countryCode.replaceAll('+', '');
          },
        ),
      ),
      
      const SizedBox(height: 18),
      
      _buildLabeledField(
        label: emailUserString,
        child: CommonTextField(
          controller: provider.emailController,
          borderRadius: 8.0,
        ),
      ),
      
      const SizedBox(height: 24),
      
      /// LOCATION DETAILS
      _buildSubSectionHeader(locationDetailsString, Icons.map_outlined),
      const SizedBox(height: 16),
      
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildLabeledField(
              label: stateString,
              child: AppSearchableDropdown<Statelistm>(
                dropdownKey: ValueKey(provider.selectedStates),
                initialItem: provider.selectedStates,
                hintText: stateString,
                futureRequest: (value) => provider.getFilterState(value, context),
                items: Provider.of<AddresProviders>(context, listen: false).mainStateList,
                itemAsString: (item) => item.stateName.toString(),
                headerBuilder: (context, selectedItem, enabled) {
                  return Text(provider.selectedStates == null ? selectStateString : provider.selectedStates!.stateName.toString());
                },
                onChanged: (vals) {
                  provider.selectedStates = vals;
                  Provider.of<AddresProviders>(context, listen: false).filtersCity(provider.selectedStates!.stateID);
                  provider.selectedCitys = null;
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildLabeledField(
              label: cityString,
              child: AppSearchableDropdown<Citylistm>(
                dropdownKey: ValueKey(provider.selectedCitys),
                initialItem: provider.selectedCitys,
                hintText: cityString,
                futureRequest: (value) => provider.getFilterCitys(value, context),
                items: Provider.of<AddresProviders>(context, listen: false).filtersCityList,
                itemAsString: (item) => item.cityName.toString(),
                headerBuilder: (context, selectedItem, enabled) {
                  return Text(provider.selectedCitys == null ? selectCityString : provider.selectedCitys!.cityName.toString());
                },
                onChanged: (vals) {
                  provider.selectedCitys = vals;
                  Provider.of<AddresProviders>(context, listen: false).filterPincodes(provider.selectedCitys!.cityID);
                },
              ),
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 18),
      
      _buildLabeledField(
        label: pincodeString,
        child: AppSearchableDropdown<pincodem>(
          dropdownKey: ValueKey(provider.selectedPincodes),
          initialItem: provider.selectedPincodes,
          hintText: pincodeString,
          futureRequest: (value) => provider.getFilterPincode(value, context),
          items: Provider.of<AddresProviders>(context, listen: false).filtersPincodeList,
          itemAsString: (item) => item.code.toString(),
          headerBuilder: (context, selectedItem, enabled) {
            return Text(provider.selectedPincodes == null ? selectPincodeString : provider.selectedPincodes!.code.toString());
          },
          onChanged: (vals) {
            provider.selectedPincodes = vals;
          },
        ),
      ),
    ],
  );
}

// =========================================================
// EDUCATION TAB (Renamed but functionality unchanged)
// =========================================================

Widget _educationTab(Size size, EmployeeMasterProvider provider) {
  // Shimmer for education tab while loading
  if (provider.islodering) {
    return Column(
      children: List.generate(4, (index) => _buildShimmerField(size)),
    );
  }
  
  return Column(
    children: [
      responsiveRow(
        child1: _buildLabeledField(
          label: highestDegreeString,
          child: CommonTextField(
            controller: provider.heighestDegreeController,
            borderRadius: 8.0,
          ),
        ),
        child2: _buildLabeledField(
          label: degreeNameString,
          child: CommonTextField(
            controller: provider.degreeNameController,
            borderRadius: 8.0,
          ),
        ),
      ),
      const SizedBox(height: 18),
      responsiveRow(
        child1: _buildLabeledField(
          label: universitySchoolString,
          child: CommonTextField(
            controller: provider.uniSclController,
            borderRadius: 8.0,
          ),
        ),
        child2: _buildLabeledField(
          label: passingYearString,
          child: CommonTextField(
            controller: provider.passingYearController,
            borderRadius: 8.0,
            keyboardType: const TextInputType.numberWithOptions(),
          ),
        ),
      ),
    ],
  );
}

// =========================================================
// BANK TAB (Renamed but functionality unchanged)
// =========================================================

Widget _bankDetailsTab(Size size, EmployeeMasterProvider provider) {
  // Shimmer for bank tab while loading
  if (provider.islodering) {
    return Column(
      children: List.generate(6, (index) => _buildShimmerField(size)),
    );
  }
  
  return Column(
    children: [
      IfscCodeDropdown(
        provider.selectedIfsccode,
        (value) {
          provider.selectedIfsccode = value;
          provider.bankNameController.text = provider.selectedIfsccode!.bankName.toString();
          provider.branchNameController.text = provider.selectedIfsccode!.branchName.toString();
        },
        () {
          provider.bankNameController.clear();
          provider.branchNameController.clear();
        },
      ),
      
      const SizedBox(height: 18),
      
      responsiveRow(
        child1: _buildLabeledField(
          label: bankNameString,
          child: CommonTextField(
            controller: provider.bankNameController,
            borderRadius: 8.0,
            readOnly: true,
          ),
        ),
        child2: _buildLabeledField(
          label: branchNameString,
          child: CommonTextField(
            controller: provider.branchNameController,
            borderRadius: 8.0,
            readOnly: true,
          ),
        ),
      ),
      
      const SizedBox(height: 18),
      
      _buildLabeledField(
        label: accountNoString,
        child: CommonTextField(
          controller: provider.accNoController,
          borderRadius: 8.0,
          keyboardType: const TextInputType.numberWithOptions(),
          maxLength: 14,
        ),
      ),
      
      const SizedBox(height: 18),
      
      _buildLabeledField(
        label: accountTypeString,
        child: Container(
          height: 50.0,
          decoration: BoxDecoration(
            border: Border.all(color: ColorConst.textBorder, width: 1.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<Mstclass>(
              isExpanded: true,
              hint: Text(
                provider.selectedAccounttype == null ? accountTypeString : provider.selectedAccounttype!.description.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: ColorConst.hintextColor,
                ),
              ),
              items: provider.bankAccountTypesList.map((item) => DropdownItem<Mstclass>(
                value: item,
                child: Text(
                  item.description!,
                  style: TextStyle(fontSize: 15, color: ColorConst.black),
                ),
              )).toList(),
              selectedItemBuilder: (context) {
                return provider.bankAccountTypesList.map((item) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      provider.selectedAccounttype == null ? accountTypeString : provider.selectedAccounttype!.description.toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              onChanged: (Mstclass? value) {
                provider.setAccType(value);
              },
            ),
          ),
        ),
      ),
      
      const SizedBox(height: 18),
      
      responsiveRow(
        child1: _buildLabeledField(
          label: uanNumberString,
          child: CommonTextField(
            controller: provider.uanNOController,
            borderRadius: 8.0,
          ),
        ),
        child2: _buildLabeledField(
          label: esicNumberString,
          child: CommonTextField(
            controller: provider.esicController,
            borderRadius: 8.0,
          ),
        ),
      ),
    ],
  );
}

// =========================================================
// STATUS
// =========================================================

Widget _buildStatusSection(EmployeeMasterProvider provider) {
  return Container(
    decoration: BoxDecoration(
      color: ColorConst.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Radio<bool>(
          value: true,
          activeColor: ColorConst.greenColor,
          groupValue: provider.isActive,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          onChanged: (v) => provider.changeStatus(v!),
        ),
        const SizedBox(width: 6),
        Text(activeString, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 20),
        Radio<bool>(
          value: false,
          activeColor: ColorConst.red,
          groupValue: provider.isActive,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          onChanged: (v) => provider.changeStatus(v!),
        ),
        const SizedBox(width: 6),
        Text(inActiveString, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

// =========================================================
// HELPER WIDGETS
// =========================================================

Widget _buildLabeledField({
  required String label,
  bool isRequired = false,
  required Widget child,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: ColorConst.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          children: [
            if (isRequired)
              TextSpan(
                text: " *",
                style: TextStyle(
                  color: ColorConst.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

Widget _buildSubSectionHeader(String title, IconData icon) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: ColorConst.themeColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ColorConst.themeColor, size: 18),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ColorConst.themeColor,
        ),
      ),
    ],
  );
}

// =========================================================
// SHIMMER HELPER WIDGET
// =========================================================

Widget _buildShimmerField(Size size) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: size.width * 0.3,
            height: 14,
            color: Colors.grey.withOpacity(0.05),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 50.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
          ),
        ],
      ),
    ),
  );
}

// =========================================================
// RESPONSIVE ROW
// =========================================================

Widget responsiveRow({required Widget child1, required Widget child2}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        return Column(children: [child1, const SizedBox(height: 16), child2]);
      }
      return Row(
        children: [
          Expanded(child: child1),
          const SizedBox(width: 16),
          Expanded(child: child2),
        ],
      );
    },
  );
}

// =========================================================
// CARD DECORATION
// =========================================================

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: ColorConst.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.06),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

Future<void> showImagePickerOptions(BuildContext context, EmployeeMasterProvider provider) async {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Icon(Icons.photo_library, color: ColorConst.themeColor),
                title: Text(chooseFromGalleryString),
                onTap: () {
                  Navigator.pop(context);
                  provider.pickProfileImageFromGallery();
                },
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Icon(Icons.camera_alt, color: ColorConst.themeColor),
                title: Text(takeAPhotoString),
                onTap: () {
                  Navigator.pop(context);
                  provider.pickProfileImageFromCamera();
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}