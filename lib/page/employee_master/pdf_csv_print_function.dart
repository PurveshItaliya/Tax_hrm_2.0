// ignore_for_file: unnecessary_non_null_assertion, strict_top_level_inference
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

// PDF Download Function
downloadDirectory({title,  List<int>? docs}) async {
  Directory? externalDir;

  int fileIndex = 1;
  String filePath;
  bool permission = await requestStoragePermission();

    if(!permission){
      showtoastmessage("Storage permission required");
      return;
    }
  if(Platform.isAndroid) {
    externalDir = Directory('/storage/emulated/0/Download/TAX HRM 2.0');
  } else if(Platform.isIOS) {
    externalDir = await getApplicationDocumentsDirectory();
  }

  // Create the directory if it does not exist
  if (!(externalDir!.existsSync())) {
    externalDir.createSync(recursive: true);
  }

  do {
    filePath = '${externalDir.path}/$title($fileIndex).pdf';
    fileIndex++;
  } while (await File(filePath).exists());
  File path  = File(filePath);

  await path.writeAsBytes(docs!).then((value) {
  showtoastmessage('PDF Download Successfully!!!');
  },);
}

// CSV Download Function
downloadCSVDirectory({title,  String? csvDataSave}) async {
  Directory? externalDir;
  int fileIndex = 1;
  String filePath;
    if(Platform.isAndroid) {
    externalDir = Directory('/storage/emulated/0/Download/TAX HRM 2.0');
  } else if(Platform.isIOS) {
    externalDir = await getApplicationDocumentsDirectory();
  }
  if (!await externalDir!.exists()) {
    await externalDir.create(recursive: true);
  }
  do {
    filePath = '${externalDir.path}/$title($fileIndex).csv';
    fileIndex++;
  } while (await File(filePath).exists());
  File path  = File(filePath);
  await path.writeAsString(csvDataSave!).then((value) {
    showtoastmessage('CSV Download Successfully!!!');
  },);
}

// // Print LandScape Layout
// printLandScape(docs) async {
//   await Printing.layoutPdf(
//       format: PdfPageFormat.a4.landscape,
//       onLayout: (PdfPageFormat format) async => docs.save());
// }
// // Print Portrait Layout
// printPortrait(docs) async {
//   await Printing.layoutPdf(
//       format: PdfPageFormat.a4,
//       onLayout: (PdfPageFormat format) async => docs.save());
// }

// URL PDF Download Function
Future<void> downloadAndSavePDF(String url, String fileName) async {
  final response = await http.get(Uri.parse(url));

  Directory? externalDir;

  int fileIndex = 1;
  String filePath;
  if(Platform.isAndroid) {
    externalDir = Directory('/storage/emulated/0/Download/TAX CRM');
  } else if(Platform.isIOS) {
    externalDir = await getApplicationDocumentsDirectory();
  }

  // Create the directory if it does not exist
  if (!(externalDir!.existsSync())) {
    externalDir.createSync(recursive: true);
  }

  do {
    filePath = '${externalDir!.path}/$fileName($fileIndex).pdf';
    fileIndex++;
  } while (await File(filePath).exists());
  File path  = File(filePath);

  await path.writeAsBytes(response.bodyBytes).then((value) {
    showtoastmessage('PDF Download Successfully!!!');
  },);
}


// Excel Download Function
Future downloadExcelDirectory({title,  String? csvDataSave}) async {
  Directory? externalDir;
  int fileIndex = 1;
  String filePath;
    if(Platform.isAndroid) {
    externalDir = Directory('/storage/emulated/0/Download/TAX CRM');
  } else if(Platform.isIOS) {
    externalDir = await getApplicationDocumentsDirectory();
  }
  if (!await externalDir!.exists()) {
    await externalDir.create(recursive: true);
  }
  do {
    filePath = '${externalDir.path}/$title($fileIndex).xlsx';
    fileIndex++;
  } while (await File(filePath).exists());
  File path  = File(filePath);
  await path.writeAsString(csvDataSave!).then((value) {
    showtoastmessage('Excel Download Successfully!!!');
  },);
}

// Excel Download Function
Future downloadImageOrPdfDirectory({title,  String? filePaths}) async {
  final response = await http.get(Uri.parse(filePaths!));

  Directory? externalDir;

  int fileIndex = 1;
  String filePath;
  if(Platform.isAndroid) {
    externalDir = Directory('/storage/emulated/0/Download/TAX CRM');
  } else if(Platform.isIOS) {
    externalDir = await getApplicationDocumentsDirectory();
  }

  // Create the directory if it does not exist
  if (!(externalDir!.existsSync())) {
    externalDir.createSync(recursive: true);
  }

  do {
    filePath = '${externalDir!.path}/$title($fileIndex).${filePaths.toString().split(".").last.toString()}';
    fileIndex++;
  } while (await File(filePath).exists());
  File path  = File(filePath);

  await path.writeAsBytes(response.bodyBytes).then((value) {
    showtoastmessage('Download Successfully!!!');
  },);
}

Future<bool> requestStoragePermission() async {
  if (!Platform.isAndroid) {
    return true;
  }

  if (await Permission.storage.request().isGranted) {
    return true;
  }

  if (await Permission.manageExternalStorage.request().isGranted) {
    return true;
  }

  return false;
}