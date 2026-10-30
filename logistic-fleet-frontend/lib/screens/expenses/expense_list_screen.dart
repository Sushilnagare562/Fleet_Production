import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../providers/expense_provider.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadMyExpenses();
    });
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'FUEL':
        return Icons.local_gas_station;
      case 'TOLL':
        return Icons.toll;
      case 'FOOD':
        return Icons.restaurant;
      case 'MAINTENANCE':
        return Icons.build;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final l10n = context.l10n;
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          if (added == true && mounted) {
            context.read<ExpenseProvider>().loadMyExpenses();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpense),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ExpenseProvider>().loadMyExpenses(),
        child: expenseProvider.loading && expenseProvider.expenses.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppGradients.brand,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppShadows.brand,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.thisMonth,
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(
                          currency.format(expenseProvider.totalThisMonth),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (expenseProvider.expenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(l10n.noExpensesLogged,
                            style: TextStyle(color: context.fleet.textSecondary)),
                      ),
                    )
                  else
                    ...expenseProvider.expenses.map((expense) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: AppGradients.tint(AppColors.primary),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_iconFor(expense.category), color: AppColors.primary, size: 20),
                            ),
                            title: Text(l10n.expenseCategory(expense.category)),
                            subtitle: Text(
                              '${DateFormat('MMM d, y').format(expense.expenseDate)}'
                              '${expense.description != null ? ' • ${expense.description}' : ''}',
                            ),
                            trailing: Text(
                              currency.format(expense.amount),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        )),
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }
}
