import '../models/match_item.dart';
import '../models/bet_entry.dart';

class RiskMetrics {
  final double profitA;
  final double profitDraw;
  final double profitB;
  final double worstLoss;
  final BetSide? worstSide;
  final double hedgeAmount;
  final double hedgeOdd;
  final double afterProfitA;
  final double afterProfitDraw;
  final double afterProfitB;
  final double afterWorstLoss;
  final double improvement;
  final double biasPercent;
  final bool shouldHedge;
  final BetSide? heavySide;

  RiskMetrics({
    required this.profitA,
    required this.profitDraw,
    required this.profitB,
    required this.worstLoss,
    required this.worstSide,
    required this.biasPercent,
    required this.shouldHedge,
    required this.hedgeAmount,
    required this.hedgeOdd,
    required this.afterProfitA,
    required this.afterProfitDraw,
    required this.afterProfitB,
    required this.afterWorstLoss,
    required this.improvement,
    required this.heavySide,
  });
}

class RiskEngine {
  static RiskMetrics calculateRisk(MatchItem match, double threshold) {
    final totalPool = match.poolA + match.poolDraw + match.poolB;

    final profitA = totalPool - (match.poolA * match.oddA);
    final profitDraw = totalPool - (match.poolDraw * match.oddDraw);
    final profitB = totalPool - (match.poolB * match.oddB);

    final profits = <BetSide, double>{
      BetSide.teamA: profitA,
      BetSide.draw: profitDraw,
      BetSide.teamB: profitB,
    };

    final worstEntry = profits.entries.reduce(
      (current, next) => current.value <= next.value ? current : next,
    );
    final worstSide = worstEntry.key;
    final worstLoss = worstEntry.value;

    final hedgeOdd = _oddOf(match, worstSide);
    final shouldHedge = worstLoss < 0;
    final hedgeAmount = shouldHedge && hedgeOdd > 1
        ? worstLoss.abs() / (hedgeOdd - 1)
        : 0.0;

    final afterProfitA = _afterProfit(
      side: BetSide.teamA,
      oldProfit: profitA,
      worstSide: worstSide,
      hedgeAmount: hedgeAmount,
      hedgeOdd: hedgeOdd,
    );
    final afterProfitDraw = _afterProfit(
      side: BetSide.draw,
      oldProfit: profitDraw,
      worstSide: worstSide,
      hedgeAmount: hedgeAmount,
      hedgeOdd: hedgeOdd,
    );
    final afterProfitB = _afterProfit(
      side: BetSide.teamB,
      oldProfit: profitB,
      worstSide: worstSide,
      hedgeAmount: hedgeAmount,
      hedgeOdd: hedgeOdd,
    );

    final afterWorstLoss = [afterProfitA, afterProfitDraw, afterProfitB].reduce(
      (current, next) => current <= next ? current : next,
    );
    final improvement = afterWorstLoss - worstLoss;
    final biasPercent = totalPool > 0
        ? (worstLoss.abs() / totalPool) * 100
        : 0.0;

    return RiskMetrics(
      profitA: profitA,
      profitDraw: profitDraw,
      profitB: profitB,
      worstLoss: worstLoss,
      worstSide: worstSide,
      biasPercent: biasPercent,
      shouldHedge: shouldHedge && biasPercent > threshold,
      hedgeAmount: hedgeAmount,
      hedgeOdd: hedgeOdd,
      afterProfitA: afterProfitA,
      afterProfitDraw: afterProfitDraw,
      afterProfitB: afterProfitB,
      afterWorstLoss: afterWorstLoss,
      improvement: improvement,
      heavySide: shouldHedge ? worstSide : null,
    );
  }

  static double _oddOf(MatchItem match, BetSide side) {
    return switch (side) {
      BetSide.teamA => match.oddA,
      BetSide.draw => match.oddDraw,
      BetSide.teamB => match.oddB,
    };
  }

  static double _afterProfit({
    required BetSide side,
    required double oldProfit,
    required BetSide worstSide,
    required double hedgeAmount,
    required double hedgeOdd,
  }) {
    if (hedgeAmount <= 0) {
      return oldProfit;
    }
    if (side == worstSide) {
      return oldProfit + (hedgeAmount * (hedgeOdd - 1));
    }
    return oldProfit - hedgeAmount;
  }
}
