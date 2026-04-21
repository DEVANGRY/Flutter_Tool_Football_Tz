import '../models/match_item.dart';
import '../models/bet_entry.dart';

class RiskMetrics {
  final double biasPercent;
  final bool shouldHedge;
  final double hedgeAmount;
  final BetSide? heavySide;

  RiskMetrics({
    required this.biasPercent,
    required this.shouldHedge,
    required this.hedgeAmount,
    required this.heavySide,
  });
}

class RiskEngine {
  static RiskMetrics calculateRisk(MatchItem match, double threshold) {
    double a = match.poolA;
    double b = match.poolB;

    double total = a + b;

    if (total == 0) {
      return RiskMetrics(
        biasPercent: 0,
        shouldHedge: false,
        hedgeAmount: 0,
        heavySide: null,
      );
    }

    double bias = ((a - b).abs() / total) * 100;

    BetSide heavy = a > b ? BetSide.teamA : BetSide.teamB;

    double hedge = (a - b).abs() / 2;

    return RiskMetrics(
      biasPercent: bias,
      shouldHedge: bias > threshold,
      hedgeAmount: hedge,
      heavySide: heavy,
    );
  }
}
