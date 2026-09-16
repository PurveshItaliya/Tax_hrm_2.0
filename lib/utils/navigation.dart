// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:tax_hrm/widigets/offline_banner_widget.dart';

nextScreen(BuildContext context, Widget page, {onthenValue}) async {
  await Navigator.of(context)
      .push(MaterialPageRoute(
        builder: (_) => OfflineBannerWrapper(child: page),
        settings: RouteSettings(name: page.runtimeType.toString()),
      ))
      .then(onthenValue ?? (value) {});
}

backScreen(context) {
  Navigator.pop(context);
}

nextscreenReplace(BuildContext context, Widget page, {onthenValue}) async {
  await Navigator.of(context)
      .pushReplacement(MaterialPageRoute(
        builder: (_) => OfflineBannerWrapper(child: page),
        settings: RouteSettings(name: page.runtimeType.toString()),
      ))
      .then(onthenValue ?? (value) {});
}

nextscreenRemove(BuildContext context, Widget page, {onthenValue}) async {
  await Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => OfflineBannerWrapper(child: page),
      settings: RouteSettings(name: page.runtimeType.toString()),
    ),
    (route) => false,
  ).then(onthenValue ?? (value) {});
}

