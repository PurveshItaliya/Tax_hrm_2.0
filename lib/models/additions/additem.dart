// ignore_for_file: strict_top_level_inference, prefer_typing_uninitialized_variables

List<ItemsAddAddition> additionList = [];
List<ItemsAddAddition> additionList2 = [];

class ItemsAddAddition {
  var empId, payment, type, amount, date, remarks, companyId, cguid;

  ItemsAddAddition({
    this.empId,
    this.payment,
    this.type,
    this.amount,
    this.date,
    this.remarks,
    this.companyId,
    this.cguid,
  });

  factory ItemsAddAddition.fromJson(Map<String, dynamic> json) =>
      ItemsAddAddition(
        empId: json["EmpId"] ?? "",
        payment: json["Payment"] ?? "",
        type: json["Type"] ?? "",
        amount: json["Amount"] ?? "",
        date: json["Date"] ?? "",
        remarks: json["Remarks"] ?? "",
        companyId: json["CompanyId"] ?? "",
        cguid: json["Cguid"] ?? "",
      );

  Map<String, dynamic> toJson() => {
    "EmpId": empId,
    "Payment": payment,
    "Type": type,
    "Amount": amount,
    "Date": date,
    "Remarks": remarks,
    "CompanyId": companyId,
    "Cguid": cguid,
  };
}
