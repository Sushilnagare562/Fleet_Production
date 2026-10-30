import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import 'admin_dashboard_screen.dart';
import 'admin_drivers_screen.dart';
import 'admin_expenses_screen.dart';
import 'admin_vehicles_screen.dart';
import 'reports_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    AdminDashboardScreen(),
    AdminDriversScreen(),
    AdminVehiclesScreen(),
    AdminExpensesScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 22,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined), label: l10n.navDashboard),
          BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline), label: l10n.navDrivers),
          BottomNavigationBarItem(
              icon: const Icon(Icons.local_shipping_outlined), label: l10n.navFleet),
          BottomNavigationBarItem(
              icon: const Icon(Icons.fact_check_outlined), label: l10n.navApprovals),
          BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_rounded), label: l10n.navReports),
        ],
      ),
    );
  }
}
