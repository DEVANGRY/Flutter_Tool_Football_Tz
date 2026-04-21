import 'package:flutter/material.dart';

class RiskBadge extends StatelessWidget {
  final bool isDanger;

  const RiskBadge({super.key, required this.isDanger});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isDanger ? "Rủi ro cao" : "Ổn"),
      backgroundColor: isDanger
          ? Colors.red.withOpacity(0.2)
          : Colors.green.withOpacity(0.2),
    );
  }
}
