
import 'package:tax_hrm/models/company/getallcompany.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:http/http.dart' as http;

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
