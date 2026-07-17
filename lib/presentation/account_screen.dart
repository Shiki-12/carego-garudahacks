import 'package:flutter/material.dart';

import '../constants.dart';
import 'about_screen.dart';
import 'help_center_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';

class AccountScreen extends StatelessWidget {
  final bool showScaffold;

  const AccountScreen({
    Key? key,
    this.showScaffold = true,
  }) : super(key: key);

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Keluar dari Akun?'),
          content: const Text('Ini hanya simulasi logout untuk MVP.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Anda berhasil keluar (simulasi)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Keluar',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            16,
            showScaffold ? 18 : MediaQuery.of(context).padding.top + 18,
            16,
            18,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 72,
                  height: 72,
                  color: kPrimarylightColor,
                  child: Image.asset(
                    'assets/images/person.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, Pengguna',
                      style: TextStyle(
                        color: kHardTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'pengguna@carego.id',
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              _AccountMenuTile(
                icon: Icons.person,
                title: 'Profil Saya',
                onTap: () => _open(context, const ProfileScreen()),
              ),
              _AccountMenuTile(
                icon: Icons.account_balance_wallet,
                title: 'Saldo & Pembayaran',
                onTap: () => _open(context, const WalletScreen()),
              ),
              _AccountMenuTile(
                icon: Icons.notifications,
                title: 'Notifikasi',
                onTap: () => _open(context, const NotificationsScreen()),
              ),
              _AccountMenuTile(
                icon: Icons.help_outline,
                title: 'Pusat Bantuan',
                onTap: () => _open(context, const HelpCenterScreen()),
              ),
              _AccountMenuTile(
                icon: Icons.info_outline,
                title: 'Tentang Aplikasi',
                onTap: () => _open(context, const AboutScreen()),
              ),
              _AccountMenuTile(
                icon: Icons.logout,
                title: 'Keluar',
                isDanger: true,
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ],
    );

    if (!showScaffold) return content;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
      ),
      body: content,
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDanger;
  final VoidCallback onTap;

  const _AccountMenuTile({
    required this.icon,
    required this.title,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.red[600]! : const Color(0xff0D9488);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDanger ? Colors.red[600] : kHardTextColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: kPrimaryDarkColor),
      ),
    );
  }
}
