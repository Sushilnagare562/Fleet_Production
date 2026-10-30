import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../providers/earning_provider.dart';
import '../../providers/expense_provider.dart';
import 'admin_add_earning_screen.dart';
import 'admin_add_expense_screen.dart';

class AdminExpensesScreen extends StatefulWidget {
  const AdminExpensesScreen({super.key});

  @override
  State<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Rebuild so the FAB swaps between "Add expense" and "Add earning".
      if (!_tabController.indexIsChanging) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadAllExpenses();
      context.read<EarningProvider>().loadAllEarnings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminAddExpenseScreen()),
    );
    if (added == true && mounted) {
      context.read<ExpenseProvider>().loadAllExpenses();
    }
  }

  Future<void> _addEarning() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminAddEarningScreen()),
    );
    if (added == true && mounted) {
      context.read<EarningProvider>().loadAllEarnings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.approvals),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: l10n.expenses), Tab(text: l10n.earnings)],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tabController.index == 0 ? _addExpense : _addEarning,
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0 ? l10n.addExpense : l10n.addEarning),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ExpenseApprovalTab(), _EarningsPayoutTab()],
      ),
    );
  }
}

class _ExpenseApprovalTab extends StatelessWidget {
  const _ExpenseApprovalTab();

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'APPROVED':
        return l10n.expApproved;
      case 'REJECTED':
        return l10n.expRejected;
      default:
        return l10n.expPending;
    }
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'FUEL':
        return Icons.local_gas_station_rounded;
      case 'TOLL':
        return Icons.toll_rounded;
      case 'FOOD':
        return Icons.restaurant_rounded;
      case 'MAINTENANCE':
        return Icons.build_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expenseProvider = context.watch<ExpenseProvider>();
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final pending = expenseProvider.allExpenses.where((e) => e.status == 'PENDING');
    final pendingTotal = pending.fold<double>(0, (sum, e) => sum + e.amount);

    return RefreshIndicator(
      onRefresh: () => context.read<ExpenseProvider>().loadAllExpenses(),
      child: expenseProvider.loading && expenseProvider.allExpenses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppShadows.brand,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.awaitingReview, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                          const SizedBox(height: 4),
                          Text('${pending.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(l10n.pendingValue, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                          const SizedBox(height: 4),
                          Text(currency.format(pendingTotal),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (expenseProvider.allExpenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 44, color: context.fleet.textSecondary.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(l10n.noExpensesSubmitted,
                              style: TextStyle(color: context.fleet.textSecondary)),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(l10n.useAddExpenseHint,
                              style: TextStyle(color: context.fleet.textSecondary.withOpacity(0.7), fontSize: 12)),
                        ),
                      ],
                    ),
                  )
                else
                  ...expenseProvider.allExpenses.map((expense) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.tint(AppColors.primary),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(_iconFor(expense.category), size: 16, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(expense.driverName ?? l10n.driver,
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(expense.status).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(_statusLabel(l10n, expense.status),
                                        style: TextStyle(
                                            color: _statusColor(expense.status), fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('${l10n.expenseCategory(expense.category)} • ${DateFormat('MMM d, y').format(expense.expenseDate)}',
                                  style: TextStyle(color: context.fleet.textSecondary, fontSize: 12)),
                              if (expense.description != null) ...[
                                const SizedBox(height: 4),
                                Text(expense.description!),
                              ],
                              const SizedBox(height: 10),
                              Text(currency.format(expense.amount),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                              if (expense.status == 'PENDING') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                                        onPressed: () =>
                                            context.read<ExpenseProvider>().reviewExpense(expense.id!, 'REJECTED'),
                                        child: Text(l10n.reject),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            context.read<ExpenseProvider>().reviewExpense(expense.id!, 'APPROVED'),
                                        child: Text(l10n.approve),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}

class _EarningsPayoutTab extends StatelessWidget {
  const _EarningsPayoutTab();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final earningProvider = context.watch<EarningProvider>();
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final pending = earningProvider.allEarnings.where((e) => e.status != 'PAID');
    final paidTotal =
        earningProvider.allEarnings.where((e) => e.status == 'PAID').fold<double>(0, (sum, e) => sum + e.totalAmount);
    final pendingTotal = pending.fold<double>(0, (sum, e) => sum + e.totalAmount);

    return RefreshIndicator(
      onRefresh: () => context.read<EarningProvider>().loadAllEarnings(),
      child: earningProvider.loading && earningProvider.allEarnings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MiniSummary(
                        label: l10n.pendingPayout,
                        value: currency.format(pendingTotal),
                        color: AppColors.warning,
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniSummary(
                        label: l10n.paidOut,
                        value: currency.format(paidTotal),
                        color: AppColors.success,
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (earningProvider.allEarnings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 44, color: context.fleet.textSecondary.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(l10n.noEarningsRecorded, style: TextStyle(color: context.fleet.textSecondary)),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(l10n.useAddEarningHint,
                              style: TextStyle(color: context.fleet.textSecondary.withOpacity(0.7), fontSize: 12)),
                        ),
                      ],
                    ),
                  )
                else
                  ...earningProvider.allEarnings.map((earning) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                (earning.status == 'PAID' ? AppColors.success : AppColors.warning).withOpacity(0.12),
                            child: Icon(earning.status == 'PAID' ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                color: earning.status == 'PAID' ? AppColors.success : AppColors.warning, size: 20),
                          ),
                          title: Text(earning.driverName ?? l10n.driver, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(currency.format(earning.totalAmount)),
                          trailing: earning.status == 'PAID'
                              ? Text(l10n.paid, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700))
                              : TextButton(
                                  onPressed: () => context.read<EarningProvider>().markPaid(earning.id),
                                  child: Text(l10n.markPaid),
                                ),
                        ),
                      )),
              ],
            ),
    );
  }
}

class _MiniSummary extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniSummary({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.fleet.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.fleet.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(gradient: AppGradients.tint(color), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11.5, color: context.fleet.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
