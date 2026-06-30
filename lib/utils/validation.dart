import 'package:tax_hrm/utils/titlesfile.dart';

String? allValidation(String value) {
  if (value.isEmpty) {
    return filedrequiredString;
  } else {
    return null;
  }
}

String? allValidEmail(String value) {
  var regex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@gmail\.com$'
  );
  if (value.isNotEmpty) {
    if (!regex.hasMatch(value)) {
      return validEmailAddString;
    } else {
      return null;
    }
  } else {
    return null;
  }
}

String? allValidMobile(String value) {
  var regex = RegExp(r'^[6-9]\d{9}$');
  if (value.isNotEmpty) {
    if (!regex.hasMatch(value)) {
      return validMobileAddString;
    } else {
      return null;
    }
  } else {
    return null;
  }
}

