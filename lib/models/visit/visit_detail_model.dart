class VisitDetailModel {
  int? visitId;
  int? companyId;
  String? visitUkeyId;
  String? visitName;
  int? partyId;
  String? visitTime;
  String? startTime;
  String? endTime;
  String? visitStatus;
  String? imgLogitude;
  String? imgLatitude;
  String? remarks;
  String? visitAssignTo;
  String? flag;
  String? iPAddress;
  String? serverName;
  String? entryTime;
  String? custId;
  String? fileName;
  String? partyName;
  String? mobile1;
  String? mobile2;
  String? partyAddress;
  String? assigntoName;
  List<VisitDocument>? documents;

  VisitDetailModel({
    this.visitId,
    this.companyId,
    this.visitUkeyId,
    this.visitName,
    this.partyId,
    this.visitTime,
    this.startTime,
    this.endTime,
    this.visitStatus,
    this.imgLogitude,
    this.imgLatitude,
    this.remarks,
    this.visitAssignTo,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
    this.fileName,
    this.partyName,
    this.mobile1,
    this.mobile2,
    this.partyAddress,
    this.assigntoName,
    this.documents,
  });

  VisitDetailModel.fromJson(Map<String, dynamic> json) {
    visitId = json['VisitId'];
    companyId = json['CompanyId'];
    visitUkeyId = json['VisitUkeyId'];
    visitName = json['VisitName'];
    partyId = json['PartyId'];
    visitTime = json['VisitTime'];
    startTime = json['StartTime'];
    endTime = json['EndTime'];
    visitStatus = json['VisitStatus'];
    imgLogitude = json['ImgLogitude'];
    imgLatitude = json['ImgLatitude'];
    remarks = json['Remarks'];
    visitAssignTo = json['VisitAssignTo'];
    flag = json['Flag'];
    iPAddress = json['IPAddress'];
    serverName = json['ServerName'];
    entryTime = json['EntryTime'];
    custId = json['CustId'];
    fileName = json['FileName'];
    partyName = json['PartyName'];
    mobile1 = json['Mobile1'];
    mobile2 = json['Mobile2'];
    partyAddress = json['PartyAddress'];
    assigntoName = json['AssigntoName'];
    if (json['Documents'] != null) {
      documents = <VisitDocument>[];
      json['Documents'].forEach((v) {
        documents!.add(VisitDocument.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['VisitId'] = visitId;
    data['CompanyId'] = companyId;
    data['VisitUkeyId'] = visitUkeyId;
    data['VisitName'] = visitName;
    data['PartyId'] = partyId;
    data['VisitTime'] = visitTime;
    data['StartTime'] = startTime;
    data['EndTime'] = endTime;
    data['VisitStatus'] = visitStatus;
    data['ImgLogitude'] = imgLogitude;
    data['ImgLatitude'] = imgLatitude;
    data['Remarks'] = remarks;
    data['VisitAssignTo'] = visitAssignTo;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    data['FileName'] = fileName;
    data['PartyName'] = partyName;
    data['Mobile1'] = mobile1;
    data['Mobile2'] = mobile2;
    data['PartyAddress'] = partyAddress;
    data['AssigntoName'] = assigntoName;
    if (documents != null) {
      data['Documents'] = documents!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VisitDocument {
  String? fileName;
  String? originalFileName;
  String? documentUrl;
  
  // Adding flexible fields in case JSON has them
  VisitDocument({this.fileName, this.originalFileName, this.documentUrl});

  VisitDocument.fromJson(Map<String, dynamic> json) {
    fileName = json['FileName'];
    originalFileName = json['OriginalFileName'];
    documentUrl = json['DocumentUrl'] ?? json['Url'] ?? json['FileUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['FileName'] = fileName;
    data['OriginalFileName'] = originalFileName;
    data['DocumentUrl'] = documentUrl;
    return data;
  }
}
