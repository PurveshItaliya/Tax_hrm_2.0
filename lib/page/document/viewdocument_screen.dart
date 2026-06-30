import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/documentsclass/showdocuments.dart';
import 'package:tax_hrm/provider/documentprovider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';

class ViewDocumentScreen extends StatefulWidget {
  final DocumentViews selectedData; 
  const ViewDocumentScreen({super.key, required this.selectedData});

  @override
  State<ViewDocumentScreen> createState() => _ViewDocumentScreenState();
}

class _ViewDocumentScreenState extends State<ViewDocumentScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
    Provider.of<DocumentsProvider>(context, listen: false).loadViewDocuments(selectedData: widget.selectedData);
  }
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    var documentproviders = Provider.of<DocumentsProvider>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              appBar: showCustomeAppBar(widget.selectedData.filename.toString(), size,titleColors: ColorConst.appbarTextColor,iconsOntap: (){
                backScreen(context);
              }),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  documentproviders.contentType == null  ? loaderDesign() : documentproviders.contentType!.startsWith('image') ?
                    SizedBox(height: size.height *0.8,child: Image.network('${widget.selectedData.filePath}${widget.selectedData.filename}')) :
                    SizedBox(
                      height: size.height *0.8,
                      child: SfPdfViewer.network('${widget.selectedData.filePath}${widget.selectedData.filename}',onDocumentLoadFailed: (details) {},onDocumentLoaded: (details) {}),
                    ),
                ],
              ),
            );
  }
}