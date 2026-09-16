import 'dart:io';

void main() {
  final dir = Directory(r'd:\Umang\Tax_hrm_2.0\lib\page');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

  int count = 0;
  final patterns = [
    RegExp(r'child:\s*internetProvider\.connectionType\s*==\s*0\s*\?\s*const\s*NoInternetViewPage\(\)\s*:\s*'),
    RegExp(r'child:\s*checkInterNetConnection\.connectionType\s*==\s*0\s*\?\s*const\s*NoInternetViewPage\(\)\s*:\s*'),
    RegExp(r'return\s+checkInterNetConnection\.connectionType\s*==\s*0\s*\?\s*const\s*NoInternetViewPage\(\)\s*:\s*'),
    RegExp(r'return\s+internetProvider\.connectionType\s*==\s*0\s*\?\s*const\s*NoInternetViewPage\(\)\s*:\s*'),
    RegExp(r'checkInterNetConnection\.connectionType\s*==\s*0\s*\?\s*const\s*NoInternetViewPage\(\)\s*:\s*'),
    RegExp(r'internetProvider\.connectionType\s*==\s*0\s*\?\s*const\s*NoInternetViewPage\(\)\s*:\s*')
  ];

  for (final file in files) {
    String content = file.readAsStringSync();
    String newContent = content;

    for (int i = 0; i < patterns.length; i++) {
      if (i < 2) { // child patterns
        newContent = newContent.replaceAll(patterns[i], 'child: ');
      } else if (i < 4) { // return patterns
        newContent = newContent.replaceAll(patterns[i], 'return ');
      } else {
        newContent = newContent.replaceAll(patterns[i], '');
      }
    }

    if (newContent != content) {
      file.writeAsStringSync(newContent);
      count++;
    }
  }

  print('Modified $count files.');
}
