import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:tax_hrm/provider/commanDataseta.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/timelinesprovider.dart';
import 'package:tax_hrm/services/location_batch_service.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';

import 'package:tax_hrm/page/usertimelineview/smart_timeline_screen.dart';
import '../../widigets/toastmessage.dart';

class EmployeTimelines extends StatefulWidget {
  final String userId;
  const EmployeTimelines({super.key, required this.userId});

  @override
  State<EmployeTimelines> createState() => _EmployeTimelinesState();
}

class _EmployeTimelinesState extends State<EmployeTimelines> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  LatLng? _lastCenteredPoint;
  int? _selectedIndex;
  StreamSubscription? _timelineUpdateSub;
  bool _isSheetOpen = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('MapActive', true));
    Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
    Provider.of<TimeLineServices>(context, listen: false).timeViewLoadData(setEmpId: widget.userId);
    
    _timelineUpdateSub = FlutterBackgroundService().on('update_timeline').listen((event) {
      if (mounted) {
        Provider.of<TimeLineServices>(context, listen: false).timeViewLoadData(setEmpId: widget.userId);
      }
    });

    _sheetController.addListener(() {
      if (mounted && _sheetController.isAttached) {
        bool isOpenNow = _sheetController.size > 0.05;
        if (isOpenNow != _isSheetOpen) {
          setState(() {
            _isSheetOpen = isOpenNow;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('MapActive', false));
    _timelineUpdateSub?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  void _toggleBottomSheet() {
    if (_isSheetOpen) {
      _collapseBottomSheet();
    } else {
      setState(() {
        _isSheetOpen = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sheetController.isAttached) {
          _sheetController.animateTo(
            0.60,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _collapseBottomSheet() {
    if (_isSheetOpen) {
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      } else {
        setState(() {
          _isSheetOpen = false;
        });
      }
    }
  }

  String _formatDurationBetween(String? timeStr1, String? timeStr2) {
    if (timeStr1 == null || timeStr2 == null) return '';
    try {
      DateTime t1 = DateTime.parse(timeStr1);
      DateTime t2 = DateTime.parse(timeStr2);
      Duration diff = t2.difference(t1).abs();
      if (diff.inMinutes < 1) {
        return '${diff.inSeconds}s';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}m';
      } else {
        int mins = diff.inMinutes % 60;
        return mins > 0 ? '${diff.inHours}h ${mins}m' : '${diff.inHours}h';
      }
    } catch (_) {
      return '';
    }
  }

  void _centerMapOnPoints(List<LatLng> points) {
    if (points.isNotEmpty && points.last != _lastCenteredPoint) {
      _lastCenteredPoint = points.last;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = points.length - 1;
          });
          try {
            _mapController.move(points.last, 16.0);
          } catch (e) { /* ignored */ }
        }
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
    List<dynamic> validTimelineItems = [];

    for (int i = 0; i < timeLineServices.showUserTimeLines.length; i++) {
      var item = timeLineServices.showUserTimeLines[i];
      if (item.latitude != null && item.logitude != null) {
        double? lat = double.tryParse(item.latitude!);
        double? lng = double.tryParse(item.logitude!);
        if (lat != null && lng != null) {
          bool isMarkerSelected = _selectedIndex == i;
          LatLng point = LatLng(lat, lng);
          pointsList.add(point);
          validTimelineItems.add(item);

          markersList.add(
            Marker(
              point: point,
              width: isMarkerSelected ? 26.0 : 18.0,
              height: isMarkerSelected ? 26.0 : 18.0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedIndex == i) {
                      _selectedIndex = null;
                    } else {
                      _selectedIndex = i;
                      _mapController.move(point, 16.0);
                    }
                  });
                  _collapseBottomSheet();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isMarkerSelected ? Colors.orange : ColorConst.themeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: isMarkerSelected ? 2.5 : 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: isMarkerSelected ? Colors.black45 : Colors.black26,
                        blurRadius: isMarkerSelected ? 4 : 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "${i + 1}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMarkerSelected ? 11 : 9,
                        fontFamily: fontInterSemiBoldString,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    // Generate midpoint duration markers between consecutive points
    for (int k = 0; k < pointsList.length - 1; k++) {
      LatLng p1 = pointsList[k];
      LatLng p2 = pointsList[k + 1];
      LatLng midPoint = LatLng((p1.latitude + p2.latitude) / 2, (p1.longitude + p2.longitude) / 2);

      String durationText = _formatDurationBetween(
        validTimelineItems[k].entryTime,
        validTimelineItems[k + 1].entryTime,
      );

      if (durationText.isNotEmpty) {
        markersList.add(
          Marker(
            point: midPoint,
            width: 70.0,
            height: 25.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white70, width: 0.8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 9, color: Colors.amberAccent),
                  const SizedBox(width: 2),
                  Text(
                    durationText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: fontInterSemiBoldString,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    // Auto-center map when points change
    _centerMapOnPoints(pointsList);

    return Scaffold(
              backgroundColor: ColorConst.scaffoldColor,
              extendBodyBehindAppBar: true,
              body: Stack(
                children: [
                  // 1. Fullscreen Map View
                  Positioned.fill(
                    child: FlutterMap(
                      mapController: _mapController,
                            options: MapOptions(
                              onTap: (tapPosition, point) {
                                setState(() {
                                  _selectedIndex = null;
                                });
                                _collapseBottomSheet();
                              },
                              initialCenter: pointsList.isNotEmpty
                                  ? pointsList.last
                                  : const LatLng(21.209371, 72.833692),
                              initialZoom: 14.0,
                              minZoom: 3.0,
                              maxZoom: 22.0,
                              cameraConstraint: CameraConstraint.contain(
                                bounds: LatLngBounds(
                                  const LatLng(-90, -180),
                                  const LatLng(90, 180),
                                ),
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                                fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.hrmnewapp.taxhrm',
                                maxNativeZoom: 20,
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

                        // 2. Glassmorphic Blurred Header Overlay with Vertical Black Gradient
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                              child: Container(
                                padding: EdgeInsets.only(
                                  top: MediaQuery.of(context).padding.top + 6,
                                  left: 10,
                                  right: 10,
                                  bottom: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.85),
                                      Colors.black.withOpacity(0.50),
                                      Colors.black.withOpacity(0.15),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.4, 0.8, 1.0],
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Back Icon Button
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => backScreen(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.25),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Title & Selected Date Subtitle
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            timeLineString,
                                            style: TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontFamily: fontInterSemiBoldString,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black45,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            DateFormat('dd MMMM yyyy').format(timeLineServices.setDates),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white.withOpacity(0.85),
                                              fontFamily: fontInterMediumString,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Calendar Date Picker Action Icon Button
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
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
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.20),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: Colors.white.withOpacity(0.35), width: 0.8),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.calendar_month_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              DateFormat('dd MMM').format(timeLineServices.setDates),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontFamily: fontInterSemiBoldString,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // 🧠 Smart View Button — navigates to processed movement timeline
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SmartTimelineScreen(userId: widget.userId),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED).withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF7C3AED).withOpacity(0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                                            SizedBox(width: 5),
                                            Text('Smart',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              )),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // Sync/Create Timeline Action Button (Testing)
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () async {
                                        showtoastmessage('Syncing pending locations to timeline...');
                                        final String userDataStr = await SaveUser().getUserDatas();
                                        if (userDataStr.isNotEmpty) {
                                          final dynamic userData = jsonDecode(userDataStr);
                                          
                                          // Force capture a location point so the API always fires
                                          try {
                                            Position pos = await Geolocator.getCurrentPosition(
                                              desiredAccuracy: LocationAccuracy.high,
                                              timeLimit: const Duration(seconds: 5),
                                            );
                                            await LocationBatchStorage.appendLocation(
                                              latitude: pos.latitude,
                                              longitude: pos.longitude,
                                              entryTime: DateTime.now(),
                                            );
                                          } catch (_) {}
                                          
                                          await LocationBatchStorage.uploadPendingBatch(userData: userData, isMapScreen: true, isAppForeground: true);
                                          if (context.mounted) {
                                            Provider.of<TimeLineServices>(context, listen: false).timeViewLoadData(setEmpId: widget.userId);
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.cloud_upload_rounded,
                                          color: Colors.white,
                                          size: 19,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // Refresh Action Button
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        Provider.of<TimeLineServices>(context, listen: false).timeViewLoadData(setEmpId: widget.userId);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.25),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.refresh_rounded,
                                          color: Colors.white,
                                          size: 19,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 3. Premium Redesigned Draggable Bottom Sheet
                        if (_isSheetOpen)
                          DraggableScrollableSheet(
                            controller: _sheetController,
                            initialChildSize: 0.60,
                            minChildSize: 0.0,
                            maxChildSize: 0.60,
                            snap: true,
                            snapSizes: const [0.0, 0.60],
                            builder: (context, scrollController) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: ColorConst.white,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 18,
                                      offset: const Offset(0, -6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Drag Handle
                                    GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: _collapseBottomSheet,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        width: double.infinity,
                                        child: Center(
                                          child: Container(
                                            width: 44,
                                            height: 4.5,
                                            decoration: BoxDecoration(
                                              color: ColorConst.grey.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Header Bar with Close Button
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: ColorConst.themeColor.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.route_rounded,
                                              color: ColorConst.themeColor,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            locationTimelineString,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: ColorConst.black,
                                              fontFamily: fontInterSemiBoldString,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: ColorConst.themeColor.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              timeLineServices.islodering
                                                  ? loadingCoordinatesString
                                                  : "${timeLineServices.showUserTimeLines.length} Logs",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: ColorConst.themeColor,
                                                fontFamily: fontInterMediumString,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(20),
                                            onTap: _collapseBottomSheet,
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: ColorConst.greyOpicityColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const Divider(height: 14, thickness: 0.8),

                                    // Timeline List
                                    Expanded(
                                      child: refreshIndicatorDesign(
                                        onRefreshOntap: () async {
                                          await Provider.of<TimeLineServices>(context, listen: false).timeViewLoadData(setEmpId: widget.userId);
                                        },
                                        widgetDesign: ListView.builder(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          controller: scrollController,
                                          itemCount: timeLineServices.islodering
                                              ? 10
                                              : (timeLineServices.showUserTimeLines.isEmpty
                                                  ? 1
                                                  : timeLineServices.showUserTimeLines.length),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                          itemBuilder: (context, index) {
                                            if (timeLineServices.islodering) {
                                              return Shimmer(
                                                child: Container(
                                                  width: size.width,
                                                  margin: const EdgeInsets.only(bottom: 10),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                  child: Row(
                                                    children: [
                                                      Container(height: 16, width: 60, color: ColorConst.greyOpicityColor),
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                                                        child: Column(
                                                          children: [
                                                            Container(width: 2, height: size.height * 0.02, color: ColorConst.grey),
                                                            Container(
                                                              width: size.width * 0.05,
                                                              height: size.width * 0.05,
                                                              decoration: BoxDecoration(color: ColorConst.grey, shape: BoxShape.circle),
                                                              child: Icon(Icons.check, size: 14, color: ColorConst.white),
                                                            ),
                                                            Container(width: 2, height: size.height * 0.04, color: ColorConst.grey),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Container(
                                                          padding: EdgeInsets.all(size.width * 0.02),
                                                          height: size.height * 0.07,
                                                          decoration: BoxDecoration(color: ColorConst.greyOpicityColor, borderRadius: BorderRadius.circular(8)),
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
                                              var item = timeLineServices.showUserTimeLines[index];
                                              DateTime dateTime = DateTime.parse(item.entryTime ?? '');
                                              String formattedTime = DateFormat('hh:mm a').format(dateTime);

                                              bool isLast = index == timeLineServices.showUserTimeLines.length - 1;
                                              bool isSelected = _selectedIndex == index;

                                              return IntrinsicHeight(
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    // Left Timeline Node Connector
                                                    SizedBox(
                                                      width: 26,
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            width: 24,
                                                            height: 24,
                                                            decoration: BoxDecoration(
                                                              color: isSelected ? Colors.orange : ColorConst.themeColor,
                                                              shape: BoxShape.circle,
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: isSelected ? Colors.orange.withOpacity(0.4) : ColorConst.themeColor.withOpacity(0.3),
                                                                  blurRadius: 4,
                                                                  offset: const Offset(0, 2),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                "${index + 1}",
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontFamily: fontInterSemiBoldString,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          if (!isLast)
                                                            Expanded(
                                                              child: Container(
                                                                width: 2,
                                                                color: isSelected ? Colors.orange.withOpacity(0.5) : ColorConst.themeColor.withOpacity(0.25),
                                                              ),
                                                            )
                                                          else
                                                            const Expanded(child: SizedBox()),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),

                                                    // Right Log Card
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            if (_selectedIndex == index) {
                                                              _selectedIndex = null;
                                                            } else {
                                                              _selectedIndex = index;
                                                              double? lat = double.tryParse(item.latitude ?? '');
                                                              double? lng = double.tryParse(item.logitude ?? '');
                                                              if (lat != null && lng != null) {
                                                                _mapController.move(LatLng(lat, lng), 16.0);
                                                              }
                                                            }
                                                          });
                                                          _collapseBottomSheet();
                                                        },
                                                        child: AnimatedContainer(
                                                          duration: const Duration(milliseconds: 200),
                                                          margin: const EdgeInsets.only(bottom: 10),
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: BoxDecoration(
                                                            color: isSelected ? ColorConst.themeColor.withOpacity(0.06) : ColorConst.white,
                                                            borderRadius: BorderRadius.circular(14),
                                                            border: Border.all(
                                                              color: isSelected ? ColorConst.themeColor : Colors.grey.shade200,
                                                              width: isSelected ? 1.5 : 1,
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: isSelected ? ColorConst.themeColor.withOpacity(0.1) : Colors.black.withOpacity(0.04),
                                                                blurRadius: isSelected ? 8 : 4,
                                                                offset: const Offset(0, 2),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              // Top Row: Time & Device
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons.access_time_filled_rounded,
                                                                        size: 14,
                                                                        color: isSelected ? ColorConst.themeColor : ColorConst.black,
                                                                      ),
                                                                      const SizedBox(width: 5),
                                                                      Text(
                                                                        formattedTime,
                                                                        style: TextStyle(
                                                                          fontSize: 13,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: ColorConst.black,
                                                                          fontFamily: fontInterSemiBoldString,
                                                                        ),
                                                                      ),
                                                                      if (index > 0) ...[
                                                                        Builder(
                                                                          builder: (context) {
                                                                            var prevItem = timeLineServices.showUserTimeLines[index - 1];
                                                                            String gapStr = _formatDurationBetween(prevItem.entryTime, item.entryTime);
                                                                            if (gapStr.isEmpty) return const SizedBox();
                                                                            return Padding(
                                                                              padding: const EdgeInsets.only(left: 6),
                                                                              child: Container(
                                                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                                                decoration: BoxDecoration(
                                                                                  color: Colors.orange.withOpacity(0.12),
                                                                                  borderRadius: BorderRadius.circular(6),
                                                                                  border: Border.all(color: Colors.orange.withOpacity(0.3), width: 0.8),
                                                                                ),
                                                                                child: Row(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  children: [
                                                                                    const Icon(Icons.schedule, size: 9, color: Colors.orange),
                                                                                    const SizedBox(width: 2),
                                                                                    Text(
                                                                                      "+$gapStr",
                                                                                      style: const TextStyle(
                                                                                        fontSize: 9.5,
                                                                                        fontWeight: FontWeight.bold,
                                                                                        color: Colors.orange,
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ],
                                                                  ),
                                                                  if (item.deviceName != null && item.deviceName!.isNotEmpty)
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                                      decoration: BoxDecoration(
                                                                        color: ColorConst.greyOpicityColor,
                                                                        borderRadius: BorderRadius.circular(6),
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          Icon(
                                                                            item.deviceType.toString().toLowerCase().contains("android")
                                                                                ? Icons.android
                                                                                : Icons.phone_iphone,
                                                                            size: 11,
                                                                            color: ColorConst.textgrey,
                                                                          ),
                                                                          const SizedBox(width: 4),
                                                                          Text(
                                                                            item.deviceName.toString(),
                                                                            style: TextStyle(
                                                                              fontSize: 10,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: ColorConst.textgrey,
                                                                              fontFamily: fontInterMediumString,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                              const SizedBox(height: 6),

                                                              // Bottom Row: Location Icon & Address
                                                              Row(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(top: 1),
                                                                    child: Icon(
                                                                      Icons.location_on_rounded,
                                                                      size: 14,
                                                                      color: isSelected ? Colors.orange : ColorConst.themeColor,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 5),
                                                                  Expanded(
                                                                    child: Text(
                                                                      item.address.toString(),
                                                                      style: TextStyle(
                                                                        fontSize: 11.5,
                                                                        height: 1.3,
                                                                        color: ColorConst.textgrey,
                                                                        fontFamily: fontInterRegularString,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        // 4. Floating Expand Pill Button on Map Stack (Shown ONLY when bottom sheet is closed)
                        if (!_isSheetOpen)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: _toggleBottomSheet,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: ColorConst.themeColor,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ColorConst.themeColor.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.route_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Timeline Logs (${timeLineServices.showUserTimeLines.length})",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: fontInterSemiBoldString,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.keyboard_arrow_up_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
  }
}