import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/document/viewdocument_screen.dart';
import 'package:tax_hrm/provider/documentprovider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/comman_shimmer_design.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class ShowDocumentScreen extends StatefulWidget {
  const ShowDocumentScreen({super.key});

  @override
  State<ShowDocumentScreen> createState() => _ShowDocumentScreenState();
}

class _ShowDocumentScreenState extends State<ShowDocumentScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
    Provider.of<DocumentsProvider>(context, listen: false).loadingData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      safeAreaBgAndTextColor(context,);
    });
  }
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    var documentproviders = Provider.of<DocumentsProvider>(context);
    Provider.of<LanguageProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: (documentproviders.islodering)?SizedBox():Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.03),
                child: iconWithTextBtnDesign(size,addDocumentString,isIcon: false,isImage: false,onTap: () {
                  documentproviders.selectedFiles.clear();
                  documentproviders.documentCategorey.clear();
                  showAddDialog(context,size: size,imageOntap: () async { await documentproviders.loadImageData(ImageSource.gallery);},);
                }, isgradient: true),
              ),
              appBar: showCustomeAppBar(documentString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){
                backScreen(context);
              }),
              body: refreshIndicatorDesign(
                onRefreshOntap: () async {
                  await Provider.of<DocumentsProvider>(context, listen: false).loadingData();
                },
                widgetDesign: documentproviders.islodering ? 
                  holidaysShimmer(size): 
                  documentproviders.showDocumentList.isEmpty
                    ? SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: SizedBox(width: size.width,height: size.height * 0.7, child: noDataFoundsDesign(size, noDocumentAddedString,nodataFoundsImagString)))
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                      itemCount: documentproviders.showDocumentList.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: ColorConst.white,
                            border: Border.all(color: ColorConst.grey.withOpacity(.5)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: EdgeInsets.only(left: size.width*0.03),
                              leading: Icon(Icons.file_copy),
                              title: Text(documentproviders.showDocumentList[index].filename.toString(),style: TextStyle(fontFamily: fontInterSemiBoldString,fontSize: 15,fontWeight: FontWeight.w700,color: ColorConst.holidayTitleColors),),
                              subtitle: Text("Category: ${documentproviders.showDocumentList[index].category}",style: TextStyle(fontFamily: fontInterMediumString,fontSize: 13,fontWeight: FontWeight.w500,color: ColorConst.holidaySubTitleColors),),
                              trailing: PopupMenuButton(
                                offset: Offset(0, size.height * 0.063),
                                color: ColorConst.white,
                                iconColor: ColorConst.black,
                                itemBuilder: (context) {
                                  return [
                                    popupMenuDesign(value: 0, icon: Icons.delete, title: deleteString, size: size),
                                    popupMenuDesign(value: 1, icon: Icons.remove_red_eye_outlined, title: viewString, size: size),
                                  ];
                                },
                                onSelected: (value) async {
                                  if (value == 0) {
                                    showDeleteDialog(context,size,yesOntap: () async {await documentproviders.deleteEmployeDocuments(context,deleteEmpImage: documentproviders.showDocumentList[index].id); },noOnTap: (){Navigator.pop(context);});
                                  } else if (value == 1) {
                                    nextScreen(context, ViewDocumentScreen(selectedData: documentproviders.showDocumentList[index],),onthenValue: (value) {},);
                                  }
                                }
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return heightSpacer(size.height * 0.015);
                      },
                    ),
              ),
            );
  }
}