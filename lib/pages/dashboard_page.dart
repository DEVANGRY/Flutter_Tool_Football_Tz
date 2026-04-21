import 'package:flutter/material.dart';
import '../models/match_item.dart';
import '../models/bet_entry.dart';
import '../services/risk_engine.dart';
import '../widgets/match_card.dart';
import '../utils/format.dart';

class DashboardPage extends StatefulWidget {
  final List<MatchItem> matches;
  final double riskThreshold;
  final Function(String matchId, BetSide side, double amount) onAddBet;
  final Function(String matchId, double oddA, double oddB, double oddDraw)
  onUpdateOdds;

  const DashboardPage({
    super.key,
    required this.matches,
    required this.riskThreshold,
    required this.onAddBet,
    required this.onUpdateOdds,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DateTime _now;
  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
  }
  Widget build(BuildContext context) {
    final matches = widget.matches;
    final now = _now;

    final totalMatches = matches.length;
    final totalBetAmount = matches.fold<double>(
      0,
      (sum, m) => sum + m.totalPool,
    );
    final matchesNeedingHedge = matches
        .where(
          (m) => RiskEngine.calculateRisk(m, widget.riskThreshold).shouldHedge,
        )
        .length;
    final totalPotentialProfit = matches.fold<double>(0, (sum, m) {
      final pnl =
          double.tryParse(calculatePnL(m, 'A')) ?? 0; // Lấy P/L trung bình
      return sum + pnl;
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.deepPurple.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Kiếm Tiền Không Khó",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDateTime(now),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade800,
                      Colors.deepPurple.shade600,
                      Colors.purple.shade500,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: 20,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // THỐNG KÊ TỔNG QUAN
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        "Tổng quan hệ thống",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statCard(
                        icon: Icons.sports_soccer,
                        label: "Tổng trận",
                        value: "$totalMatches",
                        color: Colors.blue,
                      ),
                      _statCard(
                        icon: Icons.attach_money,
                        label: "Tổng tiền cược",
                        value: money(totalBetAmount),
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard(
                        icon: Icons.warning_amber,
                        label: "Cần hedging",
                        value: "$matchesNeedingHedge",
                        color: Colors.orange,
                      ),
                      _statCard(
                        icon: Icons.trending_up,
                        label: "Lợi nhuận dự kiến trong ngày",
                        value: money(totalPotentialProfit),
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // DANH SÁCH TRẬN ĐẤU
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    "Danh sách trận đấu ($totalMatches)",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // LIST VIEW TRẬN
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final match = matches[index];
                final risk = RiskEngine.calculateRisk(
                  match,
                  widget.riskThreshold,
                );
                return MatchCard(
                  match: match,
                  risk: risk,
                  now: now,
                  index: index,
                );
              }, childCount: matches.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text("Nhập cược"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final days = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final dayName = days[dt.weekday - 1];
    final month = dt.month < 10 ? "0${dt.month}" : "${dt.month}";
    return "$dayName, ${dt.day}/$month/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
