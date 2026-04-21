import 'package:first_block/models/bet_entry.dart';
import 'package:first_block/models/match_item.dart';
import 'package:first_block/services/risk_engine.dart';
import 'package:flutter/material.dart';
import 'risk_badge.dart';
import 'exposure_bar.dart';
import 'scenario_tile.dart';
import '../utils/format.dart';
import '../pages/scenario_detail_page.dart';

class MatchCard extends StatelessWidget {
  final MatchItem match;
  final RiskMetrics risk;
  final DateTime now;
  final int index;

  const MatchCard({
    super.key,
    required this.match,
    required this.risk,
    required this.now,
    required this.index,
  });
  double getPnL(String side) {
    switch (side) {
      case "A":
        return (match.poolB + match.poolDraw) - (match.poolA * match.oddA);
      case "B":
        return (match.poolA + match.poolDraw) - (match.poolB * match.oddB);
      case "D":
        return (match.poolA + match.poolB) - (match.poolDraw * match.oddDraw);
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pnlA = getPnL("A");
    final pnlB = getPnL("B");
    final pnlD = getPnL("D");
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TITLE + BADGE + TIME
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Bắt đầu: ${_formatMatchTime(now.add(Duration(hours: index + 1)))}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                RiskBadge(isDanger: risk.shouldHedge),
              ],
            ),

            const SizedBox(height: 12),

            // EXPOSURE BAR
            ExposureBar(match: match),

            const SizedBox(height: 12),

            // POOL INFO
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _info(
                  "Tổng Tiền Kèo",
                  "${money(calculateTotalBetAmount(match))}",
                ),
                _info("Pool ${match.nameTeamA}", money(match.poolA)),
                _info("Pool ${match.nameTeamB}", money(match.poolB)),
                _info("Pool Hòa", money(match.poolDraw)),
                _info("Bias", "${risk.biasPercent.toStringAsFixed(1)}%"),
              ],
            ),

            const SizedBox(height: 12),

            // P/L SECTION
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "P/L dự kiến",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ScenarioTile(
                    label: "${match.nameTeamA} thắng",
                    value: money(double.parse(calculatePnL(match, "A"))),
                    pnl: pnlA,
                    onTap: () {
                      double payout = match.poolA * match.oddA;
                      double receive = match.poolB + match.poolDraw;
                      double pnl = receive - payout;
                      double total = calculateTotalBetAmount(match);
                      double percent = (pnl / total) * 100;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScenarioDetailPage(
                            title: "${match.nameTeamA} thắng",
                            matchName: match.title,
                            side: match.nameTeamA,
                            payOut: payout,
                            receive: receive,
                            pnl: pnl,
                            percentPnL: percent,
                            poolDetails: {
                              "Pool ${match.nameTeamA}": match.poolA,
                              "Pool ${match.nameTeamB}": match.poolB,
                              "Pool Hòa": match.poolDraw,
                            },
                            oddDetails: {"Odd ${match.nameTeamA}": match.oddA},
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ScenarioTile(
                    label: "${match.nameTeamB} thắng",
                    value: money(double.parse(calculatePnL(match, "B"))),
                    pnl: pnlB,
                    onTap: () {
                      double payout = match.poolB * match.oddB;
                      double receive = match.poolA + match.poolDraw;
                      double pnl = receive - payout;
                      double total = calculateTotalBetAmount(match);
                      double percent = (pnl / total) * 100;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScenarioDetailPage(
                            title: "${match.nameTeamB} thắng",
                            matchName: match.title,
                            side: match.nameTeamB,
                            payOut: payout,
                            receive: receive,
                            pnl: pnl,
                            percentPnL: percent,
                            poolDetails: {
                              "Pool ${match.nameTeamA}": match.poolA,
                              "Pool ${match.nameTeamB}": match.poolB,
                              "Pool Hòa": match.poolDraw,
                            },
                            oddDetails: {"Odd ${match.nameTeamB}": match.oddB},
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ScenarioTile(
                    label: "Hòa",
                    value: money(double.parse(calculatePnL(match, "D"))),
                    pnl: pnlD,
                    onTap: () {
                      double payout = match.poolDraw * match.oddDraw;
                      double receive = match.poolA + match.poolB;
                      double pnl = receive - payout;
                      double total = calculateTotalBetAmount(match);
                      double percent = (pnl / total) * 100;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScenarioDetailPage(
                            title: "Hòa",
                            matchName: match.title,
                            side: "Hòa",
                            payOut: payout,
                            receive: receive,
                            pnl: pnl,
                            percentPnL: percent,
                            poolDetails: {
                              "Pool ${match.nameTeamA}": match.poolA,
                              "Pool ${match.nameTeamB}": match.poolB,
                              "Pool Hòa": match.poolDraw,
                            },
                            oddDetails: {"Odd Hòa": match.oddDraw},
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // HEDGE ALERT
            if (risk.shouldHedge) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Cần đẩy sang nhà cái khác: ${money(risk.hedgeAmount)} cửa ${risk.heavySide == BetSide.teamA ? match.nameTeamA : match.nameTeamB}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87),
        children: [
          TextSpan(
            text: "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  String _formatMatchTime(DateTime dt) {
    final days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final dayName = days[dt.weekday % 7];
    return "$dayName ${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
