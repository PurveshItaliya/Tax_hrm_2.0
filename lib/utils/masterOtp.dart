// ignore_for_file: file_names, strict_top_level_inference

import 'package:intl/intl.dart';

genrateMasterOtp() {
  String setOtp;
  final currentDate = DateTime.now();
  final formattedDate = DateFormat('dd-MM-yy').format(currentDate);
  String removedash = formattedDate.replaceAll('-', '');
  List<String> charList = stringToList(removedash);
  List<String> reversedList = reverseList(charList);
  setOtp = reversedList.join().toString();
  return setOtp;
}

List<String> stringToList(String inputString) {
  return inputString.split('');
}

List<String> reverseList(List<String> inputList) {
  return inputList.reversed.toList();
}
