// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:tax_hrm/widigets/app_searchable_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/departmentclass/Designationmasterclass/position.dart';
import 'package:tax_hrm/models/departmentclass/departemtmaster/departmentdata.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/recruitment/recruitmentmodel.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/department_provider.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/position_provider.dart';
import 'package:tax_hrm/provider/recuritmentprovider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/utils/validation.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class AddRecruitmentScreen extends StatefulWidget {
  final bool addEditFlag;final RecruitmentModal? getRecruitmentData;
  const AddRecruitmentScreen({super.key,required this.addEditFlag,required this.getRecruitmentData});

  @override
  State<AddRecruitmentScreen> createState() => _AddRecruitmentScreenState();
}

class _AddRecruitmentScreenState extends State<AddRecruitmentScreen> {

  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    Provider.of<DepartmentServices>(context,listen: false).getDepartmentMasterData();
    Provider.of<PositionMasterService>(context,listen: false,).designatiionLoadingData();
  }

  final userRecruitmentFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final recuritmentProvider = Provider.of<RecuritmentProvider>(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final datePickerProvider = Provider.of<CommandWidigetsProvider>(context);
    final positionMasterService = Provider.of<PositionMasterService>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            backgroundColor:ColorConst.scaffoldColor,
            appBar: showCustomeAppBar(candidateDetailsString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
            body: recuritmentProvider.islodering ? userProfileShimmer(size) : Padding(
              padding: EdgeInsets.all(size.width * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: userRecruitmentFormKey,
                        autovalidateMode: recuritmentProvider.autoRecuritmentvalidateMode,
                        child:Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonTextField(controller: recuritmentProvider.txtCandidateNameController,hintText: enterCandidateNameString,showHeading: candidateNameString,validator: (value) {
                              if(value!.isEmpty) {
                                return '$pleaseEnterString $candidateNameString';
                              }
                              return null;
                            }),
                            heightSpacer(size.height*0.01),
                            CommonTextField(controller: recuritmentProvider.txtCandidateDateController,readOnly: true,hintText: selectDateString,suffixIcon: IgnorePointer(child: IconButton(onPressed: (){}, icon: Icon(Icons.calendar_today_outlined,color: ColorConst.passwordColor,),)),showHeading: dateString,onTap: () {
                                recuritmentProvider.selectDatePicker(context,size,dateController: datePickerProvider,selectDatePic: recuritmentProvider.recurimentStartDate,).then((value) {
                                    recuritmentProvider.recurimentStartDate = value;
                                    recuritmentProvider.txtCandidateDateController.text = dateFormatdate(recuritmentProvider.recurimentStartDate);
                                 },);
                                },),
                            heightSpacer(size.height * 0.01),
                            Text("$departmentString :", style: normalHeadingText(size)),
                            heightSpacer(size.height * 0.01),
                            AppSearchableDropdown<DepartMnetModel>(
                              dropdownKey: ValueKey(recuritmentProvider.selectedDepartment),
                              initialItem: recuritmentProvider.selectedDepartment,
                              hintText: selectDepartmentNameString,
                              futureRequest: context.read<DepartmentServices>().getFilterDepartment,
                              items: context.read<DepartmentServices>().activepartment,
                              itemAsString: (item) => item.departmentName.toString(),
                              headerBuilder: (context, selectedItem, enabled) {
                                return Text(recuritmentProvider.selectedDepartment == null ? selectDepartmentNameString : recuritmentProvider.selectedDepartment!.departmentName.toString());
                              },
                              onChanged: (value) {
                                recuritmentProvider.depatmentontap(value,positionMasterService);
                              },
                            ),
                            heightSpacer(size.height * 0.01),
                            Text("$designationString :", style: normalHeadingText(size)),
                            heightSpacer(size.height * 0.01),
                            AppSearchableDropdown<PositionDataL>(
                              dropdownKey: ValueKey(recuritmentProvider.selectedDesignation),
                              initialItem: recuritmentProvider.selectedDesignation,
                              hintText: selectDesignationNameString,
                              futureRequest: recuritmentProvider.getFilterDesignation,
                              items: recuritmentProvider.getFiltersPostionList,
                              itemAsString: (item) => item.positionName.toString(),
                              headerBuilder: (context, selectedItem, enabled) {
                                return Text(recuritmentProvider.selectedDesignation == null ? selectDesignationNameString : recuritmentProvider.selectedDesignation!.positionName.toString());
                              },
                              onChanged: (value) {
                                recuritmentProvider.designationontap(value);
                              },
                            ),
                            heightSpacer(size.height*0.01),
                            Text("$conductedByString :", style: normalHeadingText(size)),
                            heightSpacer(size.height * 0.01),
                            AppSearchableDropdown<Employeelists>(
                              dropdownKey: ValueKey(recuritmentProvider.selectedEmployeeList),
                              initialItem: recuritmentProvider.selectedEmployeeList,
                              hintText: selectConductedByString,
                              futureRequest:  Provider.of<EmployeMastServices>(context,listen: false).getFilterEmployeeby,
                              items: Provider.of<EmployeMastServices>(context,listen: false).emplists,
                              itemAsString: (item) => "${item.firstName.toString()} ${item.lastName.toString()}",
                              headerBuilder: (context, selectedItem, enabled) {
                                return Text(recuritmentProvider.selectedEmployeeList == null ? selectConductedByString : "${recuritmentProvider.selectedEmployeeList!.firstName.toString()} ${recuritmentProvider.selectedEmployeeList!.lastName.toString()}");
                              },
                              onChanged: (value) {
                                recuritmentProvider.employessontap(value);
                              },
                            ),
                            heightSpacer(size.height*0.01),
                            CommonTextField(controller: recuritmentProvider.txtreferenceByController,hintText: enterReferenceByNameString,showHeading: referenceByString),
                            heightSpacer(size.height*0.01),
                            CommonTextField(controller: recuritmentProvider.txtVenueController,hintText: enterVenueNameString,showHeading: venueString),
                            heightSpacer(size.height*0.01),
                            CommonTextField(controller: recuritmentProvider.txtExperienceController,hintText: enterExperienceString,showHeading: experienceString,keyboardType: TextInputType.number,
                              inputformat: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4),],
                            ),
                            heightSpacer(size.height*0.01),
                            CommonTextField(controller: recuritmentProvider.txtMobileController,hintText: enterMobileNoString,showHeading: mobileNoString,keyboardType: TextInputType.number,
                              inputformat: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10),],validator: (p0) => allValidMobile(p0!),
                            ),
                            heightSpacer(size.height*0.01),
                            CommonTextField(controller: recuritmentProvider.txtEmailController,hintText: enterEmailString,showHeading: emailUserString,validator: (p0) => allValidEmail(p0!),),
                            heightSpacer(size.height*0.01),
                            CommonTextField(controller: recuritmentProvider.txtLastSalaryController,hintText: enterLastSalaryString,showHeading: lastSalaryString,keyboardType: TextInputType.number,
                              inputformat: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6),],
                            ),
                            heightSpacer(size.height*0.01),
                            CommonTextField(controller: recuritmentProvider.txtExperienceSalaryController,hintText: enterExpectedSalaryString,showHeading: expectedSalaryString,keyboardType: TextInputType.number,
                              inputformat: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6),],
                            ),
                            heightSpacer(size.height*0.01),
                            CommonTextField(controller: recuritmentProvider.txtRemarkController,hintText: enterEventRemarksString,showHeading: eventRemarkString,maxLines: 3,),
                            heightSpacer(size.height*0.01),
                          ],
                        ) 
                      ),
                    ),
                  ),
                  heightSpacer(size.height *0.02),
                  Row(
                    children: [
                      Expanded(child: btnDesign(size,titles: saveString,onTap: () async {
                        await recuritmentProvider.handleSubmit(context, userRecruitmentFormKey, widget.addEditFlag, widget.addEditFlag?"":widget.getRecruitmentData);
                      }, isgradient: true,)),
                      widthSpacer(size.width *0.02),
                      Expanded(child: btnDesign(size,titles: cancelString,bgColor: Colors.transparent,borderColors: ColorConst.themeColor,textColors: ColorConst.themeColor,onTap: () {Navigator.pop(context);},)),
                    ],
                  ),
                ],
              ),
            ),
          );
  }
}
