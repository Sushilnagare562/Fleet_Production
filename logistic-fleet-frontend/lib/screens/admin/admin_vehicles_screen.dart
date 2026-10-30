import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import 'add_vehicle_screen.dart';

class AdminVehiclesScreen extends StatefulWidget {
  const AdminVehiclesScreen({super.key});

  @override
  State<AdminVehiclesScreen> createState() => _AdminVehiclesScreenState();
}

class _AdminVehiclesScreenState extends State<AdminVehiclesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadVehicles();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'MAINTENANCE':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'TRUCK':
        return Icons.local_shipping;
      case 'VAN':
        return Icons.airport_shuttle;
      case 'BIKE':
        return Icons.two_wheeler;
      case 'CAR':
        return Icons.directions_car;
      default:
        return Icons.commute;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navFleet)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
          );
          if (added == true && mounted) context.read<AdminProvider>().loadVehicles();
        },
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addVehicle),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadVehicles(),
        child: admin.vehicles.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(context.l10n.noVehiclesYet, style: TextStyle(color: context.fleet.textSecondary)),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: admin.vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final vehicle = admin.vehicles[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Icon(_typeIcon(vehicle.type), color: AppColors.primary, size: 20),
                      ),
                      title: Text(vehicle.vehicleNumber),
                      subtitle: Text(
                        '${vehicle.model ?? vehicle.type}'
                        '${vehicle.assignedDriverName != null ? ' • ${vehicle.assignedDriverName}' : ' • ${context.l10n.unassigned}'}',
                      ),
                      trailing: DropdownButton<String>(
                        value: vehicle.status,
                        underline: const SizedBox(),
                        isDense: true,
                        itemHeight: null,
                        items: ['ACTIVE', 'MAINTENANCE', 'INACTIVE']
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(context.l10n.vehicleStatus(s), style: TextStyle(fontSize: 12, color: _statusColor(s))),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            context.read<AdminProvider>().updateVehicleStatus(vehicle.id, value);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
