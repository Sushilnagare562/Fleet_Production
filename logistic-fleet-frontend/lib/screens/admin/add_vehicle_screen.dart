import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/driver.dart';
import '../../providers/admin_provider.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _modelController = TextEditingController();
  final _capacityController = TextEditingController();
  String _type = 'TRUCK';
  Driver? _assignedDriver;
  bool _submitting = false;

  final _types = const ['TRUCK', 'VAN', 'BIKE', 'CAR', 'OTHER'];

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
    _numberController.dispose();
    _modelController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final success = await context.read<AdminProvider>().createVehicle(
          vehicleNumber: _numberController.text.trim(),
          type: _type,
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          capacityKg: _capacityController.text.trim().isEmpty
              ? null
              : double.tryParse(_capacityController.text.trim()),
          assignedDriverId: _assignedDriver?.id,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.couldNotAddVehicle)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addVehicle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _numberController,
                    decoration: InputDecoration(labelText: l10n.vehicleNumber),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isDense: true,
                    itemHeight: null,
                    menuMaxHeight: 320,
                    value: _type,
                    decoration: InputDecoration(labelText: l10n.type),
                    items: _types.map((t) => DropdownMenuItem(value: t, child: Text(l10n.vehicleType(t)))).toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modelController,
                    decoration: InputDecoration(labelText: l10n.modelOpt),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.capacityOpt),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Driver?>(
                    isDense: true,
                    itemHeight: null,
                    menuMaxHeight: 320,
                    value: _assignedDriver,
                    decoration: InputDecoration(labelText: l10n.assignToDriverOpt),
                    items: [
                      DropdownMenuItem<Driver?>(value: null, child: Text(l10n.unassigned)),
                      ...admin.drivers.map((d) => DropdownMenuItem(value: d, child: Text(d.name))),
                    ],
                    onChanged: (v) => setState(() => _assignedDriver = v),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(l10n.addVehicle),
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
