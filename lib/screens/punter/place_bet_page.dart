import 'package:flutter/material.dart';
import 'models/bet_entry.dart';
import 'models/match_item.dart';
import 'utils/formatters.dart';

class PlaceBetPage extends StatefulWidget {
  final MatchItem match;

  const PlaceBetPage({super.key, required this.match});

  @override
  State<PlaceBetPage> createState() => _PlaceBetPageState();
}

class _PlaceBetPageState extends State<PlaceBetPage> {
  BetSide? selectedSide;
  final amountController = TextEditingController();
  final List<double> quickAmounts = [
    100000,
    500000,
    1000000,
    5000000,
    10000000,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt cược'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.match.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'Sắp diễn ra',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chọn cửa cược',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _buildBetOption(
            BetSide.teamA,
            'Đội A',
            widget.match.oddA,
            Icons.sports_soccer,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildBetOption(
            BetSide.draw,
            'Hòa',
            widget.match.oddDraw,
            Icons.horizontal_rule,
            Colors.grey,
          ),
          const SizedBox(height: 12),
          _buildBetOption(
            BetSide.teamB,
            'Đội B',
            widget.match.oddB,
            Icons.sports_soccer,
            Colors.orange,
          ),
          const SizedBox(height: 24),
          Text(
            'Số tiền đặt cược',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Nhập số tiền',
              hintText: 'Ví dụ: 1000000',
              prefixText: 'đ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickAmounts.map((amount) {
              return OutlinedButton(
                onPressed: () {
                  setState(() {
                    amountController.text = amount.toInt().toString();
                  });
                },
                child: Text(money(amount)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (selectedSide != null && amountController.text.isNotEmpty) ...[
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tóm tắt cược',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildSummaryRow(
                      'Cửa cược:',
                      _getSideName(selectedSide!),
                    ),
                    _buildSummaryRow(
                      'Tỷ lệ:',
                      _getOdds(selectedSide!).toStringAsFixed(2),
                    ),
                    _buildSummaryRow(
                      'Tiền đặt:',
                      money(double.tryParse(amountController.text) ?? 0),
                    ),
                    const Divider(),
                    _buildSummaryRow(
                      'Tiền thắng dự kiến:',
                      money(_calculatePotentialWin()),
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: selectedSide != null &&
                    (double.tryParse(amountController.text) ?? 0) > 0
                ? _placeBet
                : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Xác nhận đặt cược',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBetOption(
    BetSide side,
    String label,
    double odds,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedSide == side;
    return InkWell(
      onTap: () {
        setState(() {
          selectedSide = side;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    'Tỷ lệ: ${odds.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                odds.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _getSideName(BetSide side) {
    switch (side) {
      case BetSide.teamA:
        return 'Đội A';
      case BetSide.teamB:
        return 'Đội B';
      case BetSide.draw:
        return 'Hòa';
    }
  }

  double _getOdds(BetSide side) {
    switch (side) {
      case BetSide.teamA:
        return widget.match.oddA;
      case BetSide.teamB:
        return widget.match.oddB;
      case BetSide.draw:
        return widget.match.oddDraw;
    }
  }

  double _calculatePotentialWin() {
    if (selectedSide == null) return 0;
    final amount = double.tryParse(amountController.text) ?? 0;
    final odds = _getOdds(selectedSide!);
    return amount * odds;
  }

  void _placeBet() {
    final amount = double.tryParse(amountController.text) ?? 0;
    if (amount <= 0 || selectedSide == null) return;

    final odds = _getOdds(selectedSide!);

    setState(() {
      widget.match.bets.add(
        BetEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          side: selectedSide!,
          amount: amount,
          odds: odds,
          createdAt: DateTime.now(),
        ),
      );
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Đặt cược thành công!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cửa: ${_getSideName(selectedSide!)}'),
            Text('Số tiền: ${money(amount)}'),
            Text('Tỷ lệ: ${odds.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'Tiền thắng dự kiến: ${money(_calculatePotentialWin())}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                selectedSide = null;
                amountController.clear();
              });
            },
            child: const Text('Đặt cược tiếp'),
          ),
        ],
      ),
    );
  }
}
