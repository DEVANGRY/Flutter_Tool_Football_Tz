library bookie_management_app;

import 'package:flutter/material.dart';
import 'models/match_item.dart';
import 'models/bet_entry.dart';
import 'models/hedge_order.dart';
import 'services/risk_engine.dart';
import 'pages/dashboard_page.dart';
import 'pages/hedging_page.dart';
import 'pages/settings_page.dart';
import 'pages/admin_page.dart';
import 'pages/bet_entry_page.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    print(details.exception);
  };
  runApp(const BookieApp());
}

class BookieApp extends StatelessWidget {
  const BookieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bookie Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  double _riskThreshold = 20;

  // Danh sách matches - quản lý tập trung
  final List<MatchItem> _matches = [
    MatchItem(
      id: 'm1',
      title: 'Manchester City vs Liverpool',
      nameTeamA: 'Manchester City',
      nameTeamB: 'Liverpool',
      oddA: 1.82,
      oddB: 2.15,
      oddDraw: 3.10,
      bets: [
        BetEntry(
          id: 'b1',
          side: BetSide.teamA,
          amount: 12000000,
          odds: 1.82,
          nameTeam: 'Tran Van An',
          createdAt: DateTime(2026, 4, 22, 9, 15),
        ),
        BetEntry(
          id: 'b2',
          side: BetSide.teamB,
          amount: 4000000,
          odds: 2.15,
          nameTeam: 'Pham Minh Duc',
          createdAt: DateTime(2026, 4, 22, 10, 40),
        ),
        BetEntry(
          id: 'b3',
          side: BetSide.draw,
          amount: 2000000,
          odds: 3.10,
          nameTeam: 'Le Quoc Huy',
          createdAt: DateTime(2026, 4, 22, 11, 5),
        ),
      ],
    ),
    MatchItem(
      id: 'm2',
      title: 'Real Madrid vs Barcelona',
      nameTeamA: 'Real Madrid',
      nameTeamB: 'Barcelona',
      oddA: 1.95,
      oddB: 1.90,
      oddDraw: 3.25,
      bets: [
        BetEntry(
          id: 'b4',
          side: BetSide.teamA,
          amount: 7000000,
          odds: 1.95,
          nameTeam: 'Nguyen Huu Khang',
          createdAt: DateTime(2026, 4, 22, 12, 10),
        ),
        BetEntry(
          id: 'b5',
          side: BetSide.teamB,
          amount: 9000000,
          odds: 1.90,
          nameTeam: 'Doan Gia Bao',
          createdAt: DateTime(2026, 4, 22, 12, 35),
        ),
      ],
    ),
  ];

  // Thêm bet mới (từ form đơn giản)
  void _addBet(String matchId, BetSide side, double amount) {
    final match = _matches.firstWhere(
      (m) => m.id == matchId,
      orElse: () => throw Exception("Match not found"),
    );
    final odds = switch (side) {
      BetSide.teamA => match.oddA,
      BetSide.teamB => match.oddB,
      BetSide.draw => match.oddDraw,
    };

    setState(() {
      match.bets.add(
        BetEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          side: side,
          amount: amount,
          odds: odds,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  // Thêm bet mới từ trang nhập cược đầy đủ
  void _addBetFromEntryPage(String matchId, BetEntry bet) {
    final match = _matches.firstWhere(
      (m) => m.id == matchId,
      orElse: () => throw Exception("Match not found"),
    );
    setState(() {
      match.bets.add(bet);
    });
  }

  // Mở trang nhập cược
  void _openBetEntryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BetEntryPage(matches: _matches, onAddBet: _addBetFromEntryPage),
      ),
    );
  }

  // Thêm hedge order
  void _addHedgeOrder(
    String matchId,
    String bookie,
    BetSide side,
    double amount,
  ) {
    final match = _matches.firstWhere((m) => m.id == matchId);
    setState(() {
      match.hedges.add(
        HedgeOrder(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          targetBookie: bookie,
          side: side,
          amount: amount,
          status: HedgeStatus.pending,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  // Toggle hedge status
  void _toggleHedgeStatus(String matchId, String orderId) {
    final match = _matches.firstWhere((m) => m.id == matchId);
    setState(() {
      final order = match.hedges.firstWhere((h) => h.id == orderId);
      order.status = order.status == HedgeStatus.pending
          ? HedgeStatus.settled
          : HedgeStatus.pending;
    });
  }

  // Cập nhật odds
  void _updateOdds(String matchId, double oddA, double oddB, double oddDraw) {
    final match = _matches.firstWhere((m) => m.id == matchId);
    setState(() {
      match.oddA = oddA;
      match.oddB = oddB;
      match.oddDraw = oddDraw;
    });
  }

  // Thêm trận đấu mới
  void _addMatch(
    String title,
    String nameTeamA,
    String nameTeamB,
    double oddA,
    double oddB,
    double oddDraw,
  ) {
    setState(() {
      _matches.add(
        MatchItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          nameTeamA: nameTeamA,
          nameTeamB: nameTeamB,
          oddA: oddA,
          oddB: oddB,
          oddDraw: oddDraw,
        ),
      );
    });
  }

  // Xóa trận đấu
  void _deleteMatch(MatchItem match) {
    setState(() {
      _matches.removeWhere((m) => m.id == match.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardPage(
            matches: _matches,
            riskThreshold: _riskThreshold,
            onAddBet: _addBet,
            onUpdateOdds: _updateOdds,
            onOpenBetEntry: _openBetEntryPage,
          ),
          HedgingPage(
            matches: _matches,
            riskThreshold: _riskThreshold,
            onAddHedge: _addHedgeOrder,
            onToggleHedgeStatus: _toggleHedgeStatus,
          ),
          AdminPage(
            matches: _matches,
            onAddMatch: _addMatch,
            onUpdateOdds: (match, oddA, oddB, oddDraw) {
              _updateOdds(match.id, oddA, oddB, oddDraw);
            },
            onDeleteMatch: _deleteMatch,
          ),
          SettingsPage(
            threshold: _riskThreshold,
            onThresholdChanged: (value) {
              setState(() => _riskThreshold = value);
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Hedging',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
