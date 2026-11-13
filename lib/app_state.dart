import 'dart:async';

import 'package:flutter/material.dart';
import 'models.dart';
import 'supa.dart';
import 'utils.dart';

/// State aplikasi yang tersinkron dengan Supabase (tabel users, settings,
/// attendance). Alat IoT menulis ke tabel yang sama, jadi app cukup
/// membaca ulang tiap beberapa detik (polling).
class AppState extends ChangeNotifier {
  AppState({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  DateTime get now => _clock();
  DateTime get today => dateOnly(now);

  // ---------------------------------------------------------------- Sesi
  Role? role;
  Student? currentStudent;
  String userName = '';
  String userNisn = '';

  Timer? _timer;
  bool _busy = false;

  /// Mengembalikan pesan error, atau null jika berhasil.
  Future<String?> login(Role r, String user, String pass) async {
    if (user.trim().isEmpty || pass.isEmpty) return 'Isi username dan password';
    try {
      final res = await Supa.rpc('login_user', {
        'p_user': user.trim(),
        'p_pass': pass,
      });
      if (res == null || res is! Map) {
        return 'Username atau password salah';
      }
      final found = (res['role'] ?? '').toString();
      if (r == Role.guru && found != 'guru') {
        return 'Akun ini bukan akun guru';
      }
      if (r == Role.siswa && found == 'guru') {
        return 'Akun ini akun guru, pilih tombol Guru';
      }
      role = r;
      userName = (res['nama'] ?? '').toString();
      userNisn = (res['nisn'] ?? '').toString();
      currentStudent = r == Role.siswa
          ? Student(
              id: '${res['id']}',
              name: userName,
              nisn: userNisn,
              cardUid: res['uid']?.toString(),
            )
          : null;
      await refresh();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => refresh());
      notifyListeners();
      return null;
    } catch (e) {
      return 'Tidak bisa terhubung ke server: $e';
    }
  }

  void logout() {
    _timer?.cancel();
    role = null;
    currentStudent = null;
    students.clear();
    _records.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------- Data
  final List<Student> students = [];
  final Map<String, AttRecord> _records = {};

  String _key(String id, DateTime d) => '$id|${d.year}-${d.month}-${d.day}';

  List<Student> get sortedStudents {
    final list = [...students];
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Student? studentByUid(String uid) {
    for (final s in students) {
      if (s.cardUid == uid) return s;
    }
    return null;
  }

  Student studentById(String id) => students.firstWhere((s) => s.id == id);

  AttRecord? recordOf(String id, DateTime d) => _records[_key(id, d)];

  AttRecord? todayRecord(String id) => recordOf(id, today);

  String? _uidOf(String id) {
    for (final s in students) {
      if (s.id == id) return s.cardUid;
    }
    return null;
  }

  static const _excusedNames = ['izin', 'sakit', 'alpha', 'dispen'];

  static AttStatus _excusedFrom(String s) => switch (s) {
        'izin' => AttStatus.izin,
        'sakit' => AttStatus.sakit,
        'alpha' => AttStatus.alpha,
        _ => AttStatus.dispen,
      };

  Future<List<dynamic>> _fetchAll(String table, Map<String, String> q) async {
    // Supabase membatasi 1000 baris per permintaan: ambil per halaman.
    final out = <dynamic>[];
    var offset = 0;
    while (true) {
      final page = await Supa.select(
          table, {...q, 'limit': '1000', 'offset': '$offset'});
      out.addAll(page);
      if (page.length < 1000) break;
      offset += 1000;
    }
    return out;
  }

  Future<void> refresh() async {
    if (_busy || role == null) return;
    _busy = true;
    try {
      final since = dateOnly(today.subtract(const Duration(days: 35)));
      final sinceStr =
          '${since.year}-${two(since.month)}-${two(since.day)}';

      final results = await Future.wait([
        Supa.select('users', {'select': 'id,uid,nama,nisn', 'role': 'eq.siswa'}),
        Supa.select('settings', {'select': '*', 'id': 'eq.1', 'limit': '1'}),
        _fetchAll('attendance', {
          'select': 'uid,status,terlambat,tgl,created_at',
          'tgl': 'gte.$sinceStr',
          'order': 'id',
        }),
      ]);

      // users
      final rows = results[0] as List;
      final fresh = <Student>[
        for (final r in rows)
          Student(
            id: '${r['id']}',
            name: (r['nama'] ?? '').toString(),
            nisn: (r['nisn'] ?? '').toString(),
            cardUid: r['uid']?.toString(),
          ),
      ];
      students
        ..clear()
        ..addAll(fresh);

      // settings
      final st = results[1] as List;
      if (st.isNotEmpty) _applySettings(Map<String, dynamic>.from(st.first));

      // attendance -> record per siswa per hari
      _records.clear();
      final idByUid = {
        for (final s in students)
          if (s.cardUid != null) s.cardUid!: s.id
      };
      for (final r in results[2] as List) {
        final uid = r['uid']?.toString();
        final tgl = r['tgl']?.toString();
        final sid = uid == null ? null : idByUid[uid];
        if (sid == null || tgl == null) continue;
        final day = dateOnly(DateTime.parse(tgl));
        final at = DateTime.parse(r['created_at'].toString()).toLocal();
        final status = (r['status'] ?? '').toString().toLowerCase();
        final key = _key(sid, day);
        final rec = _records[key] ??
            AttRecord(
                studentId: sid, date: day, status: AttStatus.hadir, updatedAt: at);
        if (at.isAfter(rec.updatedAt)) rec.updatedAt = at;
        if (status == 'masuk') {
          rec.masuk = at;
          rec.status = r['terlambat'] == true ? AttStatus.terlambat : AttStatus.hadir;
        } else if (status == 'pulang') {
          rec.pulang = at;
        } else if (_excusedNames.contains(status)) {
          rec.status = _excusedFrom(status);
        }
        _records[key] = rec;
      }

      // pendaftaran kartu: selesai jika alat sudah menyimpan siswa baru
      if (_pendingNisn != null) {
        for (final s in students) {
          if (s.nisn == _pendingNisn && s.cardUid != null) {
            registeredStudent = s;
            _pendingName = null;
            _pendingNisn = null;
            break;
          }
        }
      }

      syncError = null;
    } catch (e) {
      syncError = 'Gagal sinkron: $e';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  String? syncError;

  // -------------------------------------------------- Mode & jadwal jam
  Mode mode = Mode.masuk;

  /// Jadwal default Senin–Jumat. Harus sama dengan jadwal di fungsi tap_kartu.
  final Map<int, DaySchedule> weeklySchedule = {
    for (var d = 1; d <= 5; d++)
      d: const DaySchedule(
        masuk: TimeOfDay(hour: 7, minute: 0),
        pulang: TimeOfDay(hour: 15, minute: 0),
      ),
  };

  DateTime? _ovDay;
  TimeOfDay? _ovMasuk;
  TimeOfDay? _ovPulang;

  TimeOfDay? _parseTime(dynamic v) {
    if (v == null) return null;
    final p = v.toString().split(':');
    if (p.length < 2) return null;
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  void _applySettings(Map<String, dynamic> s) {
    mode = (s['session_type'] ?? 'masuk').toString().toLowerCase() == 'pulang'
        ? Mode.pulang
        : Mode.masuk;
    final od = s['override_date']?.toString();
    _ovDay = od == null ? null : dateOnly(DateTime.parse(od));
    _ovMasuk = _parseTime(s['masuk_limit']);
    _ovPulang = _parseTime(s['pulang_time']);
  }

  bool isOverridden(Mode m) {
    if (_ovDay != today) return false;
    return (m == Mode.masuk ? _ovMasuk : _ovPulang) != null;
  }

  TimeOfDay? limitFor(Mode m) {
    if (isOverridden(m)) return m == Mode.masuk ? _ovMasuk : _ovPulang;
    final s = weeklySchedule[today.weekday];
    if (s == null) return null;
    return m == Mode.masuk ? s.masuk : s.pulang;
  }

  String _hhmm(TimeOfDay t) => '${two(t.hour)}:${two(t.minute)}:00';
  String _ymd(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  Future<String?> _patchSettings(Map<String, dynamic> data) async {
    try {
      await Supa.patch('settings', {'id': 'eq.1'}, data);
      return null;
    } catch (e) {
      syncError = 'Gagal menyimpan: $e';
      notifyListeners();
      return syncError;
    }
  }

  Future<void> setMode(Mode m) async {
    mode = m;
    notifyListeners();
    await _patchSettings({'session_type': m.label}); // 'Masuk' / 'Pulang'
  }

  Future<String?> changeTodayLimit(Mode m, TimeOfDay t) async {
    // Jika override lama dari hari lain, kosongkan dulu agar tidak ikut berlaku.
    final stale = _ovDay != today;
    final data = <String, dynamic>{
      'override_date': _ymd(today),
      if (stale) 'masuk_limit': null,
      if (stale) 'pulang_time': null,
      if (m == Mode.masuk) 'masuk_limit': _hhmm(t) else 'pulang_time': _hhmm(t),
    };
    final err = await _patchSettings(data);
    if (err == null) {
      _ovDay = today;
      if (stale) {
        _ovMasuk = null;
        _ovPulang = null;
      }
      if (m == Mode.masuk) {
        _ovMasuk = t;
      } else {
        _ovPulang = t;
      }
      notifyListeners();
    }
    return err;
  }

  Future<void> resetTodayLimit(Mode m) async {
    if (_ovDay != today) return;
    final err = await _patchSettings(
        {m == Mode.masuk ? 'masuk_limit' : 'pulang_time': null});
    if (err == null) {
      if (m == Mode.masuk) {
        _ovMasuk = null;
      } else {
        _ovPulang = null;
      }
      notifyListeners();
    }
  }

  // ------------------------------------------------------------ Tap kartu
  /// Hanya untuk simulator (tanpa alat). Alat asli memanggil fungsi yang sama.
  Future<TapResult> onCardTapped(String uid) async {
    try {
      if (waitingForCard) return await _simulateRegister(uid);
      final res =
          await Supa.rpc('tap_kartu', {'p_uid': uid, 'p_sesi': mode.label});
      await refresh();
      final status = res is Map ? res['status'] : null;
      final nama = res is Map ? (res['nama'] ?? '') : '';
      final s = studentByUid(uid);
      switch (status) {
        case 'success':
          return TapResult(
              TapOutcome.attended,
              '$nama tap ${mode.label.toLowerCase()}'
              '${res['terlambat'] == true ? ' (Terlambat)' : ''}',
              s);
        case 'exists':
          return TapResult(TapOutcome.duplicate, '$nama sudah tap ${mode.label.toLowerCase()}', s);
        case 'libur':
          return TapResult(TapOutcome.ignored, 'Hari ini libur, absen tidak dicatat', s);
        case 'unknown':
          return const TapResult(TapOutcome.unknownCard, 'Kartu belum terdaftar');
      }
      return const TapResult(TapOutcome.ignored, 'Respon tidak dikenal');
    } catch (e) {
      return TapResult(TapOutcome.ignored, 'Gagal: $e');
    }
  }

  // ------------------------------------------------ Perizinan manual guru
  bool canMark(String id) {
    final r = todayRecord(id);
    return r == null || (r.masuk == null && r.pulang == null);
  }

  Future<String?> markExcuse(String id, AttStatus s) async {
    assert(s.isExcused);
    if (!canMark(id)) return null;
    final uid = _uidOf(id);
    if (uid == null) return 'Siswa belum punya kartu';
    final same = todayRecord(id)?.status == s;
    final day = _ymd(today);
    try {
      await Supa.delete('attendance', {
        'uid': 'eq.$uid',
        'tgl': 'eq.$day',
        'status': 'in.(Izin,Sakit,Alpha,Dispen)',
      });
      if (!same) {
        await Supa.insert('attendance', {
          'uid': uid,
          'status': s.label,
          'tgl': day,
        });
      }
      await refresh();
      return null;
    } catch (e) {
      syncError = 'Gagal menyimpan: $e';
      notifyListeners();
      return syncError;
    }
  }

  // ------------------------------------------------------- Ringkasan guru
  Iterable<AttRecord> get _todayRecords => students
      .map((s) => todayRecord(s.id))
      .whereType<AttRecord>();

  List<AttRecord> get todayList {
    final list = _todayRecords.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  int countStatus(AttStatus s) => _todayRecords.where((r) => r.status == s).length;
  int get belumTap => students.length - _todayRecords.length;

  List<DailySummary> dailySummaries(int n) {
    final out = <DailySummary>[];
    var d = today;
    var guard = 0;
    while (out.length < n && guard < 60) {
      guard++;
      if (d.weekday <= 5) {
        final counts = {for (final s in AttStatus.values) s: 0};
        var total = 0;
        for (final st in students) {
          final r = recordOf(st.id, d);
          if (r != null) {
            counts[r.status] = counts[r.status]! + 1;
            total++;
          }
        }
        out.add(DailySummary(d, counts, students.length - total));
      }
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return out;
  }

  // -------------------------------------------------------- Data siswa
  List<AttRecord> historyFor(String id) {
        final list = _records.values
        .where((r) => r.studentId == id && r.date.isBefore(today))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  MonthStats monthStats(String id) {
    var hadir = 0, telat = 0, absen = 0, dispen = 0;
    for (final r in _records.values) {
      if (r.studentId != id) continue;
      if (r.date.year != today.year || r.date.month != today.month) continue;
      switch (r.status) {
        case AttStatus.hadir:
          hadir++;
        case AttStatus.terlambat:
          telat++;
        case AttStatus.dispen:
          dispen++;
        default:
          absen++;
      }
    }
    final total = hadir + telat + dispen + absen;
    final pct = total == 0 ? null : (((hadir + telat + dispen) / total) * 100).round();
    return MonthStats(hadir, telat, absen, pct);
  }

  // --------------------------------------------- Pendaftaran & edit kartu
  String? _pendingName;
  String? _pendingNisn;
  Student? registeredStudent;
  String? registrationError;
  int _uidCounter = 100;

  /// UID karangan untuk tombol simulasi (mode debug).
  String newCardUid() => '0xSIM${_uidCounter++}';

  /// Simulasi alat saat pendaftaran: menyimpan user baru seperti main.py.
  Future<TapResult> _simulateRegister(String uid) async {
    final nama = _pendingName!, nisn = _pendingNisn!;
    try {
      await Supa.insert('users', {'uid': uid, 'nama': nama, 'nisn': nisn});
      await Supa.patch('settings', {'id': 'eq.1'},
          {'mode': 'normal', 'target_nama': null, 'target_nisn': null});
      await refresh();
      return TapResult(TapOutcome.registered, 'Kartu sudah terdaftar: $nama');
    } on SupaException catch (e) {
      registrationError =
          e.status == 409 ? 'Kartu atau NISN sudah dipakai' : 'Gagal: ${e.body}';
      notifyListeners();
      return TapResult(TapOutcome.cardUsed, registrationError!);
    }
  }

  bool get waitingForCard => _pendingNisn != null;
  String? get pendingName => _pendingName;
  int get unregisteredCount => students.where((s) => s.cardUid == null).length;
  int get registeredCount => students.length - unregisteredCount;

  /// Menyuruh alat masuk mode daftar. Alat yang menyimpan UID ke tabel users.
  Future<String?> startRegistration(String name, String nisn) async {
    final n = name.trim();
    final i = nisn.trim();
    if (n.isEmpty || i.isEmpty) return 'Nama dan NISN wajib diisi';
    if (students.any((s) => s.nisn == i)) return 'NISN $i sudah terdaftar';
    final err = await _patchSettings(
        {'mode': 'register', 'target_nama': n, 'target_nisn': i});
    if (err != null) return err;
    // Baca ulang untuk memastikan server benar-benar menyimpan mode daftar.
    try {
      final chk = await Supa.select('settings', {'select': 'mode', 'id': 'eq.1'});
      if (chk.isEmpty) {
        return 'Baris settings dengan id=1 tidak ditemukan di Supabase';
      }
      if ((chk.first['mode'] ?? '').toString() != 'register') {
        return 'Server tidak menyimpan mode daftar (mode sekarang: ${chk.first['mode']})';
      }
    } catch (e) {
      return 'Gagal memeriksa pengaturan: $e';
    }
    _pendingName = n;
    _pendingNisn = i;
    registeredStudent = null;
    registrationError = null;
    notifyListeners();
    return null;
  }

  Future<void> cancelRegistration() async {
    _pendingName = null;
    _pendingNisn = null;
    notifyListeners();
    await _patchSettings({'mode': 'normal', 'target_nama': null, 'target_nisn': null});
  }

  Future<String?> updateStudent(String id, String name, String nisn) async {
    final n = name.trim();
    final i = nisn.trim();
    if (n.isEmpty || i.isEmpty) return 'Nama dan NISN wajib diisi';
    if (students.any((s) => s.nisn == i && s.id != id)) {
      return 'NISN $i sudah dipakai siswa lain';
    }
    try {
      await Supa.patch('users', {'id': 'eq.$id'}, {'nama': n, 'nisn': i});
      await refresh();
      return null;
    } catch (e) {
      return 'Gagal menyimpan: $e';
    }
  }
}

final AppState app = AppState();