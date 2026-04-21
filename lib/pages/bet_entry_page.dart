import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/match_item.dart';
import '../models/bet_entry.dart';
import '../utils/format.dart';

class BetEntryPage extends StatefulWidget {
  final List<MatchItem> matches;
  final Function(String matchId, BetEntry bet) onAddBet;

  const BetEntryPage({
    super.key,
    required this.matches,
    required this.onAddBet,
  });

  @override
  State<BetEntryPage> createState() => _BetEntryPageState();
}

class _BetEntryPageState extends State<BetEntryPage> {
  String? _selectedMatchId;
  BetSide? _selectedSide;
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TimeOfDay _betTime = TimeOfDay.now();
  DateTime _betDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  MatchItem? get _selectedMatch {
    if (_selectedMatchId == null) return null;
    return widget.matches.firstWhere(
      (m) => m.id == _selectedMatchId,
      orElse: () => widget.matches.first,
    );
  }

  double get _currentOdds {
    if (_selectedMatch == null || _selectedSide == null) return 0;
    switch (_selectedSide!) {
      case BetSide.teamA:
        return _selectedMatch!.oddA;
      case BetSide.teamB:
        return _selectedMatch!.oddB;
      case BetSide.draw:
        return _selectedMatch!.oddDraw;
    }
  }

  void _resetForm() {
    setState(() {
      _selectedMatchId = null;
      _selectedSide = null;
      _nameController.clear();
      _amountController.clear();
      _noteController.clear();
      _betTime = TimeOfDay.now();
      _betDate = DateTime.now();
    });
  }

  void _submitBet() {
    if (_selectedMatchId == null || _selectedSide == null) {
      _showSnackBar('Vui lòng chọn trận và cửa cược', Colors.red);
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập tên người đánh', Colors.red);
      return;
    }
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showSnackBar('Vui lòng nhập số tiền hợp lệ', Colors.red);
      return;
    }

    final bet = BetEntry(
      id: 'b${DateTime.now().millisecondsSinceEpoch}',
      side: _selectedSide!,
      amount: amount,
      odds: _currentOdds,
      createdAt: DateTime(
        _betDate.year,
        _betDate.month,
        _betDate.day,
        _betTime.hour,
        _betTime.minute,
      ),
      nameTeam: _nameController.text.trim(),
    );

    widget.onAddBet(_selectedMatchId!, bet);
    _showSnackBar('✅ Đã thêm cược thành công!', Colors.green);
    _resetForm();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _betDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() => _betDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _betTime,
    );
    if (picked != null) {
      setState(() => _betTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập cược mới'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'Làm mới form',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bước 1: Chọn trận đấu
            _buildSectionTitle('1. Chọn trận đấu', Icons.sports_soccer),
            const SizedBox(height: 12),
            _buildMatchSelector(),

            const SizedBox(height: 24),

            // Bước 2: Chọn cửa cược
            if (_selectedMatchId != null) ...[
              _buildSectionTitle('2. Chọn cửa cược', Icons.touch_app),
              const SizedBox(height: 12),
              _buildSideSelector(),
              const SizedBox(height: 24),
            ],

            // Bước 3: Nhập thông tin
            if (_selectedSide != null) ...[
              _buildSectionTitle('3. Thông tin cược', Icons.edit_note),
              const SizedBox(height: 12),
              _buildBetInfoForm(),
              const SizedBox(height: 32),
            ],

            // Nút submit
            if (_selectedSide != null) _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: widget.matches.asMap().entries.map((entry) {
          final index = entry.key;
          final match = entry.value;
          final isSelected = _selectedMatchId == match.id;
          return Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedMatchId = match.id;
                    _selectedSide = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepPurple.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border(
                      bottom: index < widget.matches.length - 1
                          ? BorderSide(color: Colors.grey.shade200)
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepPurple
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.nameTeamA,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'vs ${match.nameTeamB}',
                              style: TextStyle(
                                fontSize: 13,
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
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${match.bets.length} cược',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Colors.deepPurple
                            : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSideSelector() {
    final match = _selectedMatch!;
    return Row(
      children: [
        _buildSideCard(
          side: BetSide.teamA,
          label: match.nameTeamA,
          odds: match.oddA,
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildSideCard(
          side: BetSide.draw,
          label: 'Hòa',
          odds: match.oddDraw,
          color: Colors.orange,
        ),
        const SizedBox(width: 8),
        _buildSideCard(
          side: BetSide.teamB,
          label: match.nameTeamB,
          odds: match.oddB,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildSideCard({
    required BetSide side,
    required String label,
    required double odds,
    required Color color,
  }) {
    final isSelected = _selectedSide == side;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSide = side),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                _getSideIcon(side),
                color: isSelected ? color : Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  odds.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSideIcon(BetSide side) {
    switch (side) {
      case BetSide.teamA:
        return Icons.flag;
      case BetSide.teamB:
        return Icons.flag_outlined;
      case BetSide.draw:
        return Icons.handshake;
    }
  }

  Widget _buildBetInfoForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Tên người đánh
          _buildInputField(
            controller: _nameController,
            label: '👤 Tên người đánh',
            hint: 'Nhập tên người đánh...',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),

          // Số tiền
          _buildInputField(
            controller: _amountController,
            label: '💰 Số tiền cược',
            hint: 'Nhập số tiền...',
            icon: Icons.money,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            prefixText: 'VNĐ ',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Ngày & Giờ
          Row(
            children: [
              Expanded(
                child: _buildDateTimePicker(
                  label: '📅 Ngày đánh',
                  value: '${_betDate.day}/${_betDate.month}/${_betDate.year}',
                  icon: Icons.calendar_today,
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimePicker(
                  label: '🕐 Giờ đánh',
                  value:
                      '${_betTime.hour.toString().padLeft(2, '0')}:${_betTime.minute.toString().padLeft(2, '0')}',
                  icon: Icons.access_time,
                  onTap: _selectTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ghi chú
          _buildInputField(
            controller: _noteController,
            label: '📝 Ghi chú (không bắt buộc)',
            hint: 'Nhập ghi chú...',
            icon: Icons.note,
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // Preview
          _buildBetPreview(),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: Icon(icon, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBetPreview() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final potentialWin = amount * _currentOdds;
    final profit = potentialWin - amount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.preview, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Xem trước cược',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPreviewItem(
                'Tỷ lệ',
                _currentOdds.toStringAsFixed(2),
                Colors.blue,
              ),
              _buildPreviewItem('Tiền cược', money(amount), Colors.green),
              _buildPreviewItem('Thắng', money(potentialWin), Colors.orange),
              _buildPreviewItem('Lời', money(profit), Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitBet,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 24),
            SizedBox(width: 8),
            Text(
              'Xác nhận cược',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
