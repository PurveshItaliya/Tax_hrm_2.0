// ignore_for_file: strict_top_level_inference, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/department/department_screen_design.dart';
import 'package:tax_hrm/provider/department_provider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/pagniation.dart';
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

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    Provider.of<DepartmentServices>(context,listen: false,).departmentLoadingData().then((value) {
      Provider.of<AppPaginationProvider>(context,listen: false).countPaginationPage(Provider.of<DepartmentServices>(context,listen: false).showedepartment,0);
    },);
  }

  final userDepartFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context,);
    final departmentServices =  Provider.of<DepartmentServices>(context);
    final appPaginationController = Provider.of<AppPaginationProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: departmentServices.islodering ? SizedBox() : Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.06),
                child: iconWithTextBtnDesign(size,addDepartmentString,isIcon: false,onTap: () {
                  departmentServices.departmentnamecontroller.text = "";
                  departmentServices.departmentStatus = "true";
                  departmentServices.departmentHandleSubmit(context,size,userDepartFormKey,addEditFlag:true,setdid: "",);
                },isgradient: true,isImage: false),
              ),
              appBar: showCustomeAppBar(departmentMasterString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}, actions: [
                IconButton(onPressed: (){
                  showNumberOfData(context, size,departmentServices.showedepartment,);
                }, icon:const Icon(Icons.more_vert))
              ],),
              body: refreshIndicatorDesign(
                onRefreshOntap: () {
                  return _loadAllData();
                },
                widgetDesign: Padding(
                  padding: EdgeInsets.all(size.height*0.02),
                  child: departmentServices.islodering ? departmentMasterShimmer(size,true) : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      departmentServices.showedepartment.isEmpty
                      ? Expanded(child: SingleChildScrollView(child: SizedBox(width: size.width,height: size.height*0.65,child: noDataFoundsDesign(size, noDepartmentAddedString,nodataFoundsImagString)))) 
                      : Expanded(
                        child: ListView.builder(
                          itemCount: departmentServices.showedepartment.length,
                          padding: EdgeInsets.only(bottom: size.height * 0.075),
                          itemBuilder: (context, index) {
                            if(appPaginationController.endIndexShow > index && appPaginationController.startIndextoShow <= index) {
                              return departmentCard(
                                true,
                                size: size,titles: departmentServices.showedepartment[index].departmentName,deleteOntap: (){
                                  showDeleteDialog(context,size,yesOntap: () {
                                    departmentServices.deleteDepartmentHandleSubmit(context,setdid: departmentServices.showedepartment[index]).then((value) async {
                                      await appPaginationController.countPaginationPage(departmentServices.showedepartment,0);
                                    },);
                                  },noOnTap: (){Navigator.pop(context);});
                                },editOntap: (){
                                  departmentServices.editDepartmentHandleSubmit(context,size,userDepartFormKey,setdid: departmentServices.showedepartment[index]);
                                },borderColor: 
                                departmentServices.showedepartment[index].isActive.toString().toLowerCase() == 'null'.toString().toLowerCase() ? ColorConst.themeColor :
                                departmentServices.showedepartment[index].isActive.toString().toLowerCase() == 'True'.toString().toLowerCase() ?ColorConst.themeColor  :  ColorConst.redDarkColors
                              );
                            } else{
                              return SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      departmentServices.showedepartment.isEmpty ? SizedBox() : CommonPagination(appPaginationController.setSelectedPaginationPage, appPaginationController.setTotalPaginationPage, (int index) {
                        appPaginationController.countPaginationPage(departmentServices.showedepartment, index);
                      },),
                    ],
                  )
                ),
              ),
            );
  }
}
