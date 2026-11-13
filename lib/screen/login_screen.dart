import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'guru/guru_shell.dart';
import 'siswa/siswa_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Role _role = Role.siswa;
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await app.login(_role, _user.text, _pass.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => _role == Role.guru ? const GuruShell() : const SiswaShell(),
    ));
  }

  Widget _roleButton(Role r, IconData icon, String label) {
    final sel = _role == r;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _role = r;
          _error = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? C.blue : C.line, width: sel ? 1.8 : 1),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: sel ? C.blue : C.mute),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: sel ? C.blue : C.mute)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const Text('RFID ATTENDANCE',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Text('Monitoring Absensi Siswa',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 40),
                  Row(children: [
                    _roleButton(Role.siswa, Icons.person_outline, 'Siswa'),
                    const SizedBox(width: 12),
                    _roleButton(Role.guru, Icons.co_present_outlined, 'Guru'),
                  ]),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _user,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                        hintText: _role == Role.siswa ? 'NISN' : 'Nama guru'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _pass,
                    obscureText: _hide,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_hide ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: C.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: C.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('LOGIN',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Sistem Absensi Siswa Berbasis RFID',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.navy)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
