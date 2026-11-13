import 'package:flutter/material.dart';   
import '../../app_state.dart';
import '../../widgets.dart';
import '../profil_view.dart';
import 'kartu_page.dart';
import 'monitoring_page.dart';
import 'perizinan_page.dart';

class GuruShell extends StatefulWidget {
  const GuruShell({super.key});

  @override
  State<GuruShell> createState() => _GuruShellState();
}

class _GuruShellState extends State<GuruShell> {
  int _tab = 0; // 0 Monitoring, 1 Perizinan, 2 Kartu
  bool _profile = false;

  @override
  Widget build(BuildContext context) {
    final tabs = SegTabs(index: _tab, onChanged: (i) => setState(() => _tab = i));
    final Widget body;
    if (_profile) {
      body = ProfileView(name: app.userName, rows: const [
        ('Peran', 'Guru / Admin'),
      ]);
    } else {
      body = switch (_tab) {
        0 => MonitoringPage(tabs: tabs),
        1 => PerizinanPage(tabs: tabs),
        _ => KartuPage(tabs: tabs),
      };
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: body),
            BottomBar(
              items: const [
                (Icons.home_outlined, 'Home'),
                (Icons.fact_check_outlined, 'Absensi'),
                (Icons.person_outline, 'Profil'),
              ],
              index: _profile ? 2 : (_tab == 0 ? 0 : 1),
              onTap: (i) => setState(() {
                switch (i) {
                  case 0:
                    _profile = false;
                    _tab = 0;
                  case 1:
                    _profile = false;
                    if (_tab == 0) _tab = 1;
                  default:
                    _profile = true;
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}
