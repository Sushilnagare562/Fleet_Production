import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Android / iOS / desktop: `dart:io` and `path_provider` both work here,
/// so the report is written into the app's documents directory and the
/// local path is returned so it can be opened (OpenFilex) or shared
/// (share_plus) afterwards.
Future<String?> saveReportBytes(Uint8List bytes, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
