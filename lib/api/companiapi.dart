
import 'dart:io';
import 'package:tax_hrm/models/company/getallcompany.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:http/http.dart' as http;

class FileUploadClass {
  File? selectedImages;
  String? setImgType;
  String? cguid;
  FileUploadClass({required this.selectedImages, required this.setImgType, this.cguid});
}

class CompanyMasterApi {
  //--------------------------Add Company Document -------------------------\\
  Future<dynamic> uploadDocuments({
    List<FileUploadClass>? files,
    companyid,
    cguid,
  }) async {
    var url = Uri.parse('$apibaseurl/api/Master/CompanyFileupload');
    var token = curentUser is Map ? curentUser['token'] : curentUser?.token;
    var header = {
      'Content-Type': 'application/json',
      'Accept': '*/*',
      'Authorization': 'bearer $token',
    };

    var req = http.MultipartRequest("POST", url);
    req.headers.addAll(header);

    if (companyid != null) {
      req.fields['CompanyId'] = companyid.toString();
    }
    if (cguid != null) {
      req.fields['Cguid'] = cguid.toString();
    }

    //-----------Send Multiple File  ---------------\\
    if (files != null) {
      for (var item in files) {
        if (item.setImgType != null) {
          req.fields['Category'] = item.setImgType!;
        }
        if (companyid != null) {
          req.fields['CompanyId'] = companyid.toString();
        }
        if (cguid != null) {
          req.fields['Cguid'] = cguid.toString();
        } else if (item.cguid != null) {
          req.fields['Cguid'] = item.cguid!;
        }
        if (item.selectedImages != null) {
          var pic = await http.MultipartFile.fromPath(
            'Filename',
            item.selectedImages!.path,
          );
          req.files.add(pic);
        }
      }
    }

    print('------------------------>>>> CompanyFileupload req.fields: ${req.fields} | files count: ${req.files.length}');
    var response = await req.send();
    return response.statusCode;
  }
}

class CompanyDataApis {
  Future getCompanyDataList() async {
    var url = Uri.parse(
      '${apibaseurl}api/Master/CompanyList?CustId=${curentUser['CustId']} ',
    );

    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'bearer ${curentUser['token']}',
      },
    );
    if (response.statusCode == 200) {
      return getCompanyDataFromJson(response.body);
    } else {
      return response.statusCode;
    }
  }
}

