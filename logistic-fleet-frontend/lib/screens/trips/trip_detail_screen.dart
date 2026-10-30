import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/dock_event.dart';
import '../../models/trip.dart';
import '../../services/dock_service.dart';
import '../../services/trip_service.dart';
import '../home/widgets_status_badge.dart';
import 'dock_in_out_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final _tripService = TripService();
  final _dockService = DockService();
  Trip? _trip;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  // Dock events for this trip, used to show per-stop progress and to enforce
  // that every pickup/delivery stop is docked in AND out before completing.
  List<DockEvent> _dockEvents = [];
  bool _dockLoadError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trip = await _tripService.getTrip(widget.tripId);
      setState(() => _trip = trip);
      await _loadDockEvents();
    } catch (e) {
      setState(() => _error = context.l10n.couldNotLoadTrip);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadDockEvents() async {
    try {
      final events = await _dockService.getEventsForTrip(widget.tripId);
      if (!mounted) return;
      setState(() {
        _dockEvents = events;
        _dockLoadError = false;
      });
    } catch (_) {
      // Best-effort: if this fails we simply don't show/enforce dock progress.
      if (mounted) setState(() => _dockLoadError = true);
    }
  }

  /// Dock progress for a single stop.
  ({bool inDone, bool outDone}) _stopDock(RouteStop stop) {
    final ev = _dockEvents.where((e) => e.routeStopId == stop.id);
    return (
      inDone: ev.any((e) => e.eventType == 'DOCK_IN'),
      outDone: ev.any((e) => e.eventType == 'DOCK_OUT'),
    );
  }

  /// True when every pickup & delivery stop has been docked in AND out.
  /// If the dock data couldn't be loaded we don't block the driver.
  bool _allStopsDocked(Trip trip) {
    if (_dockLoadError) return true;
    final relevant =
        trip.routeStops.where((s) => s.stopType == 'PICKUP' || s.stopType == 'DELIVERY');
    if (relevant.isEmpty) return true;
    return relevant.every((s) {
      final d = _stopDock(s);
      return d.inDone && d.outDone;
    });
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    try {
      final updated = await _tripService.updateStatus(widget.tripId, status);
      setState(() => _trip = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.couldNotUpdateStatus)));
      }
    } finally {
      setState(() => _updating = false);
    }
  }

  /// Opens the device's default maps app with turn-by-turn directions to a
  /// single stop. Kept simple (one destination at a time) since the driver
  /// works through stops one by one, in the order shown on this screen.
  Future<void> _openNavigation(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    final opened = await canLaunchUrl(uri) && await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.couldNotOpenMaps)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_trip?.tripCode ?? context.l10n.tripDetails)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _buildContent(_trip!),
      bottomNavigationBar: _trip == null ? null : _buildActionBar(_trip!),
    );
  }

  Widget _buildContent(Trip trip) {
    final l10n = context.l10n;
    String stopLabel(String t) => t == 'PICKUP'
        ? l10n.pickup
        : t == 'DELIVERY'
        ? l10n.delivery
        : t == 'WAYPOINT'
        ? l10n.waypoint
        : t;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.tripStatusTitle, style: Theme.of(context).textTheme.titleMedium),
              StatusBadge(status: trip.status),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(icon: Icons.trip_origin, label: l10n.origin, value: trip.origin),
                  const Divider(height: 24),
                  _InfoRow(icon: Icons.location_on, label: l10n.destination, value: trip.destination),
                  if (trip.distanceKm != null) ...[
                    const Divider(height: 24),
                    _InfoRow(icon: Icons.route, label: l10n.distance, value: '${trip.distanceKm} km'),
                  ],
                  if (trip.scheduledStart != null) ...[
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.schedule,
                      label: l10n.scheduledStart,
                      value: DateFormat('MMM d, y • h:mm a').format(trip.scheduledStart!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (trip.routeStops.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.route, style: Theme.of(context).textTheme.titleMedium),
                if (trip.routeStops.length > 1)
                  Text(
                    l10n.inVisitOrder,
                    style: TextStyle(fontSize: 12, color: context.fleet.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...(() {
              // Stops come back from the API already carrying the dispatcher's
              // (possibly route-optimized) sequenceNo — sort defensively here
              // so the driver always sees them in the order they should be visited.
              final sortedStops = [...trip.routeStops]
                ..sort((a, b) => (a.sequenceNo ?? 0).compareTo(b.sequenceNo ?? 0));

              Color stopColor(String type) {
                if (type == 'PICKUP') return AppColors.primary;
                if (type == 'DELIVERY') return AppColors.accent;
                return context.fleet.textSecondary;
              }

              return sortedStops.map((stop) {
                final color = stopColor(stop.stopType);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.12),
                      child: Text(
                        stop.sequenceNo?.toString() ?? '•',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(stop.locationName),
                    subtitle: Text(stopLabel(stop.stopType)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (stop.latitude != null && stop.longitude != null)
                          IconButton(
                            icon: const Icon(Icons.navigation_outlined),
                            tooltip: l10n.navigate,
                            onPressed: () => _openNavigation(stop.latitude!, stop.longitude!),
                          ),
                        _dockControl(trip, stop),
                      ],
                    ),
                  ),
                );
              });
            })(),
          ],
          if (trip.notes != null && trip.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l10n.notes, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(trip.notes!, style: TextStyle(color: context.fleet.textSecondary)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Per-stop dock control shown in the route list:
  ///  - not started  -> "Dock" (brand colour)
  ///  - docked in     -> "Dock out" (accent colour, still pending)
  ///  - docked in+out -> green "Completed" chip (not tappable)
  Widget _dockControl(Trip trip, RouteStop stop) {
    final l10n = context.l10n;
    final d = _stopDock(stop);

    Future<void> open() async {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DockInOutScreen(tripId: trip.id, routeStop: stop)),
      );
      await _loadDockEvents();
    }

    if (!_dockLoadError && d.inDone && d.outDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
            const SizedBox(width: 5),
            Text(l10n.statusCompleted,
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      );
    }

    final pendingOut = !_dockLoadError && d.inDone && !d.outDone;
    return TextButton(
      onPressed: open,
      style: TextButton.styleFrom(
        foregroundColor: pendingOut ? AppColors.accent : AppColors.primary,
      ),
      child: Text(
        pendingOut ? l10n.dockOut : l10n.dock,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget? _buildActionBar(Trip trip) {
    final l10n = context.l10n;
    String? nextStatus;
    String? label;

    if (trip.status == 'ASSIGNED') {
      nextStatus = 'IN_PROGRESS';
      label = l10n.startTrip;
    } else if (trip.status == 'IN_PROGRESS') {
      nextStatus = 'COMPLETED';
      label = l10n.completeTrip;
    }

    if (nextStatus == null) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _updating
              ? null
              : () {
                  // Completing the trip requires every pickup & delivery stop
                  // to be fully docked in AND out first.
                  if (nextStatus == 'COMPLETED' && !_allStopsDocked(trip)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.dockAllStopsFirst)),
                    );
                    return;
                  }
                  _updateStatus(nextStatus!);
                },
          child: _updating
              ? const SizedBox(
              height: 20, width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(label!),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.fleet.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: context.fleet.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}