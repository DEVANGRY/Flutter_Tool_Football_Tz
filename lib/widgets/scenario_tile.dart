import 'package:flutter/material.dart';
import '../utils/format.dart';

class ScenarioTile extends StatelessWidget {
  final String label;
  final String value;

  const ScenarioTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    double moneyValue =
        double.tryParse(value.replaceAll("+", "").replaceAll("-", "")) ?? 0;
    final isProfit =
        (value[0] == "+" ? double.parse(value) : double.parse(value)) >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isProfit ? Colors.green : Colors.red).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            "${isProfit ? "+" : "-"}${money(moneyValue)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isProfit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
