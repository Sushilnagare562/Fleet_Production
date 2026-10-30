import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/driver.dart';
import '../../providers/admin_provider.dart';
import '../../providers/earning_provider.dart';

/// Lets an admin create an earning record for a driver — a base amount for
/// a trip/period, plus optional bonus and deduction. This is what actually
/// "activates" the Earnings tab: without it there was no way to get an
/// earning into the system for admins to mark paid.
class AdminAddEarningScreen extends StatefulWidget {
  const AdminAddEarningScreen({super.key});

  @override
  State<AdminAddEarningScreen> createState() => _AdminAddEarningScreenState();
}

class _AdminAddEarningScreenState extends State<AdminAddEarningScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseController = TextEditingController();
  final _bonusController = TextEditingController();
  final _deductionController = TextEditingController();
  Driver? _selectedDriver;
  bool _submitting = false;

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
    _baseController.dispose();
    _bonusController.dispose();
    _deductionController.dispose();
    super.dispose();
  }

  double get _total {
    final base = double.tryParse(_baseController.text) ?? 0;
    final bonus = double.tryParse(_bonusController.text) ?? 0;
    final deduction = double.tryParse(_deductionController.text) ?? 0;
    return base + bonus - deduction;
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

    final success = await context.read<EarningProvider>().createEarning(
      driverId: _selectedDriver!.id,
      baseAmount: double.parse(_baseController.text),
      bonus: _bonusController.text.trim().isEmpty ? null : double.tryParse(_bonusController.text),
      deduction: _deductionController.text.trim().isEmpty ? null : double.tryParse(_deductionController.text),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(context.read<EarningProvider>().error ?? context.l10n.couldNotSaveEarning),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addEarning)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
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
                    validator: (v) => v == null ? l10n.pleaseSelectDriver : null,
                    hint: admin.drivers.isEmpty
                        ? Text(l10n.loadingDrivers)
                        : Text(l10n.selectDriver),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _baseController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: l10n.baseAmount, prefixText: '₹ ', prefixIcon: const Icon(Icons.currency_rupee_rounded)),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.fieldRequired;
                      if (double.tryParse(v) == null || double.parse(v) <= 0) return l10n.enterValidAmount;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bonusController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: l10n.bonus, prefixText: '₹ ', prefixIcon: const Icon(Icons.add_circle_outline_rounded)),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deductionController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: l10n.deduction, prefixText: '₹ ', prefixIcon: const Icon(Icons.remove_circle_outline_rounded)),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppGradients.brand,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.totalPayout, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(
                          '₹${_total.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
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
                          : Text(l10n.saveEarning, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}