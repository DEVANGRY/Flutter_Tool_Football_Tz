import 'package:flutter/material.dart';
import 'models/bet_entry.dart';
import 'models/match_item.dart';
import 'utils/formatters.dart';

class MyBetsPage extends StatelessWidget {
  final List<MatchItem> matches;

  const MyBetsPage({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    final allBets = <({MatchItem match, BetEntry bet})>[];
    for (final match in matches) {
      for (final bet in match.bets) {
        allBets.add((match: match, bet: bet));
      }
    }

    allBets.sort((a, b) => b.bet.createdAt.compareTo(a.bet.createdAt));

    if (allBets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có cược nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy đặt cược vào trận đấu yêu thích!',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    double totalStaked = allBets.fold(0, (sum, item) => sum + item.bet.amount);
    double potentialWin = allBets.fold(
        0, (sum, item) => sum + (item.bet.amount * item.bet.odds));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'Tổng cược',
                      allBets.length.toString(),
                      Icons.receipt,
                    ),
                    _buildStatColumn(
                      'Tổng tiền đặt',
                      money(totalStaked),
                      Icons.payments,
                    ),
                    _buildStatColumn(
                      'Tiềm năng thắng',
                      money(potentialWin),
                      Icons.trending_up,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Lịch sử cược',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...allBets.map((item) => _buildBetCard(context, item.match, item.bet)),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade700),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildBetCard(BuildContext context, MatchItem match, BetEntry bet) {
    final potentialWin = bet.amount * bet.odds;
    final profit = potentialWin - bet.amount;

    Color sideColor;
    switch (bet.side) {
      case BetSide.teamA:
        sideColor = Colors.blue;
        break;
      case BetSide.teamB:
        sideColor = Colors.orange;
        break;
      case BetSide.draw:
        sideColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Đang chờ',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sideColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: sideColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_soccer, color: sideColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sideLabel(bet.side),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sideColor,
                          ),
                        ),
                        Text(
                          'Tỷ lệ: ${bet.odds.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    money(bet.amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiền thắng dự kiến',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      money(potentialWin),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Lợi nhuận',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '+${money(profit)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Text(
              formatTime(bet.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
