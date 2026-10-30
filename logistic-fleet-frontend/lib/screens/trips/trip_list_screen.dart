import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/trip.dart';
import '../../providers/trip_provider.dart';
import '../home/widgets_status_badge.dart';
import 'trip_detail_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadMyTrips();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myTrips),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.fleet.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [Tab(text: l10n.active), Tab(text: l10n.history)],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<TripProvider>().loadMyTrips(),
        child: tripProvider.loading && tripProvider.trips.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _TripList(trips: tripProvider.activeTrips, emptyText: l10n.noActiveTrips),
                  _TripList(trips: tripProvider.pastTrips, emptyText: l10n.noTripHistory),
                ],
              ),
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  final List<Trip> trips;
  final String emptyText;

  const _TripList({required this.trips, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.local_shipping_outlined, size: 48, color: context.fleet.textSecondary),
          const SizedBox(height: 12),
          Center(
            child: Text(emptyText, style: TextStyle(color: context.fleet.textSecondary)),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(trip.tripCode,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.fleet.textSecondary)),
                      StatusBadge(status: trip.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.trip_origin, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(trip.origin, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 7),
                    child: SizedBox(height: 16, child: VerticalDivider(width: 2, thickness: 2)),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(trip.destination, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  if (trip.scheduledStart != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      DateFormat('MMM d, y • h:mm a').format(trip.scheduledStart!),
                      style: TextStyle(fontSize: 12, color: context.fleet.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
