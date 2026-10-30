import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../home/widgets_status_badge.dart';

/// Shows the live, filtered list of trips for a single status (Assigned,
/// In Progress, Completed, Cancelled) — reached by tapping the matching
/// stat card on the Fleet Dashboard. Stays live: it reads straight from
/// [AdminProvider.allTrips], so pulling to refresh (or any other screen
/// updating trips) is reflected here immediately.
class AdminTripStatusScreen extends StatelessWidget {
  final String status;
  final String title;
  final Color color;

  const AdminTripStatusScreen({
    super.key,
    required this.status,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Text('$title ${context.l10n.tripsWord}'),
          ],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          final trips = admin.allTrips.where((t) => t.status == status).toList();

          return RefreshIndicator(
            onRefresh: () => admin.loadDashboard(),
            child: trips.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Icon(StatusColors.iconForTripStatus(status), size: 48, color: color.withOpacity(0.35)),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          context.l10n.noTripsInStatus,
                          style: TextStyle(color: context.fleet.textSecondary),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: trips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.tint(color),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(StatusColors.iconForTripStatus(status), color: color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${trip.origin} → ${trip.destination}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${trip.tripCode}'
                                      '${trip.driverName != null ? ' • ${trip.driverName}' : ''}'
                                      '${trip.scheduledStart != null ? ' • ${DateFormat('MMM d, h:mm a').format(trip.scheduledStart!)}' : ''}',
                                      style: TextStyle(fontSize: 12, color: context.fleet.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(status: trip.status),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
