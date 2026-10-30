import 'dart:html' as html;
import 'dart:typed_data';

/// Web: `dart:io` and `path_provider`'s directory lookups don't exist in the
/// browser sandbox (there is no app-local filesystem), which is why the
/// report generation previously failed here. Instead, the bytes are handed
/// straight to the browser as a download via an object URL + a synthetic
/// anchor click — the standard way to trigger a "Save As" download from
/// in-memory bytes on Flutter Web.
///
/// There's no local file afterwards (the browser owns the download), so
/// this always returns null; callers use that to know Open/Share aren't
/// applicable on this platform.
Future<String?> saveReportBytes(Uint8List bytes, String fileName) async {
  const xlsxMimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  final blob = html.Blob([bytes], xlsxMimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  return null;
}
