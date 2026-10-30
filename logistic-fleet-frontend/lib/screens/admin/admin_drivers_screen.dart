import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/driver.dart';
import '../../providers/admin_provider.dart';
import 'add_driver_screen.dart';

class AdminDriversScreen extends StatefulWidget {
  const AdminDriversScreen({super.key});

  @override
  State<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends State<AdminDriversScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDrivers();
    });
  }

  Future<void> _handleMenuAction(BuildContext context, Driver driver, String action) async {
    final admin = context.read<AdminProvider>();

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.deleteDriverConfirm),
          content: Text('${driver.name} ${context.l10n.driverDeleteExplain}'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(context.l10n.cancel)),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.delete, style: const TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      final success = await admin.deleteDriver(driver.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.success : AppColors.danger,
          content: Text(success ? '${driver.name} ${context.l10n.wasDeleted}' : (admin.error ?? context.l10n.couldNotDeleteDriver)),
        ),
      );
      return;
    }

    // action is 'ON_LEAVE' or 'ACTIVE'
    final success = await admin.setDriverStatus(driver.id, action);
    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(admin.error ?? context.l10n.couldNotUpdateDriverStatus),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navDrivers)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddDriverScreen()),
          );
          if (added == true && mounted) context.read<AdminProvider>().loadDrivers();
        },
        icon: const Icon(Icons.person_add),
        label: Text(context.l10n.addDriver),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadDrivers(),
        child: admin.drivers.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(context.l10n.noDriversYet, style: TextStyle(color: context.fleet.textSecondary)),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: admin.drivers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final driver = admin.drivers[index];
                  final statusColor = driver.isOnLeave ? AppColors.warning : AppColors.success;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.12),
                        child: Text(
                          driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(driver.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${driver.phone}${driver.vehicleNumber != null ? ' • ${driver.vehicleNumber}' : ''}'),
                          if (driver.isOnLeave)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  context.l10n.onLeave,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
                                ),
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: driver.isOnLeave,
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (action) => _handleMenuAction(context, driver, action),
                        itemBuilder: (context) => [
                          if (driver.isOnLeave)
                            PopupMenuItem(
                              value: 'ACTIVE',
                              child: ListTile(
                                leading: const Icon(Icons.play_circle_outline, color: AppColors.success),
                                title: Text(context.l10n.markAsActive),
                                contentPadding: EdgeInsets.zero,
                              ),
                            )
                          else
                            PopupMenuItem(
                              value: 'ON_LEAVE',
                              child: ListTile(
                                leading: const Icon(Icons.pause_circle_outline, color: AppColors.warning),
                                title: Text(context.l10n.markAsOnLeave),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                              title: Text(context.l10n.deleteDriver, style: const TextStyle(color: AppColors.danger)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
