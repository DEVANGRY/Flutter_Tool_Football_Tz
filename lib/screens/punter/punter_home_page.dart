import 'package:flutter/material.dart';
import 'models/match_item.dart';
import 'matches_list_page.dart';
import 'my_bets_page.dart';

class PunterHomePage extends StatefulWidget {
  final List<MatchItem> matches;

  const PunterHomePage({super.key, required this.matches});

  @override
  State<PunterHomePage> createState() => _PunterHomePageState();
}

class _PunterHomePageState extends State<PunterHomePage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      MatchesListPage(matches: widget.matches),
      MyBetsPage(matches: widget.matches),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt cược'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Quay lại Admin',
          ),
        ],
      ),
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_soccer),
            label: 'Trận đấu',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Cược của tôi',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() => currentIndex = index);
        },
      ),
    );
  }
}
