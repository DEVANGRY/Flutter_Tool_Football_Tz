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
    final exposures = <BetSide, double>{
      BetSide.teamA: match.poolA,
      BetSide.teamB: match.poolB,
      BetSide.draw: match.poolDraw,
    };

    final total = exposures.values.fold<double>(
      0.0,
      (sum, value) => sum + value,
    );

    if (total == 0) {
      return RiskMetrics(
        biasPercent: 0.0,
        shouldHedge: false,
        hedgeAmount: 0.0,
        heavySide: null,
      );
    }

    final heavyEntry = exposures.entries.reduce(
      (current, next) => current.value >= next.value ? current : next,
    );

    final double idealPerSide = total / exposures.length;
    final double excess = heavyEntry.value - idealPerSide;
    final double bias =
        excess <= 0 ? 0.0 : ((excess / total) * 100).toDouble();

    return RiskMetrics(
      biasPercent: bias.toDouble(),
      shouldHedge: bias > threshold,
      hedgeAmount: (excess <= 0 ? 0.0 : excess).toDouble(),
      heavySide: excess <= 0 ? null : heavyEntry.key,
    );
  }
}
