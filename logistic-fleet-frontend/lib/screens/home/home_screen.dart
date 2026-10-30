import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../earnings/earnings_screen.dart';
import '../expenses/expense_list_screen.dart';
import '../profile/profile_screen.dart';
import '../trips/trip_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    TripListScreen(),
    ExpenseListScreen(),
    EarningsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.local_shipping_outlined), label: l10n.navTrips),
          BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined), label: l10n.navExpenses),
          BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_outlined), label: l10n.navEarnings),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline), label: l10n.navProfile),
        ],
      ),
    );
  }
}
