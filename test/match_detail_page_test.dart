import 'package:first_block/models/bet_entry.dart';
import 'package:first_block/models/match_item.dart';
import 'package:first_block/pages/match_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows bettor name, side, amount, time and P/L in match detail', (
    WidgetTester tester,
  ) async {
    final match = MatchItem(
      id: 'm1',
      title: 'A vs B',
      nameTeamA: 'Team A',
      nameTeamB: 'Team B',
      oddA: 1.8,
      oddB: 2.1,
      oddDraw: 3.1,
      bets: [
        BetEntry(
          id: 'b1',
          side: BetSide.teamA,
          amount: 1000000,
          odds: 1.8,
          createdAt: DateTime(2026, 4, 22, 9, 15),
          nameTeam: 'Nguyen Van A',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: MatchDetailPage(match: match)),
    );

    expect(find.text('Nguyen Van A'), findsOneWidget);
    expect(find.text('Team A @ 1.80'), findsOneWidget);
    expect(find.text('1.000.000'), findsOneWidget);
    expect(find.text('Đặt lúc: 09:15 22/04'), findsOneWidget);
    expect(find.textContaining('P/L:'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Team A thắng:'), findsOneWidget);
    expect(find.textContaining('-800'), findsAtLeastNWidgets(1));
  });

  testWidgets('shows empty state when no bets', (WidgetTester tester) async {
    final match = MatchItem(
      id: 'm2',
      title: 'C vs D',
      nameTeamA: 'Team C',
      nameTeamB: 'Team D',
      oddA: 2.0,
      oddB: 2.2,
      oddDraw: 3.3,
    );

    await tester.pumpWidget(
      MaterialApp(home: MatchDetailPage(match: match)),
    );

    expect(find.text('Chưa có người nhập cược cho trận này'), findsOneWidget);
  });
}
