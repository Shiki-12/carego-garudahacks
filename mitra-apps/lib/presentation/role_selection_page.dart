import 'package:flutter/material.dart';

import '../constants.dart';
import '../size_confige.dart';
import '../model.dart/mitra_role.dart';
import 'auth_page.dart';

/// SRS-01 (US-MA-001): Layar pemilihan jenis kemitraan.
/// Dipilih SEBELUM auth/melengkapi profil, sesuai PRD_Mitra 5.1.
class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({Key? key}) : super(key: key);

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  int? _selectedRole;
  int? _selectedEntity;

  static const _roles = [
    _RoleOption(
      title: "Caregiver",
      subtitle: "Panti jompo, yayasan, atau caregiver mandiri",
      icon: Icons.favorite,
    ),
    _RoleOption(
      title: "Driver Ambulans",
      subtitle: "Armada RS/klinik atau driver mandiri",
      icon: Icons.airport_shuttle,
    ),
    _RoleOption(
      title: "Rental Alat Medis",
      subtitle: "Toko alat kesehatan atau perorangan",
      icon: Icons.local_hospital,
    ),
  ];

  static const _entities = ["Instansi / Faskes", "Independen / Mandiri"];

  // Rental tidak membedakan instansi vs mandiri (SRS-01 FR-MA-03).
  bool get _needsEntityChoice => _selectedRole != null && _selectedRole != 2;

  bool get _canContinue =>
      _selectedRole != null && (!_needsEntityChoice || _selectedEntity != null);

  /// Rakit MitraRole dari pilihan index (SRS-07).
  MitraRole _buildRole() {
    final type = [
      MitraProviderType.caregiver,
      MitraProviderType.ambulance,
      MitraProviderType.rental,
    ][_selectedRole!];

    // Rental tanpa entitas (FR-RX-06).
    if (!_needsEntityChoice) return MitraRole(type: type);

    final entity = _selectedEntity == 0
        ? MitraEntityType.agency
        : MitraEntityType.independent;
    return MitraRole(type: type, entity: entity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.06)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: getRelativeHeight(0.05)),
              Text(
                "Pilih Jenis Kemitraan",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: getRelativeWidth(0.07),
                ),
              ),
              SizedBox(height: getRelativeHeight(0.006)),
              Text(
                "Tentukan layanan yang ingin Anda sediakan di CAREGO",
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: getRelativeWidth(0.036),
                ),
              ),
              SizedBox(height: getRelativeHeight(0.03)),
              ...List.generate(_roles.length, (index) {
                final role = _roles[index];
                final isSelected = _selectedRole == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRole = index;
                      _selectedEntity = null;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: getRelativeHeight(0.018)),
                    padding: EdgeInsets.all(getRelativeWidth(0.04)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? kPrimaryDarkColor
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                          color: (isSelected
                                  ? kPrimaryDarkColor
                                  : Colors.black)
                              .withValues(alpha: isSelected ? 0.18 : 0.06),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: getRelativeWidth(0.14),
                          height: getRelativeWidth(0.14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                kCategoriesPrimaryColor[index],
                                kCategoriesSecondryColor[index],
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            role.icon,
                            color: Colors.white,
                            size: getRelativeWidth(0.065),
                          ),
                        ),
                        SizedBox(width: getRelativeWidth(0.04)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.title,
                                style: TextStyle(
                                  color: kHardTextColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: getRelativeWidth(0.042),
                                ),
                              ),
                              SizedBox(height: getRelativeHeight(0.003)),
                              Text(
                                role.subtitle,
                                style: TextStyle(
                                  color: Colors.blueGrey[400],
                                  fontSize: getRelativeWidth(0.03),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? kPrimaryDarkColor
                              : kLightTextColor,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (_needsEntityChoice) ...[
                SizedBox(height: getRelativeHeight(0.01)),
                Text(
                  "Tipe Entitas",
                  style: TextStyle(
                    color: kHardTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: getRelativeWidth(0.042),
                  ),
                ),
                SizedBox(height: getRelativeHeight(0.012)),
                Row(
                  children: List.generate(_entities.length, (index) {
                    final isSelected = _selectedEntity == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedEntity = index),
                        child: Container(
                          margin: EdgeInsets.only(
                            right: index == 0 ? getRelativeWidth(0.03) : 0,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: getRelativeHeight(0.016),
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? kPrimaryDarkColor : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _entities[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : kHardTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: getRelativeWidth(0.032),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              SizedBox(height: getRelativeHeight(0.04)),
              GestureDetector(
                onTap: _canContinue
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AuthPage(role: _buildRole()),
                          ),
                        );
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: getRelativeHeight(0.02),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _canContinue
                          ? [kPrimarylightColor, kPrimaryDarkColor]
                          : [kLightTextColor, kLightTextColor],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      if (_canContinue)
                        BoxShadow(
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                          color: kPrimaryDarkColor.withValues(alpha: 0.35),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "Lanjutkan",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: getRelativeWidth(0.045),
                      ),
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

class _RoleOption {
  final String title;
  final String subtitle;
  final IconData icon;

  const _RoleOption({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}