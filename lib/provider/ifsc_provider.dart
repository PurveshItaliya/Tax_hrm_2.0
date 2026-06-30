


// ignore_for_file: strict_top_level_inference

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:tax_hrm/api/ifscApi.dart';
import 'package:tax_hrm/models/ifsc/create_new_model.dart';
import 'package:tax_hrm/models/ifsc/delete_ifsc_model.dart';
import 'package:tax_hrm/models/ifsc/ifsc_model.dart';
import 'package:tax_hrm/provider/pagniation.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';

class IfscMastServices extends ChangeNotifier {


bool islodering = false;
bool get isloderings => islodering;
setloading(bool value){
  islodering = value;
  // notifyListeners();
}

//------------------------  Get  All IfscData   --------------------------\\
List<IfscListModel>  getallIfscDataList  = [];

List<IfscListModel>  showallIfscDataList  = [];

 Future getifscData()async {
    setloading(true);
  await  IfscApiCall().getifscdatalist().then((value) {


getallIfscDataList = value;
showallIfscDataList = value;
  setloading(false);
  notifyListeners();

    });
  }

//-----------------------------------------------------------------------\\


//------------------------------ Create New Ifsc--------------------------\\

  createNewIfscs(bankname,brancename,ifsccode,cguids,context,insertmood,setid) {
    IfscApiCall()
        .creatIfscApi(bankname,brancename,ifsccode,cguids,insertmood,setid)
        .then((value) {
CreateNewIfsc  createResponse  = value as CreateNewIfsc;

if(createResponse.success.toString() == 'true'){



if(insertmood == true){
showtoastmessage('New Ifsc  Add Successfully');

}else{
showtoastmessage('Update Successfully');

}
Navigator.pop(context);

getifscData().then((value) {
          Provider.of<AppPaginationProvider>(context, listen: false).countPaginationPage(showallIfscDataList,0);
        },);


}
    });
  }




//-------------------------Delet IfscData ----------------------------\\

  deletIfsc(id) {
    IfscApiCall().deleteIfsc(id).then((value) {

DleteMyTask  deleteResponse  = value as DleteMyTask;


if(deleteResponse.success.toString() == 'true'){

  showtoastmessage('Delete Successfully');
}else{
  showtoastmessage('Something Wrong');
}
getifscData();
      notifyListeners();
    
    });
  }
}