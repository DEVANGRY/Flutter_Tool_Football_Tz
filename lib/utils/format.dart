import 'package:first_block/models/bet_entry.dart';
import 'package:first_block/models/match_item.dart';
import 'package:intl/intl.dart';

String money(double value) {
  final formatter = NumberFormat('#,###', 'vi_VN');
  return '${formatter.format(value)}';
}

String sideLabel(dynamic side) {
  switch (side.toString()) {
    case 'BetSide.teamA':
      return 'Đội A';
    case 'BetSide.teamB':
      return 'Đội B';
    default:
      return 'Hòa';
  }
}

String calculatePnL(MatchItem match, String result) {
  double totalPayout = 0;

  for (var bet in match.bets) {
    if (result == "A" && bet.side == BetSide.teamA) {
      totalPayout += (bet.amount - bet.amount * bet.odds);
    } else if (result == "B" && bet.side == BetSide.teamB) {
      totalPayout += (bet.amount - bet.amount * bet.odds);
    } else if (result == "D" && bet.side == BetSide.draw) {
      totalPayout += (bet.amount - bet.amount * bet.odds);
    }
  }

  return "$totalPayout";
}

double calculateTotalBetAmount(MatchItem match) {
  return match.bets.fold(0, (sum, bet) => sum! + bet.amount) ?? 0;
}
