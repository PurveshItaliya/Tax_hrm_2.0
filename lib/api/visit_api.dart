import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/models/visit/party_list_model.dart';
import 'package:tax_hrm/models/visit/visit_detail_model.dart';

class VisitApis {
  Future<List<PartyListModel>> getPartyListDropdown(String custId, String companyId) async {
    var url = Uri.parse('${apibaseurl}api/Master/PartyListDropdown?CustId=$custId&CompanyId=$companyId');
    developer.log('--- API GET Request ---', name: 'VisitApis');
    developer.log('URL: $url', name: 'VisitApis');
    var response = await http.get(url, headers: {
      'Authorization': 'bearer ${curentUser['token']}',
    });

    developer.log('Status Code: ${response.statusCode}', name: 'VisitApis');
    developer.log('Response Body: ${response.body}', name: 'VisitApis');

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => PartyListModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load party list');
    }
  }

  Future<List<dynamic>> getVisitList(String companyId, String visitStatus, String visitAssignTo) async {
    var url = Uri.parse('${apibaseurl}api/hrm/VisitList?CompanyId=$companyId&VisitStatus=$visitStatus&VisitAssignTo=$visitAssignTo');
    developer.log('--- API GET Request ---', name: 'VisitApis');
    developer.log('URL: $url', name: 'VisitApis');
    var response = await http.get(url, headers: {
      'Authorization': 'bearer ${curentUser['token']}',
    });

    developer.log('Status Code: ${response.statusCode}', name: 'VisitApis');
    developer.log('Response Body: ${response.body}', name: 'VisitApis');

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data; // Using dynamic list since we don't have a rigid model yet
    } else {
      throw Exception('Failed to load visit list');
    }
  }

  Future<VisitDetailModel> getVisitById(String companyId, String visitUkeyId) async {
    var url = Uri.parse('${apibaseurl}api/hrm/GetVisitById?CompanyId=$companyId&VisitUkeyId=$visitUkeyId');
    developer.log('--- API GET Request (Visit Details) ---', name: 'VisitApis');
    developer.log('URL: $url', name: 'VisitApis');
    var response = await http.get(url, headers: {
      'Authorization': 'bearer ${curentUser['token']}',
    });

    developer.log('Status Code: ${response.statusCode}', name: 'VisitApis');
    developer.log('Response Body: ${response.body}', name: 'VisitApis');

    if (response.statusCode == 200) {
      return VisitDetailModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load visit details');
    }
  }

  Future<bool> deleteVisit(String visitUkeyId) async {
    var url = Uri.parse('${apibaseurl}api/hrm/DeleteVisit?VisitUkeyId=$visitUkeyId');
    developer.log('--- API GET Request (Delete) ---', name: 'VisitApis');
    developer.log('URL: $url', name: 'VisitApis');
    var response = await http.get(url, headers: {
      'Authorization': 'bearer ${curentUser['token']}',
    });

    developer.log('Status Code: ${response.statusCode}', name: 'VisitApis');
    developer.log('Response Body: ${response.body}', name: 'VisitApis');

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete visit');
    }
  }

  Future<dynamic> createUpdateVisit(Map<String, dynamic> visitData, {String flag = 'A'}) async {
    var body = {
      "FLAG": flag,
      "customervisit": visitData
    };
    var url = Uri.parse('${apibaseurl}api/hrm/CreateUpdateVisit');
    developer.log('--- API POST Request (FLAG: $flag) ---', name: 'VisitApis');
    developer.log('URL: $url', name: 'VisitApis');
    developer.log('Request Body: ${jsonEncode(body)}', name: 'VisitApis');

    try {
      var response = await http.post(url, body: jsonEncode(body), headers: {
        'Authorization': 'bearer ${curentUser['token']}',
        'Content-Type': 'application/json',
      });

      developer.log('Status Code: ${response.statusCode}', name: 'VisitApis');
      developer.log('Response Body: ${response.body}', name: 'VisitApis');

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (parseError) {
          developer.log('JSON Parse Error: $parseError', name: 'VisitApis', error: parseError);
          developer.log('Raw body that failed to parse: ${response.body}', name: 'VisitApis');
          throw Exception('Server returned 200 but response is not valid JSON: ${response.body}');
        }
      } else {
        developer.log(
          '--- CreateUpdateVisit FAILED ---\nStatus: ${response.statusCode}\nBody: ${response.body}',
          name: 'VisitApis',
        );
        throw Exception(
          'CreateUpdateVisit failed [${response.statusCode}]: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      if (e is Exception && e.toString().contains('CreateUpdateVisit failed')) {
        rethrow;
      }
      developer.log('Network/Unexpected Error in createUpdateVisit: $e', name: 'VisitApis', error: e, stackTrace: stackTrace);
      throw Exception('Network error in createUpdateVisit: $e');
    }
  }

  Future createTaskFileUpload({
    required List<String> filename, 
    required String cguid,
    required String companyId,
    required String partyId,
    String category = 'Visit',
  }) async {
    var url = Uri.parse('${apibaseurl}api/Master/CompanyFileupload');
    developer.log('--- API POST Request (File Upload) ---', name: 'VisitApis');
    developer.log('URL: $url', name: 'VisitApis');

    var headers = {
      'Authorization': 'bearer ${curentUser['token']}',
    };
    var request = http.MultipartRequest('POST', url);
    request.fields.addAll({
      'Category': category,
      'PartyId': partyId,
      'CompanyId': companyId,
      'Cguid': cguid,
      'CustId': curentUser['CustId'] ?? '',
      'EmpId': curentUser['Id']?.toString() ?? '',
    });

    for (var file in filename) {
      developer.log('Attaching file: $file', name: 'VisitApis');
      request.files.add(
        await http.MultipartFile.fromPath(
          'Filename',
          file,
        ),
      );
    }
    request.headers.addAll(headers);

    developer.log('Sending multipart request...', name: 'VisitApis');
    developer.log('Request Headers: ${request.headers}', name: 'VisitApis');
    developer.log('Request Fields: ${request.fields}', name: 'VisitApis');

    http.StreamedResponse response = await request.send();
    
    developer.log('Status Code: ${response.statusCode}', name: 'VisitApis');
    String responseBody = await response.stream.bytesToString();
    developer.log('Response Body: $responseBody', name: 'VisitApis');

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Upload Failed');
    }
  }
}
