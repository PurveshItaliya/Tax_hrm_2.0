// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:tax_hrm/api/addressapi.dart';
import 'package:tax_hrm/models/address/citylist_model.dart';
import 'package:tax_hrm/models/address/pincode_model.dart';
import 'package:tax_hrm/models/address/statelist_model.dart';

class AddresProviders extends ChangeNotifier {
  List<Statelistm> mainStateList = [];
  List<Citylistm> mainCityList = [];
  List<pincodem> mainPincodeList = [];

  List<Citylistm> filtersCityList = [];
  List<pincodem> filtersPincodeList = [];

  //--------------------  Stat  ---------------------\\
  Future getallStat() async {
    mainStateList = await AddresDataApi().statelist();
    await getallCitys();
    await getallPincodes();
    notifyListeners();
  }


  //--------------------   City  ---------------------\\
  Future getallCitys() async {
    mainCityList = await AddresDataApi().citylist();
    notifyListeners();
  }
  //---------------------------------------------\\

  //--------------------   Pincode  --------------------------\\
  Future getallPincodes() async {
    mainPincodeList = await AddresDataApi().PinCode();
    notifyListeners();
  }

  Future filtersCity(setstatid) async {
    filtersCityList.clear();

    for (var element in mainCityList) {
      if (element.stateID.toString() == setstatid.toString()) {
        filtersCityList.add(element);
        notifyListeners();
      }
    }
  }

  Future filterPincodes(setCityid) async {
    filtersPincodeList.clear();
    for (var element in mainPincodeList) {
      if (element.cityID == setCityid) {
        filtersPincodeList.add(element);
        notifyListeners();
      }
    }
  }
}
