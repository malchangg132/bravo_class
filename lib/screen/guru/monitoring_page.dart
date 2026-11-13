import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets.dart';

class MonitoringPage extends StatelessWidget {
  const MonitoringPage({super.key, required this.tabs});
  final Widget tabs;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final list = app.todayList;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Halo, ${app.userName} 👋',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const Text('Monitoring absensi hari ini',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            tabs,
            if (app.syncError != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: C.redBg, borderRadius: BorderRadius.circular(10)),
                child: Text(app.syncError!,
                    style: const TextStyle(color: C.red, fontSize: 12.5)),
              ),
            ],
            const SizedBox(height: 14),
            _ModeCard(), // sengaja tidak const agar ikut rebuild saat state berubah
            const SizedBox(height: 18),
            Eyebrow(fmtHeader(app.today)),
            const SizedBox(height: 2),
            const Text('Kehadiran hari ini',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: StatTile('${app.countStatus(AttStatus.hadir)}', 'Hadir',
                        Icons.check_box_outlined, C.green)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatTile('${app.countStatus(AttStatus.terlambat)}', 'Terlambat',
                        Icons.schedule_rounded, C.amber)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatTile('${app.belumTap}', 'Belum tap',
                        Icons.groups_2_outlined, C.mute)),
              ],
            ),
            const SizedBox(height: 18),
            SectionTitle(
              'Monitor real-time',
              'Daftar siswa',
              trailing: TextButton(
                onPressed: () => _showRekap(context),
                child: const Text('Lihat Rekap'),
              ),
            ),
            const SizedBox(height: 6),
            if (list.isEmpty)
              const AppCard(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text('Belum ada siswa yang tap kartu hari ini',
                      style: TextStyle(color: C.mute)),
                ),
              )
            else
              for (final r in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AttendanceTile(app.studentById(r.studentId), r),
                ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => showTapSimulator(context),
                icon: const Icon(Icons.nfc_rounded),
                label: const Text('Simulasi tap kartu (debug)'),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showRekap(BuildContext context) {
    final data = app.dailySummaries(14);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rekap harian',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: C.line),
                  itemBuilder: (_, i) {
                    final d = data[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 78,
                            child: Text('${dayName(d.day)}\n${fmtShort(d.day)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12.5)),
                          ),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                for (final s in AttStatus.values)
                                  if (d.counts[s]! > 0)
                                    _CountChip(s, d.counts[s]!),
                                if (d.belum > 0)
                                  Text('${d.belum} belum tap',
                                      style: const TextStyle(fontSize: 11, color: C.mute)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip(this.status, this.n);
  final AttStatus status;
  final int n;

  @override
  Widget build(BuildContext context) {
    final c = statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(8)),
      child: Text('${status.label} $n',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.fg)),
    );
  }
}

/// Kartu biru: pilih mode masuk/pulang + ganti jam (khusus hari ini).
class _ModeCard extends StatelessWidget {
  const _ModeCard();

  Future<void> _changeTime(BuildContext context) async {
    final m = app.mode;
    final cur = app.limitFor(m) ?? const TimeOfDay(hour: 7, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: cur,
      helpText: 'Ganti jam ${m.label.toLowerCase()} (hanya hari ini)',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;
    await app.changeTodayLimit(m, picked);
    if (!context.mounted) return;
    showSnack(context,
        'Jam ${m.label.toLowerCase()} hari ini diubah ke ${fmtTod(picked)}. Besok kembali ke jadwal normal.');
  }

  @override
  Widget build(BuildContext context) {
    final m = app.mode;
    final lim = app.limitFor(m);
    final over = app.isOverridden(m);

    Widget modeButton(Mode value, IconData icon) {
      final sel = m == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => app.setMode(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: sel ? Colors.white : const Color(0x26FFFFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: sel ? C.navy : Colors.white),
                const SizedBox(width: 6),
                Text(value.label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: sel ? C.navy : Colors.white)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.nfc_rounded, color: C.navy),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mode Absensi Aktif',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('Siswa menempelkan kartu sesuai sesi yang berlangsung',
                        style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 10.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              modeButton(Mode.masuk, Icons.login_rounded),
              const SizedBox(width: 10),
              modeButton(Mode.pulang, Icons.logout_rounded),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0x33FFFFFF)),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        m == Mode.masuk
                            ? 'Batas jam masuk (lewat = terlambat)'
                            : 'Jam pulang',
                        style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(lim == null ? 'Tidak ada jadwal' : fmtTod(lim),
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: lim == null ? 15 : 26,
                                fontWeight: FontWeight.w800)),
                        if (over) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: C.amberBg, borderRadius: BorderRadius.circular(7)),
                            child: const Text('Diubah hari ini',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: C.amber)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (over)
                IconButton(
                  tooltip: 'Kembalikan ke jadwal normal',
                  onPressed: () => app.resetTodayLimit(m),
                  icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
                ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: C.navy,
                ),
                onPressed: () => _changeTime(context),
                icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                label: const Text('Ganti jam'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile(this.s, this.r);
  final Student s;
  final AttRecord r;

  @override
  Widget build(BuildContext context) {
    final taps = <String>[
      if (r.masuk != null) 'Masuk ${fmtTime(r.masuk)}',
      if (r.pulang != null) 'Pulang ${fmtTime(r.pulang)}',
    ];
    final detail = r.masuk == null && r.pulang == null
        ? '${r.status.label} (diisi guru)'
        : '${fmtShort(r.date)} · ${taps.join(' · ')}';

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Initials(s.name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                Text('UID ${s.cardUid ?? '-'}',
                    style: const TextStyle(fontSize: 10.5, color: C.mute)),
                Text(detail, style: const TextStyle(fontSize: 10.5, color: C.mute)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmtTime(r.masuk ?? r.pulang).replaceAll('--.--', '-'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              const SizedBox(height: 3),
              StatusBadge(r.status),
            ],
          ),
        ],
      ),
    );
  }
}
