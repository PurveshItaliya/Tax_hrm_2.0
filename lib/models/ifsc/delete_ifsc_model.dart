// To parse this JSON data, do
//
//     final dleteMyTask = dleteMyTaskFromJson(jsonString);

import 'dart:convert';

DleteMyTask dleteMyTaskFromJson(String str) => DleteMyTask.fromJson(json.decode(str));

String dleteMyTaskToJson(DleteMyTask data) => json.encode(data.toJson());

class DleteMyTask {
    bool? success;
    String? data;

    DleteMyTask({
        this.success,
        this.data,
    });

    factory DleteMyTask.fromJson(Map<String, dynamic> json) => DleteMyTask(
        success: json["Success"],
        data: json["data"],
    );

    Map<String, dynamic> toJson() => {
        "Success": success,
        "data": data,
    };
}
