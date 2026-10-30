import 'dart:typed_data';

/// Fallback implementation. Real platforms resolve to
/// [report_file_saver_web.dart] (Web) or [report_file_saver_io.dart]
/// (Android/iOS/desktop) instead — see report_file_saver.dart.
Future<String?> saveReportBytes(Uint8List bytes, String fileName) {
  throw UnsupportedError('Saving reports is not supported on this platform.');
}
