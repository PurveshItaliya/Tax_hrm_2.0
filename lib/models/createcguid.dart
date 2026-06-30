// ignore_for_file: depend_on_referenced_packages

import 'package:uuid/uuid.dart';

String generateCustomUuid() {
  // Create a Uuid object
  var uuid = const Uuid();

  // Generate a random UUID
  var randomUuid = uuid.v4();

  // Extract segments from the generated UUID
  var segments = randomUuid.split('-');

  // Customize the format and length
  var customUuid = '${segments[0][0]}${segments[0][1]}'
      '${segments[1][0]}${segments[1][1]}'
      '${segments[2][0]}${segments[2][1]}'
      '${segments[3][0]}${segments[3][1]}'
      '${segments[4][0]}${segments[4][1]}'
      '${segments[4].substring(2)}';

  // Ensure the length is between 15 and 20 characters
  if (customUuid.length < 15) {
    customUuid += segments[0].substring(2, 15 - customUuid.length + 2);
  } else if (customUuid.length > 20) {
    customUuid = customUuid.substring(0, 20);
  }

  return customUuid;
}
