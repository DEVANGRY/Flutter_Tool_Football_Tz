import 'package:flutter/material.dart';
import '../models/match_item.dart';
import '../utils/format.dart';

class AdminPage extends StatefulWidget {
  final List<MatchItem> matches;
  final void Function(
    String title,
    String nameTeamA,
    String nameTeamB,
    double oddA,
    double oddB,
    double oddDraw,
  )
  onAddMatch;
  final void Function(MatchItem match, double oddA, double oddB, double oddDraw)
  onUpdateOdds;
  final ValueChanged<MatchItem> onDeleteMatch;

  const AdminPage({
    super.key,
    required this.matches,
    required this.onAddMatch,
    required this.onUpdateOdds,
    required this.onDeleteMatch,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _teamAController = TextEditingController();
  final _teamBController = TextEditingController();
  final _oddAController = TextEditingController(text: '1.90');
  final _oddBController = TextEditingController(text: '1.90');
  final _oddDrawController = TextEditingController(text: '3.20');

  @override
  void dispose() {
    _titleController.dispose();
    _teamAController.dispose();
    _teamBController.dispose();
    _oddAController.dispose();
    _oddBController.dispose();
    _oddDrawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalBets = widget.matches.fold<int>(
      0,
      (sum, m) => sum + m.bets.length,
    );
    final totalPool = widget.matches.fold<double>(
      0,
      (sum, m) => sum + m.totalPool,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.indigo.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Matches',
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
                      Colors.indigo.shade800,
                      Colors.indigo.shade600,
                      Colors.blue.shade500,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.sports_soccer,
                    size: 44,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
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
                      const Icon(Icons.insights, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        'Tổng quan Matches',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _statCard(
                        icon: Icons.sports_soccer,
                        label: 'Số trận',
                        value: '${widget.matches.length}',
                        color: Colors.blue,
                      ),
                      _statCard(
                        icon: Icons.receipt_long,
                        label: 'Số cược',
                        value: '$totalBets',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statCard(
                        icon: Icons.account_balance_wallet,
                        label: 'Tổng pool',
                        value: money(totalPool),
                        color: Colors.green,
                      ),
                      _statCard(
                        icon: Icons.show_chart,
                        label: 'TB / trận',
                        value: widget.matches.isEmpty
                            ? '0'
                            : money(totalPool / widget.matches.length),
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_circle, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Text(
                          'Thêm trận đấu mới',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên trận đấu',
                        hintText: 'Ví dụ: Arsenal vs Chelsea',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên trận';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _teamAController,
                            decoration: const InputDecoration(
                              labelText: 'Tên Đội A',
                              hintText: 'Arsenal',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nhập tên đội A';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _teamBController,
                            decoration: const InputDecoration(
                              labelText: 'Tên Đội B',
                              hintText: 'Chelsea',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nhập tên đội B';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _oddAController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Odds Đội A',
                            ),
                            validator: _validateOdd,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _oddBController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Odds Đội B',
                            ),
                            validator: _validateOdd,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _oddDrawController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Odds Hòa',
                            ),
                            validator: _validateOdd,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitAddMatch,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm trận'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    'Danh sách trận (${widget.matches.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.matches.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Chưa có trận đấu nào'),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final match = widget.matches[index];
                  return _buildMatchCard(match);
                }, childCount: widget.matches.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildMatchCard(MatchItem match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            match.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            '${match.nameTeamA} vs ${match.nameTeamB}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoPill(
                'Odd ${match.nameTeamA}',
                match.oddA.toStringAsFixed(2),
                Colors.blue,
              ),
              _infoPill(
                'Odd ${match.nameTeamB}',
                match.oddB.toStringAsFixed(2),
                Colors.red,
              ),
              _infoPill(
                'Odd Hòa',
                match.oddDraw.toStringAsFixed(2),
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pool: ${match.nameTeamA} ${money(match.poolA)} • ${match.nameTeamB} ${money(match.poolB)} • Hòa ${money(match.poolDraw)}',
          ),
          const SizedBox(height: 4),
          Text(
            'Tổng cược: ${money(match.totalPool)} • Bets: ${match.bets.length}',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEditOddsDialog(match),
                icon: const Icon(Icons.tune),
                label: const Text('Sửa odds'),
              ),
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(match),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa trận'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateOdd(String? value) {
    final odd = double.tryParse((value ?? '').trim());
    if (odd == null || odd <= 1) {
      return '> 1.0';
    }
    return null;
  }

  void _submitAddMatch() {
    if (!_formKey.currentState!.validate()) return;

    widget.onAddMatch(
      _titleController.text.trim(),
      _teamAController.text.trim(),
      _teamBController.text.trim(),
      double.parse(_oddAController.text.trim()),
      double.parse(_oddBController.text.trim()),
      double.parse(_oddDrawController.text.trim()),
    );

    _titleController.clear();
    _teamAController.clear();
    _teamBController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã thêm trận đấu')));
  }

  void _showEditOddsDialog(MatchItem match) {
    final oddAController = TextEditingController(text: match.oddA.toString());
    final oddBController = TextEditingController(text: match.oddB.toString());
    final oddDrawController = TextEditingController(
      text: match.oddDraw.toString(),
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Sửa odds - ${match.title}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oddAController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Odds A'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: oddBController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Odds B'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: oddDrawController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Odds Hòa'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final a = double.tryParse(oddAController.text.trim());
                final b = double.tryParse(oddBController.text.trim());
                final d = double.tryParse(oddDrawController.text.trim());

                if (a == null || b == null || d == null) return;
                widget.onUpdateOdds(match, a, b, d);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật odds trận đấu')),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(MatchItem match) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa trận đấu?'),
        content: Text('Bạn có chắc muốn xóa trận "${match.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              widget.onDeleteMatch(match);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Đã xóa trận đấu')));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
