import 'package:flutter_test/flutter_test.dart';
import 'package:first_block/models/bet_entry.dart';
import 'package:first_block/models/match_item.dart';
import 'package:first_block/services/risk_engine.dart';

void main() {
  group('RiskEngine.calculateRisk', () {
    test('returns no hedge when pools are empty', () {
      final match = MatchItem(
        id: 'm0',
        title: 'A vs B',
        nameTeamA: 'A',
        nameTeamB: 'B',
        oddA: 1.9,
        oddB: 1.9,
        oddDraw: 3.2,
      );

      final metrics = RiskEngine.calculateRisk(match, 20);

      expect(metrics.shouldHedge, isFalse);
      expect(metrics.biasPercent, 0);
      expect(metrics.hedgeAmount, 0);
      expect(metrics.heavySide, isNull);
    });

    test('includes draw pool when selecting heavy side and hedge amount', () {
      final match = MatchItem(
        id: 'm1',
        title: 'A vs B',
        nameTeamA: 'A',
        nameTeamB: 'B',
        oddA: 1.9,
        oddB: 2.0,
        oddDraw: 3.2,
        bets: [
          BetEntry(
            id: 'b1',
            side: BetSide.teamA,
            amount: 100,
            odds: 1.9,
            createdAt: DateTime.now(),
          ),
          BetEntry(
            id: 'b2',
            side: BetSide.teamB,
            amount: 200,
            odds: 2.0,
            createdAt: DateTime.now(),
          ),
          BetEntry(
            id: 'b3',
            side: BetSide.draw,
            amount: 700,
            odds: 3.2,
            createdAt: DateTime.now(),
          ),
        ],
      );

      final metrics = RiskEngine.calculateRisk(match, 20);

      expect(metrics.heavySide, BetSide.draw);
      expect(metrics.shouldHedge, isTrue);
      expect(metrics.hedgeAmount, closeTo(366.6667, 0.001));
      expect(metrics.biasPercent, closeTo(36.6667, 0.001));
    });
  });
}

