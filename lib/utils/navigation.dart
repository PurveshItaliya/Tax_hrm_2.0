// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';

nextScreen(BuildContext context, Widget page, {onthenValue}) async {
  await Navigator.of(context,).push(MaterialPageRoute(builder: (_) => page)).then(onthenValue ?? (value) {});
}

backScreen(context) {
  Navigator.pop(context);
}

nextscreenReplace(BuildContext context, Widget page, {onthenValue}) async {
  await Navigator.of(context,).pushReplacement(MaterialPageRoute(builder: (_) => page)).then(onthenValue ?? (value) {});
}

nextscreenRemove(BuildContext context, Widget page, {onthenValue}) async {
  await Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (_) => page),(route) => false,).then(onthenValue ?? (value) {});
}
