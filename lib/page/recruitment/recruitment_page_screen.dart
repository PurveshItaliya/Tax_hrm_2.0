// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/recruitment/add_recruitment_screen.dart';
import 'package:tax_hrm/page/recruitment/recruitment_screen_design.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/recuritmentprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/dateformat.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/custometextfiled.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class RecruitmentPageScreen extends StatefulWidget {
  const RecruitmentPageScreen({super.key});

  @override
  State<RecruitmentPageScreen> createState() => _RecruitmentPageScreenState();
}

class _RecruitmentPageScreenState extends State<RecruitmentPageScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    await Provider.of<RecuritmentProvider>(context,listen: false).recuritmentLoadingData();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context,);
    final recuritmentProvider =  Provider.of<RecuritmentProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: recuritmentProvider.islodering ? SizedBox() : Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.03),
                child: iconWithTextBtnDesign(size,addCandidateString,isIcon: false,onTap: () async {
                  await recuritmentProvider.clearDataRecuriment(context,true);
                  nextScreen(context, AddRecruitmentScreen(addEditFlag: true, getRecruitmentData: null),onthenValue: (value) {
                    _loadAllData();
                  });
                },isgradient: true,isImage: false),
              ),
              appBar: showCustomeAppBar(candidateString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
              body: refreshIndicatorDesign(
                onRefreshOntap: () {
                  return _loadAllData();
                },
                widgetDesign: Padding(
                  padding: EdgeInsets.all(size.height*0.02),
                  child: recuritmentProvider.islodering ? departmentMasterShimmer(size,false) : Column(
                    children: [
                      CommonTextField(controller: recuritmentProvider.txtSerchController,fillColors: ColorConst.white,borderColor: ColorConst.transparent,hintText: searchCandidateListString,prefixIcon: Padding(padding: const EdgeInsets.only(left: 10,right: 10),child: Icon(Icons.search,color: ColorConst.commatextIconsColors,),),onChanged: (value) {recuritmentProvider.searchAllRecuritmentData(value);},),
                      heightSpacer(size.height*0.02,),
                      recuritmentProvider.getRecuirtmentGroupList.isEmpty
                          ? Expanded(child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),child: SizedBox(width: size.width,height: size.height*0.65,child: noDataFoundsDesign(size, noCandidateAddedString,nodataFoundsImagString)))) 
                          : Expanded(
                            child: ListView.builder(physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: recuritmentProvider.getRecuirtmentGroupList.length,
                              padding: EdgeInsets.only(
                                bottom: size.height * 0.10,
                              ),
                              itemBuilder: (context, index) {
                                return  recruitmentCard(size: size,titles: recuritmentProvider.getRecuirtmentGroupList[index].name,conductedBy: "${recuritmentProvider.getRecuirtmentGroupList[index].firstName} ${recuritmentProvider.getRecuirtmentGroupList[index].lastName}",departmentName: recuritmentProvider.getRecuirtmentGroupList[index].departmentName,position: recuritmentProvider.getRecuirtmentGroupList[index].positionName,interviewDate: dateFormatdate(DateTime.parse(recuritmentProvider.getRecuirtmentGroupList[index].recruitmentDate.toString())),editOntap: () async {
                                  recuritmentProvider.clearDataRecuriment(context, false);
                                  await recuritmentProvider.editHandleSubmit(context,recuritmentProvider.getRecuirtmentGroupList[index],);
                                },deleteOntap: (){
                                  showDeleteDialog(context,size,yesOntap: () {recuritmentProvider.deleteRecuritmentMaster(context,setRecuritmentid: recuritmentProvider.getRecuirtmentGroupList[index].recruitmentID);},noOnTap: (){Navigator.pop(context);});
                                });
                              },
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            );
  }
}
