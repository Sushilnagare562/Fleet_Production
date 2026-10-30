/// Platform-specific report saving, selected at compile time.
///
/// `dart.library.html` is checked before `dart.library.io` on purpose: some
/// SDK versions expose a (non-functional) `dart:io` shim on Web too, so
/// checking `html` first is what guarantees the Web build actually gets
/// [report_file_saver_web.dart] instead of the `dart:io`/path_provider
/// version, which is exactly what was crashing report downloads on Web.
export 'report_file_saver_stub.dart'
    if (dart.library.html) 'report_file_saver_web.dart'
    if (dart.library.io) 'report_file_saver_io.dart';
