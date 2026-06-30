// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tax_hrm/page/splashPage.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/commanWidget.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class NoInternetViewPage extends StatefulWidget {
  const NoInternetViewPage({super.key});

  @override
  State<NoInternetViewPage> createState() => _NoInternetViewPageState();
}

class _NoInternetViewPageState extends State<NoInternetViewPage> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        color: ColorConst.white,
        height: size.height,
        width: size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: size.height * 0.45,
              child: SvgPicture.asset(noInterNetString),
            ),
            Text(
              ooopsString,
              style: TextStyle(
                fontSize: size.height * 0.055,
                fontFamily: fontInterMediumString,
                color: ColorConst.grey,
              ),
            ),
            heightSpacer(size.height * 0.02),
            Text(
              internetDecString.toUpperCase(),
              style: TextStyle(
                fontSize: size.height * 0.018,
                fontFamily: fontInterRegularString,
              ),
              textAlign: TextAlign.center,
            ),
            heightSpacer(size.height * 0.02),
            btnDesign(
              size,
              titles: tryAgainString,
              width: size.width * 0.50,
              onTap: () {
                nextscreenReplace(context,ShowSpleshPage(),onthenValue: (val) {},);
              },
              isgradient: true
            ),
          ],
        ),
      ),
    );
  }
}
