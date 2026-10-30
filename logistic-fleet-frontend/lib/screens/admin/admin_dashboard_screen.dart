import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/trip.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/animated_stat_card.dart';
import '../home/widgets_status_badge.dart';
import '../profile/profile_screen.dart';
import 'admin_trip_status_screen.dart';
import 'assign_trip_screen.dart';
import 'live_tracking_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  void _openStatus(BuildContext context, String status, String title, Color color) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminTripStatusScreen(status: status, title: title, color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final summary = admin.tripSummary;
    final l10n = context.l10n;

    // Four status stat cards, built once so the layout can arrange them
    // responsively (2×2 on phones, 4-across on tablets/web).
    final statCards = summary == null
        ? <Widget>[]
        : <Widget>[
            AnimatedStatCard(
              label: l10n.statusAssigned,
              value: summary.assigned,
              color: AppColors.warning,
              icon: Icons.pending_actions_rounded,
              onTap: () => _openStatus(context, 'ASSIGNED', l10n.statusAssigned, AppColors.warning),
            ),
            AnimatedStatCard(
              label: l10n.statusInProgress,
              value: summary.inProgress,
              color: AppColors.primary,
              icon: Icons.local_shipping_rounded,
              onTap: () => _openStatus(context, 'IN_PROGRESS', l10n.statusInProgress, AppColors.primary),
            ),
            AnimatedStatCard(
              label: l10n.statusCompleted,
              value: summary.completed,
              color: AppColors.success,
              icon: Icons.check_circle_rounded,
              onTap: () => _openStatus(context, 'COMPLETED', l10n.statusCompleted, AppColors.success),
            ),
            AnimatedStatCard(
              label: l10n.statusCancelled,
              value: summary.cancelled,
              color: AppColors.danger,
              icon: Icons.cancel_rounded,
              onTap: () => _openStatus(context, 'CANCELLED', l10n.statusCancelled, AppColors.danger),
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fleetDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_rounded),
            tooltip: l10n.navLiveTracking,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: l10n.profile,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final assigned = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AssignTripScreen()),
          );
          if (assigned == true && mounted) {
            context.read<AdminProvider>().loadDashboard();
          }
        },
        icon: const Icon(Icons.add_road),
        label: Text(l10n.assignTrip),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadDashboard(),
        child: admin.loading && summary == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _LiveTrackingBanner(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (summary != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, left: 2),
                          child: Text(
                            l10n.tapCardHint,
                            style: TextStyle(fontSize: 12, color: context.fleet.textSecondary, fontStyle: FontStyle.italic),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 720;
                            if (wide) {
                              return Row(
                                children: [
                                  for (int i = 0; i < statCards.length; i++) ...[
                                    Expanded(child: statCards[i]),
                                    if (i != statCards.length - 1) const SizedBox(width: 12),
                                  ],
                                ],
                              );
                            }
                            return Column(
                              children: [
                                Row(children: [
                                  Expanded(child: statCards[0]),
                                  const SizedBox(width: 12),
                                  Expanded(child: statCards[1]),
                                ]),
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(child: statCards[2]),
                                  const SizedBox(width: 12),
                                  Expanded(child: statCards[3]),
                                ]),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppGradients.brand,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: AppShadows.brand,
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.totalTrips, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                                  const SizedBox(height: 4),
                                  Text('${summary.total}',
                                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                                ],
                              ),
                              if (summary.total > 0) SizedBox(height: 64, width: 64, child: _StatusDonut(summary: summary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.liveTrips, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          Text('${admin.allTrips.length} ${l10n.totalLower}', style: TextStyle(color: context.fleet.textSecondary, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (admin.allTrips.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(l10n.noTripsAssignOne,
                                style: TextStyle(color: context.fleet.textSecondary)),
                          ),
                        )
                      else
                        ...admin.allTrips.take(20).map((trip) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.tint(StatusColors.forTripStatus(trip.status)),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(StatusColors.iconForTripStatus(trip.status),
                                      color: StatusColors.forTripStatus(trip.status), size: 18),
                                ),
                                title: Text('${trip.origin} → ${trip.destination}',
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  '${trip.tripCode}'
                                  '${trip.driverName != null ? ' • ${trip.driverName}' : ''}'
                                  '${trip.scheduledStart != null ? ' • ${DateFormat('MMM d, h:mm a').format(trip.scheduledStart!)}' : ''}',
                                ),
                                trailing: StatusBadge(status: trip.status),
                              ),
                            )),
                      const SizedBox(height: 72),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _LiveTrackingBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _LiveTrackingBanner({required this.onTap});

  @override
  State<_LiveTrackingBanner> createState() => _LiveTrackingBannerState();
}

class _LiveTrackingBannerState extends State<_LiveTrackingBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE65100), Color(0xFFF57C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.brand,
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                FadeTransition(
                  opacity: Tween(begin: 0.25, end: 0.65).animate(_controller),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), shape: BoxShape.circle),
                  child: const Icon(Icons.satellite_alt_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.liveFleetTracking,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(l10n.seeEveryTruck,
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class _StatusDonut extends StatelessWidget {
  final TripStatusSummary summary;

  const _StatusDonut({required this.summary});

  @override
  Widget build(BuildContext context) {
    final segments = <MapEntry<double, Color>>[
      MapEntry(summary.assigned.toDouble(), Colors.white.withOpacity(0.95)),
      MapEntry(summary.inProgress.toDouble(), Colors.white.withOpacity(0.7)),
      MapEntry(summary.completed.toDouble(), Colors.white.withOpacity(0.45)),
      MapEntry(summary.cancelled.toDouble(), Colors.white.withOpacity(0.22)),
    ].where((e) => e.key > 0).toList();

    if (segments.isEmpty) return const SizedBox.shrink();

    return PieChart(
      PieChartData(
        sections: segments
            .map((e) => PieChartSectionData(
                  value: e.key,
                  color: e.value,
                  showTitle: false,
                  radius: 12,
                ))
            .toList(),
        centerSpaceRadius: 20,
        sectionsSpace: 2,
      ),
    );
  }
}
