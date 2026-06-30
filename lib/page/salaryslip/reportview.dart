// ignore_for_file: prefer_const_constructors_in_immutables, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ReportView extends StatefulWidget {
  final String url;

  ReportView({required this.url});

  @override
  _ReportViewState createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: ColorConst.white,
      appBar: showCustomeAppBar('View PaySlip', size,titleColors: ColorConst.appbarTextColor, iconsOntap: () {
        backScreen(context);
      },),
      body: SfPdfViewer.network(
        widget.url,
        onDocumentLoadFailed: (details) {
        },
      ),
    );
  }
}
