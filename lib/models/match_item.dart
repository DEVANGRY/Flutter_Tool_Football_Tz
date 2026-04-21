import 'bet_entry.dart';
import 'hedge_order.dart';

class MatchItem {
  final String id;
  final String title;
  final String nameTeamA;
  final String nameTeamB;
  double oddA;
  double oddB;
  double oddDraw;

  final List<BetEntry> bets;
  final List<HedgeOrder> hedges;

  MatchItem({
    required this.id,
    required this.title,
    required this.nameTeamA,
    required this.nameTeamB,
    required this.oddA,
    required this.oddB,
    required this.oddDraw,
    List<BetEntry>? bets,
    List<HedgeOrder>? hedges,
  }) : bets = bets ?? [],
       hedges = hedges ?? [];

  double get poolA => bets
      .where((e) => e.side == BetSide.teamA)
      .fold(0, (s, e) => s + e.amount);

  double get poolB => bets
      .where((e) => e.side == BetSide.teamB)
      .fold(0, (s, e) => s + e.amount);

  double get poolDraw =>
      bets.where((e) => e.side == BetSide.draw).fold(0, (s, e) => s + e.amount);

  double get totalPool => poolA + poolB + poolDraw;

  // Hedge getters
  double get hedgeA => hedges
      .where((e) => e.side == BetSide.teamA && e.status == HedgeStatus.pending)
      .fold(0, (s, e) => s + e.amount);

  double get hedgeB => hedges
      .where((e) => e.side == BetSide.teamB && e.status == HedgeStatus.pending)
      .fold(0, (s, e) => s + e.amount);

  double get hedgeDraw => hedges
      .where((e) => e.side == BetSide.draw && e.status == HedgeStatus.pending)
      .fold(0, (s, e) => s + e.amount);

  double get netExposureA => poolA - hedgeA;
  double get netExposureB => poolB - hedgeB;
  double get netExposureDraw => poolDraw - hedgeDraw;
}
