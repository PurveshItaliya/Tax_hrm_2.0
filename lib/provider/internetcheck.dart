// ignore_for_file: strict_top_level_inference, override_on_non_overriding_member, unnecessary_cast

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class InternetConnectionProvider with ChangeNotifier {
  var connectionType = 1;
  final Connectivity connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _streamSubscription;

  Future<void> getAllConnectionData() async {
    await getConnectivityType();
  }

  Future<void> getConnectivityType() async {
    try {
      List<ConnectivityResult> connectivityResult = await connectivity.checkConnectivity();
      _updateState(connectivityResult);

      _streamSubscription?.cancel();
      _streamSubscription = connectivity.onConnectivityChanged.listen((event) {
        _updateState(event);
      });
    } catch (e) {
      // ignore
    }
  }

  void _updateState(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.none) || result.isEmpty) {
      if (!result.any((element) => element != ConnectivityResult.none)) {
        connectionType = 0;
      } else {
        connectionType = 1;
      }
    } else if (result.contains(ConnectivityResult.wifi)) {
      connectionType = 1;
    } else if (result.contains(ConnectivityResult.mobile)) {
      connectionType = 2;
    } else {
      connectionType = 1;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
