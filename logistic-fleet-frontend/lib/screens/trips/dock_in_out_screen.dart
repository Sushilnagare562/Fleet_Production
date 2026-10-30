import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/dock_event.dart';
import '../../models/trip.dart';
import '../../services/dock_service.dart';

/// Records DOCK_IN / DOCK_OUT for a single route stop (pickup OR delivery).
///
/// Order is enforced: the driver must DOCK IN before DOCK OUT — the Dock-out
/// button stays disabled until Dock-in is recorded, and each button turns
/// green (and locks) once its event has been recorded, so a stop can't be
/// docked in or out twice.
class DockInOutScreen extends StatefulWidget {
  final int tripId;
  final RouteStop routeStop;

  const DockInOutScreen({super.key, required this.tripId, required this.routeStop});

  @override
  State<DockInOutScreen> createState() => _DockInOutScreenState();
}

enum _DockPhase { locked, active, done }

class _DockInOutScreenState extends State<DockInOutScreen> {
  final _dockService = DockService();
  final _remarksController = TextEditingController();
  bool _submitting = false;
  Position? _position;
  bool _locating = false;

  // Progress for THIS stop, loaded from the backend so re-opening the screen
  // (or coming back later) still reflects what's already been done.
  bool _loadingStatus = true;
  bool _dockedIn = false;
  bool _dockedOut = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _loadDockStatus();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadDockStatus() async {
    try {
      final events = await _dockService.getEventsForTrip(widget.tripId);
      final forStop = events.where((e) => e.routeStopId == widget.routeStop.id);
      if (!mounted) return;
      setState(() {
        _dockedIn = forStop.any((e) => e.eventType == 'DOCK_IN');
        _dockedOut = forStop.any((e) => e.eventType == 'DOCK_OUT');
        _loadingStatus = false;
      });
    } catch (_) {
      // Non-fatal: default to "nothing done yet" so the driver can still dock.
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _position = position);
    } catch (_) {
      // Location is optional — dock events can still be recorded without coordinates.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit(String eventType) async {
    // Guard against out-of-order submits even if a button somehow fires.
    if (eventType == 'DOCK_OUT' && !_dockedIn) return;
    if (eventType == 'DOCK_IN' && _dockedIn) return;

    setState(() => _submitting = true);
    try {
      final event = DockEvent(
        tripId: widget.tripId,
        routeStopId: widget.routeStop.id,
        eventType: eventType,
        locationName: widget.routeStop.locationName,
        latitude: _position?.latitude,
        longitude: _position?.longitude,
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      );
      await _dockService.recordEvent(event);
      if (!mounted) return;
      setState(() {
        if (eventType == 'DOCK_IN') _dockedIn = true;
        if (eventType == 'DOCK_OUT') _dockedOut = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.eventRecorded)),
      );
      // Dock IN keeps the driver here so they can dock OUT next. Once dock OUT
      // is done the stop is complete — return to the trip (signalling refresh).
      if (eventType == 'DOCK_OUT' && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.couldNotRecordEvent)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final inPhase = _dockedIn ? _DockPhase.done : _DockPhase.active;
    final outPhase = _dockedOut
        ? _DockPhase.done
        : (_dockedIn ? _DockPhase.active : _DockPhase.locked);

    return Scaffold(
      // pop(false) if the driver leaves without finishing dock-out; the trip
      // screen refreshes either way so an in-progress dock still shows.
      appBar: AppBar(title: Text(widget.routeStop.locationName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _locating
                          ? Text(l10n.gettingLocation)
                          : Text(
                              _position != null
                                  ? '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}'
                                  : l10n.locationUnavailable,
                              style: TextStyle(color: context.fleet.textSecondary),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.remarks,
                alignLabelWithHint: true,
              ),
            ),
            const Spacer(),

            // Step hint — makes the required order explicit.
            if (!_loadingStatus && !_dockedIn)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: context.fleet.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.dockInFirst,
                        style: TextStyle(fontSize: 12.5, color: context.fleet.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

            if (_loadingStatus)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _DockButton(
                      phase: inPhase,
                      activeIcon: Icons.arrow_downward_rounded,
                      activeLabel: l10n.dockIn,
                      doneLabel: l10n.dockedIn,
                      busy: _submitting,
                      onPressed: () => _submit('DOCK_IN'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DockButton(
                      phase: outPhase,
                      activeIcon: Icons.arrow_upward_rounded,
                      activeLabel: l10n.dockOut,
                      doneLabel: l10n.dockedOut,
                      busy: _submitting,
                      onPressed: () => _submit('DOCK_OUT'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A dock-in / dock-out button whose colour reflects its [phase]:
///  - [locked]  grey + lock icon, disabled (dock-out before dock-in)
///  - [active]  brand-coloured, tappable
///  - [done]    green + check, disabled (already recorded)
class _DockButton extends StatelessWidget {
  final _DockPhase phase;
  final IconData activeIcon;
  final String activeLabel;
  final String doneLabel;
  final bool busy;
  final VoidCallback onPressed;

  const _DockButton({
    required this.phase,
    required this.activeIcon,
    required this.activeLabel,
    required this.doneLabel,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final fleet = context.fleet;

    switch (phase) {
      case _DockPhase.done:
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_rounded, size: 18),
          label: Text(doneLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.success,
            disabledForegroundColor: Colors.white,
          ),
        );
      case _DockPhase.locked:
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.lock_outline_rounded, size: 18),
          label: Text(activeLabel),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: fleet.textSecondary.withOpacity(0.14),
            disabledForegroundColor: fleet.textSecondary,
          ),
        );
      case _DockPhase.active:
        return ElevatedButton.icon(
          onPressed: busy ? null : onPressed,
          icon: Icon(activeIcon, size: 18),
          label: Text(activeLabel),
        );
    }
  }
}
