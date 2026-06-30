import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/timelinesprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';

class LocationTimeLines extends StatefulWidget {
  const LocationTimeLines({super.key});

  @override
  State<LocationTimeLines> createState() => _LocationTimeLinesState();
}

class _LocationTimeLinesState extends State<LocationTimeLines> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TimeLineServices>(context, listen: false).getCurrentLocation(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeLineServices = Provider.of<TimeLineServices>(context);
    Size size = MediaQuery.of(context).size;
    return AlertDialog(
      backgroundColor: ColorConst.white,
      content: Container(
        height: size.width * 0.55,
        color: ColorConst.white,
        width: size.width,
        child: timeLineServices.showLocationLoader == true
            ? Center(child: CircularProgressIndicator(color: ColorConst.themeColor),)
            : Column(
                children: [
                  Text(
                    addtoLocationTimeLineString,
                    style: TextStyle(
                      color: ColorConst.black,
                      fontSize: size.height * 0.02,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(),
                  SizedBox(
                    width: size.width,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          userTimelineImgString,
                          color: ColorConst.themeColor,
                          height: size.height * 0.05,
                        ),

                        SizedBox(
                          width: size.width * 0.52,
                          child: Text(
                            timeLineServices.currentLocation == ''
                                ? ''
                                : timeLineServices.currentLocation.toString(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),

                  btnDesign(size,titles: doneString,isgradient: true,borderRadiused: 15.0,onTap: () {timeLineServices.callAddTimeLines(context);})
                ],
              ),
      ),
    );
  }
}
