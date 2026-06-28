import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:bantay_eskwela/features/guidance/domain/violation_model.dart';
import 'package:bantay_eskwela/core/services/file_saver.dart';

/// Builds an .xlsx file of all [violations] and saves/downloads it.
///
/// [liveGradeSection] optionally maps a studentId to the student's current
/// grade & section so the export reflects up-to-date student data instead of
/// the snapshot stored on each violation. Falls back to the stored values when
/// a student isn't found.
Future<void> exportViolationsToExcel(
  List<ViolationModel> violations, {
  Map<String, (String grade, String section)>? liveGradeSection,
}) async {
  final excel = Excel.createExcel();
  final sheet = excel['Violations'];
  // Drop the auto-created default sheet so only "Violations" remains.
  if (excel.sheets.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }

  // Header row
  const headers = [
    'Student Name',
    'Grade',
    'Section',
    'Violation Type',
    'Severity',
    'Description',
    'Action Taken',
    'Date of Incident',
    'Recorded By',
  ];
  sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

  // Data rows
  final df = DateFormat('yyyy-MM-dd');
  for (final v in violations) {
    final live = liveGradeSection?[v.studentId];
    final grade = live?.$1 ?? v.gradeLevel;
    final section = live?.$2 ?? v.section;
    sheet.appendRow([
      TextCellValue(v.studentName),
      TextCellValue(grade),
      TextCellValue(section),
      TextCellValue(v.type),
      TextCellValue(v.severity.label),
      TextCellValue(v.description),
      TextCellValue(v.actionTaken.trim().isEmpty ? 'Pending' : v.actionTaken),
      TextCellValue(df.format(v.dateOfIncident)),
      TextCellValue(v.recordedByName),
    ]);
  }

  final encoded = excel.encode();
  if (encoded == null) return;

  final fileName =
      'violations_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
  await saveFile(
    bytes: Uint8List.fromList(encoded),
    fileName: fileName,
    mimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
}
