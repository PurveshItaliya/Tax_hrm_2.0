import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/timelinesprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/appbars.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';

class EmployeTimelines extends StatefulWidget {
  final String userId;
  const EmployeTimelines({super.key, required this.userId});

  @override
  State<EmployeTimelines> createState() => _EmployeTimelinesState();
}

class _EmployeTimelinesState extends State<EmployeTimelines> {
  final MapController _mapController = MapController();
  LatLng? _lastCenteredPoint;

  @override
  void initState() {
    super.initState();
    Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
    Provider.of<TimeLineServices>(context, listen: false).timeViewLoadData(setEmpId: widget.userId);
  }

  void _centerMapOnPoints(List<LatLng> points) {
    if (points.isNotEmpty && points.first != _lastCenteredPoint) {
      _lastCenteredPoint = points.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(points.first, 14.0);
        } catch (e) { /* ignored */ }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(context);
    final datePickerProviders = Provider.of<CommandWidigetsProvider>(context);
    final timeLineServices = Provider.of<TimeLineServices>(context);

    // Prepare map markers and polyline points
    List<LatLng> pointsList = [];
    List<Marker> markersList = [];

    for (int i = 0; i < timeLineServices.showUserTimeLines.length; i++) {
      var item = timeLineServices.showUserTimeLines[i];
      if (item.latitude != null && item.logitude != null) {
        double? lat = double.tryParse(item.latitude!);
        double? lng = double.tryParse(item.logitude!);
        if (lat != null && lng != null) {
          LatLng point = LatLng(lat, lng);
          pointsList.add(point);
          markersList.add(
            Marker(
              point: point,
              width: 36.0,
              height: 36.0,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorConst.themeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Center(
                  child: Text(
                    "${i + 1}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: fontInterSemiBoldString,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    // Auto-center map when points change
    _centerMapOnPoints(pointsList);

    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              appBar: showCustomeAppBar(
                timeLineString,
                size,
                titleColors: ColorConst.appbarTextColor,
                iconsOntap: () {
                  backScreen(context);
                },
              ),
              body: Stack(
                children: [
                  // 1. Map View filling the background
                  Positioned.fill(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: pointsList.isNotEmpty
                            ? pointsList.first
                            : const LatLng(21.209371, 72.833692),
                        initialZoom: 14.0,
                        minZoom: 3.0,
                        maxZoom: 18.0,
                        cameraConstraint: CameraConstraint.contain(
                          bounds: LatLngBounds(
                            const LatLng(-90, -180),
                            const LatLng(90, 180),
                          ),
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.tax_hrm.app',
                        ),
                        if (pointsList.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: pointsList,
                                strokeWidth: 4.0,
                                color: ColorConst.themeColor,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: markersList,
                        ),
                      ],
                    ),
                  ),

                  // 2. Floating Header Card with Date Selection
                  Positioned(
                    top: 15,
                    left: 15,
                    right: 15,
                    child: Card(
                      color: ColorConst.white,
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Date Selection",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                      fontFamily: fontInterMediumString,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(timeLineServices.setDates),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: ColorConst.black,
                                      fontFamily: fontInterSemiBoldString,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: ColorConst.themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  datePickerProviders.pickDate(
                                    context,
                                    size,
                                    timeLineServices.setDates,
                                    null,
                                    DateTime.now(),
                                    (val) {
                                      timeLineServices.setDates = val;
                                      timeLineServices.timeViewLoadData(setEmpId: widget.userId);
                                    },
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.calendar_month,
                                    color: ColorConst.themeColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),



                  // 3. Draggable Scrollable Bottom Sheet containing the timeline list
                  DraggableScrollableSheet(
                    initialChildSize: 0.4,
                    minChildSize: 0.15,
                    maxChildSize: 0.85,
                    builder: (context, scrollController) {
                      int itemCount;
                      if (timeLineServices.islodering) {
                        itemCount = 1 + 20; // 1 header + 20 shimmers
                      } else if (timeLineServices.showUserTimeLines.isEmpty) {
                        itemCount = 1 + 1;  // 1 header + 1 empty state widget
                      } else {
                        itemCount = 1 + timeLineServices.showUserTimeLines.length; // 1 header + loaded logs
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: ColorConst.scaffoldColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: itemCount,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Drag pill handle
                                  const SizedBox(height: 10),
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[400],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // Header details
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Location Timeline",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: ColorConst.black,
                                            fontFamily: fontInterSemiBoldString,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          timeLineServices.islodering
                                              ? "Loading coordinates..."
                                              : "${timeLineServices.showUserTimeLines.length} coordinates logged",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            fontFamily: fontInterRegularString,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                ],
                              );
                            }

                            // Content items
                            if (timeLineServices.islodering) {
                              return Shimmer(
                                child: Container(
                                  width: size.width,
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    children: [
                                      Container(height: 18, width: 70, color: Colors.grey.shade400),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 2,
                                              height: size.height * 0.03,
                                              color: ColorConst.grey,
                                            ),
                                            Container(
                                              width: size.width * 0.06,
                                              height: size.width * 0.06,
                                              decoration: const BoxDecoration(
                                                color: ColorConst.grey,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.check, size: 16, color: ColorConst.white),
                                            ),
                                            Container(
                                              width: 2,
                                              height: size.height * 0.055,
                                              color: ColorConst.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.all(size.width * 0.03),
                                          height: size.height * 0.09,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade400,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (timeLineServices.showUserTimeLines.isEmpty) {
                              return Padding(
                                padding: EdgeInsets.only(top: size.height * 0.05),
                                child: Center(
                                  child: noDataFoundsDesign(
                                    size,
                                    noTimeLineAddedString,
                                    nodataFoundsImagString,
                                  ),
                                ),
                              );
                            } else {
                              var item = timeLineServices.showUserTimeLines[index - 1];
                              DateTime dateTime = DateTime.parse(item.entryTime ?? '');
                              String formattedTime = DateFormat('hh:mm a').format(dateTime);

                              bool isLast = (index - 1) == timeLineServices.showUserTimeLines.length - 1;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Connected Timeline Indicator
                                      SizedBox(
                                        width: 12,
                                        child: Column(
                                          children: [
                                            // Top line segment (above the dot)
                                            if (index - 1 == 0)
                                              const SizedBox(height: 18)
                                            else
                                              Container(
                                                width: 2,
                                                height: 18,
                                                color: ColorConst.themeColor.withOpacity(0.4),
                                              ),

                                            // Dot
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: const BoxDecoration(
                                                color: ColorConst.themeColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),

                                            // Bottom line segment (below the dot)
                                            if (!isLast)
                                              Expanded(
                                                child: Container(
                                                  width: 2,
                                                  color: ColorConst.themeColor.withOpacity(0.4),
                                                ),
                                              )
                                            else
                                              const Expanded(child: SizedBox()),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 15),

                                      // Log Card Item
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            double? lat = double.tryParse(item.latitude ?? '');
                                            double? lng = double.tryParse(item.logitude ?? '');
                                            if (lat != null && lng != null) {
                                              _mapController.move(LatLng(lat, lng), 16.0);
                                            }
                                          },
                                          child: Card(
                                            color: ColorConst.white,
                                            elevation: 1,
                                            shadowColor: Colors.black12,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                            margin: const EdgeInsets.only(bottom: 15),
                                            child: Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        formattedTime,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: ColorConst.black,
                                                          fontFamily: fontInterSemiBoldString,
                                                        ),
                                                      ),
                                                      if (item.deviceName != null && item.deviceName!.isNotEmpty)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[200],
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(
                                                                item.deviceType.toString().toLowerCase().contains("android")
                                                                    ? Icons.android
                                                                    : Icons.phone_iphone,
                                                                size: 12,
                                                                color: Colors.grey[700],
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                item.deviceName.toString(),
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.grey[700],
                                                                  fontFamily: fontInterMediumString,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    item.address.toString(),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                      fontFamily: fontInterRegularString,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Row(
                                                  //   children: [
                                                  //     const Icon(
                                                  //       Icons.location_on,
                                                  //       size: 14,
                                                  //       color: ColorConst.themeColor,
                                                  //     ),
                                                  //     const SizedBox(width: 4),
                                                  //     Text(
                                                  //       "Lat: ${item.latitude}, Lng: ${item.logitude}",
                                                  //       style: const TextStyle(
                                                  //         fontSize: 12,
                                                  //         fontWeight: FontWeight.w600,
                                                  //         color: ColorConst.themeColor,
                                                  //         fontFamily: fontInterSemiBoldString,
                                                  //       ),
                                                  //     ),
                                                  //   ],
                                                  // ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
  }
}
