import 'package:flutter/material.dart';
import 'app_state.dart';
import 'models.dart';
import 'theme.dart';
import 'utils.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final AttStatus status;

  @override
  Widget build(BuildContext context) {
    final c = statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status.label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c.fg)),
    );
  }
}

class Initials extends StatelessWidget {
  const Initials(this.name, {super.key, this.size = 38});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE6EEFB),
        borderRadius: BorderRadius.circular(size / 2.6),
      ),
      child: Text(initials(name),
          style: TextStyle(
              fontSize: size * 0.34, fontWeight: FontWeight.w700, color: C.navy)),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11, letterSpacing: 0.6, color: C.mute, fontWeight: FontWeight.w600));
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.eyebrow, this.title, {super.key, this.trailing});
  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(eyebrow),
              const SizedBox(height: 2),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: C.ink)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile(this.value, this.label, this.icon, this.color, {super.key});
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: C.ink)),
          Text(label, style: const TextStyle(fontSize: 11, color: C.mute)),
        ],
      ),
    );
  }
}

class SegTabs extends StatelessWidget {
  const SegTabs({super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.monitor_heart_outlined, 'Monitoring'),
    (Icons.edit_note_rounded, 'Perizinan'),
    (Icons.badge_outlined, 'Kartu'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFE5ECF6), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: i == index
                        ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4)]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_items[i].$1, size: 16, color: i == index ? C.blue : C.mute),
                      const SizedBox(width: 5),
                      Text(_items[i].$2,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                              color: i == index ? C.ink : C.mute)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<(IconData, String)> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.line),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1, size: 22, color: i == index ? C.blue : C.mute),
                      const SizedBox(height: 2),
                      Text(items[i].$2,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == index ? FontWeight.w800 : FontWeight.w500,
                              color: i == index ? C.blue : C.mute)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Satu baris riwayat kehadiran siswa.
class HistoryTile extends StatelessWidget {
  const HistoryTile(this.r, {super.key});
  final AttRecord r;

  @override
  Widget build(BuildContext context) {
    Widget time(IconData icon, DateTime? t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: C.mute),
            const SizedBox(width: 3),
            Text(fmtTime(t), style: const TextStyle(fontSize: 12, color: C.ink)),
          ],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fmtShort(r.date),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                Text(dayName(r.date), style: const TextStyle(fontSize: 11, color: C.mute)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                time(Icons.login_rounded, r.masuk),
                const SizedBox(width: 14),
                time(Icons.logout_rounded, r.pulang),
              ],
            ),
          ),
          StatusBadge(r.status),
        ],
      ),
    );
  }
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}

/// Simulator reader RFID — hanya untuk uji coba tanpa hardware.
Future<void> showTapSimulator(BuildContext context, {Student? only}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TapSimulator(only: only),
  );
}

class _TapSimulator extends StatefulWidget {
  const _TapSimulator({this.only});
  final Student? only;

  @override
  State<_TapSimulator> createState() => _TapSimulatorState();
}

class _TapSimulatorState extends State<_TapSimulator> {
  String? _last;

  Future<void> _tap(String uid) async {
    final r = await app.onCardTapped(uid);
    if (mounted) setState(() => _last = r.message);
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.only != null ? [widget.only!] : app.sortedStudents;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Simulator reader RFID',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                  'Mode reader saat ini: ${app.mode.label}'
                  '${app.waitingForCard ? ' · menunggu kartu untuk pendaftaran' : ''}',
                  style: const TextStyle(color: C.mute, fontSize: 12.5)),
              if (_last != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: C.greenBg, borderRadius: BorderRadius.circular(10)),
                  child: Text(_last!,
                      style: const TextStyle(color: C.green, fontWeight: FontWeight.w600)),
                ),
              ],
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final s in list)
                      if (s.cardUid != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Initials(s.name),
                          title: Text(s.name),
                          subtitle: Text(s.cardUid!),
                          trailing: const Icon(Icons.nfc_rounded, color: C.blue),
                          onTap: () => _tap(s.cardUid!),
                        ),
                    if (widget.only == null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.add_card_rounded, color: C.navy),
                        title: const Text('Kartu baru (belum terdaftar)'),
                        subtitle: const Text('Dipakai untuk uji pendaftaran kartu'),
                        onTap: () => _tap(app.newCardUid()),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
