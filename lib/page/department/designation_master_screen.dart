import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/provider/department_provider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/pagniation.dart';
import 'package:tax_hrm/provider/position_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/common_popmenu.dart';
import 'package:tax_hrm/widigets/commonpaginator.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';

class DesignationScreen extends StatefulWidget {
  const DesignationScreen({super.key});

  @override
  State<DesignationScreen> createState() => _DesignationScreenState();
}

class _DesignationScreenState extends State<DesignationScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    Provider.of<PositionMasterService>(context,listen: false,).designatiionLoadingData().then((value) {
      Provider.of<AppPaginationProvider>(context,listen: false).countPaginationPage(Provider.of<PositionMasterService>(context,listen: false).showPositions,0);
    },);
    Provider.of<DepartmentServices>(context,listen: false).getDepartmentMasterData();
  }

  final userDesignationFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context,);
    final desigNationMasterService =  Provider.of<PositionMasterService>(context);
    final appPaginationController = Provider.of<AppPaginationProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: desigNationMasterService.islodering ? SizedBox() : Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.06),
                child: iconWithTextBtnDesign(size,addDesignationString,isIcon: false,onTap: () {
                  desigNationMasterService.designationnamecontroller.text = "";
                  desigNationMasterService.designationStatus = "true";
                  desigNationMasterService.selectedDepartment = null;
                  desigNationMasterService.designationHandleSubmit(context,size,userDesignationFormKey,addEditFlag:true,setdid: "",);
                },isgradient: true,isImage: false),
              ),
              appBar: showCustomeAppBar(designationMasterString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);},actions: [
                IconButton(onPressed: (){
                  showNumberOfData(context, size,desigNationMasterService.showPositions,);
                }, icon:const Icon(Icons.more_vert))
              ],),
              body: refreshIndicatorDesign(
                onRefreshOntap: () {
                  return _loadAllData();
                },
                widgetDesign: Padding(
                  padding: EdgeInsets.all(size.height*0.02),
                  child: desigNationMasterService.islodering ? departmentMasterShimmer(size,false) : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      desigNationMasterService.showPositions.isEmpty
                      ? Expanded(child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),child: SizedBox(width: size.width,height: size.height*0.65,child: noDataFoundsDesign(size, noDesignationAddedString,nodataFoundsImagString)))) 
                      : Expanded(
                        child: ListView.builder(physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: desigNationMasterService.showPositions.length,
                          padding: EdgeInsets.only(bottom: size.height * 0.075),
                          itemBuilder: (context, index) {
                            if(appPaginationController.endIndexShow > index && appPaginationController.startIndextoShow <= index) {
                              return departmentCard(
                                false,
                                size: size,titles: desigNationMasterService.showPositions[index].positionName.toString().toLowerCase() == 'null' ?"": desigNationMasterService.showPositions[index].positionName.toString(),deleteOntap: (){
                                  showDeleteDialog(context,size,yesOntap: () {
                                    desigNationMasterService.deleteDesignationHandleSubmit(context,setdid: desigNationMasterService.showPositions[index]).then((value) async {
                                      await appPaginationController.countPaginationPage(desigNationMasterService.showPositions,0);
                                    },);
                                  },noOnTap: (){Navigator.pop(context);});
                                },editOntap: (){
                                  desigNationMasterService.editDesignationHandleSubmit(context,size,userDesignationFormKey,setdid: desigNationMasterService.showPositions[index]);
                                },borderColor: 
                                desigNationMasterService.showPositions[index].isActive.toString().toLowerCase() == 'null'.toString().toLowerCase() ? ColorConst.themeColor :
                                desigNationMasterService.showPositions[index].isActive.toString().toLowerCase() == 'True'.toString().toLowerCase() ?ColorConst.themeColor  :  ColorConst.redDarkColors,
                                departmentName:  "$departmentNameString :- ${desigNationMasterService.showPositions[index].departmentName.toString().toLowerCase() == 'null' ?"": desigNationMasterService.showPositions[index].departmentName.toString()}",
                              );
                            } else{
                              return SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      desigNationMasterService.showPositions.isEmpty ? SizedBox() : CommonPagination(appPaginationController.setSelectedPaginationPage, appPaginationController.setTotalPaginationPage, (int index) {
                        appPaginationController.countPaginationPage(desigNationMasterService.showPositions, index);
                      },),
                    ],
                  )
                ),
              ),
            );
  }
}
