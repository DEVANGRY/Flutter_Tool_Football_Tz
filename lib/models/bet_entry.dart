
enum BetSide { teamA, teamB, draw }

class BetEntry {
  final String id;
  final BetSide side;
  final double amount;
  final double odds;
  final DateTime createdAt;
  final String? nameTeam;

  BetEntry({
    required this.id,
    required this.side,
    required this.amount,
    required this.odds,
    required this.createdAt,
    this.nameTeam,
  });
}
