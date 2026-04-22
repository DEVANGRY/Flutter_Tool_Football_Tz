import 'package:flutter/material.dart';
import '../models/match_item.dart';
import '../models/bet_entry.dart';
import '../models/hedge_order.dart';
import '../services/risk_engine.dart';
import '../utils/format.dart';

class HedgingPage extends StatefulWidget {
  final List<MatchItem> matches;
  final double riskThreshold;
  final Function(String matchId, String bookie, BetSide side, double amount)
  onAddHedge;
  final Function(String matchId, String orderId) onToggleHedgeStatus;

  const HedgingPage({
    super.key,
    required this.matches,
    required this.riskThreshold,
    required this.onAddHedge,
    required this.onToggleHedgeStatus,
  });

  @override
  State<HedgingPage> createState() => _HedgingPageState();
}

class _HedgingPageState extends State<HedgingPage> {
  // Danh sách bookies mẫu
  final List<String> _bookies = [
    'Bet365',
    'W88',
    'FB88',
    'M88',
    'VN88',
    '12Bet',
  ];

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách các trận cần hedging từ widget.matches
    final matchesNeedingHedge = widget.matches.where((m) {
      final risk = RiskEngine.calculateRisk(m, widget.riskThreshold);
      return risk.shouldHedge;
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.orange.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "Hedging",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade800,
                      Colors.orange.shade600,
                      Colors.deepOrange.shade500,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // Thống kê tổng quan
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.balance, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        "Tổng quan Hedging",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statCard(
                        icon: Icons.warning_amber,
                        label: "Cần hedge",
                        value: "${matchesNeedingHedge.length}",
                        color: Colors.orange,
                      ),
                      _statCard(
                        icon: Icons.pending_actions,
                        label: "Chờ xử lý",
                        value: "${_getPendingCount()}",
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard(
                        icon: Icons.check_circle,
                        label: "Đã settle",
                        value: "${_getSettledCount()}",
                        color: Colors.green,
                      ),
                      _statCard(
                        icon: Icons.attach_money,
                        label: "Tổng amount",
                        value: money(_getTotalHedgeAmount()),
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tiêu đề danh sách
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    "Danh sách trận cần Hedging",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Danh sách các trận cần hedging
          if (matchesNeedingHedge.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Tất cả các trận đã an toàn!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Không có trận nào cần hedging lúc này",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final match = matchesNeedingHedge[index];
                return _HedgeMatchCard(
                  match: match,
                  hedgeOrders: match.hedges,
                  bookies: _bookies,
                  riskThreshold: widget.riskThreshold,
                  onAddOrder: (bookie, side, amount) {
                    widget.onAddHedge(match.id, bookie, side, amount);
                  },
                  onUpdateStatus: (orderId) {
                    widget.onToggleHedgeStatus(match.id, orderId);
                  },
                );
              }, childCount: matchesNeedingHedge.length),
            ),

          // Padding bottom
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  int _getPendingCount() {
    int count = 0;
    for (var match in widget.matches) {
      count += match.hedges
          .where((o) => o.status == HedgeStatus.pending)
          .length;
    }
    return count;
  }

  int _getSettledCount() {
    int count = 0;
    for (var match in widget.matches) {
      count += match.hedges
          .where((o) => o.status == HedgeStatus.settled)
          .length;
    }
    return count;
  }

  double _getTotalHedgeAmount() {
    double total = 0;
    for (var match in widget.matches) {
      total += match.hedges.fold(0, (sum, o) => sum + o.amount);
    }
    return total;
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget hiển thị thông tin một trận cần hedging
class _HedgeMatchCard extends StatefulWidget {
  final MatchItem match;
  final List<HedgeOrder> hedgeOrders;
  final List<String> bookies;
  final double riskThreshold;
  final Function(String bookie, BetSide side, double amount) onAddOrder;
  final Function(String orderId) onUpdateStatus;

  const _HedgeMatchCard({
    required this.match,
    required this.hedgeOrders,
    required this.bookies,
    required this.riskThreshold,
    required this.onAddOrder,
    required this.onUpdateStatus,
  });

  @override
  State<_HedgeMatchCard> createState() => _HedgeMatchCardState();
}

class _HedgeMatchCardState extends State<_HedgeMatchCard> {
  @override
  Widget build(BuildContext context) {
    final risk = RiskEngine.calculateRisk(widget.match, widget.riskThreshold);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.match.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.match.nameTeamA} vs ${widget.match.nameTeamB}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Bias: ${risk.biasPercent.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pool info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _poolInfo(
                    label: widget.match.nameTeamA,
                    pool: widget.match.poolA,
                    odd: widget.match.oddA,
                    isHeavy: risk.heavySide == BetSide.teamA,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _poolInfo(
                    label: 'Hòa',
                    pool: widget.match.poolDraw,
                    odd: widget.match.oddDraw,
                    isHeavy: risk.heavySide == BetSide.draw,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _poolInfo(
                    label: widget.match.nameTeamB,
                    pool: widget.match.poolB,
                    odd: widget.match.oddB,
                    isHeavy: risk.heavySide == BetSide.teamB,
                  ),
                ),
              ],
            ),
          ),

          // Hedge amount recommendation
          _hedgeInsightBlock(risk),

          // Nút thêm hedge order
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddHedgeDialog(context),
                icon: const Icon(Icons.add),
                label: const Text("Thêm lệnh Hedge"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // Danh sách hedge orders
          if (widget.hedgeOrders.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.list, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    "Hedge Orders (${widget.hedgeOrders.length})",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...widget.hedgeOrders.map((order) => _hedgeOrderTile(order)),
          ],
        ],
      ),
    );
  }

  Widget _poolInfo({
    required String label,
    required double pool,
    required double odd,
    required bool isHeavy,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHeavy ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isHeavy ? Border.all(color: Colors.red.shade200) : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            money(pool),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isHeavy ? Colors.red : Colors.black,
            ),
          ),
          Text(
            "Odd: ${odd.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          if (isHeavy)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "Nặng",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hedgeOrderTile(HedgeOrder order) {
    final isPending = order.status == HedgeStatus.pending;
    final sideLabel = switch (order.side) {
      BetSide.teamA => widget.match.nameTeamA,
      BetSide.teamB => widget.match.nameTeamB,
      BetSide.draw => 'Hòa',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? Colors.orange.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.pending : Icons.check_circle,
            color: isPending ? Colors.orange : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${order.targetBookie} - $sideLabel",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  money(order.amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (isPending)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => widget.onUpdateStatus(order.id),
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: "Settle",
                  iconSize: 20,
                ),
                IconButton(
                  onPressed: () => widget.onUpdateStatus(order.id),
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: "Hủy",
                  iconSize: 20,
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Settled",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddHedgeDialog(BuildContext context) {
    String selectedBookie = widget.bookies.first;
    final currentRisk = RiskEngine.calculateRisk(widget.match, widget.riskThreshold);
    BetSide selectedSide = currentRisk.worstSide ?? BetSide.teamA;
    bool simulateHedge = true;
    final amountController = TextEditingController(
      text: currentRisk.hedgeAmount.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.add_circle, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      "Thêm lệnh Hedge",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Chọn Bookie
                const Text(
                  "Chọn Bookie",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: selectedBookie,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: widget.bookies
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedBookie = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Chọn Side
                const Text(
                  "Chọn cửa đặt",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _sideOption(
                        label: widget.match.nameTeamA,
                        odd: widget.match.oddA,
                        isSelected: selectedSide == BetSide.teamA,
                        onTap: () {
                          setModalState(() {
                            selectedSide = BetSide.teamA;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _sideOption(
                        label: 'Hòa',
                        odd: widget.match.oddDraw,
                        isSelected: selectedSide == BetSide.draw,
                        onTap: () {
                          setModalState(() {
                            selectedSide = BetSide.draw;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _sideOption(
                        label: widget.match.nameTeamB,
                        odd: widget.match.oddB,
                        isSelected: selectedSide == BetSide.teamB,
                        onTap: () {
                          setModalState(() {
                            selectedSide = BetSide.teamB;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Switch(
                      value: simulateHedge,
                      onChanged: (value) {
                        setModalState(() {
                          simulateHedge = value;
                        });
                      },
                      activeThumbColor: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Simulate Hedge",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Nhập số tiền
                const Text(
                  "Số tiền",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModalState(() {}),
                  decoration: InputDecoration(
                    prefixText: "₫ ",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    final selectedOdd = _oddOf(selectedSide);
                    final simulated = simulateHedge
                        ? _simulateRisk(
                            currentRisk,
                            selectedSide,
                            amount,
                            selectedOdd,
                          )
                        : currentRisk;
                    return _hedgeInsightBlock(
                      simulated,
                      margin: EdgeInsets.zero,
                      header: "Preview",
                      showRawBeforeAfterLabel: false,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Nút xác nhận
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      if (amount > 0) {
                        widget.onAddOrder(selectedBookie, selectedSide, amount);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Xác nhận",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sideOption({
    required String label,
    required double odd,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.orange.shade700 : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              odd.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.orange.shade700
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sideDisplayName(BetSide side) {
    return switch (side) {
      BetSide.teamA => widget.match.nameTeamA,
      BetSide.teamB => widget.match.nameTeamB,
      BetSide.draw => 'Hòa',
    };
  }

  double _oddOf(BetSide side) {
    return switch (side) {
      BetSide.teamA => widget.match.oddA,
      BetSide.teamB => widget.match.oddB,
      BetSide.draw => widget.match.oddDraw,
    };
  }

  Widget _hedgeInsightBlock(
    RiskMetrics risk, {
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(horizontal: 16),
    String header = "Phân tích Hedge",
    bool showRawBeforeAfterLabel = true,
  }) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                header,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            showRawBeforeAfterLabel ? "TRƯỚC KHI HEDGE" : "BEFORE",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _pnlRow(label: widget.match.nameTeamA, value: risk.profitA),
          _pnlRow(label: "Hòa", value: risk.profitDraw),
          _pnlRow(label: widget.match.nameTeamB, value: risk.profitB),
          const SizedBox(height: 6),
          Text(
            "Lỗ nhiều nhất: ${money(risk.worstLoss)} (${_sideDisplayName(risk.worstSide ?? BetSide.teamA)})",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "GỢI Ý HEDGE",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            risk.worstSide == null || risk.hedgeAmount <= 0
                ? "Không cần hedge thêm."
                : "Bet ${money(risk.hedgeAmount)} vào ${_sideDisplayName(risk.worstSide!)} @${risk.hedgeOdd.toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Divider(height: 18),
          Text(
            showRawBeforeAfterLabel ? "SAU KHI HEDGE" : "AFTER",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _pnlRow(label: widget.match.nameTeamA, value: risk.afterProfitA),
          _pnlRow(label: "Hòa", value: risk.afterProfitDraw),
          _pnlRow(label: widget.match.nameTeamB, value: risk.afterProfitB),
          const SizedBox(height: 6),
          Text(
            "Lỗ: ${money(risk.afterWorstLoss)} (Cải thiện từ: ${money(risk.worstLoss)})",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: risk.improvement > 0 ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Cải thiện: +${money(risk.improvement)}",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: risk.improvement > 0 ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pnlRow({required String label, required double value}) {
    final isProfit = value >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(
            money(value),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isProfit ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  RiskMetrics _simulateRisk(
    RiskMetrics base,
    BetSide side,
    double amount,
    double odd,
  ) {
    final safeAmount = amount < 0 ? 0.0 : amount;
    final safeOdd = odd <= 1 ? 1.01 : odd;

    double calcAfter(BetSide outcome, double oldProfit) {
      if (safeAmount <= 0) {
        return oldProfit;
      }
      if (outcome == side) {
        return oldProfit + (safeAmount * (safeOdd - 1));
      }
      return oldProfit - safeAmount;
    }

    final afterA = calcAfter(BetSide.teamA, base.profitA);
    final afterDraw = calcAfter(BetSide.draw, base.profitDraw);
    final afterB = calcAfter(BetSide.teamB, base.profitB);
    final afterWorst = [afterA, afterDraw, afterB].reduce(
      (a, b) => a <= b ? a : b,
    );

    return RiskMetrics(
      profitA: base.profitA,
      profitDraw: base.profitDraw,
      profitB: base.profitB,
      worstLoss: base.worstLoss,
      worstSide: side,
      hedgeAmount: safeAmount,
      hedgeOdd: safeOdd,
      afterProfitA: afterA,
      afterProfitDraw: afterDraw,
      afterProfitB: afterB,
      afterWorstLoss: afterWorst,
      improvement: afterWorst - base.worstLoss,
      biasPercent: base.biasPercent,
      shouldHedge: base.shouldHedge,
      heavySide: side,
    );
  }
}
