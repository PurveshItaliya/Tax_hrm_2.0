// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/company/timelines.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
// import 'package:tax_hrm/provider/timelinesprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';

class GoogleMapViews extends StatefulWidget {
  List<LocationTimelInes> userTimeLine;
  GoogleMapViews(this.userTimeLine,{super.key});

  @override
  State<GoogleMapViews> createState() => _GoogleMapViewsState();
}

class _GoogleMapViewsState extends State<GoogleMapViews> {
  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
    // Provider.of<TimeLineServices>(context, listen: false).callSetData(widget.userTimeLine);
  }



  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    safeAreaBgAndTextColor(context);
    // final timeLineServices = Provider.of<TimeLineServices>(context);
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              appBar: showCustomeAppBar(googleMapString, size, titleColors: ColorConst.appbarTextColor, iconsOntap: () {backScreen(context);},),
              // body: GoogleMap(
              //   polylines:  {
              //     Polyline(polylineId: PolylineId('value'),
              //     points: timeLineServices.polylineCoordinates,
              //     color: ColorConst.black
              //     )
              //   },
              //   markers: timeLineServices.myMarker,
              //   mapType: MapType.normal,
              //   onMapCreated: (controller) {
              //     timeLineServices.controller.complete(controller);
              //   },
              //   initialCameraPosition: timeLineServices.cameraPosition
              // ),
            );
  }
}
