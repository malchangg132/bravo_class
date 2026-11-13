import 'package:flutter/material.dart';

import 'screen/login_screen.dart';
import 'theme.dart';

void main() => runApp(const RfidApp());

class RfidApp extends StatelessWidget {
  const RfidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RFID Absen',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: C.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nfc_rounded, size: 72, color: Colors.white),
            SizedBox(height: 14),
            Text('RFID ATTENDANCE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            SizedBox(height: 4),
            Text('Monitoring Absensi Siswa', style: TextStyle(color: Color(0xCCFFFFFF))),
          ],
        ),
      ),
    );
  }
}
