import 'dart:io';

void main() {
  final dir = Directory(r'd:\Umang\Tax_hrm_2.0\lib\page');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

  int count = 0;
  for (final file in files) {
    String content = file.readAsStringSync();
    String newContent = content.replaceAll(RegExp(r"import 'package:tax_hrm/widigets/noInternetView\.dart';\r?\n?"), '');
    
    if (newContent != content) {
      file.writeAsStringSync(newContent);
      count++;
    }
  }

  print('Cleaned unused imports in $count files.');
}
