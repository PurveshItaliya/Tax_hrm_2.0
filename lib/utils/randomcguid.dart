// ignore_for_file: depend_on_referenced_packages

import 'dart:math';
import 'package:uuid/uuid.dart';

String generateGuid() {
    var uuid = const Uuid();
    var first = uuid.v4();
    var second = uuid.v4();
    var third = uuid.v4();

    // Extracting the required parts
    var part1 = first.substring(0, 8);
    var part2 = second.substring(0, 8);
    var part3 = third.substring(0, 8);

    return '$part1-$part2-$part3';
  }



//----------------------  AutoTask Refrence -----------------\\

String autoRefrenceNumber() {
 var rndnumber="";
  var rnd=  Random();
  for (var i = 0; i < 6; i++) {
  rndnumber = rndnumber + rnd.nextInt(9).toString();
  }

    // Extracting the required parts
    var part1 = 'AT';


    return '$part1$rndnumber';
  }



