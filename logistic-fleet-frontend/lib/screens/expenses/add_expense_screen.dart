import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'FUEL';
  DateTime _date = DateTime.now();
  bool _submitting = false;

  final _categories = const ['FUEL', 'TOLL', 'FOOD', 'MAINTENANCE', 'OTHER'];

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
    setState(() => _submitting = true);

    final expense = Expense(
      category: _category,
      amount: double.parse(_amountController.text),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      expenseDate: _date,
    );

    final success = await context.read<ExpenseProvider>().addExpense(expense);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.couldNotSaveExpense)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addExpense)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                isDense: true,
                itemHeight: null,
                menuMaxHeight: 320,
                value: _category,
                decoration: InputDecoration(labelText: l10n.categoryLabel),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(l10n.expenseCategory(c))))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.amountLabel, prefixText: '₹ '),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.fieldRequired;
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return l10n.enterValidAmount;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: l10n.description),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.date),
                subtitle: Text(DateFormat('MMM d, y').format(_date)),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.saveExpense),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
