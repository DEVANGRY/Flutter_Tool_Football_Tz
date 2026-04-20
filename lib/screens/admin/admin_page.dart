part of bookie_management_app;

class AdminPage extends StatefulWidget {
  final List<MatchItem> matches;
  final void Function(String title, double oddA, double oddB, double oddDraw)
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
  final _oddAController = TextEditingController(text: '1.90');
  final _oddBController = TextEditingController(text: '1.90');
  final _oddDrawController = TextEditingController(text: '3.20');

  @override
  void dispose() {
    _titleController.dispose();
    _oddAController.dispose();
    _oddBController.dispose();
    _oddDrawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thêm trận đấu mới',
                    style: Theme.of(context).textTheme.titleLarge,
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
                          controller: _oddAController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Odds A',
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
                            labelText: 'Odds B',
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
        const SizedBox(height: 12),
        Text('Quản lý trận đấu', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (widget.matches.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chưa có trận đấu nào'),
            ),
          )
        else
          ...widget.matches.map(
            (match) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Odds: A ${match.oddA} • B ${match.oddB} • Hòa ${match.oddDraw}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tổng pool: ${money(match.totalPool)} • Bets: ${match.bets.length}',
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
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
      double.parse(_oddAController.text.trim()),
      double.parse(_oddBController.text.trim()),
      double.parse(_oddDrawController.text.trim()),
    );

    _titleController.clear();
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa trận đấu')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

