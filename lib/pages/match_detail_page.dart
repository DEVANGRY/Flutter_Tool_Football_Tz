import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bet_entry.dart';
import '../models/match_item.dart';
import '../utils/format.dart';

class MatchDetailPage extends StatelessWidget {
  final MatchItem match;

  const MatchDetailPage({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final pnlA = _projectedPnL(match, BetSide.teamA);
    final pnlB = _projectedPnL(match, BetSide.teamB);
    final pnlDraw = _projectedPnL(match, BetSide.draw);
    final displayBets = [...match.bets]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết trận'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.withOpacity(0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Tổng số cược: ${match.bets.length}'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PnlChip(label: '${match.nameTeamA} thắng', pnl: pnlA),
                    _PnlChip(label: '${match.nameTeamB} thắng', pnl: pnlB),
                    _PnlChip(label: 'Hòa', pnl: pnlDraw),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: match.bets.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có người nhập cược cho trận này',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayBets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final bet = displayBets[index];
                      return _BetTile(match: match, bet: bet, index: index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  double _projectedPnL(MatchItem match, BetSide resultSide) {
    final payout = match.bets
        .where((e) => e.side == resultSide)
        .fold<double>(0, (s, e) => s + (e.amount * e.odds));
    final receive = match.bets
        .where((e) => e.side != resultSide)
        .fold<double>(0, (s, e) => s + e.amount);
    return receive - payout;
  }
}

class _PnlChip extends StatelessWidget {
  final String label;
  final double pnl;

  const _PnlChip({required this.label, required this.pnl});

  @override
  Widget build(BuildContext context) {
    final isPositive = pnl >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: ${money(pnl)}',
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BetTile extends StatelessWidget {
  final MatchItem match;
  final BetEntry bet;
  final int index;

  const _BetTile({required this.match, required this.bet, required this.index});

  @override
  Widget build(BuildContext context) {
    final betPnl = bet.amount - (bet.amount * bet.odds);
    final betPnlColor = betPnl >= 0 ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.deepPurple.withOpacity(0.12),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bet.nameTeam?.trim().isNotEmpty == true
                      ? bet.nameTeam!.trim()
                      : 'Khong ro ten',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _sideLabel(match, bet),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đặt lúc: ${DateFormat('HH:mm dd/MM').format(bet.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'P/L: ${money(betPnl)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: betPnlColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            money(bet.amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  String _sideLabel(MatchItem match, BetEntry bet) {
    switch (bet.side) {
      case BetSide.teamA:
        return '${match.nameTeamA} @ ${bet.odds.toStringAsFixed(2)}';
      case BetSide.teamB:
        return '${match.nameTeamB} @ ${bet.odds.toStringAsFixed(2)}';
      case BetSide.draw:
        return 'Hoa @ ${bet.odds.toStringAsFixed(2)}';
    }
  }
}
