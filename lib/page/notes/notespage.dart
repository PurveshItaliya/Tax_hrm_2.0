import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/notesprovider.dart';
import 'package:tax_hrm/utils/basicdata.dart';
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

class NotesViewPage extends StatefulWidget {
  const NotesViewPage({super.key});

  @override
  State<NotesViewPage> createState() => _NotesViewPageState();
}

class _NotesViewPageState extends State<NotesViewPage> {
  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
    Provider.of<NotesProviders>(context, listen: false).loadingData();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context,);
    final notesProvidersData =  Provider.of<NotesProviders>(context);
    Provider.of<LanguageProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              appBar: showCustomeAppBar(noteString, size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){backScreen(context);}),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: notesProvidersData.islodering ? SizedBox() : Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.03),
                child: iconWithTextBtnDesign(size,addNewNoteString,isIcon: false,onTap: () {notesProvidersData.notesHandleSubmit(context,size);},isgradient: true,isImage: false),
              ),
              body: Padding(
                padding: EdgeInsets.only(top: size.height*0.03,bottom: size.height*0.03),
                child: notesProvidersData.islodering ? notesShimmer(size) : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: EdgeInsets.only(left: size.height*0.02,right: size.height*0.02),child: CommonTextField(controller: notesProvidersData.txtNotesController,fillColors: ColorConst.white,borderColor: ColorConst.transparent,hintText: searchNotesString,prefixIcon: Padding(padding: const EdgeInsets.only(left: 10,right: 10),child: Icon(Icons.search,color: ColorConst.commatextIconsColors,),),onChanged: (value) {notesProvidersData.searchAllNotesData(value);},),),
                    heightSpacer(size.height*0.02,),
                    notesProvidersData.showUserNotesList.isEmpty
                    ? Expanded(child: refreshIndicatorDesign(onRefreshOntap: () async { await Provider.of<NotesProviders>(context, listen: false).loadingData(); }, widgetDesign: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: SizedBox(width: size.width,height: size.height*0.65,child: noDataFoundsDesign(size, noNotesAddedString,nodataFoundsImagString))))) :
                    Expanded(
                      child: refreshIndicatorDesign(
                        onRefreshOntap: () async { await Provider.of<NotesProviders>(context, listen: false).loadingData(); },
                        widgetDesign: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          shrinkWrap: true,
                        itemCount: notesProvidersData.showUserNotesList.length,
                        padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
                        separatorBuilder: (context, index) {
                          return heightSpacer(size.height * 0.02);
                        },
                        itemBuilder: (context, index) {
                          return Container(
                            padding: EdgeInsets.all(size.width*0.025),
                            decoration: BoxDecoration(
                              color: ColorConst.white,
                              border: Border(bottom: BorderSide(color: ColorConst.containerBorderColor,width: 1),top: BorderSide(color: ColorConst.containerBorderColor,width: 1))
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(radius: 20,backgroundColor: ColorConst.circleBgColors,child: Text("P",style: TextStyle(color: ColorConst.black,fontSize: 13,fontFamily: fontInterMediumString,fontWeight: FontWeight.w500),),),
                                    widthSpacer(size.width*0.03,),
                                    Expanded(child: Text(notesProvidersData.showUserNotesList[index].message.toString(),style: TextStyle(fontFamily: fontInterMediumString,fontSize: 12,fontWeight: FontWeight.w500,color: ColorConst.notesTitlesColors),)),
                                    widthSpacer(size.width*0.03,),
                                    Text(dateFormatddMMMyyyy(DateTime.parse(notesProvidersData.showUserNotesList[index].entryTime.toString())),style: TextStyle(fontFamily: fontInterMediumString,fontSize: 11,fontWeight: FontWeight.w500,color: ColorConst.notesSubTitlesColors),),
                                  ],
                                ),
                                if(notesProvidersData.showUserNotesList[index].img != "")...[
                                  heightSpacer(size.height*0.008,),
                                  ClipRRect(borderRadius: BorderRadius.circular(size.width * 0.03),child: Image.network('${apibaseurl}UploadFiles/Notes/${selectedcurentcompany!.companyId}/${curentUser['Id']}/${notesProvidersData.showUserNotesList[index].img.toString()}',height: size.height * 0.09,fit: BoxFit.cover,),),
                                ]
                              ],
                            )
                          );
                        },
                        ),
                      ),
                    ),
                  ],
                ),
              )
            );
  }
}
