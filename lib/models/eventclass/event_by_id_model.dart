class EventByIdModel {
  int? eventId;
  String? eventName;
  int? companyId;
  String? startDate;
  String? endDate;
  String? eventPlace;
  String? description;
  String? cguid;
  String? flag;
  String? iPAddress;
  String? serverName;
  String? entryTime;
  String? custId;
  List<FileList>? fileList;

  EventByIdModel({
    this.eventId,
    this.eventName,
    this.companyId,
    this.startDate,
    this.endDate,
    this.eventPlace,
    this.description,
    this.cguid,
    this.flag,
    this.iPAddress,
    this.serverName,
    this.entryTime,
    this.custId,
    this.fileList,
  });

  EventByIdModel.fromJson(Map<String, dynamic> json) {
    eventId = json['EventId'];
    eventName = json['EventName'];
    companyId = json['CompanyId'];
    startDate = json['StartDate'];
    endDate = json['EndDate'];
    eventPlace = json['EventPlace'];
    description = json['Description'];
    cguid = json['Cguid'];
    flag = json['Flag'];
    iPAddress = json['IPAddress'];
    serverName = json['ServerName'];
    entryTime = json['EntryTime'];
    custId = json['CustId'];
    if (json['FileList'] != null) {
      fileList = <FileList>[];
      json['FileList'].forEach((v) {
        fileList!.add(FileList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['EventId'] = eventId;
    data['EventName'] = eventName;
    data['CompanyId'] = companyId;
    data['StartDate'] = startDate;
    data['EndDate'] = endDate;
    data['EventPlace'] = eventPlace;
    data['Description'] = description;
    data['Cguid'] = cguid;
    data['Flag'] = flag;
    data['IPAddress'] = iPAddress;
    data['ServerName'] = serverName;
    data['EntryTime'] = entryTime;
    data['CustId'] = custId;
    if (fileList != null) {
      data['FileList'] = fileList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FileList {
  int? id;
  String? filename;
  String? fileType;
  String? fileSize;
  String? category;
  dynamic timestamp;
  dynamic partyId;
  String? companyId;
  String? filePath;
  dynamic partyName;
  String? cguid;

  FileList({
    this.id,
    this.filename,
    this.fileType,
    this.fileSize,
    this.category,
    this.timestamp,
    this.partyId,
    this.companyId,
    this.filePath,
    this.partyName,
    this.cguid,
  });

  FileList.fromJson(Map<String, dynamic> json) {
    id = json['Id'];
    filename = json['Filename'];
    fileType = json['FileType'];
    fileSize = json['FileSize']?.toString();
    category = json['Category'];
    timestamp = json['Timestamp'];
    partyId = json['PartyId'];
    companyId = json['CompanyId']?.toString();
    filePath = json['FilePath'];
    partyName = json['PartyName'];
    cguid = json['Cguid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Id'] = id;
    data['Filename'] = filename;
    data['FileType'] = fileType;
    data['FileSize'] = fileSize;
    data['Category'] = category;
    data['Timestamp'] = timestamp;
    data['PartyId'] = partyId;
    data['CompanyId'] = companyId;
    data['FilePath'] = filePath;
    data['PartyName'] = partyName;
    data['Cguid'] = cguid;
    return data;
  }
}
