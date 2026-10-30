import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/driver.dart';
import '../../models/expense.dart';
import '../../providers/admin_provider.dart';
import '../../providers/expense_provider.dart';

/// Lets an admin log an expense on behalf of a driver — e.g. entering a
/// paper fuel receipt handed in at the depot. Saved as already approved.
class AdminAddExpenseScreen extends StatefulWidget {
  const AdminAddExpenseScreen({super.key});

  @override
  State<AdminAddExpenseScreen> createState() => _AdminAddExpenseScreenState();
}

class _AdminAddExpenseScreenState extends State<AdminAddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'FUEL';
  DateTime _date = DateTime.now();
  Driver? _selectedDriver;
  bool _submitting = false;

  final _categories = const ['FUEL', 'TOLL', 'FOOD', 'MAINTENANCE', 'OTHER'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      if (admin.drivers.isEmpty) admin.loadDrivers();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseSelectDriver)),
      );
      return;
    }

    setState(() => _submitting = true);

    final expense = Expense(
      category: _category,
      amount: double.parse(_amountController.text),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      expenseDate: _date,
    );

    final success = await context.read<ExpenseProvider>().addExpenseForDriver(_selectedDriver!.id, expense);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(context.read<ExpenseProvider>().error ?? context.l10n.couldNotSaveExpense),
        ),
      );
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
    final admin = context.watch<AdminProvider>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addExpense)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: AppGradients.tint(AppColors.primary),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.adminExpenseApprovedNote,
                        style: TextStyle(fontSize: 12.5, color: AppColors.primaryDark.withOpacity(0.9)),
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButtonFormField<Driver>(
                isDense: true,
                itemHeight: null,
                menuMaxHeight: 320,
                value: _selectedDriver,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.driver, prefixIcon: const Icon(Icons.person_outline_rounded)),
                items: admin.drivers
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.name, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDriver = v),
                validator: (v) => v == null ? l10n.selectDriver : null,
                hint: admin.drivers.isEmpty
                    ? Text(l10n.loadingDrivers)
                    : Text(l10n.selectDriver),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isDense: true,
                itemHeight: null,
                menuMaxHeight: 320,
                value: _category,
                decoration: InputDecoration(labelText: l10n.categoryLabel, prefixIcon: Icon(_iconFor(_category))),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(l10n.expenseCategory(c))))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.amountLabel, prefixText: '₹ ', prefixIcon: const Icon(Icons.currency_rupee_rounded)),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.fieldRequired;
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return l10n.enterValidAmount;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: l10n.description, prefixIcon: const Icon(Icons.notes_rounded)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.date),
                subtitle: Text(DateFormat('MMM d, y').format(_date)),
                trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.saveExpense, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
