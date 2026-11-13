import 'package:flutter/material.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Geser ke WIB (UTC+7). Field jam/tanggal hasilnya adalah waktu dinding WIB,
/// apa pun zona waktu HP. Dipakai agar sama dengan perhitungan di server.
DateTime wib(DateTime t) => t.toUtc().add(const Duration(hours: 7));

String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? parseDate(String? s) {
  if (s == null || s.length < 10) return null;
  return DateTime(int.parse(s.substring(0, 4)), int.parse(s.substring(5, 7)),
      int.parse(s.substring(8, 10)));
}

const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String dayName(DateTime d) => _days[d.weekday - 1];
String monthLong(DateTime d) => _months[d.month - 1];
String monthShort(DateTime d) => monthLong(d).substring(0, 3);
String two(int n) => n.toString().padLeft(2, '0');

/// "29 Sep"
String fmtShort(DateTime d) => '${d.day} ${monthShort(d)}';

/// "SELASA, 29 SEPTEMBER 2026"
String fmtHeader(DateTime d) =>
    '${dayName(d)}, ${d.day} ${monthLong(d)} ${d.year}'.toUpperCase();

/// "06.48" (atau "--.--" jika kosong)
String fmtTime(DateTime? t) => t == null ? '--.--' : '${two(t.hour)}.${two(t.minute)}';
String fmtTod(TimeOfDay t) => '${two(t.hour)}.${two(t.minute)}';

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

String greeting(DateTime n) {
  if (n.hour < 11) return 'Selamat Pagi';
  if (n.hour < 15) return 'Selamat Siang';
  if (n.hour < 18) return 'Selamat Sore';
  return 'Selamat Malam';
}
