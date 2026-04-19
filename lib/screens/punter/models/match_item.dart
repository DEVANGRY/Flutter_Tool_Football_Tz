import 'bet_entry.dart';

class MatchItem {
  final String id;
  final String title;
  double oddA;
  double oddB;
  double oddDraw;
  final List<BetEntry> bets;

  MatchItem({
    required this.id,
    required this.title,
    required this.oddA,
    required this.oddB,
    required this.oddDraw,
    List<BetEntry>? bets,
  }) : bets = bets ?? [];

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
}
