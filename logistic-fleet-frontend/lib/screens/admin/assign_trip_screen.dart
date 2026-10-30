import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/driver.dart';
import '../../models/trip.dart';
import '../../models/vehicle.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/searchable_picker.dart';
import 'add_vehicle_screen.dart';
import 'location_picker_screen.dart';

/// Localizes a stop-type ENUM value (PICKUP/DELIVERY/WAYPOINT) for display.
/// The enum value itself is never altered.
String localizedStopType(AppLocalizations l10n, String type) {
  switch (type) {
    case 'PICKUP':
      return l10n.pickup;
    case 'DELIVERY':
      return l10n.delivery;
    case 'WAYPOINT':
      return l10n.waypoint;
    default:
      return type;
  }
}

class AssignTripScreen extends StatefulWidget {
  const AssignTripScreen({super.key});

  @override
  State<AssignTripScreen> createState() => _AssignTripScreenState();
}

class _AssignTripScreenState extends State<AssignTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _notesController = TextEditingController();

  Driver? _selectedDriver;
  Vehicle? _selectedVehicle;
  DateTime? _scheduledStart;
  DateTime? _scheduledEnd;
  bool _submitting = false;
  bool _optimizing = false;

  /// Coordinates picked on the map for origin/destination — null until the
  /// admin taps "Pick on map". Nothing here is ever typed as raw numbers.
  PickedLocation? _originLocation;
  PickedLocation? _destinationLocation;

  /// Extra stops beyond origin/destination (waypoints or additional pickups/deliveries).
  final List<RouteStop> _extraStops = [];

  /// Set once "Optimize route" succeeds — the visit order that will actually
  /// be submitted. Cleared whenever origin/destination/stops change, so a
  /// stale suggestion can never be sent silently.
  List<RouteStop>? _optimizedStops;
  double? _optimizedTotalKm;
  int? _optimizedEtaMinutes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      if (admin.drivers.isEmpty) admin.loadDrivers();
      if (admin.vehicles.isEmpty) admin.loadVehicles();
    });
    _originController.addListener(_invalidateOptimizedOrder);
    _destinationController.addListener(_invalidateOptimizedOrder);
  }

  void _invalidateOptimizedOrder() {
    if (_optimizedStops != null) {
      setState(() {
        _optimizedStops = null;
        _optimizedTotalKm = null;
        _optimizedEtaMinutes = null;
      });
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickOriginLocation() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _originLocation?.latitude,
          initialLng: _originLocation?.longitude,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _originLocation = picked;
      if (_originController.text.trim().isEmpty && picked.address != null) {
        _originController.text = picked.address!;
      }
      _optimizedStops = null;
      _optimizedTotalKm = null;
      _optimizedEtaMinutes = null;
    });
  }

  Future<void> _pickDestinationLocation() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _destinationLocation?.latitude,
          initialLng: _destinationLocation?.longitude,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _destinationLocation = picked;
      if (_destinationController.text.trim().isEmpty && picked.address != null) {
        _destinationController.text = picked.address!;
      }
      _optimizedStops = null;
      _optimizedTotalKm = null;
      _optimizedEtaMinutes = null;
    });
  }

  Future<void> _addStop() async {
    final result = await showDialog<RouteStop>(
      context: context,
      builder: (_) => const _AddStopDialog(),
    );
    if (result != null) {
      setState(() {
        _extraStops.add(result);
        _optimizedStops = null;
        _optimizedTotalKm = null;
        _optimizedEtaMinutes = null;
      });
    }
  }

  void _removeStop(int index) {
    setState(() {
      _extraStops.removeAt(index);
      _optimizedStops = null;
      _optimizedTotalKm = null;
      _optimizedEtaMinutes = null;
    });
  }

  Future<void> _optimizeRoute() async {
    if (_originController.text.trim().isEmpty || _destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterOriginDestFirst)),
      );
      return;
    }

    final stopsToOptimize = <RouteStop>[
      RouteStop(
        locationName: _originController.text.trim(),
        stopType: 'PICKUP',
        latitude: _originLocation?.latitude,
        longitude: _originLocation?.longitude,
        plannedTime: _scheduledStart,
      ),
      RouteStop(
        locationName: _destinationController.text.trim(),
        stopType: 'DELIVERY',
        latitude: _destinationLocation?.latitude,
        longitude: _destinationLocation?.longitude,
        plannedTime: _scheduledEnd,
      ),
      ..._extraStops,
    ];

    final withCoords = stopsToOptimize.where((s) => s.latitude != null && s.longitude != null).length;
    if (withCoords < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pickAMapLocation)),
      );
      return;
    }

    setState(() => _optimizing = true);
    final admin = context.read<AdminProvider>();
    final result = await admin.optimizeRoute(stops: stopsToOptimize);
    if (!mounted) return;
    setState(() => _optimizing = false);

    if (result == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(admin.error ?? context.l10n.couldNotOptimize)));
      return;
    }

    setState(() {
      _optimizedStops = result.orderedStops
          .map((o) => RouteStop(
                locationName: o.stop.locationName,
                latitude: o.stop.latitude,
                longitude: o.stop.longitude,
                stopType: o.stop.stopType,
                plannedTime: o.stop.plannedTime,
                sequenceNo: o.sequenceNo,
              ))
          .toList();
      _optimizedTotalKm = result.totalDistanceKm;
      _optimizedEtaMinutes = result.estimatedDurationMinutes;
      if (_distanceController.text.trim().isEmpty) {
        _distanceController.text = result.totalDistanceKm.toStringAsFixed(1);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseSelectDriver)),
      );
      return;
    }
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseSelectVehicle)),
      );
      return;
    }

    setState(() => _submitting = true);

    // Prefer the optimized order if one has been computed; otherwise fall
    // back to origin -> destination (+ any manually added stops, entered order).
    final routeStops = _optimizedStops ??
        [
          RouteStop(
            locationName: _originController.text.trim(),
            stopType: 'PICKUP',
            latitude: _originLocation?.latitude,
            longitude: _originLocation?.longitude,
            plannedTime: _scheduledStart,
          ),
          RouteStop(
            locationName: _destinationController.text.trim(),
            stopType: 'DELIVERY',
            latitude: _destinationLocation?.latitude,
            longitude: _destinationLocation?.longitude,
            plannedTime: _scheduledEnd,
          ),
          ..._extraStops,
        ];

    final admin = context.read<AdminProvider>();
    final success = await admin.assignTrip(
          driverId: _selectedDriver!.id,
          vehicleId: _selectedVehicle!.id,
          origin: _originController.text.trim(),
          destination: _destinationController.text.trim(),
          scheduledStart: _scheduledStart,
          scheduledEnd: _scheduledEnd,
          distanceKm: _distanceController.text.trim().isEmpty
              ? null
              : double.tryParse(_distanceController.text.trim()),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          routeStops: routeStops,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(admin.error ?? context.l10n.couldNotAssignTrip)));
    }
  }

  /// Opens the "Add vehicle" screen without leaving Assign Trip — the new
  /// vehicle is created via the same shared [AdminProvider], which prepends
  /// it to `admin.vehicles`, so it's selected here right away.
  Future<void> _addVehicle() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
    );
    if (added == true && mounted) {
      final admin = context.read<AdminProvider>();
      if (admin.vehicles.isNotEmpty) {
        setState(() => _selectedVehicle = admin.vehicles.first);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final l10n = context.l10n;
    final dateFormat = DateFormat('MMM d, y • h:mm a');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assignTrip)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SearchablePickerField<Driver>(
                label: l10n.driver,
                leadingIcon: Icons.person_outline,
                searchHint: l10n.searchDriverHint,
                value: _selectedDriver,
                items: admin.drivers,
                itemLabel: (d) => '${d.name} (${d.phone})',
                itemSubtitle: (d) => d.email,
                searchText: (d) => '${d.name} ${d.phone} ${d.email}',
                emptyText: l10n.noDriversAvailable,
                onSelected: (d) => setState(() => _selectedDriver = d),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Builder(builder: (context) {
                      final activeVehicles = admin.vehicles.where((v) => v.status == 'ACTIVE').toList();
                      final currentValue = activeVehicles.contains(_selectedVehicle) ? _selectedVehicle : null;
                      return SearchablePickerField<Vehicle>(
                        label: l10n.vehicle,
                        leadingIcon: Icons.local_shipping_outlined,
                        searchHint: l10n.searchVehicleHint,
                        value: currentValue,
                        items: activeVehicles,
                        itemLabel: (v) =>
                            '${v.vehicleNumber} (${v.type}${v.model != null && v.model!.isNotEmpty ? " · ${v.model}" : ""})',
                        itemSubtitle: (v) => v.capacityKg != null ? '${l10n.capacityWord}: ${v.capacityKg} kg' : v.type,
                        searchText: (v) => '${v.vehicleNumber} ${v.type} ${v.model ?? ''}',
                        emptyText: l10n.noActiveVehicles,
                        onSelected: (v) => setState(() => _selectedVehicle = v),
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: OutlinedButton.icon(
                      onPressed: _addVehicle,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addVehicle),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                    ),
                  ),
                ],
              ),
              if (admin.vehicles.isNotEmpty && admin.vehicles.every((v) => v.status != 'ACTIVE'))
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    l10n.noActiveVehiclesHint,
                    style: TextStyle(fontSize: 12, color: context.fleet.textSecondary),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _originController,
                decoration: InputDecoration(labelText: l10n.originPickup),
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 6),
              _MapPickRow(picked: _originLocation, onTap: _pickOriginLocation),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(labelText: l10n.destinationDelivery),
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 6),
              _MapPickRow(picked: _destinationLocation, onTap: _pickDestinationLocation),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.additionalStops, style: Theme.of(context).textTheme.titleSmall),
                  TextButton.icon(
                    onPressed: _addStop,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addStop),
                  ),
                ],
              ),
              if (_extraStops.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    l10n.addWaypointsHint,
                    style: TextStyle(fontSize: 12, color: context.fleet.textSecondary),
                  ),
                ),
              ..._extraStops.asMap().entries.map((entry) => Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(radius: 14, child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 12))),
                      title: Text(entry.value.locationName),
                      subtitle: Text(
                        entry.value.latitude != null
                            ? '${localizedStopType(l10n, entry.value.stopType)} • ${l10n.pinnedOnMap}'
                            : '${localizedStopType(l10n, entry.value.stopType)} • ${l10n.noLocationPinned}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _removeStop(entry.key),
                      ),
                    ),
                  )),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _optimizing ? null : _optimizeRoute,
                icon: _optimizing
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.route),
                label: Text(_optimizing ? l10n.optimizing : l10n.optimizeRoute),
              ),
              if (_optimizedStops != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: AppColors.primary.withOpacity(0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(l10n.suggestedVisitOrder, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._optimizedStops!.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('${s.sequenceNo}. ${s.locationName}  (${localizedStopType(l10n, s.stopType)})'),
                            )),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.totalWord} ≈ ${_optimizedTotalKm?.toStringAsFixed(1)} km • ~${_optimizedEtaMinutes} ${l10n.minDrive}',
                          style: TextStyle(fontSize: 12, color: context.fleet.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _distanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.distanceOpt),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.scheduledStart),
                subtitle: Text(_scheduledStart != null ? dateFormat.format(_scheduledStart!) : l10n.tapToSet),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final picked = await _pickDateTime(_scheduledStart);
                  if (picked != null) setState(() => _scheduledStart = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.scheduledEnd),
                subtitle: Text(_scheduledEnd != null ? dateFormat.format(_scheduledEnd!) : l10n.tapToSet),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final picked = await _pickDateTime(_scheduledEnd);
                  if (picked != null) setState(() => _scheduledEnd = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.notesOptional, alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.assignTrip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Replaces raw lat/lng fields — a chip showing whether a point is pinned
/// yet, plus a single "Pick on map" tap target. Nobody types a coordinate.
class _MapPickRow extends StatelessWidget {
  final PickedLocation? picked;
  final VoidCallback onTap;

  const _MapPickRow({required this.picked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                picked != null ? Icons.check_circle : Icons.location_off_outlined,
                size: 16,
                color: picked != null ? AppColors.success : context.fleet.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  picked != null ? context.l10n.locationPinned : context.l10n.noLocationPinnedYet,
                  style: TextStyle(fontSize: 12, color: context.fleet.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: Text(picked != null ? context.l10n.change : context.l10n.pickOnMap),
        ),
      ],
    );
  }
}

class _AddStopDialog extends StatefulWidget {
  const _AddStopDialog();

  @override
  State<_AddStopDialog> createState() => _AddStopDialogState();
}

class _AddStopDialogState extends State<_AddStopDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _stopType = 'WAYPOINT';
  PickedLocation? _picked;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    // Push above the dialog's own navigator so the full-screen map picker
    // isn't squeezed into the dialog box.
    final picked = await Navigator.of(context, rootNavigator: true).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLat: _picked?.latitude, initialLng: _picked?.longitude),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _picked = picked;
        if (_nameController.text.trim().isEmpty && picked.address != null) {
          _nameController.text = picked.address!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.addStop),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: context.l10n.locationName),
              validator: (v) => (v == null || v.trim().isEmpty) ? context.l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _stopType,
              decoration: InputDecoration(labelText: context.l10n.stopType),
              items: [
                DropdownMenuItem(value: 'WAYPOINT', child: Text(context.l10n.waypoint)),
                DropdownMenuItem(value: 'PICKUP', child: Text(context.l10n.pickup)),
                DropdownMenuItem(value: 'DELIVERY', child: Text(context.l10n.delivery)),
              ],
              onChanged: (v) => setState(() => _stopType = v ?? 'WAYPOINT'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickLocation,
              icon: Icon(_picked != null ? Icons.check_circle : Icons.map_outlined, size: 18),
              label: Text(_picked != null ? context.l10n.locationPinnedTapChange : context.l10n.pickOnMap),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.mapLocationOptionalNote,
              style: TextStyle(fontSize: 11, color: context.fleet.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.cancel)),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(RouteStop(
              locationName: _nameController.text.trim(),
              stopType: _stopType,
              latitude: _picked?.latitude,
              longitude: _picked?.longitude,
            ));
          },
          child: Text(context.l10n.add),
        ),
      ],
    );
  }
}
