// ignore_for_file: strict_top_level_inference, non_constant_identifier_names, empty_catches

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tax_hrm/models/departmentclass/departemtmaster/deletedepartment.dart';
import 'package:tax_hrm/models/employes/employeid.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/employes/gettotal_user.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';

class Employeeclass {

  //==================== Get Employee Data =======================\\

  Future emppppapi() async {
    var url = Uri.parse(
      "${apibaseurl}api/Master/GetEmpList?CustId=${curentUser['CustId']}&CompanyId=${selectedcurentcompany!.companyId}",
    );
    var response = await http.get(
      url,
      headers: {'Authorization': "bearer ${curentUser['token']}"},
    );
    return employeelistsFromJson(response.body);
  }

  //==================== Delete Employee Data =======================\\

    Future deleteEmploye(eid) async {
    var url = Uri.parse(
        "$apibaseurl/api/Master/DeleteEmp?Id=$eid");
    var response = await http.get(url,  headers: {'Authorization': "bearer ${curentUser['token']}"});
    return deleteDepartmentmodelFromJson(response.body);
  }

   //==================== Get Total User =======================\\
   Future getTotalUserApi() async {
    var url = Uri.parse('$apibaseurl/api/Master/TotalUserList?Custid=${curentUser['CustId']}');

    var response = await http.get(url, headers:{'Authorization': "bearer ${curentUser['token']}"});

    return getTotalUserModalFromJson(response.body);
}

 //==================== Delete Image =======================\\
   Future deleteImage(eid) async {
    var url = Uri.parse(
        "$apibaseurl/api/Master/DeleteImagetest?Id=$eid");
    var response = await http.get(url,  headers: {'Authorization': "bearer ${curentUser['token']}"});
    return deleteDepartmentmodelFromJson(response.body);
  }

 //==================== Create employee =======================\\
createEmpp12(
      {File?  FILES,
    firstname,
    lastname,
    mobile1,
    mobile2,
    address1,
    address2,
    address3,
    dob,
    doj,
    pincode,
    cityid,
    statid,
    email,
    gender,
    pan,
    marstatus,
      bankname,
       branchname,
        accno,
          salary,
          accountType,
          salaryamount,
          totalhours,
          username,
          password,
          highestDegree,
          degreeName,
          universityName,
          passingYear,
          uanNo,
          esicNo,
          selectedDepartment,
          selectedposition,
          roletypes,
          selectedifsc,
          bool?  insertmood,seteid,
          activemood,
          setCguids,
workType,
officeLocation,
locationRadius,
isFetchLocation,
      required Function(dynamic val) listenRes}) async {
    var url = Uri.parse('${apibaseurl}api/Master/CreateEmp');
    var header = {'Accept' : '*/*', 'Authorization':
            'bearer  ${curentUser['token']}'};
try{

  var body = <String, String>{
        "CompanyId": selectedcurentcompany!.companyId.toString(),
        "FirstName": firstname?.toString() ?? '',
        "LastName": lastname?.toString() ?? '',
        "Mobile1": mobile1?.toString() ?? '',
        "Mobile2": mobile2?.toString() ?? '',
        "Add1": address1?.toString() ?? '',
        "Add2": address2?.toString() ?? '',
        "Add3": address3?.toString() ?? '',
        "DOB":  dob?.toString() ?? '',
        "DOJ":  doj?.toString() ?? '',
        "PincodeId": pincode?.toString() ?? '',
        "CityId": cityid?.toString() ?? '',
        "StateId": statid?.toString() ?? '',
        "Email": email?.toString() ?? '',
        "Gender": gender?.toString() ?? '',
        "PAN": pan?.toString() ?? '',
        "MaritalStatus": marstatus?.toString() ?? '',
        "DepartmentId": selectedDepartment?.toString() ?? '',
        "PositionId": selectedposition?.toString() ?? '',
        "Role": roletypes?.toString() ?? '',
        "IFSC": selectedifsc?.toString() ?? '',
        "BankName": bankname?.toString() ?? '',
        "BranchName": branchname?.toString() ?? '',
        "AccNo": accno?.toString() ?? '',
        "AccType": accountType?.toString() ?? '',
        "SalaryType": salary?.toString() ?? '',
        "SalaryAmount": salaryamount?.toString() ?? '',
        "Totalhours": totalhours?.toString() ?? '',
        "CustId": '${curentUser['CustId']}',
        "UserName": username?.toString() ?? '',
        "Password": password?.toString() ?? '',
         "Cguid":  setCguids?.toString() ?? '',
        "IPAddress":"${curentUser['IPAddress']}",
        "IsActive": activemood.toString(),
         "HighestDegree": highestDegree?.toString() ?? '',
        "DegreeName": degreeName?.toString() ?? '',
         "UniversityName": universityName?.toString() ?? '',
         "PassingYear": passingYear?.toString() ?? '',
         "UANNo": uanNo?.toString() ?? '',
         "ESICNo": esicNo?.toString() ?? '',
         "Shiftcguid":'',
         "RegisterDate":"",
          "Flag":'A',
          "WorkType": workType?.toString() ?? '',
          "OfficeLocation": officeLocation?.toString() ?? '',
          "LocationRadius": locationRadius?.toString() ?? '50',
          "IsFetchLocation": isFetchLocation?.toString() ?? 'false',
    };


    var req = http.MultipartRequest("POST", url);
    req.headers.addAll(header);
    req.fields.addAll(body);
    if (FILES != null) {
      var pic = await http.MultipartFile.fromPath("Img", FILES.path);
      req.files.add(pic);


    }
    var response = await req.send();
    final value = await response.stream.bytesToString();
    dynamic decoded;
    try {
      decoded = value.isEmpty ? <String, dynamic>{} : jsonDecode(value);
    } catch (e) {
      decoded = {
        'message': 'HTTP ${response.statusCode}: Failed to decode response. Raw body: $value'
      };
    }
    listenRes(decoded);
    return decoded;


}catch(e){ /* ignored */ }
           
  
  }

  //==================== Update Employee Data =======================\\

 
Future<dynamic> updateEmployes({
  File? FILES,
  firstname,
  lastname,
  mobile1,
  mobile2,
  address1,
  address2,
  address3,
  dob,
  doj,
  pincode,
  cityid,
  statid,
  email,
  gender,
  pan,
  marstatus,
  bankname,
  branchname,
  accno,
  accountType,
  salary,
  salaryamount,
  totalhours,
  username,
  password,
  highestDegree,
  degreeName,
  universityName,
  passingYear,
  uanNo,
  esicNo,
  selectedDepartment,
  selectedposition,
  roletypes,
  selectedifsc,
  seteid,
  userStatus,  // This might be a bool
  workType,
  officeLocation,
  locationRadius,
  isFetchLocation,
  setCguids,
  bool removeImage = false,
  required Function(dynamic val) listenRes
}) async {
  var url = Uri.parse('${apibaseurl}api/Master/UpdateEmp');
  var header = {
    'Accept': '*/*', 
    'Authorization': 'bearer ${curentUser['token']}'
  };

  var updatebody = <String, String>{
    "id": seteid.toString(), // Ensure it's string
    "CompanyId": '${selectedcurentcompany!.companyId}',
    "FirstName": firstname?.toString() ?? '',
    "LastName": lastname?.toString() ?? '',
    "Mobile1": mobile1?.toString() ?? '',
    "Mobile2": mobile2?.toString() ?? '',
    "Add1": address1?.toString() ?? '',
    "Add2": address2?.toString() ?? '',
    "Add3": address3?.toString() ?? '',
    "DOB": dob?.toString() ?? '',
    "DOJ": doj?.toString() ?? '',
    "PincodeId": pincode?.toString() ?? '',
    "CityId": cityid?.toString() ?? '',
    "StateId": statid?.toString() ?? '',
    "Email": email?.toString() ?? '',
    "Gender": gender?.toString() ?? '',
    "PAN": pan?.toString() ?? '',
    "MaritalStatus": marstatus?.toString() ?? '',
    "DepartmentId": selectedDepartment?.toString() ?? '',
    "PositionId": selectedposition?.toString() ?? '',
    "Role": roletypes?.toString() ?? '',
    "IFSC": selectedifsc?.toString() ?? '',
    "BankName": bankname?.toString() ?? '',
    "BranchName": branchname?.toString() ?? '',
    "AccNo": accno?.toString() ?? '',
    "AccType": accountType?.toString() ?? '',
    "SalaryType": salary?.toString() ?? '',
    "SalaryAmount": salaryamount?.toString() ?? '',
    "Totalhours": totalhours?.toString() ?? '',
    "CustId": '${curentUser['CustId']}',
    "UserName": username?.toString() ?? '',
    "Password": password?.toString() ?? '',
    "IsActive": userStatus.toString(), // Convert bool to string
    "Cguid": setCguids?.toString() ?? '',
    "IPAddress": "${curentUser['IPAddress']}",
    "HighestDegree": highestDegree?.toString() ?? '',
    "DegreeName": degreeName?.toString() ?? '',
    "UniversityName": universityName?.toString() ?? '',
    "PassingYear": passingYear?.toString() ?? '',
    "UANNo": uanNo?.toString() ?? '',
    "ESICNo": esicNo?.toString() ?? '',
    "RegisterDate": "",
    "Flag": 'U',
    "WorkType": workType?.toString() ?? '',
    "OfficeLocation": officeLocation?.toString() ?? '',
    "LocationRadius": locationRadius?.toString() ?? '50',
    "IsFetchLocation": isFetchLocation?.toString() ?? 'false',
  };

  if (removeImage) {
    updatebody["Img"] = "";
  }
  
  var req = http.MultipartRequest("POST", url);
  req.headers.addAll(header);
  req.fields.addAll(updatebody);
  
  if (FILES != null) {
    var pic = await http.MultipartFile.fromPath("Img", FILES.path);
    req.files.add(pic);
  }
  
  var response = await req.send();
  final value = await response.stream.bytesToString();
  dynamic decoded;
  try {
    decoded = value.isEmpty ? <String, dynamic>{} : jsonDecode(value);
  } catch (e) {
    decoded = {
      'message': 'HTTP ${response.statusCode}: Failed to decode response. Raw body: $value'
    };
  }
  listenRes(decoded);
  return decoded;
}


Future<dynamic> updateEmployeswithoutImage(
      {
    firstname,
    lastname,
    mobile1,
    mobile2,
    address1,
    address2,
    address3,
    dob,
    doj,
    pincode,
    cityid,
    statid,
    email,
    gender,
    pan,
    marstatus,
      bankname,
       branchname,
        accno,
        accountType,
         salary,
          salaryamount,
          totalhours,
          username,
          password,
          highestDegree,
          degreeName,
          universityName,
          passingYear,
          uanNo,
          esicNo,
          selectedDepartment,
          selectedposition,
          roletypes,
          selectedifsc,
          seteid,
          userStatus,
          setimag,
          setCguids,
          workType,
          officeLocation,
          locationRadius,
          isFetchLocation,
          bool removeImage = false,
          required Function(dynamic val) listenRes

    }) async {




  var updatebody = <String, String>{
        "id":seteid?.toString() ?? '',
        "CompanyId": '${selectedcurentcompany!.companyId}',
        "FirstName": firstname?.toString() ?? '',
        "LastName": lastname?.toString() ?? '',
        "Mobile1": mobile1?.toString() ?? '',
        "Mobile2": mobile2?.toString() ?? '',
        "Add1": address1?.toString() ?? '',
        "Add2": address2?.toString() ?? '',
        "Add3": address3?.toString() ?? '',
        "DOB":  dob?.toString() ?? '',
        "DOJ":  doj?.toString() ?? '',
        "PincodeId": pincode?.toString() ?? '',
        "CityId": cityid?.toString() ?? '',
        "StateId": statid?.toString() ?? '',
        "Email": email?.toString() ?? '',
        "Gender": gender?.toString() ?? '',
        "PAN": pan?.toString() ?? '',
        "MaritalStatus": marstatus?.toString() ?? '',
        "DepartmentId": selectedDepartment?.toString() ?? '',
        "PositionId": selectedposition?.toString() ?? '',
        "Role": roletypes?.toString() ?? '',
        "IFSC": selectedifsc?.toString() ?? '',
        "BankName": bankname?.toString() ?? '',
        "BranchName": branchname?.toString() ?? '',
        "AccNo": accno?.toString() ?? '',
        "AccType":accountType?.toString() ?? '',
        "SalaryType": salary?.toString() ?? '',
        "SalaryAmount": salaryamount?.toString() ?? '',
        "Totalhours": totalhours?.toString() ?? '',
        "CustId": '${curentUser['CustId']}',
        "UserName": username?.toString() ?? '',
        "Password": password?.toString() ?? '',
        "IsActive":userStatus.toString(),
        "Cguid":  setCguids?.toString() ?? '',
        "IPAddress":"${curentUser['IPAddress']}",
        "HighestDegree": highestDegree?.toString() ?? '',
        "DegreeName": degreeName?.toString() ?? '',
        "UniversityName": universityName?.toString() ?? '',
        "PassingYear": passingYear?.toString() ?? '',
        "UANNo": uanNo?.toString() ?? '',
        "ESICNo": esicNo?.toString() ?? '',
        "RegisterDate": "",
        "Flag":'U',
        "WorkType": workType?.toString() ?? '',
        "OfficeLocation": officeLocation?.toString() ?? '',
        "LocationRadius": locationRadius?.toString() ?? '50',
        "IsFetchLocation": isFetchLocation?.toString() ?? 'false',
    };

  if (removeImage) {
    updatebody["Img"] = "";
  }

    var url = Uri.parse('$apibaseurl/api/Master/UpdateEmp');



    var response = await http.post(url, body: jsonEncode(updatebody), headers: {
      'Authorization': 'bearer ${curentUser['token']}',
      'Content-Type': 'application/json',
      'Accept': '*/*',
      
    });
    //return cretaeDepartMentFromJson(response.body);



final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
listenRes(decoded);
return decoded;



  }










Future  getEmployeByid(employeid)async{


    var url = Uri.parse(
        "$apibaseurl/api/Master/GetEmpListById?Id=$employeid");

    var response = await http.get(url, headers: {
      'Authorization':
          "bearer ${curentUser!.token}"
    });
 
    return employeByidFromJson(response.body);

}

}
