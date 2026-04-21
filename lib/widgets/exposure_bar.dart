import 'package:flutter/material.dart';
import '../models/match_item.dart';
import '../utils/format.dart';

class ExposureBar extends StatelessWidget {
  final MatchItem match;

  const ExposureBar({super.key, required this.match});
  @override
  Widget build(BuildContext context) {
    double total = match.totalPool == 0 ? 1 : match.totalPool;

    return Column(
      children: [
        _row(
          "${match.nameTeamA} (${match.oddA})",
          match.poolA / total,
          match.poolA,
        ),
        _row(
          "${match.nameTeamB} (${match.oddB})",
          match.poolB / total,
          match.poolB,
        ),
        _row(
          "Hòa (${match.oddDraw}) ",
          match.poolDraw / total,
          match.poolDraw,
        ),
      ],
    );
  }

  Widget _row(String label, double percent, double value) {
    Color color = percent > 0.6
        ? Colors.red
        : percent > 0.4
        ? Colors.orange
        : Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text("$label")),
              Text("${(percent * 100).toStringAsFixed(1)}% • ${money(value)}"),
            ],
          ),
          LinearProgressIndicator(value: percent, color: color),
        ],
      ),
    );
  }
}
