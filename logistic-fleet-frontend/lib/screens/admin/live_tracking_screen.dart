import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/gps_device.dart';
import '../../models/vehicle.dart';
import '../../providers/admin_provider.dart';
import '../../providers/live_tracking_provider.dart';

/// Localizes the model-derived device status label ('Running' / 'Idle' /
/// 'Parked' / else) without changing the underlying value the model reports.
String localizedDeviceStatus(AppLocalizations l10n, String label) {
  switch (label) {
    case 'Running':
      return l10n.devRunning;
    case 'Idle':
      return l10n.devIdle;
    case 'Parked':
      return l10n.devParked;
    default:
      return l10n.devOffline;
  }
}

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  GpsDevice? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiveTrackingProvider>().start();
      final admin = context.read<AdminProvider>();
      if (admin.vehicles.isEmpty) admin.loadVehicles();
    });
  }

  Color _statusColor(GpsDevice d) {
    switch (d.statusLabel) {
      case 'Running':
        return AppColors.success;
      case 'Idle':
        return AppColors.warning;
      case 'Parked':
        return context.fleet.textSecondary;
      default:
        return AppColors.danger;
    }
  }

  double _markerHue(GpsDevice d) {
    switch (d.statusLabel) {
      case 'Running':
        return BitmapDescriptor.hueGreen;
      case 'Idle':
        return BitmapDescriptor.hueOrange;
      case 'Parked':
        return BitmapDescriptor.hueAzure;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  void _showAddDeviceDialog() {
    showDialog(context: context, builder: (_) => const _AddDeviceDialog());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tracking = context.watch<LiveTrackingProvider>();
    final located = tracking.devices.where((d) => d.hasLocation).toList();

    final markers = located.map((d) {
      return Marker(
        markerId: MarkerId(d.deviceId),
        position: LatLng(d.lastLat!, d.lastLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(d)),
        infoWindow: InfoWindow(title: d.vehicleNumber ?? d.deviceId, snippet: localizedDeviceStatus(l10n, d.statusLabel)),
        onTap: () => setState(() => _selected = d),
      );
    }).toSet();

    return Scaffold(
      body: Stack(
        children: [
          located.isEmpty
              ? _EmptyMapState(loading: tracking.loading, hasDevices: tracking.devices.isNotEmpty)
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(located.first.lastLat!, located.first.lastLng!),
                    zoom: 12,
                  ),
                  markers: markers,
                  onMapCreated: (c) => _mapController = c,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onTap: (_) => setState(() => _selected = null),
                ),

          // Top status bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Back button — the map is a full-screen pushed route with no
                  // AppBar, so on mobile there was no way to return. This pops
                  // back to the dashboard.
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  _Pill(
                    icon: tracking.connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    label: tracking.connected ? l10n.live : l10n.reconnecting,
                    color: tracking.connected ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _Pill(
                    icon: Icons.local_shipping_rounded,
                    label: '${tracking.onlineCount}/${tracking.devices.length} ${l10n.online}',
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  _CircleButton(icon: Icons.add_location_alt_rounded, onTap: _showAddDeviceDialog),
                ],
              ),
            ),
          ),

          if (_selected != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: _DeviceInfoCard(
                device: _selected!,
                statusColor: _statusColor(_selected!),
                onClose: () => setState(() => _selected = null),
                onRecenter: () {
                  if (_selected!.hasLocation && _mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(LatLng(_selected!.lastLat!, _selected!.lastLng!), 15),
                    );
                  }
                },
                onRemove: () async {
                  await tracking.removeDevice(_selected!.id);
                  setState(() => _selected = null);
                },
              ),
            ),
        ],
      ),
      floatingActionButton: located.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _showAddDeviceDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.fleet.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.fleet.surface,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: AppShadows.soft),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _EmptyMapState extends StatelessWidget {
  final bool loading;
  final bool hasDevices;

  const _EmptyMapState({required this.loading, required this.hasDevices});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      color: context.fleet.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const CircularProgressIndicator()
              else ...[
                Icon(Icons.satellite_alt_outlined, size: 56, color: context.fleet.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  hasDevices ? l10n.waitingGps : l10n.noGpsDevices,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  hasDevices ? l10n.gpsRegisteredNoLoc : l10n.tapPlusLinkGps,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.fleet.textSecondary, fontSize: 12.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  final GpsDevice device;
  final Color statusColor;
  final VoidCallback onClose;
  final VoidCallback onRecenter;
  final VoidCallback onRemove;

  const _DeviceInfoCard({
    required this.device,
    required this.statusColor,
    required this.onClose,
    required this.onRecenter,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.fleet.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.tint(statusColor),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.local_shipping_rounded, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.vehicleNumber ?? device.deviceId,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(device.driverName ?? l10n.unassigned,
                        style: TextStyle(color: context.fleet.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(localizedDeviceStatus(l10n, device.statusLabel),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11)),
              ),
              IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: onClose),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(icon: Icons.speed_rounded, label: l10n.speed,
                  value: '${device.lastSpeedKmh?.toStringAsFixed(0) ?? '-'} km/h'),
              _Metric(icon: Icons.local_gas_station_rounded, label: l10n.fuel,
                  value: '${device.lastFuelPercent?.toStringAsFixed(0) ?? '-'}%'),
              _Metric(icon: Icons.access_time_rounded, label: l10n.updated,
                  value: device.lastSeenAt != null ? _timeAgo(device.lastSeenAt!) : '-'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRecenter,
                  icon: const Icon(Icons.my_location_rounded, size: 16),
                  label: Text(l10n.recenter),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                onPressed: onRemove,
                tooltip: l10n.unlinkDevice,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Metric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          Text(label, style: TextStyle(color: context.fleet.textSecondary, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _AddDeviceDialog extends StatefulWidget {
  const _AddDeviceDialog();

  @override
  State<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<_AddDeviceDialog> {
  final _deviceIdController = TextEditingController();
  Vehicle? _selectedVehicle;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_deviceIdController.text.trim().isEmpty || _selectedVehicle == null) {
      setState(() => _error = context.l10n.enterDeviceIdVehicle);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<LiveTrackingProvider>().addDevice(
            deviceId: _deviceIdController.text.trim(),
            vehicleId: _selectedVehicle!.id,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vehicles = context.watch<AdminProvider>().vehicles;

    return AlertDialog(
      title: Text(l10n.addGpsDevice),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _deviceIdController,
            decoration: InputDecoration(
              labelText: l10n.deviceId,
              hintText: l10n.deviceIdHint,
              prefixIcon: const Icon(Icons.sensors_rounded),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<Vehicle>(
            isDense: true,
            itemHeight: null,
            menuMaxHeight: 320,
            initialValue: _selectedVehicle,
            decoration: InputDecoration(labelText: l10n.vehicle, prefixIcon: const Icon(Icons.local_shipping_outlined)),
            items: vehicles
                .map((v) => DropdownMenuItem(value: v, child: Text(v.vehicleNumber, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _selectedVehicle = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n.add),
        ),
      ],
    );
  }
}
