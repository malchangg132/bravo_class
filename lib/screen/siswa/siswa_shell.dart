import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets.dart';
import '../profil_view.dart';

class SiswaShell extends StatefulWidget {
  const SiswaShell({super.key});

  @override
  State<SiswaShell> createState() => _SiswaShellState();
}

class _SiswaShellState extends State<SiswaShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = app.currentStudent!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _tab == 0
                  ? const SiswaHome()
                  : ProfileView(name: s.name, rows: [
                      ('Peran', 'Siswa'),
                      ('NISN', s.nisn),
                      ('Kelas', s.kelas),
                      ('UID Kartu', s.cardUid ?? '-'),
                    ]),
            ),
            BottomBar(
              items: const [
                (Icons.home_outlined, 'Home'),
                (Icons.person_outline, 'Profil'),
              ],
              index: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
          ],
        ),
      ),
    );
  }
}

class SiswaHome extends StatelessWidget {
  const SiswaHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final s = app.currentStudent!;
        final rec = app.todayRecord(s.id);
        final stats = app.monthStats(s.id);
        final history = app.historyFor(s.id);
        final firstName = s.name.split(' ').first;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Eyebrow('Dashboard siswa'),
            const SizedBox(height: 2),
            Text('${greeting(app.now)}, $firstName',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),

            // Kartu profil + persentase kehadiran
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: C.navy,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Text(initials(s.name),
                            style: const TextStyle(
                                color: C.navy, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                            Text('NISN ${s.nisn} · ${s.kelas}',
                                style: const TextStyle(
                                    color: Color(0xCCFFFFFF), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0x33FFFFFF)),
                  ),
                  const Text('Kehadiran bulan ini',
                      style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 11)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(stats.percent == null ? '-' : '${stats.percent}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800)),
                      const Spacer(),
                      _MiniStat('Hadir', stats.hadir),
                      const SizedBox(width: 16),
                      _MiniStat('Tidak hadir', stats.tidakHadir),
                      const SizedBox(width: 16),
                      _MiniStat('Terlambat', stats.terlambat),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Ringkasan kehadiran hari ini (terisi otomatis saat tap kartu)
            SectionTitle(
              'Hari ini · ${fmtHeader(app.today).replaceFirst(RegExp(r' \d{4}$'), '')}',
              'Ringkasan kehadiran',
              trailing: rec == null
                  ? const Text('Belum tap',
                      style: TextStyle(fontSize: 11, color: C.mute, fontWeight: FontWeight.w600))
                  : StatusBadge(rec.status),
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  _TapRow(
                    icon: Icons.login_rounded,
                    label: 'Jam masuk',
                    time: rec?.masuk,
                  ),
                  const Divider(height: 1, color: C.line),
                  _TapRow(
                    icon: Icons.logout_rounded,
                    label: 'Jam pulang',
                    time: rec?.pulang,
                  ),
                ],
              ),
            ),
            if (rec != null && rec.status.isExcused)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Status ${rec.status.label} diisi oleh guru.',
                    style: const TextStyle(fontSize: 12, color: C.mute)),
              ),
            const SizedBox(height: 22),

            // Rekap = hari-hari sebelumnya
            SectionTitle(
              'Riwayat terbaru',
              'Rekap kehadiran',
              trailing: TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => _HistoryPage(studentId: s.id))),
                child: const Text('Lihat semua'),
              ),
            ),
            const SizedBox(height: 6),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: history.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Belum ada riwayat', style: TextStyle(color: C.mute)),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < history.take(3).length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: C.line),
                          HistoryTile(history[i]),
                        ],
                      ],
                    ),
            ),

            if (kDebugMode) ...[
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () => showTapSimulator(context, only: s),
                icon: const Icon(Icons.nfc_rounded),
                label: Text('Simulasi tap kartu (mode ${app.mode.label})'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 10)),
        Text('$value',
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _TapRow extends StatelessWidget {
  const _TapRow({required this.icon, required this.label, required this.time});
  final IconData icon;
  final String label;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    final done = time != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: done ? C.greenBg : C.greyBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: done ? C.green : C.mute),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: C.mute)),
                Text(fmtTime(time),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(done ? 'Tercatat' : 'Belum tap',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: done ? C.green : C.mute)),
              if (done)
                Text(fmtShort(time!), style: const TextStyle(fontSize: 11, color: C.mute)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final list = app.historyFor(studentId);
    return Scaffold(
      appBar: AppBar(title: const Text('Rekap kehadiran'), backgroundColor: C.bg),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: C.line),
        itemBuilder: (_, i) => HistoryTile(list[i]),
      ),
    );
  }
}
