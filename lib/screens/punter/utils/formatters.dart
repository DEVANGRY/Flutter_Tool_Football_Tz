import '../models/bet_entry.dart';

String money(double value) {
  final negative = value < 0;
  final raw = value.abs().round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    final position = raw.length - i;
    buffer.write(raw[i]);
    if (position > 1 && position % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${negative ? '-' : ''}${buffer.toString()}đ';
}

String sideLabel(BetSide side) {
  switch (side) {
    case BetSide.teamA:
      return 'Đội A';
    case BetSide.teamB:
      return 'Đội B';
    case BetSide.draw:
      return 'Hòa';
  }
}

String sideShort(BetSide side) {
  switch (side) {
    case BetSide.teamA:
      return 'A';
    case BetSide.teamB:
      return 'B';
    case BetSide.draw:
      return 'H';
  }
}

String formatTime(DateTime time) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)} - ${two(time.day)}/${two(time.month)}/${time.year}';
}
