import 'package:flutter/material.dart';

class ScenarioTile extends StatelessWidget {
  final String label;
  final String value;
  final double pnl;
  final VoidCallback onTap;

  const ScenarioTile({
    super.key,
    required this.label,
    required this.value,
    required this.pnl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = pnl >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isProfit
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isProfit ? Colors.green : Colors.red),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isProfit ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Chi tiết →",
              style: TextStyle(
                fontSize: 11,
                color: isProfit ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
