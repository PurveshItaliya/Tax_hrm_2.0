// ignore_for_file: file_names, must_be_immutable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/splashprovider.dart';
import 'package:tax_hrm/provider/userloginprovider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/imagesfile.dart';
import 'package:tax_hrm/widigets/noInternetView.dart';
import 'package:video_player/video_player.dart';

class ShowSpleshPage extends StatefulWidget {
  const ShowSpleshPage({super.key,});

  @override
  State<ShowSpleshPage> createState() => _ShowSpleshPageState();
}

class _ShowSpleshPageState extends State<ShowSpleshPage> {
  VideoPlayerController? _controller;
  bool _navigated = false;

  void _triggerNavigation() {
    if (!_navigated && mounted) {
      _navigated = true;
      _controller?.pause();
      Provider.of<SplashProvider>(context, listen: false).onVideoFinished(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(splashVideoString)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller?.setLooping(false);
          _controller?.play();
          _controller?.addListener(() {
            if (_controller != null && _controller!.value.isInitialized) {
              final pos = _controller!.value.position;
              final dur = _controller!.value.duration;
              final isPlaying = _controller!.value.isPlaying;
              if (dur > Duration.zero &&
                  (pos >= dur || (!isPlaying && pos >= dur - const Duration(milliseconds: 600)))) {
                _triggerNavigation();
              }
            }
          });
        }
      }).catchError((_) {
        _triggerNavigation();
      });

    Future.delayed(const Duration(seconds: 6), () {
      _triggerNavigation();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InternetConnectionProvider>(context, listen: false).getAllConnectionData();
      Provider.of<Userloginprovider>(context, listen: false).clearData();
      final splashProvider = Provider.of<SplashProvider>(context, listen: false);
      splashProvider.isVideoFinished = false;
      splashProvider.pendingNavigationPage = null;
      splashProvider.loadingData(context);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    safeAreaBgAndTextColor(context, safeAreaBgColor: ColorConst.white);
    final checkInterNetConnection = Provider.of<InternetConnectionProvider>(
      context,
    );
    return checkInterNetConnection.connectionType == 0
        ? const NoInternetViewPage()
        : Scaffold(
            backgroundColor: Color(0xfff2f2f2),
            body: Container(
              color: Color(0xfff2f2f2),
              height: size.height,
              width: size.width,
              child: _controller != null && _controller!.value.isInitialized
                  ? Container(
                      color: Color(0xfff2f2f2),
                      child: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller!.value.size.width,
                            height: _controller!.value.size.height,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                      ),
                    )
                  : Container(color: ColorConst.white),
            ),
          );
  }
}
