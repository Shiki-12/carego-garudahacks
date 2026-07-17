import 'package:flutter/material.dart';

import '../constants.dart';
import '../core/api_service.dart';
import '../core/service_locator.dart';
import '../models/mitra_session.dart';
import '../services/auth_service.dart';
import '../size_confige.dart';
import '../model.dart/mitra_role.dart';
import 'caregiver_shell.dart';
import 'driver_shell.dart';
import 'rental_shell.dart';

/// SRS-01 (FR-MA-01): Auth Mitra — login/register dengan No. HP.
/// UI mengikuti pattern form template (rounded fields, pill CTA).
///
/// Terhubung backend via [AuthService] (doc 02 §9): register/login menyimpan
/// token sesi di secure storage, lalu resolve shell sesuai `provider_type`
/// yang dikunci server (role-lock, SRS-07). Peran hasil server diprioritaskan
/// di atas peran pilihan onboarding bila keduanya berbeda.
class AuthPage extends StatefulWidget {
  final MitraRole role;

  /// Injectable untuk test; default composition root (doc 08 §9).
  final AuthService? authService;

  const AuthPage({Key? key, required this.role, this.authService})
      : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final AuthService _auth = widget.authService ?? Services.I.auth;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLogin = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// SRS-07: resolusi shell sesuai provider_type sesi (server-authoritative).
  Widget _shellForRole(MitraRole role) {
    switch (role.type) {
      case MitraProviderType.ambulance:
        return DriverShell(role: role);
      case MitraProviderType.rental:
        return RentalShell(role: role);
      case MitraProviderType.caregiver:
        return CaregiverShell(role: role);
    }
  }

  /// Validasi input dasar sebelum kirim (doc 08 §5 — cegah request sia-sia).
  String? _validate() {
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (!_isLogin && _nameCtrl.text.trim().isEmpty) {
      return 'Nama / instansi wajib diisi';
    }
    if (phone.length < 8) {
      return 'Nomor WhatsApp tidak valid';
    }
    if (password.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final MitraSession session = _isLogin
          ? await _auth.login(
              phone: _phoneCtrl.text.trim(),
              password: _passwordCtrl.text,
            )
          : await _auth.register(
              name: _nameCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              password: _passwordCtrl.text,
              role: widget.role,
            );
      if (!mounted) return;

      // Role-lock: provider_type final dari server (SRS-07). Entitas dari
      // sesi bila ada; jika server tak mengembalikannya, pertahankan pilihan
      // onboarding agar pembedaan agency/mandiri tak hilang.
      final resolved = MitraRole(
        type: session.role.type,
        entity: session.role.entity ?? widget.role.entity,
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => _shellForRole(resolved)),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  final _outlineBorder = OutlineInputBorder(
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.circular(30),
  );

  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      contentPadding:
          EdgeInsets.symmetric(vertical: getRelativeHeight(0.02)),
      fillColor: Colors.white,
      filled: true,
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: getRelativeWidth(0.04),
        color: Colors.blueGrey.withValues(alpha: 0.9),
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.blueGrey.withValues(alpha: 0.9),
        size: getRelativeWidth(0.06),
      ),
      border: _outlineBorder,
      enabledBorder: _outlineBorder,
      focusedBorder: _outlineBorder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: Text(
          "Mitra ${widget.role.roleTitle}",
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.06)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: getRelativeHeight(0.04)),
              Text(
                _isLogin ? "Masuk" : "Daftar",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: getRelativeWidth(0.07),
                ),
              ),
              SizedBox(height: getRelativeHeight(0.006)),
              Text(
                _isLogin
                    ? "Selamat datang kembali, Mitra CAREGO"
                    : "Lengkapi data untuk menjadi Mitra CAREGO",
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: getRelativeWidth(0.036),
                ),
              ),
              SizedBox(height: getRelativeHeight(0.035)),
              if (!_isLogin) ...[
                TextField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration:
                      _fieldDecoration("Nama Lengkap / Instansi", Icons.person),
                ),
                SizedBox(height: getRelativeHeight(0.02)),
              ],
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration:
                    _fieldDecoration("Nomor WhatsApp", Icons.phone_android),
              ),
              SizedBox(height: getRelativeHeight(0.02)),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: _fieldDecoration("Kata Sandi", Icons.lock),
              ),
              if (_error != null) ...[
                SizedBox(height: getRelativeHeight(0.02)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: getRelativeWidth(0.045),
                    ),
                    SizedBox(width: getRelativeWidth(0.02)),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: getRelativeWidth(0.033),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: getRelativeHeight(0.04)),
              GestureDetector(
                onTap: _submitting ? null : _submit,
                child: Opacity(
                  opacity: _submitting ? 0.7 : 1,
                  child: Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(vertical: getRelativeHeight(0.02)),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [kPrimarylightColor, kPrimaryDarkColor],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                          color: kPrimaryDarkColor.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _submitting
                          ? SizedBox(
                              height: getRelativeWidth(0.055),
                              width: getRelativeWidth(0.055),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isLogin ? "Masuk" : "Daftar",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: getRelativeWidth(0.045),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: getRelativeHeight(0.025)),
              Center(
                child: GestureDetector(
                  onTap: _submitting
                      ? null
                      : () => setState(() {
                            _isLogin = !_isLogin;
                            _error = null;
                          }),
                  child: Text.rich(
                    TextSpan(
                      text: _isLogin
                          ? "Belum punya akun? "
                          : "Sudah punya akun? ",
                      style: TextStyle(
                        color: Colors.blueGrey[400],
                        fontSize: getRelativeWidth(0.034),
                      ),
                      children: [
                        TextSpan(
                          text: _isLogin ? "Daftar" : "Masuk",
                          style: const TextStyle(
                            color: kPrimaryDarkColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: getRelativeHeight(0.04)),
            ],
          ),
        ),
      ),
    );
  }
}
