import 'package:excel/excel.dart' hide Border;
import 'package:excel/excel.dart' as ex show Border, BorderStyle;

void main() {
  var excel = Excel.createExcel();
  
  Sheet s = excel['Test'];
  
  CellStyle headerStyle = CellStyle(
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    backgroundColorHex: ExcelColor.fromHexString('#1D976C'),
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
  );
  var cell = s.cell(CellIndex.indexByString("A1"));
  cell.value = TextCellValue("Header");
  cell.cellStyle = headerStyle;
  
  excel.save();
}
