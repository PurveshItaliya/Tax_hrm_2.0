// ignore_for_file: unused_local_variable, curly_braces_in_flow_control_structures

import 'dart:io';

void main() {
  final dir = Directory(r'd:\Umang\Tax_Hrm_New-.git\lib');
  int count = 0;
  
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      
      final regex = RegExp(r'SafeArea\s*\(');
      int searchOffset = 0;
      bool changed = false;
      
      while (true) {
        final match = regex.firstMatch(content.substring(searchOffset));
        if (match == null) break;
        
        int absoluteMatchStart = searchOffset + match.start;
        int safeAreaOpen = searchOffset + match.end - 1; // index of '('
        
        // Find closing parenthesis of SafeArea
        int openCount = 1;
        int safeAreaClose = -1;
        for (int i = safeAreaOpen + 1; i < content.length; i++) {
          if (content[i] == '(') openCount++;
          else if (content[i] == ')') {
            openCount--;
            if (openCount == 0) {
              safeAreaClose = i;
              break;
            }
          }
        }
        
        if (safeAreaClose != -1) {
          // Extract the content inside SafeArea(...)
          String insideSafeArea = content.substring(safeAreaOpen + 1, safeAreaClose);
          
          // Does it contain child: Scaffold( ?
          final childScaffoldRegex = RegExp(r'child:\s*(Scaffold\s*\()');
          final scaffoldMatch = childScaffoldRegex.firstMatch(insideSafeArea);
          
          if (scaffoldMatch != null) {
            // Remove 'child:' and everything before it that belongs to SafeArea
            String scaffoldContent = insideSafeArea.substring(scaffoldMatch.start).replaceFirst(RegExp(r'child:\s*'), '');
            scaffoldContent = scaffoldContent.trim();
            if (scaffoldContent.endsWith(',')) {
              scaffoldContent = scaffoldContent.substring(0, scaffoldContent.length - 1);
            }
            
            String before = content.substring(0, absoluteMatchStart);
            String after = content.substring(safeAreaClose + 1);
            
            content = before + scaffoldContent + after;
            changed = true;
            searchOffset = 0;
            continue;
          }
        }
        
        searchOffset = absoluteMatchStart + 8; // skip past "SafeArea"
      }
      
      if (changed) {
        entity.writeAsStringSync(content);
        count++;
      }
    }
  }
}
