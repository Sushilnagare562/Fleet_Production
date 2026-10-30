import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';

/// Result of picking a point on the map: coordinates plus a best-effort
/// human-readable address (may be null if reverse geocoding fails, e.g. offline).
class PickedLocation {
  final double latitude;
  final double longitude;
  final String? address;

  PickedLocation({required this.latitude, required this.longitude, this.address});
}

/// A map the admin drags to place a fixed center pin over the spot they
/// mean — no typing coordinates. Defaults to [initialLat]/[initialLng] if
/// given (e.g. re-opening to adjust a previously picked stop), otherwise a
/// generic starting view.
class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _controller;
  late LatLng _center;
  String? _address;
  bool _locating = false;
  bool _resolvingAddress = false;

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.initialLat ?? 19.9975, widget.initialLng ?? 73.7898); // falls back to Nashik
    _reverseGeocode(_center);
    if (widget.initialLat == null) {
      // No previous pin — try to open centered on the admin's current
      // location instead of a hard-coded city, if permission is available.
      WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation(silent: true));
    }
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _resolvingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = [p.name, p.subLocality, p.locality]
            .where((s) => s != null && s.trim().isNotEmpty)
            .toList();
        setState(() => _address = parts.isNotEmpty ? parts.join(', ') : null);
      }
    } catch (_) {
      // Reverse geocoding can fail offline, or if the Geocoding API isn't
      // enabled on the Maps API key — that's fine, coordinates still work
      // and the admin can type a name manually.
      if (mounted) setState(() => _address = null);
    } finally {
      if (mounted) setState(() => _resolvingAddress = false);
    }
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!silent) _showSnack(context.l10n.locationPermissionOff);
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final target = LatLng(position.latitude, position.longitude);
      _controller?.animateCamera(CameraUpdate.newLatLng(target));
      setState(() => _center = target);
      await _reverseGeocode(target);
    } catch (_) {
      if (!silent) _showSnack(context.l10n.couldNotGetLocation);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.pickLocation)),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) => _controller = c,
            onCameraMove: (pos) => _center = pos.target,
            onCameraIdle: () => _reverseGeocode(_center),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          // Fixed pin in the middle of the screen — the map moves under it.
          // Easier to place precisely on mobile than tapping an exact pixel.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_pin, size: 46, color: Colors.redAccent),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'use_current_location',
              backgroundColor: Colors.white,
              onPressed: _locating ? null : () => _useCurrentLocation(),
              child: _locating
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.place, size: 18, color: context.fleet.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _resolvingAddress
                              ? Text(context.l10n.locating, style: TextStyle(color: context.fleet.textSecondary))
                              : Text(
                                  _address ??
                                      '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: Text(context.l10n.useThisLocation),
                        onPressed: () => Navigator.of(context).pop(
                          PickedLocation(latitude: _center.latitude, longitude: _center.longitude, address: _address),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
