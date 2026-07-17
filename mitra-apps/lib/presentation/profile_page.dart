import 'package:flutter/material.dart';

import '../constants.dart';
import '../core/service_locator.dart';
import '../size_confige.dart';
import '../model.dart/mitra_role.dart';
import 'management_page.dart';
import 'notifications_page.dart';
import 'role_selection_page.dart';

/// Profil mitra + pintasan ke manajemen aset, notifikasi, dan keluar.
/// Menu manajemen menyesuaikan peran (SRS-07). Konten dummy (FR-MA-02).
class ProfilePage extends StatelessWidget {
  final MitraRole? role;

  const ProfilePage({Key? key, this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final menus = <_ProfileMenu>[
      ..._roleMenus(context),
      _ProfileMenu(
        title: "Notifikasi",
        subtitle: "Riwayat pesanan & aktivitas",
        icon: Icons.notifications,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(getRelativeWidth(0.05)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: getRelativeHeight(0.02)),
              Row(
                children: [
                  Container(
                    width: getRelativeWidth(0.18),
                    height: getRelativeWidth(0.18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kPrimarylightColor, kPrimaryDarkColor],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.storefront,
                      color: Colors.white,
                      size: getRelativeWidth(0.09),
                    ),
                  ),
                  SizedBox(width: getRelativeWidth(0.04)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role?.displayName ?? "Panti Jompo Sejahtera",
                          style: TextStyle(
                            color: kHardTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: getRelativeWidth(0.05),
                          ),
                        ),
                        SizedBox(height: getRelativeHeight(0.004)),
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              color: kPrimaryDarkColor,
                              size: getRelativeWidth(0.04),
                            ),
                            SizedBox(width: getRelativeWidth(0.01)),
                            Text(
                              "Mitra Terverifikasi",
                              style: TextStyle(
                                color: kPrimaryDarkColor,
                                fontWeight: FontWeight.w700,
                                fontSize: getRelativeWidth(0.032),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: getRelativeHeight(0.035)),
              ...menus.map((menu) => _buildMenuTile(menu)),
              SizedBox(height: getRelativeHeight(0.02)),
              GestureDetector(
                onTap: () async {
                  // Bersihkan sesi (token secure storage) sebelum kembali ke
                  // root — cegah layar peran lama tetap terautentikasi.
                  await Services.I.auth.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const RoleSelectionPage(),
                    ),
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(vertical: getRelativeHeight(0.018)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      "Keluar",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: getRelativeWidth(0.04),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menu manajemen yang relevan dengan peran (SRS-07 matriks fitur).
  List<_ProfileMenu> _roleMenus(BuildContext context) {
    void open(String title) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ManagementPage(title: title)),
        );

    switch (role?.type) {
      case MitraProviderType.ambulance:
        return [
          _ProfileMenu(
            title: "Armada/Alat",
            subtitle: "Kelola armada ambulans Anda",
            icon: Icons.airport_shuttle,
            onTap: () => open("Armada/Alat"),
          ),
        ];
      case MitraProviderType.rental:
        return [
          _ProfileMenu(
            title: "Katalog Rental",
            subtitle: "Kelola alat medis yang disewakan",
            icon: Icons.inventory_2,
            onTap: () => open("Katalog Rental"),
          ),
        ];
      case MitraProviderType.caregiver:
      default:
        // Caregiver mandiri: tanpa manajemen tim (FR-CG-04).
        if (role != null && role!.isIndependent) return const [];
        return [
          _ProfileMenu(
            title: "Personil",
            subtitle: "Kelola data caregiver Anda",
            icon: Icons.people,
            onTap: () => open("Personil"),
          ),
        ];
    }
  }

  Widget _buildMenuTile(_ProfileMenu menu) {
    return GestureDetector(
      onTap: menu.onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: getRelativeHeight(0.014)),
        padding: EdgeInsets.all(getRelativeWidth(0.04)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 8),
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(getRelativeWidth(0.028)),
              decoration: BoxDecoration(
                color: kPrimaryDarkColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                menu.icon,
                color: kPrimaryDarkColor,
                size: getRelativeWidth(0.055),
              ),
            ),
            SizedBox(width: getRelativeWidth(0.035)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.title,
                    style: TextStyle(
                      color: kHardTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: getRelativeWidth(0.038),
                    ),
                  ),
                  SizedBox(height: getRelativeHeight(0.003)),
                  Text(
                    menu.subtitle,
                    style: TextStyle(
                      color: Colors.blueGrey[400],
                      fontSize: getRelativeWidth(0.03),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: kLightTextColor,
              size: getRelativeWidth(0.06),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenu {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _ProfileMenu({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}