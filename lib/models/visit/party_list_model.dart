class PartyListModel {
  int? partyId;
  String? partyName;
  String? partyAddress;

  PartyListModel({
    this.partyId,
    this.partyName,
    this.partyAddress,
  });

  PartyListModel.fromJson(Map<String, dynamic> json) {
    partyId = json['PartyId'];
    partyName = json['PartyName'];
    partyAddress = json['PartyAddress'] ?? json['Address1'] ?? json['Address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['PartyId'] = partyId;
    data['PartyName'] = partyName;
    data['PartyAddress'] = partyAddress;
    return data;
  }
}
