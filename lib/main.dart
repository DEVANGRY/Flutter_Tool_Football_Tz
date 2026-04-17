import 'package:flutter/material.dart';

void main() {
  runApp(const BookieManagementApp());
}

class BookieManagementApp extends StatelessWidget {
  const BookieManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bookie Management Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

enum BetSide { teamA, teamB, draw }

enum HedgeStatus { pending, settled }

class BetEntry {
  final String id;
  final BetSide side;
  final double amount;
  final double odds;
  final DateTime createdAt;

  BetEntry({
    required this.id,
    required this.side,
    required this.amount,
    required this.odds,
    required this.createdAt,
  });
}

class HedgeOrder {
  final String id;
  final String targetBookie;
  final BetSide side;
  final double amount;
  HedgeStatus status;
  final DateTime createdAt;

  HedgeOrder({
    required this.id,
    required this.targetBookie,
    required this.side,
    required this.amount,
    required this.status,
    required this.createdAt,
  });
}

class MatchItem {
  final String id;
  final String title;
  double oddA;
  double oddB;
  double oddDraw;
  final List<BetEntry> bets;
  final List<HedgeOrder> hedges;

  MatchItem({
    required this.id,
    required this.title,
    required this.oddA,
    required this.oddB,
    required this.oddDraw,
    List<BetEntry>? bets,
    List<HedgeOrder>? hedges,
  }) : bets = bets ?? [],
       hedges = hedges ?? [];

  double get poolA => bets
      .where((e) => e.side == BetSide.teamA)
      .fold(0, (sum, e) => sum + e.amount);

  double get poolB => bets
      .where((e) => e.side == BetSide.teamB)
      .fold(0, (sum, e) => sum + e.amount);

  double get poolDraw => bets
      .where((e) => e.side == BetSide.draw)
      .fold(0, (sum, e) => sum + e.amount);

  double get totalPool => poolA + poolB + poolDraw;

  double get hedgeA => hedges
      .where((e) => e.side == BetSide.teamA && e.status == HedgeStatus.pending)
      .fold(0, (sum, e) => sum + e.amount);

  double get hedgeB => hedges
      .where((e) => e.side == BetSide.teamB && e.status == HedgeStatus.pending)
      .fold(0, (sum, e) => sum + e.amount);

  double get hedgeDraw => hedges
      .where((e) => e.side == BetSide.draw && e.status == HedgeStatus.pending)
      .fold(0, (sum, e) => sum + e.amount);

  double get netExposureA => poolA - hedgeA;
  double get netExposureB => poolB - hedgeB;
  double get netExposureDraw => poolDraw - hedgeDraw;
}

class RiskMetrics {
  final double total;
  final double biasPercent;
  final BetSide? heavySide;
  final double hedgeAmount;
  final bool shouldHedge;

  RiskMetrics({
    required this.total,
    required this.biasPercent,
    required this.heavySide,
    required this.hedgeAmount,
    required this.shouldHedge,
  });
}

class PnLScenario {
  final double teamAWin;
  final double teamBWin;
  final double draw;

  const PnLScenario({
    required this.teamAWin,
    required this.teamBWin,
    required this.draw,
  });
}

class RiskEngine {
  static RiskMetrics calculateRisk(MatchItem match, double thresholdPercent) {
    final exposures = {
      BetSide.teamA: match.netExposureA,
      BetSide.teamB: match.netExposureB,
      BetSide.draw: match.netExposureDraw,
    };

    final total = exposures.values.fold<double>(0, (sum, e) => sum + e);
    if (total <= 0) {
      return RiskMetrics(
        total: 0,
        biasPercent: 0,
        heavySide: null,
        hedgeAmount: 0,
        shouldHedge: false,
      );
    }

    final sorted = exposures.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final heavy = sorted.first;
    final light = sorted.last;
    final bias = ((heavy.value - light.value).abs() / total) * 100;
    final hedgeAmount = (heavy.value - light.value) / 2;

    return RiskMetrics(
      total: total,
      biasPercent: bias,
      heavySide: heavy.key,
      hedgeAmount: hedgeAmount > 0 ? hedgeAmount : 0,
      shouldHedge: bias > thresholdPercent,
    );
  }

  static PnLScenario calculatePnL(MatchItem match) {
    final revenue = match.totalPool;

    double payoutFor(BetSide side) {
      return match.bets
          .where((e) => e.side == side)
          .fold(0.0, (sum, e) => sum + (e.amount * e.odds));
    }

    double hedgeReturnFor(BetSide side) {
      double total = 0;
      for (final h in match.hedges.where(
        (e) => e.status == HedgeStatus.pending,
      )) {
        if (h.side == side) {
          switch (side) {
            case BetSide.teamA:
              total += h.amount * match.oddA;
              break;
            case BetSide.teamB:
              total += h.amount * match.oddB;
              break;
            case BetSide.draw:
              total += h.amount * match.oddDraw;
              break;
          }
        }
      }
      return total;
    }

    double hedgeCost() {
      return match.hedges
          .where((e) => e.status == HedgeStatus.pending)
          .fold(0.0, (sum, e) => sum + e.amount);
    }

    final hedgeSpend = hedgeCost();

    return PnLScenario(
      teamAWin:
          revenue -
          payoutFor(BetSide.teamA) -
          hedgeSpend +
          hedgeReturnFor(BetSide.teamA),
      teamBWin:
          revenue -
          payoutFor(BetSide.teamB) -
          hedgeSpend +
          hedgeReturnFor(BetSide.teamB),
      draw:
          revenue -
          payoutFor(BetSide.draw) -
          hedgeSpend +
          hedgeReturnFor(BetSide.draw),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  double riskThreshold = 20;

  final List<MatchItem> matches = [
    MatchItem(
      id: 'm1',
      title: 'Manchester City vs Liverpool',
      oddA: 1.82,
      oddB: 2.15,
      oddDraw: 3.10,
      bets: [
        BetEntry(
          id: 'b1',
          side: BetSide.teamA,
          amount: 12000000,
          odds: 1.82,
          createdAt: DateTime.now(),
        ),
        BetEntry(
          id: 'b2',
          side: BetSide.teamB,
          amount: 4000000,
          odds: 2.15,
          createdAt: DateTime.now(),
        ),
        BetEntry(
          id: 'b3',
          side: BetSide.draw,
          amount: 2000000,
          odds: 3.10,
          createdAt: DateTime.now(),
        ),
      ],
    ),
    MatchItem(
      id: 'm2',
      title: 'Real Madrid vs Barcelona',
      oddA: 1.95,
      oddB: 1.90,
      oddDraw: 3.25,
      bets: [
        BetEntry(
          id: 'b4',
          side: BetSide.teamA,
          amount: 7000000,
          odds: 1.95,
          createdAt: DateTime.now(),
        ),
        BetEntry(
          id: 'b5',
          side: BetSide.teamB,
          amount: 9000000,
          odds: 1.90,
          createdAt: DateTime.now(),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        matches: matches,
        riskThreshold: riskThreshold,
        onOpenMatch: _openMatchDetail,
      ),
      HedgingManagementPage(
        matches: matches,
        onToggleHedgeStatus: _toggleHedgeStatus,
      ),
      SettingsPage(
        threshold: riskThreshold,
        onChanged: (value) {
          setState(() => riskThreshold = value);
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Bookie Management Tool')),
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Hedging'),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Cài đặt',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() => currentIndex = index);
        },
      ),
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showQuickBetSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Nhập cược'),
            )
          : null,
    );
  }

  void _openMatchDetail(MatchItem match) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchDetailPage(
          match: match,
          threshold: riskThreshold,
          onUpdated: () => setState(() {}),
        ),
      ),
    );
    setState(() {});
  }

  void _toggleHedgeStatus(HedgeOrder order) {
    setState(() {
      order.status = order.status == HedgeStatus.pending
          ? HedgeStatus.settled
          : HedgeStatus.pending;
    });
  }

  void _showQuickBetSheet(BuildContext context) {
    String? matchId = matches.isNotEmpty ? matches.first.id : null;
    BetSide side = BetSide.teamA;
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhập cược nhanh',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: matchId,
                    items: matches
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.title),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Chọn trận đấu',
                    ),
                    onChanged: (value) {
                      setModalState(() => matchId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<BetSide>(
                    value: side,
                    items: BetSide.values
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(sideLabel(s)),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(labelText: 'Cửa cược'),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => side = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền',
                      hintText: 'Ví dụ: 5000000',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final amount =
                            double.tryParse(amountController.text.trim()) ?? 0;
                        if (matchId == null || amount <= 0) return;

                        final match = matches.firstWhere(
                          (m) => m.id == matchId,
                        );
                        double odds = switch (side) {
                          BetSide.teamA => match.oddA,
                          BetSide.teamB => match.oddB,
                          BetSide.draw => match.oddDraw,
                        };

                        setState(() {
                          match.bets.add(
                            BetEntry(
                              id: DateTime.now().microsecondsSinceEpoch
                                  .toString(),
                              side: side,
                              amount: amount,
                              odds: odds,
                              createdAt: DateTime.now(),
                            ),
                          );
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã thêm lệnh cược mới'),
                          ),
                        );
                      },
                      child: const Text('Lưu cược'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class DashboardPage extends StatelessWidget {
  final List<MatchItem> matches;
  final double riskThreshold;
  final ValueChanged<MatchItem> onOpenMatch;

  const DashboardPage({
    super.key,
    required this.matches,
    required this.riskThreshold,
    required this.onOpenMatch,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        final risk = RiskEngine.calculateRisk(match, riskThreshold);
        final pnl = RiskEngine.calculatePnL(match);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onOpenMatch(match),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      RiskBadge(isDanger: risk.shouldHedge),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ExposureBar(match: match),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      InfoChip(label: 'Pool A', value: money(match.poolA)),
                      InfoChip(label: 'Pool B', value: money(match.poolB)),
                      InfoChip(label: 'Pool Hòa', value: money(match.poolDraw)),
                      InfoChip(
                        label: 'Bias',
                        value: '${risk.biasPercent.toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'P/L dự kiến',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ScenarioTile(
                          label: 'A thắng',
                          value: pnl.teamAWin,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ScenarioTile(
                          label: 'B thắng',
                          value: pnl.teamBWin,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ScenarioTile(label: 'Hòa', value: pnl.draw),
                      ),
                    ],
                  ),
                  if (risk.shouldHedge) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Cần đẩy sang nhà cái khác: ${money(risk.hedgeAmount)} cửa ${sideLabel(risk.heavySide!)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
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

class MatchDetailPage extends StatefulWidget {
  final MatchItem match;
  final double threshold;
  final VoidCallback onUpdated;

  const MatchDetailPage({
    super.key,
    required this.match,
    required this.threshold,
    required this.onUpdated,
  });

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  final amountController = TextEditingController();
  final oddAController = TextEditingController();
  final oddBController = TextEditingController();
  final oddDrawController = TextEditingController();
  BetSide selectedSide = BetSide.teamA;

  @override
  void initState() {
    super.initState();
    oddAController.text = widget.match.oddA.toString();
    oddBController.text = widget.match.oddB.toString();
    oddDrawController.text = widget.match.oddDraw.toString();
  }

  @override
  Widget build(BuildContext context) {
    final risk = RiskEngine.calculateRisk(widget.match, widget.threshold);
    final pnl = RiskEngine.calculatePnL(widget.match);

    return Scaffold(
      appBar: AppBar(title: Text(widget.match.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng quan rủi ro',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ExposureBar(match: widget.match),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ScenarioTile(
                          label: 'A thắng',
                          value: pnl.teamAWin,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ScenarioTile(
                          label: 'B thắng',
                          value: pnl.teamBWin,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ScenarioTile(label: 'Hòa', value: pnl.draw),
                      ),
                    ],
                  ),
                  if (risk.shouldHedge) ...[
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                      title: Text(
                        'Cần hedge ${money(risk.hedgeAmount)} ở cửa ${sideLabel(risk.heavySide!)}',
                      ),
                      subtitle: Text(
                        'Bias hiện tại: ${risk.biasPercent.toStringAsFixed(1)}% > ngưỡng ${widget.threshold.toStringAsFixed(0)}%',
                      ),
                      trailing: FilledButton(
                        onPressed: () {
                          setState(() {
                            widget.match.hedges.add(
                              HedgeOrder(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                targetBookie: 'Bookie Partner X',
                                side: risk.heavySide!,
                                amount: risk.hedgeAmount,
                                status: HedgeStatus.pending,
                                createdAt: DateTime.now(),
                              ),
                            );
                          });
                          widget.onUpdated();
                        },
                        child: const Text('Tạo lệnh đẩy'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhận cược',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<BetSide>(
                    value: selectedSide,
                    decoration: const InputDecoration(labelText: 'Cửa cược'),
                    items: BetSide.values
                        .map(
                          (side) => DropdownMenuItem(
                            value: side,
                            child: Text(sideLabel(side)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedSide = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền cược',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _addBet,
                      child: const Text('Thêm cược'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cập nhật odds',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: oddAController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Odds Đội A',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: oddBController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Odds Đội B',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: oddDrawController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Odds Hòa',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _updateOdds,
                      child: const Text('Lưu odds mới'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lịch sử cược',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...widget.match.bets.reversed.map(
                    (bet) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text(sideShort(bet.side))),
                      title: Text(
                        '${sideLabel(bet.side)} - ${money(bet.amount)}',
                      ),
                      subtitle: Text(
                        'Odds ${bet.odds} • ${formatTime(bet.createdAt)}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addBet() {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    final odds = switch (selectedSide) {
      BetSide.teamA => widget.match.oddA,
      BetSide.teamB => widget.match.oddB,
      BetSide.draw => widget.match.oddDraw,
    };

    setState(() {
      widget.match.bets.add(
        BetEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          side: selectedSide,
          amount: amount,
          odds: odds,
          createdAt: DateTime.now(),
        ),
      );
      amountController.clear();
    });

    widget.onUpdated();
  }

  void _updateOdds() {
    final a = double.tryParse(oddAController.text.trim());
    final b = double.tryParse(oddBController.text.trim());
    final d = double.tryParse(oddDrawController.text.trim());

    if (a == null || b == null || d == null) return;

    setState(() {
      widget.match.oddA = a;
      widget.match.oddB = b;
      widget.match.oddDraw = d;
    });

    widget.onUpdated();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã cập nhật odds')));
  }
}

class HedgingManagementPage extends StatelessWidget {
  final List<MatchItem> matches;
  final ValueChanged<HedgeOrder> onToggleHedgeStatus;

  const HedgingManagementPage({
    super.key,
    required this.matches,
    required this.onToggleHedgeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final orders =
        matches
            .expand(
              (match) =>
                  match.hedges.map((hedge) => (match: match, hedge: hedge)),
            )
            .toList()
          ..sort((a, b) => b.hedge.createdAt.compareTo(a.hedge.createdAt));

    if (orders.isEmpty) {
      return const Center(child: Text('Chưa có lệnh hedging nào'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final item = orders[index];
        final match = item.match;
        final hedge = item.hedge;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(match.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('Đẩy ${money(hedge.amount)} - ${sideLabel(hedge.side)}'),
                Text('Nhà cái đối ứng: ${hedge.targetBookie}'),
                Text('Thời gian: ${formatTime(hedge.createdAt)}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text(
                    hedge.status == HedgeStatus.pending ? 'Đang chờ' : 'Đã thu',
                  ),
                ),
                TextButton(
                  onPressed: () => onToggleHedgeStatus(hedge),
                  child: const Text('Đổi trạng thái'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SettingsPage extends StatelessWidget {
  final double threshold;
  final ValueChanged<double> onChanged;

  const SettingsPage({
    super.key,
    required this.threshold,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ngưỡng cảnh báo rủi ro',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Bias > ${threshold.toStringAsFixed(0)}% thì hệ thống sẽ gợi ý hedge.',
                ),
                Slider(
                  min: 5,
                  max: 50,
                  divisions: 9,
                  value: threshold,
                  label: '${threshold.toStringAsFixed(0)}%',
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kiến trúc đề xuất',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('- State Management: Provider hoặc Bloc'),
                Text('- Local DB: Isar / Hive'),
                Text('- Biểu đồ nâng cao: fl_chart'),
                Text(
                  '- Có thể tách thành layers: models / services / providers / screens / widgets',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ExposureBar extends StatelessWidget {
  final MatchItem match;

  const ExposureBar({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final total = match.totalPool <= 0 ? 1 : match.totalPool;
    final aRatio = match.poolA / total;
    final bRatio = match.poolB / total;
    final dRatio = match.poolDraw / total;

    Color barColor(double ratio) {
      if (ratio >= 0.6) return Colors.red;
      if (ratio >= 0.4) return Colors.orange;
      return Colors.green;
    }

    return Column(
      children: [
        _bar('Đội A', aRatio, barColor(aRatio), match.poolA),
        const SizedBox(height: 8),
        _bar('Đội B', bRatio, barColor(bRatio), match.poolB),
        const SizedBox(height: 8),
        _bar('Hòa', dRatio, barColor(dRatio), match.poolDraw),
      ],
    );
  }

  Widget _bar(String label, double ratio, Color color, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(ratio * 100).toStringAsFixed(1)}% • ${money(amount)}'),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio.clamp(0, 1),
            minHeight: 12,
            color: color,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
}

class ScenarioTile extends StatelessWidget {
  final String label;
  final double value;

  const ScenarioTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isProfit = value >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isProfit ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            money(value),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isProfit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const InfoChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}

class RiskBadge extends StatelessWidget {
  final bool isDanger;

  const RiskBadge({super.key, required this.isDanger});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isDanger ? 'Rủi ro cao' : 'Ổn định'),
      backgroundColor: isDanger
          ? Colors.red.withOpacity(0.15)
          : Colors.green.withOpacity(0.15),
    );
  }
}

String money(double value) {
  final negative = value < 0;
  final raw = value.abs().round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    final position = raw.length - i;
    buffer.write(raw[i]);
    if (position > 1 && position % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${negative ? '-' : ''}${buffer.toString()}đ';
}

String sideLabel(BetSide side) {
  switch (side) {
    case BetSide.teamA:
      return 'Đội A';
    case BetSide.teamB:
      return 'Đội B';
    case BetSide.draw:
      return 'Hòa';
  }
}

String sideShort(BetSide side) {
  switch (side) {
    case BetSide.teamA:
      return 'A';
    case BetSide.teamB:
      return 'B';
    case BetSide.draw:
      return 'H';
  }
}

String formatTime(DateTime time) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)} - ${two(time.day)}/${two(time.month)}/${time.year}';
}
