import 'bet_entry.dart';

enum HedgeStatus { pending, settled }

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
