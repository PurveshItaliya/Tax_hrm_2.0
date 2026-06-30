// ignore_for_file: strict_top_level_inference, override_on_non_overriding_member, unnecessary_cast

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class InternetConnectionProvider with ChangeNotifier {
  // Variable to store the connectivity status

  getAllConnectionData() {
    getConnectivityType();
  }

  var connectionType = 1;
  final Connectivity connectivity = Connectivity();
  late StreamSubscription _streamSubscription;
  @override
  Future<void> getConnectivityType() async {
    late List<ConnectivityResult> connectivityResult;

    connectivityResult =
        (await (connectivity.checkConnectivity())) as List<ConnectivityResult>;
    _streamSubscription = connectivity.onConnectivityChanged.listen(
      (event) => _updateState,
    );
    notifyListeners();


    return _updateState(connectivityResult);
  }

  _updateState(List<ConnectivityResult> result) {
    switch (result) {
      case [ConnectivityResult.wifi]:
        connectionType = 1;
        break;
      case [ConnectivityResult.mobile]:
        connectionType = 2;
        break;
      case [ConnectivityResult.none]:
        connectionType = 0;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  @override
  void onClose() {
    _streamSubscription.cancel();
  }
}
