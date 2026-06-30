
import 'package:intl/intl.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/employee_master/pdf_csv_print_function.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// CSV file
Future<void> generateEmployeeCsvFile(List<Employeelists> getEmployeeList, title) async {
  List<List<dynamic>> rows = [];

  // Define the headers
  List<dynamic> row = [];
  row.add("No");
  row.add("First Name");
  row.add("Last Name");
  row.add("Email");
  row.add("DOB");
  row.add("DOJ");
  row.add("Gender");
  row.add("Mobile1");
  row.add("PAN");
  row.add("UserName");
  row.add("Password");
  row.add("Role");
  rows.add(row);

  // Add data rows
  for(int i = 0; i < getEmployeeList.length; i++) {
    row = [];
    row.add((i + 1).toString());
    row.add(getEmployeeList[i].firstName ?? '-');
    row.add(getEmployeeList[i].lastName ?? '-');
    row.add(getEmployeeList[i].email ?? '-');
    row.add(getEmployeeList[i].dOB == null ? 'No Date' : DateFormat('dd/MM/yyyy').format(DateTime.parse(getEmployeeList[i].dOB.toString().split("T").first)));
    row.add(getEmployeeList[i].dOJ == null ? 'No Date' : DateFormat('dd/MM/yyyy').format(DateTime.parse(getEmployeeList[i].dOJ.toString().split("T").first)));
    row.add(getEmployeeList[i].gender ?? '-');
    row.add(getEmployeeList[i].mobile1 ?? '-');
    row.add(getEmployeeList[i].pAN ?? '-');
    row.add(getEmployeeList[i].userName ?? '-');
    row.add(getEmployeeList[i].password ?? '-');
    row.add(getEmployeeList[i].role ?? '-');
    rows.add(row);
  }

  String employeeData = rows.map((row) => row.map((e) => '"$e"').join(",")).join("\n");

  downloadCSVDirectory(title: title, csvDataSave: employeeData);
}

/// Pdf and Print file
Future generateEmployeePrintFile({required List<Employeelists> getEmployeeList, length, title, type}) async {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (pw.Context context) {
        return [
          pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(selectedcurentcompany!.companyName.toString(),style: pw.TextStyle(fontSize: 20,fontWeight: pw.FontWeight.bold )),
                ),
                pw.SizedBox(
                    height: 10
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Record :-  $length', style: pw.TextStyle(fontSize: 15,color: PdfColors.black,fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(
                        height: 20
                    ),
                    pw.Text('$title List :- ', style: pw.TextStyle(fontSize: 15,color: PdfColors.black,fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(
                    height: 10
                ),
                pw.Container(
                  height: 30,
                  color: PdfColors.blue,
                  child: pw.Row(
                    children: [
                      pw.SizedBox(width: 40, child: pw.Text("No", style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),textAlign: pw.TextAlign.center),),
                      pw.SizedBox(width: 60, child: pw.Text("First Name", style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),textAlign: pw.TextAlign.center),),
                      pw.SizedBox(width: 60, child: pw.Text("Last Name", style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),textAlign: pw.TextAlign.center),),
                      pw.SizedBox(width: 80, child: pw.Text("Email", style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),textAlign: pw.TextAlign.center),),
                      pw.SizedBox(width: 60, child: pw.Text("DOB", style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),textAlign: pw.TextAlign.center),),
                      pw.SizedBox(width: 60, child: pw.Text("DOJ", style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),textAlign: pw.TextAlign.center),),
                      pw.SizedBox(width: 60, child: pw.Text("Gender", style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),textAlign: pw.TextAlign.center),),
                      pw.SizedBox(width: 60, child: pw.Text("Mobile1", style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),textAlign: pw.TextAlign.center),),
                      pw.SizedBox(width: 60, child: pw.Text("PAN", style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),textAlign: pw.TextAlign.center),),
                      pw.SizedBox(width: 60, child: pw.Text("UserName", style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),textAlign: pw.TextAlign.center),),
                      pw.SizedBox(width: 60, child: pw.Text("Password", style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),textAlign: pw.TextAlign.center),),
                      pw.SizedBox(width: 60, child: pw.Text("Role", style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),textAlign: pw.TextAlign.center),),
                    ],
                  ),
                ),
                for(int i =0; i < getEmployeeList.length; i++)
                  pw.Container(
                    height: 30,
                    color: i % 2 == 1 ? PdfColors.blue50 : PdfColors.white,
                    child: pw.Row(
                      children: [
                        pw.SizedBox(width: 40, child: pw.Text((i + 1).toString(), style: const pw.TextStyle(color: PdfColors.black, fontSize: 7),textAlign: pw.TextAlign.center),),
                        pw.SizedBox(width: 60, child: pw.Text(getEmployeeList[i].firstName ?? '-', style: const pw.TextStyle(color: PdfColors.black, fontSize: 7),textAlign: pw.TextAlign.center),),
                        pw.SizedBox(width: 60, child: pw.Text(getEmployeeList[i].lastName ?? '-', style: const pw.TextStyle(color: PdfColors.black, fontSize: 7),textAlign: pw.TextAlign.center),),
                        pw.SizedBox(width: 80, child: pw.Text(getEmployeeList[i].email ?? '-', style: const pw.TextStyle(color: PdfColors.black, fontSize: 7),textAlign: pw.TextAlign.center),),
                        pw.SizedBox(width: 60, child: pw.Text(getEmployeeList[i].dOB == null ? '-' : getEmployeeList[i].dOB.toString().split("T").first, style: const pw.TextStyle(color: PdfColors.black, fontSize: 7),textAlign: pw.TextAlign.center),),
                        pw.SizedBox(width: 60, child: pw.Text(getEmployeeList[i].dOJ == null ? '-' : getEmployeeList[i].dOJ.toString().split("T").first, style: const pw.TextStyle(color: PdfColors.black, fontSize: 7),textAlign: pw.TextAlign.center),),
                        pw.SizedBox(width: 60, child: pw.Text(getEmployeeList[i].gender ?? '-', style: const pw.TextStyle(color: PdfColors.black, fontSize: 7),textAlign: pw.TextAlign.center),),
                        pw.SizedBox(width: 60, child: pw.Text(getEmployeeList[i].mobile1 ?? '-', style: const pw.TextStyle(color: PdfColors.black, fontSize: 7),textAlign: pw.TextAlign.center),),
                        pw.SizedBox(width: 60, child: pw.Text(getEmployeeList[i].pAN ?? '-', style: const pw.TextStyle(color: PdfColors.black, fontSize: 7),textAlign: pw.TextAlign.center),),
                        pw.SizedBox(width: 60, child: pw.Text(getEmployeeList[i].userName ?? '-', style: const pw.TextStyle(color: PdfColors.black, fontSize: 7),textAlign: pw.TextAlign.center),),
                        pw.SizedBox(width: 60, child: pw.Text(getEmployeeList[i].password ?? '-', style: const pw.TextStyle(color: PdfColors.black, fontSize: 7),textAlign: pw.TextAlign.center),),
                        pw.SizedBox(width: 60, child: pw.Text(getEmployeeList[i].role ?? '-', style: const pw.TextStyle(color: PdfColors.black, fontSize: 7),textAlign: pw.TextAlign.center),),
                      ],
                    ),
                  ),
              ]
          ),
        ];
      },
    ),
  );

  if(type == 'Print') {
    // printLandScape(doc);
  } else if(type == 'PDF') {
    downloadDirectory(title: title, docs: await doc.save());
  }

  return doc.save();
}