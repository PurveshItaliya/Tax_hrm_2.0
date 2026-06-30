// ignore_for_file: file_names, must_be_immutable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/splashprovider.dart';
import 'package:tax_hrm/provider/userloginprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:tax_hrm/widigets/spacer.dart';
import 'package:lottie/lottie.dart';

class ShowSpleshPage extends StatefulWidget {
  const ShowSpleshPage({super.key,});

  @override
  State<ShowSpleshPage> createState() => _ShowSpleshPageState();
}

class _ShowSpleshPageState extends State<ShowSpleshPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InternetConnectionProvider>(context,listen: false,).getAllConnectionData();
      Provider.of<SplashProvider>(context,listen: false,).loadingData(context);
      Provider.of<Userloginprovider>(context,listen: false,).clearData();
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(
      context,
    );
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            body: Container(
              color: ColorConst.white,
              height: size.height,
              width: size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  heightSpacer(size.height * 0.1),
                  Center(
                    child: SvgPicture.asset(
                      appLogoString,
                      height: size.height * 0.25,
                      fit: BoxFit.fill,
                    ),
                  ),
                  heightSpacer(size.height * 0.3),
                  SizedBox(
                    height: size.height * 0.1,
                    child: Lottie.asset(loadingString),
                  ),
                ],
              ),
            ),
          );
  }
}
