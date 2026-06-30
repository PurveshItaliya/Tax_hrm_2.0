import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/master_model.dart';
import 'package:tax_hrm/utils/basicdata.dart';



class MasterApis{
Future getMasterData() async {
  var url =
      Uri.parse('$apibaseurl/api/Master/mst_Master');

  var response = await http.get(url,  headers: {'Authorization': 'bearer ${curentUser['token']}'},);
  return mstclassFromJson(response.body);
}






}