// ignore_for_file: empty_catches

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/notes/getnotes.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class NotesApisServices {

  //==================== GetNotes List =======================\\
  
  Future getNotesData() async {
    var url = Uri.parse(
      "${apibaseurl}api/HRM/GetNotesList?EmpId=${curentUser['Id']}&CompanyID=${selectedcurentcompany!.companyId}",
    );
    var response = await http.get(
      url,
      headers: {'Authorization': "bearer ${curentUser['token']}"},
    );
    return getNotesFromJson(response.body);
  }

  //==================== GetNotes List =======================\\

  //==================== Add Notes =======================\\

  Future<dynamic> createNewNotes({File? files,messages,required Function(dynamic val) listenRes}) async {
    var url = Uri.parse('$apibaseurl/api/HRM/CreateNotes');
    var header = {'Content-Type' : 'application/json', 'Accept' : '*/*', 'Authorization':'bearer ${curentUser['token']}'};
    try{
      var body = <String, String>{"Message": messages,"EmpId": '${curentUser['Id']}',"CompanyId": '${selectedcurentcompany!.companyId}',};
      var req = http.MultipartRequest("POST", url);
      req.headers.addAll(header);
      req.fields.addAll(body);
      if (files != null) {
        var pic = await http.MultipartFile.fromPath("Img", files.path);
        req.files.add(pic);
      }
      var response = await req.send();
      response.stream.transform(utf8.decoder).listen((value) {
        listenRes(jsonDecode(value));
      });
    }catch(e){ /* ignored */ }
  }

  //==================== Add Notes =======================\\

}
