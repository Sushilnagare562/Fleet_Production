import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api_client.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _RecentReport {
  final ReportType type;
  final ReportPeriod period;
  final DownloadedReport report;
  final DateTime downloadedAt;

  _RecentReport({required this.type, required this.period, required this.report, required this.downloadedAt});
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _reportService = ReportService();
  final _searchController = TextEditingController();

  bool _showingList = true; // true: "Reports List" tab, false: "Recent Reports" tab
  String _query = '';
  ReportType? _generatingType;
  final Map<ReportType, DateTime> _lastGenerated = {};
  final List<_RecentReport> _recent = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReportType> get _filteredTypes {
    if (_query.trim().isEmpty) return ReportType.values.toList();
    final q = _query.trim().toLowerCase();
    return ReportType.values.where((t) => context.l10n.reportTypeLabel(t.name).toLowerCase().contains(q)).toList();
  }

  List<_RecentReport> get _filteredRecent {
    if (_query.trim().isEmpty) return _recent;
    final q = _query.trim().toLowerCase();
    return _recent.where((r) => context.l10n.reportTypeLabel(r.type.name).toLowerCase().contains(q)).toList();
  }

  Future<void> _onGenerateTap(ReportType type) async {
    if (type == ReportType.vehicles) {
      // Point-in-time snapshot - no period needed.
      await _download(type, ReportPeriod.weekly);
      return;
    }

    final period = await showModalBottomSheet<ReportPeriod>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PeriodPickerSheet(reportLabel: context.l10n.reportTypeLabel(type.name)),
    );
    if (period != null) {
      await _download(type, period);
    }
  }

  Future<void> _download(ReportType type, ReportPeriod period) async {
    setState(() => _generatingType = type);
    try {
      final report = await _reportService.downloadReport(type: type, period: period);
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _lastGenerated[type] = now;
        _recent.insert(0, _RecentReport(type: type, period: period, report: report, downloadedAt: now));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text(
            report.canOpenOrShare ? '${context.l10n.reportTypeLabel(type.name)} ${context.l10n.reportGenerated}' : '${context.l10n.reportTypeLabel(type.name)} ${context.l10n.reportDownloaded}',
          ),
          action: report.canOpenOrShare
              ? SnackBarAction(
                  label: context.l10n.openLabel.toUpperCase(),
                  textColor: Colors.white,
                  onPressed: () => OpenFilex.open(report.localPath!),
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(ApiClient.errorMessage(e)),
        ),
      );
    } finally {
      if (mounted) setState(() => _generatingType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.reports)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                _TabToggle(
                  showingList: _showingList,
                  onChanged: (showList) => setState(() => _showingList = showList),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: context.l10n.typeToSearch,
                    prefixIcon: Icon(Icons.search_rounded, color: context.fleet.textSecondary),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: context.fleet.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _showingList ? _buildReportsList() : _buildRecentReports(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    final types = _filteredTypes;
    if (types.isEmpty) {
      return _EmptyState(icon: Icons.search_off_rounded, message: context.l10n.noReportsMatch);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: types.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final type = types[index];
        final lastGen = _lastGenerated[type];
        final isGenerating = _generatingType == type;
        return _ReportCard(
          type: type,
          lastGeneratedAt: lastGen,
          generating: isGenerating,
          onGenerate: _generatingType != null ? null : () => _onGenerateTap(type),
        );
      },
    );
  }

  Widget _buildRecentReports() {
    final recent = _filteredRecent;
    if (recent.isEmpty) {
      return _EmptyState(
        icon: Icons.description_outlined,
        message: context.l10n.noReportsYet,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: recent.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = recent[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppGradients.tint(AppColors.success),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_outlined, color: AppColors.success, size: 20),
            ),
            title: Text(context.l10n.reportTypeLabel(r.type.name), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(
              '${r.type == ReportType.vehicles ? context.l10n.snapshot : context.l10n.reportPeriodLabel(r.period.name)} • '
              '${DateFormat('MMM d, h:mm a').format(r.downloadedAt)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: r.report.canOpenOrShare
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded, size: 20),
                        tooltip: context.l10n.openLabel,
                        onPressed: () => OpenFilex.open(r.report.localPath!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined, size: 20),
                        tooltip: context.l10n.shareLabel,
                        onPressed: () =>
                            Share.shareXFiles([XFile(r.report.localPath!)], text: '${context.l10n.reportTypeLabel(r.type.name)} ${context.l10n.reportWord}'),
                      ),
                    ],
                  )
                // Web: the browser already saved the file to Downloads directly -
                // there's no app-local file left for us to open or share.
                : Tooltip(
                    message: context.l10n.savedToDownloads,
                    child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                  ),
          ),
        );
      },
    );
  }
}

/// Pill-shaped two-way toggle matching the reference dashboard: a filled
/// teal pill for the active tab, plain text for the inactive one.
class _TabToggle extends StatelessWidget {
  final bool showingList;
  final ValueChanged<bool> onChanged;

  const _TabToggle({required this.showingList, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.fleet.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(child: _TabPill(label: context.l10n.tabReportsList, selected: showingList, onTap: () => onChanged(true))),
          Expanded(child: _TabPill(label: context.l10n.tabRecentReports, selected: !showingList, onTap: () => onChanged(false))),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.brand : null,
          borderRadius: BorderRadius.circular(26),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: selected ? Colors.white : context.fleet.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// One card per report type, matching the reference layout: bold title with
/// an info tooltip, a pill "Generate" button, and a "Last Generated on" line.
class _ReportCard extends StatelessWidget {
  final ReportType type;
  final DateTime? lastGeneratedAt;
  final bool generating;
  final VoidCallback? onGenerate;

  const _ReportCard({
    required this.type,
    required this.lastGeneratedAt,
    required this.generating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          context.l10n.reportTypeLabel(type.name),
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: context.fleet.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: context.l10n.reportTypeDesc(type.name),
                        triggerMode: TooltipTriggerMode.tap,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(Icons.info_outline_rounded, size: 17, color: context.fleet.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lastGeneratedAt == null
                        ? '${context.l10n.lastGeneratedOn}: ${context.l10n.notGeneratedYet}'
                        : '${context.l10n.lastGeneratedOn}: ${DateFormat('MMM d, yyyy · h:mm a').format(lastGeneratedAt!)}',
                    style: TextStyle(fontSize: 12, color: context.fleet.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: onGenerate,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: generating
                    ? const SizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : Text(context.l10n.generate, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet asking which time window to generate the report for, shown
/// when tapping "Generate" on a report type that isn't a point-in-time
/// snapshot.
class _PeriodPickerSheet extends StatelessWidget {
  final String reportLabel;
  const _PeriodPickerSheet({required this.reportLabel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: context.fleet.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${context.l10n.generate} $reportLabel', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(context.l10n.chooseTimePeriod, style: TextStyle(color: context.fleet.textSecondary, fontSize: 12.5)),
            const SizedBox(height: 18),
            ...ReportPeriod.values.map(
              (period) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(period),
                    child: Text(context.l10n.reportPeriodLabel(period.name), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: context.fleet.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.fleet.textSecondary)),
          ],
        ),
      ),
    );
  }
}
