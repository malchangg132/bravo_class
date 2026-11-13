import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets.dart';

class KartuPage extends StatefulWidget {
  const KartuPage({super.key, required this.tabs});
  final Widget tabs;

  @override
  State<KartuPage> createState() => _KartuPageState();
}

class _KartuPageState extends State<KartuPage> {
  final _name = TextEditingController();
  final _nisn = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _nisn.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final err = await app.startRegistration(_name.text, _nisn.text);
    if (!mounted) return;
    if (err != null) {
      showSnack(context, err);
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RegistrationDialog(),
    );
    if (app.registeredStudent != null) {
      _name.clear();
      _nisn.clear();
    }
  }

  Future<void> _edit(Student s) async {
    final name = TextEditingController(text: s.name);
    final nisn = TextEditingController(text: s.nisn);
    String? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Ganti nama & NISN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama siswa'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nisn,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'NISN'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: C.red, fontSize: 12)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                final e = await app.updateStudent(s.id, name.text, nisn.text);
                if (e != null) {
                  setLocal(() => error = e);
                } else if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    nisn.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final list = app.sortedStudents;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            widget.tabs,
            const SizedBox(height: 14),
            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.badge_outlined, color: C.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pendaftaran Kartu RFID',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        Text(
                            'Isi nama dan NISN, tekan "Daftarkan Kartu", lalu tap kartu '
                            'ke reader. Kartu akan dikenali sebagai absensi siswa tersebut.',
                            style: TextStyle(fontSize: 11, color: C.mute)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: StatTile('${app.registeredCount}', 'Kartu terdaftar',
                        Icons.credit_card_rounded, C.green)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatTile('${app.unregisteredCount}', 'Belum terdaftar',
                        Icons.credit_card_off_outlined, C.amber)),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daftarkan kartu untuk',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: 'Nama siswa'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nisn,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'NISN'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _register,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Daftarkan Kartu'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionTitle(
              'Daftar siswa',
              'Pilih siswa',
              trailing: Text('${list.length} siswa',
                  style: const TextStyle(fontSize: 12, color: C.mute)),
            ),
            const SizedBox(height: 10),
            for (final s in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Initials(s.name, size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 13)),
                            Text('NISN ${s.nisn}',
                                style: const TextStyle(fontSize: 10.5, color: C.mute)),
                            Text('UID ${s.cardUid ?? 'belum terdaftar'}',
                                style: const TextStyle(fontSize: 10.5, color: C.mute)),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: C.greenBg,
                          foregroundColor: C.green,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: () => _edit(s),
                        child: const Text('Ganti',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RegistrationDialog extends StatelessWidget {
  const _RegistrationDialog();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final done = app.registeredStudent;
        if (done != null) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle_rounded, color: C.green, size: 52),
            title: const Text('Kartu sudah terdaftar'),
            content: Text(
              '${done.name}\nNISN ${done.nisn}\nUID ${done.cardUid}\n\n'
              'Namanya akan muncul di dashboard, perizinan, dan daftar siswa.',
              textAlign: TextAlign.center,
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Selesai'),
              ),
            ],
          );
        }
        return AlertDialog(
          icon: const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          title: const Text('Silakan tap kartu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tempelkan kartu RFID ke reader untuk ${app.pendingName ?? ''}.\n'
                'Layar LCD alat akan menampilkan "DAFTAR KARTU".',
                textAlign: TextAlign.center,
              ),
              if (app.registrationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(app.registrationError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: C.red, fontSize: 12.5)),
                ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => app.onCardTapped(app.newCardUid()),
                  icon: const Icon(Icons.nfc_rounded, size: 18),
                  label: const Text('Simulasi tap kartu baru'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                app.cancelRegistration();
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }
}
