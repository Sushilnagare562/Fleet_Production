import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/api_client.dart';
import 'report_file_saver.dart';

/// The four report/dashboard types admins can export, and the three
/// windows (weekly/monthly/yearly) each supports — mirrors
/// `com.logisticfleet.dto.ReportPeriod` and the `/api/admin/reports/*` endpoints
/// on the backend.
enum ReportType { trips, expenses, earnings, vehicles }

enum ReportPeriod { weekly, monthly, yearly }

extension ReportTypeX on ReportType {
  String get path => switch (this) {
        ReportType.trips => 'trips',
        ReportType.expenses => 'expenses',
        ReportType.earnings => 'earnings',
        ReportType.vehicles => 'vehicles',
      };

  String get label => switch (this) {
        ReportType.trips => 'Trips per Truck',
        ReportType.expenses => 'Expenses',
        ReportType.earnings => 'Driver Earnings',
        ReportType.vehicles => 'Fleet Status',
      };

  String get description => switch (this) {
        ReportType.trips => 'Every trip with driver, vehicle, route & distance',
        ReportType.expenses => 'Driver expense ledger with totals by status',
        ReportType.earnings => 'Base, bonus, deduction & payout per driver',
        ReportType.vehicles => 'Point-in-time snapshot of the whole fleet',
      };
}

extension ReportPeriodX on ReportPeriod {
  String get apiValue => name.toUpperCase();
  String get label => switch (this) {
        ReportPeriod.weekly => 'This Week',
        ReportPeriod.monthly => 'This Month',
        ReportPeriod.yearly => 'This Year',
      };
}

/// Result of a report download. On Android/iOS/desktop [localPath] points
/// to the saved .xlsx file so it can be opened or shared. On Web there is
/// no app-local filesystem — the browser handles the download directly —
/// so [localPath] is null there; [canOpenOrShare] reflects that.
class DownloadedReport {
  final String fileName;
  final String? localPath;

  DownloadedReport({required this.fileName, required this.localPath});

  bool get canOpenOrShare => localPath != null;
}

class ReportService {
  /// Downloads the requested report as bytes, then saves it the right way
  /// for the current platform: written to the app's documents directory on
  /// Android/iOS/desktop, or handed to the browser as a download on Web.
  Future<DownloadedReport> downloadReport({required ReportType type, required ReportPeriod period}) async {
    final query = type == ReportType.vehicles ? null : {'period': period.apiValue};

    final response = await ApiClient.instance.dio.get<List<int>>(
      '/admin/reports/${type.path}',
      queryParameters: query,
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = Uint8List.fromList(response.data!);
    final fileName = _fileNameFrom(response, type, period);
    final localPath = await saveReportBytes(bytes, fileName);

    return DownloadedReport(fileName: fileName, localPath: localPath);
  }

  String _fileNameFrom(Response response, ReportType type, ReportPeriod period) {
    final disposition = response.headers.value('content-disposition');
    if (disposition != null) {
      final match = RegExp('filename="?([^";]+)"?').firstMatch(disposition);
      if (match != null) return match.group(1)!;
    }
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final suffix = type == ReportType.vehicles ? '' : '-${period.name}';
    return 'logisticfleet-${type.path}$suffix-$stamp.xlsx';
  }
}
