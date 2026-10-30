import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../providers/earning_provider.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EarningProvider>().loadMyEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final earningProvider = context.watch<EarningProvider>();
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final summary = earningProvider.summary;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.earnings)),
      body: RefreshIndicator(
        onRefresh: () => context.read<EarningProvider>().loadMyEarnings(),
        child: earningProvider.loading && summary == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (summary != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppGradients.brand,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppShadows.brand,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.totalEarned,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            currency.format(summary.totalEarned),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text('${summary.tripCount} ${l10n.tripsWord}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryTile(
                            label: l10n.pending,
                            value: currency.format(summary.totalPending),
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryTile(
                            label: l10n.paid,
                            value: currency.format(summary.totalPaid),
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(l10n.history, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (earningProvider.earnings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(l10n.noEarningsRecorded,
                            style: TextStyle(color: context.fleet.textSecondary)),
                      ),
                    )
                  else
                    ...earningProvider.earnings.map((earning) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: AppGradients.tint(
                                    earning.status == 'PAID' ? AppColors.success : AppColors.warning),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                earning.status == 'PAID' ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                color: earning.status == 'PAID' ? AppColors.success : AppColors.warning,
                                size: 20,
                              ),
                            ),
                            title: Text(currency.format(earning.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              '${l10n.baseWord} ${currency.format(earning.baseAmount)}'
                              '${earning.bonus > 0 ? ' • ${l10n.bonusWord} ${currency.format(earning.bonus)}' : ''}'
                              '${earning.deduction > 0 ? ' • ${l10n.deductionWord} ${currency.format(earning.deduction)}' : ''}',
                            ),
                            trailing: Text(
                              l10n.earningStatus(earning.status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: earning.status == 'PAID' ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ),
                        )),
                ],
              ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, color: context.fleet.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
