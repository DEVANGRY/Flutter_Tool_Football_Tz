import '../models/match_item.dart';
import '../models/bet_entry.dart';

final sampleMatches = [
  MatchItem(
    id: 'm1',
    title: 'Manchester City vs Liverpool',
    oddA: 1.82,
    oddB: 2.15,
    nameTeamA: "Manchester City",
    nameTeamB: "Liverpool",
    oddDraw: 3.10,
    bets: [
      BetEntry(
        id: 'b1',
        side: BetSide.teamA,
        amount: 12000000,
        odds: 1.82,
        nameTeam: 'Tran Van An',
        createdAt: DateTime(2026, 4, 22, 9, 15),
      ),
      BetEntry(
        id: 'b2',
        side: BetSide.teamB,
        amount: 4000000,
        odds: 2.15,
        nameTeam: 'Pham Minh Duc',
        createdAt: DateTime(2026, 4, 22, 10, 40),
      ),
      BetEntry(
        id: 'b3',
        side: BetSide.draw,
        amount: 2000000,
        odds: 3.10,
        nameTeam: 'Le Quoc Huy',
        createdAt: DateTime(2026, 4, 22, 11, 5),
      ),
    ],
  ),

  MatchItem(
    id: 'm2',
    title: 'Real Madrid vs Barcelona',
    nameTeamA: "Real Madrid",
    nameTeamB: "Barcelona",
    oddA: 1.95,
    oddB: 1.90,
    oddDraw: 3.25,
    bets: [
      BetEntry(
        id: 'b4',
        side: BetSide.teamA,
        amount: 7000000,
        odds: 1.95,
        nameTeam: 'Nguyen Huu Khang',
        createdAt: DateTime(2026, 4, 22, 12, 10),
      ),
      BetEntry(
        id: 'b5',
        side: BetSide.teamB,
        amount: 9000000,
        odds: 1.90,
        nameTeam: 'Doan Gia Bao',
        createdAt: DateTime(2026, 4, 22, 12, 35),
      ),
    ],
  ),
];
