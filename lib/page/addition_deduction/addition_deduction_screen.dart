// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/addition_deduction/addition_deduction_design.dart';
import 'package:tax_hrm/provider/additionprovider.dart';
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

class AdditionDeductionScreen extends StatefulWidget {
  const AdditionDeductionScreen({super.key});

  @override
  State<AdditionDeductionScreen> createState() => _AdditionDeductionScreenState();
}

class _AdditionDeductionScreenState extends State<AdditionDeductionScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    Provider.of<AdditionProvider>(context,listen: false,).additionLoadingData().then((value) {
      Provider.of<AppPaginationProvider>(context,listen: false).countPaginationPage(Provider.of<AdditionProvider>(context,listen: false).mainAdditionGroupList,0);
    },);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context,);
    final additionProvider =  Provider.of<AdditionProvider>(context);
    final appPaginationController = Provider.of<AppPaginationProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: additionProvider.islodering ? SizedBox() : Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.06),
                child: iconWithTextBtnDesign(size,addAdditionDeductionString,isIcon: false,onTap: () async {
                  await additionProvider.handleSubmitList(context,null,true);
                },isgradient: true,isImage: false),
              ),
              appBar: showCustomeAppBar(additionDeductionListString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);},actions: [
                IconButton(onPressed: (){
                  showNumberOfData(context, size,additionProvider.mainAdditionGroupList,);
                }, icon:const Icon(Icons.more_vert))
              ],),
              body: refreshIndicatorDesign(
                onRefreshOntap: () {
                  return _loadAllData();
                },
                widgetDesign: Padding(
                  padding: EdgeInsets.all(size.height*0.02),
                  child: additionProvider.islodering ? departmentMasterShimmer(size,false) : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      additionProvider.mainAdditionGroupList.isEmpty
                      ? Expanded(child: SingleChildScrollView(child: SizedBox(width: size.width,height: size.height*0.65,child: noDataFoundsDesign(size, noDataFoundsString,nodataFoundsImagString)))) 
                      : Expanded(
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: additionProvider.mainAdditionGroupList.length,
                          padding: EdgeInsets.only(bottom: size.height * 0.075),
                          itemBuilder: (context, index) {
                            if(appPaginationController.endIndexShow > index && appPaginationController.startIndextoShow <= index) {
                              return additionDeductionCard(size: size,titles: additionProvider.mainAdditionGroupList[index].empName,hraValue: additionProvider.mainAdditionGroupList[index].hRA!.isEmpty ?"0":additionProvider.mainAdditionGroupList[index].hRA.toString(),daValue: additionProvider.mainAdditionGroupList[index].dA!.isEmpty ?"0":additionProvider.mainAdditionGroupList[index].dA.toString(),pfValue: additionProvider.mainAdditionGroupList[index].pF!.isEmpty ?"0":additionProvider.mainAdditionGroupList[index].pF.toString(),tdsValue: additionProvider.mainAdditionGroupList[index].tDS!.isEmpty ?"0":additionProvider.mainAdditionGroupList[index].tDS.toString(),deleteOntap: () {
                                showDeleteDialog(context,size,yesOntap: () {
                                  additionProvider.deleteAdditionDeductionHandleSubmit(context,setdid: additionProvider.mainAdditionGroupList[index]).then((value) async {
                                    await appPaginationController.countPaginationPage(additionProvider.mainAdditionGroupList,0);
                                  },);
                                },noOnTap: (){Navigator.pop(context);});
                              },editOntap: () async {
                                await additionProvider.handleSubmitList(context,additionProvider.mainAdditionGroupList[index],false);
                              });
                            } else{
                              return SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      additionProvider.mainAdditionGroupList.isEmpty ? SizedBox() : CommonPagination(appPaginationController.setSelectedPaginationPage, appPaginationController.setTotalPaginationPage, (int index) {
                        appPaginationController.countPaginationPage(additionProvider.mainAdditionGroupList, index);
                      },),
                    ],
                  )
                ),
              ),
            );
  }
}
