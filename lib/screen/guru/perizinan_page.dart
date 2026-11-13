import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets.dart';

class PerizinanPage extends StatefulWidget {
  const PerizinanPage({super.key, required this.tabs});
  final Widget tabs;

  @override
  State<PerizinanPage> createState() => _PerizinanPageState();
}

class _PerizinanPageState extends State<PerizinanPage> {
  AttStatus? _filter; // null = Semua

  static const _excuses = [
    AttStatus.izin,
    AttStatus.sakit,
    AttStatus.alpha,
    AttStatus.dispen,
  ];

  Widget _chip(String label, int count, AttStatus? value) {
    final sel = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? C.navy : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? C.navy : C.line),
          ),
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : C.ink)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: sel ? const Color(0x33FFFFFF) : C.greyBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: sel ? Colors.white : C.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final all = app.sortedStudents;
        final shown = _filter == null
            ? all
            : all.where((s) => app.todayRecord(s.id)?.status == _filter).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            widget.tabs,
            const SizedBox(height: 14),
            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: C.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Perizinan Manual',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        Text(
                            'Tandai siswa yang izin, sakit, alpha, atau dispen tanpa '
                            'menunggu scan RFID.',
                            style: TextStyle(fontSize: 11, color: C.mute)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Semua', all.length, null),
                  for (final s in _excuses) _chip(s.label, app.countStatus(s), s),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Eyebrow('Daftar siswa · ${fmtShort(app.today)}'),
            const SizedBox(height: 2),
            const Text('Pilih kategori langsung',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (shown.isEmpty)
              const AppCard(
                padding: EdgeInsets.all(20),
                child: Center(
                    child: Text('Tidak ada siswa di kategori ini',
                        style: TextStyle(color: C.mute))),
              ),
            for (final s in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ExcuseTile(s),
              ),
          ],
        );
      },
    );
  }
}

class _ExcuseTile extends StatelessWidget {
  const _ExcuseTile(this.s);
  final Student s;

  @override
  Widget build(BuildContext context) {
    final r = app.todayRecord(s.id);
    final canMark = app.canMark(s.id);
    final tapped = r != null && r.masuk != null;

    String statusText;
    if (r == null) {
      statusText = 'Belum tap';
    } else if (tapped) {
      statusText = 'Tap masuk ${fmtTime(r.masuk)}';
    } else if (r.pulang != null) {
      statusText = 'Tap pulang ${fmtTime(r.pulang)}';
    } else {
      statusText = 'Diisi manual';
    }

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Initials(s.name, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Text('Status: $statusText',
                        style: const TextStyle(fontSize: 10.5, color: C.mute)),
                  ],
                ),
              ),
              if (r != null) StatusBadge(r.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final st in _PerizinanPageState._excuses)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _ExcuseButton(
                      status: st,
                      selected: r?.status == st,
                      enabled: canMark,
                      onTap: () async {
                        final err = await app.markExcuse(s.id, st);
                        if (err != null && context.mounted) showSnack(context, err);
                      },
                    ),
                  ),
                ),
            ],
          ),
          if (!canMark)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Siswa sudah tap kartu — perizinan dikunci.',
                  style: TextStyle(fontSize: 10.5, color: C.mute)),
            ),
        ],
      ),
    );
  }
}

class _ExcuseButton extends StatelessWidget {
  const _ExcuseButton({
    required this.status,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AttStatus status;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = statusColors(status);
    final Color bg;
    final Color fg;
    final Color border;
    if (!enabled) {
      bg = C.greyBg;
      fg = const Color(0xFF9CA3AF);
      border = C.greyBg;
    } else if (selected) {
      bg = c.fg;
      fg = Colors.white;
      border = c.fg;
    } else {
      bg = Colors.white;
      fg = c.fg;
      border = C.line;
    }
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Text(status.label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
      ),
    );
  }
}
