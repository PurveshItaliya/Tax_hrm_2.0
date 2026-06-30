// ignore_for_file: depend_on_referenced_packages, strict_top_level_inference, empty_catches

import 'dart:convert';
import 'dart:io';
import 'package:tax_hrm/models/documentsclass/showdocuments.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class DocumentApis {
  // ************************************************ Get Document File *********************************************************

  Future getDocuments() async {
    var url = Uri.parse(
      '${apibaseurl}api/Master/EmpGetFileList?EmpId=${curentUser['Id']}',
    );

    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'bearer ${curentUser['token']}',
      },
    );
    return documentViewsFromJson(response.body);
  }

  // ************************************************ Get Document File *********************************************************

  // ************************************************ Delete Document File *********************************************************

  Future deleteDocuments({deleteEmpImage}) async {
    var url = Uri.parse(
      '${apibaseurl}api/Master/DeleteEmpImage?Id=$deleteEmpImage',
    );

    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'bearer ${curentUser['token']}',
      },
    );
    return jsonDecode(response.body);
  }

  // ************************************************ Delete Document File *********************************************************

  // ************************************************ Add Document File *********************************************************

  Future<dynamic> uploadDocuments({
    List<File>? files,
    category,
    required Function(dynamic val) listenRes,
  }) async {
    var url = Uri.parse('${apibaseurl}api/Master/EmpFileUploads');
    var header = {
      'Content-Type': 'application/json',
      'Accept': '*/*',
      'Authorization': 'bearer ${curentUser['token']}',
    };
    try {
      var body = <String, String>{
        "Category": category,
        "EmpId": '${curentUser['Id']}',
        "CompanyId": '${selectedcurentcompany!.companyId}',
      };

      var req = http.MultipartRequest("POST", url);
      req.headers.addAll(header);
      req.fields.addAll(body);

      //-----------Send Multiple File  ---------------\\
      if (files!.isNotEmpty) {
        for (var i = 0; i < files.length; i++) {
          req.files.add(
            http.MultipartFile(
              'Filename',
              File(files[i].path).readAsBytes().asStream(),
              File(files[i].path).lengthSync(),
              filename: basename(files[i].path.split("/").last),
            ),
          );
        }
      }
      //---------------  Send Single -------------------\\
      var response = await req.send();
      response.stream.transform(utf8.decoder).listen((value) {
        listenRes(jsonDecode(value));
      });
    } catch (e) { /* ignored */ }
  }

  // ************************************************ Add Document File *********************************************************
}
