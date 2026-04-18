import 'package:first_block/models/bet_entry.dart';
import 'package:first_block/models/match_item.dart';
import 'package:first_block/services/risk_engine.dart';
import 'package:flutter/material.dart';
import 'risk_badge.dart';
import 'exposure_bar.dart';
import 'scenario_tile.dart';
import '../utils/format.dart';

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

  @override
  Widget build(BuildContext context) {
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
                    value: calculatePnL(match, "A"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ScenarioTile(
                    label: "${match.nameTeamB} thắng",
                    value: calculatePnL(match, "B"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ScenarioTile(
                    label: "Hòa",
                    value: calculatePnL(match, "D"),
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
