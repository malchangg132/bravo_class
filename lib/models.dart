import 'package:flutter/material.dart' show TimeOfDay;

enum Role { siswa, guru }

enum Mode { masuk, pulang }

enum AttStatus { hadir, terlambat, izin, sakit, alpha, dispen }

extension ModeX on Mode {
  String get label => this == Mode.masuk ? 'Masuk' : 'Pulang';
}

extension AttStatusX on AttStatus {
  String get label => switch (this) {
        AttStatus.hadir => 'Hadir',
        AttStatus.terlambat => 'Terlambat',
        AttStatus.izin => 'Izin',
        AttStatus.sakit => 'Sakit',
        AttStatus.alpha => 'Alpha',
        AttStatus.dispen => 'Dispen',
      };

  /// Status yang diisi manual oleh guru (bukan dari tap kartu).
  bool get isExcused =>
      this == AttStatus.izin ||
      this == AttStatus.sakit ||
      this == AttStatus.alpha ||
      this == AttStatus.dispen;
}

class Student {
  Student({
    required this.id,
    required this.name,
    required this.nisn,
    this.kelas = 'XII RPL B',
    this.cardUid,
  });

  final String id;
  String name;
  String nisn;
  String kelas;

  /// UID kartu RFID. null = kartu belum didaftarkan.
  String? cardUid;
}

/// Catatan kehadiran satu siswa pada satu hari.
class AttRecord {
  AttRecord({
    required this.studentId,
    required this.date,
    required this.status,
    required this.updatedAt,
    this.masuk,
    this.pulang,
  });

  final String studentId;
  final DateTime date; // hanya tanggal (00:00)
  AttStatus status;
  DateTime? masuk; // waktu tap masuk
  DateTime? pulang; // waktu tap pulang
  DateTime updatedAt;
}

class DaySchedule {
  const DaySchedule({required this.masuk, required this.pulang});

  /// Batas jam masuk (tap setelah jam ini = terlambat).
  final TimeOfDay masuk;

  /// Jam pulang.
  final TimeOfDay pulang;
}

class DailySummary {
  DailySummary(this.day, this.counts, this.belum);
  final DateTime day;
  final Map<AttStatus, int> counts;
  final int belum;
}

class MonthStats {
  const MonthStats(this.hadir, this.terlambat, this.tidakHadir, this.percent);
  final int hadir;
  final int terlambat;
  final int tidakHadir;
  final int? percent; // null jika belum ada data
}

enum TapOutcome { attended, registered, duplicate, unknownCard, cardUsed, ignored }

class TapResult {
  const TapResult(this.outcome, this.message, [this.student]);
  final TapOutcome outcome;
  final String message;
  final Student? student;
}
