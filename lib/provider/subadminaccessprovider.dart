// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';

class SubAdminMenuAccessProvider extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }
}
