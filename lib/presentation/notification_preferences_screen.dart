import 'package:flutter/material.dart';

import '../constants.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _bookingUpdates = true;
  bool _promotions = true;
  bool _systemUpdates = true;
  bool _chatMessages = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _PreferenceTile(
            title: 'Pembaruan Pesanan',
            subtitle: 'Konfirmasi, pembatalan, dan status layanan',
            value: _bookingUpdates,
            onChanged: (value) => setState(() => _bookingUpdates = value),
          ),
          const SizedBox(height: 12),
          _PreferenceTile(
            title: 'Promo & Penawaran',
            subtitle: 'Diskon layanan dan penawaran khusus',
            value: _promotions,
            onChanged: (value) => setState(() => _promotions = value),
          ),
          const SizedBox(height: 12),
          _PreferenceTile(
            title: 'Pengumuman Sistem',
            subtitle: 'Informasi aplikasi dan pembaruan penting',
            value: _systemUpdates,
            onChanged: (value) => setState(() => _systemUpdates = value),
          ),
          const SizedBox(height: 12),
          _PreferenceTile(
            title: 'Pesan Chat',
            subtitle: 'Notifikasi saat ada pesan baru',
            value: _chatMessages,
            onChanged: (value) => setState(() => _chatMessages = value),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 3),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xff0D9488),
        title: Text(
          title,
          style: const TextStyle(
            color: kHardTextColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.blueGrey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
