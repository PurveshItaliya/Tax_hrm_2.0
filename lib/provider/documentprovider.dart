// ignore_for_file: strict_top_level_inference, empty_catches

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tax_hrm/api/documentapi.dart';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/documentsclass/showdocuments.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class DocumentsProvider extends ChangeNotifier {
  bool islodering = false;

  bool get isloderings => islodering;

  setloading(bool value) {
    islodering = value;
  }

  loadingData() async {
    try {
      showDocumentList = [];
      setloading(true);
      await getEmployeDocuments();
      setloading(false);
    } catch (e) {
      setloading(false);
    }
    notifyListeners();
  }

  List<DocumentViews> showDocumentList = [];
  List<DocumentViews> mainDocumentList = [];
  TextEditingController documentCategorey =TextEditingController();

  getEmployeDocuments() async {
    try {
      await DocumentApis().getDocuments().then((value){
        showDocumentList = value;
        mainDocumentList = value;
      }).onError((error, stackTrace) {
        setloading(false);
      },);
    } catch (e) { /* ignored */ }
  }

  //****************************************** View Douments show  ****************************************************** */

  String? contentType;

  loadViewDocuments({selectedData,}) async {
    try {
      await checkContentType('${selectedData.filePath}${selectedData.filename}').then((value){
        contentType = value;
        notifyListeners();
      });
    } catch (e) { /* ignored */ }
  }
  
  Future<String?> checkContentType(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      final contentType = response.headers['content-type'];
      return contentType;
    } catch (e) {
      return null;
    }
  }

  //****************************************** View Douments show  ****************************************************** */

  //****************************************** Delete Douments show  ****************************************************** */

  deleteEmployeDocuments(context,{deleteEmpImage}) async {
    try {
      Navigator.pop(context);
      setloading(true);
      notifyListeners();
      await DocumentApis().deleteDocuments(deleteEmpImage: deleteEmpImage).then((value) async {
        var json = value;
        if(json["Success"] == true) {
          if(json["data"] == "Success"){
            await loadingData();
          }
        }
      }).onError((error, stackTrace) {
        setloading(false);
      },);
    } catch (e) {
      setloading(false);
    }
  }

  //****************************************** Delete Douments show  ****************************************************** */

  //****************************************** Add Douments show  ****************************************************** */

  List<File> selectedFiles = [];
  List<File> holdnew = [];

  loadImageData(types) async {
    try {
      FilePickerResult? result = await getImagePic(types);
      if (result != null) {
        holdnew = result.paths.map((path) => File(path!)).toList();
        selectedFiles.addAll(holdnew);
        notifyListeners();
      }
    } catch (e) { /* ignored */ }
  }

  void removeFile(int index) {
    selectedFiles.removeAt(index);
    notifyListeners(); // 🔥 REQUIRED
  }

  Future<FilePickerResult?> getImagePic(types) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        "jpg",
        "png",
        "jpeg",
        "JPG",
        "PNG",
        "JPEG",
        "HEIC",
        "gif",
        "pdf",
      ],
    );
    return result;
  }

  bool isImageFile(String path) {
    final ext = path.split('.').last;
    return ["jpg","png","jpeg","JPG","PNG","JPEG","HEIC","gif",].contains(ext);
  }

  bool isPdfFile(String path) {
    return path.toLowerCase().endsWith('pdf');
  }

  addDocumentImage(context) async {
    try {
      if (documentCategorey.text.isEmpty&& selectedFiles.isEmpty){
        showtoastmessage("Please enter a category and select image");
      } else if (documentCategorey.text.isEmpty){
        showtoastmessage("Please enter a category");
      } else if (selectedFiles.isEmpty){
        showtoastmessage("Please select image");
      } else {
        Navigator.pop(context);
        setloading(true);
        notifyListeners();
        await uploadDocumentsEmployes(context: context,setCategorey: documentCategorey.text,setFiles: selectedFiles);
      }
    } catch (e) {
      setloading(false);
    }
  }

  uploadDocumentsEmployes({setCategorey,setFiles,context}) async {
    await DocumentApis().uploadDocuments(listenRes: (val) async {
      setloading(false); 
      await loadingData();
    },category: setCategorey,files: setFiles);
  }

  //****************************************** Add Douments show  ****************************************************** */

}
