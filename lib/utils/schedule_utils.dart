import 'package:intl/intl.dart';

List<String> generateSlots(String start, String end, {int minutes = 30}) {
  // start/end: "HH:mm"
  final fmt = DateFormat('HH:mm');
  final s = fmt.parse(start);
  final e = fmt.parse(end);
  final slots = <String>[];
  DateTime cur = s;
  while (cur.isBefore(e)) {
    final next = cur.add(Duration(minutes: minutes));
    if (!next.isAfter(e)) {
      slots.add(DateFormat('HH:mm').format(cur));
    }
    cur = next;
  }
  return slots;
}

String formatFecha(DateTime d) {
  return '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
