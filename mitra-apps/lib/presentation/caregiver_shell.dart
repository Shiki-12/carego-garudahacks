import 'package:flutter/material.dart';

import '../constants.dart';
import '../core/api_service.dart';
import '../core/service_locator.dart';
import '../size_confige.dart';
import '../model.dart/mitra_role.dart';
import 'bottom_navigation_bar.dart';
import 'mitra_header.dart';
import 'orders_page.dart';
import 'notifications_page.dart';
import 'management_page.dart';
import 'profile_page.dart';

/// SRS-08: Shell khusus Caregiver. Beranda berpusat pada JADWAL/AGENDA.
/// Varian agency (Personil + penugasan) vs independent (Profil diri).
class CaregiverShell extends StatefulWidget {
  final MitraRole role;

  const CaregiverShell({Key? key, required this.role}) : super(key: key);

  @override
  State<CaregiverShell> createState() => _CaregiverShellState();
}

class _CaregiverShellState extends State<CaregiverShell> {
  int _selectedIndex = 0;
  bool _isActive = true;
  bool _togglingAvailability = false;

  // FR-CG-01: agenda perawatan hari ini (dummy in-memory).
  static final _agenda = [
    _AgendaItem(
      time: "08:00 – 12:00",
      patient: "Budi Santoso",
      service: "Perawatan Lansia",
      address: "Jl. Melati No. 12, Jakarta",
    ),
    _AgendaItem(
      time: "13:00 – 17:00",
      patient: "Siti Aminah",
      service: "Pasca Operasi",
      address: "Jl. Kenanga No. 5, Jakarta",
    ),
  ];

  /// FR-CG-02: toggle Aktif/Libur → PUT /mitra/availability. Optimistik dengan
  /// rollback bila server menolak, agar UI tak pernah bohong soal status.
  Future<void> _toggleAvailability() async {
    if (_togglingAvailability) return;
    final target = !_isActive;
    setState(() {
      _isActive = target;
      _togglingAvailability = true;
    });
    try {
      final confirmed =
          await Services.I.availability.setAvailable(target);
      if (!mounted) return;
      setState(() => _isActive = confirmed);
      _snack(
        confirmed ? "Anda AKTIF menerima pesanan" : "Anda sedang LIBUR",
        kPrimaryDarkColor,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isActive = !target); // rollback.
      _snack(e.message, Colors.redAccent);
    } finally {
      if (mounted) setState(() => _togglingAvailability = false);
    }
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAgency = widget.role.isAgency;

    final tabs = <Widget>[
      _buildHome(),
      const OrdersPage(),
      const ChatListPage(),
      isAgency
          ? const ManagementPage(title: "Personil")
          : ProfilePage(role: widget.role),
    ];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemPressed: (index) => setState(() => _selectedIndex = index),
        // FR-CG-02: toggle Aktif/Libur di tombol tengah (PUT /mitra/availability).
        centerIcon: _isActive ? Icons.power_settings_new : Icons.power_off,
        onCenterPressed: _toggleAvailability,
        itemIcons: [
          Icons.home,
          Icons.assignment,
          Icons.message,
          isAgency ? Icons.people : Icons.account_circle,
        ],
      ),
    );
  }

  Widget _buildHome() {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MitraHeader(
              title: "Hi, Mitra",
              subtitle: widget.role.displayName,
              trailing: AvailabilityChip(
                isActive: _isActive,
                activeLabel: "Aktif",
                inactiveLabel: "Libur",
              ),
            ),
            SizedBox(height: getRelativeHeight(0.02)),
            _summaryRow(),
            SizedBox(height: getRelativeHeight(0.024)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.05)),
              child: Text(
                "Agenda Hari Ini",
                style: TextStyle(
                  color: kHardTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: getRelativeWidth(0.045),
                ),
              ),
            ),
            SizedBox(height: getRelativeHeight(0.012)),
            if (_agenda.isEmpty)
              _emptyAgenda()
            else
              ..._agenda.map(_agendaCard),
            SizedBox(height: getRelativeHeight(0.02)),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow() {
    final stats = [
      _Stat("2", "Order Aktif", Icons.assignment_turned_in),
      _Stat(widget.role.isAgency ? "5" : "1", "Personil", Icons.people),
      _Stat("Rp3.5jt", "Bulan Ini", Icons.account_balance_wallet),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.04)),
      child: Row(
        children: List.generate(stats.length, (i) {
          final s = stats[i];
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.01)),
              padding: EdgeInsets.symmetric(
                vertical: getRelativeHeight(0.016),
                horizontal: getRelativeWidth(0.02),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(s.icon,
                      color: kPrimaryDarkColor, size: getRelativeWidth(0.06)),
                  SizedBox(height: getRelativeHeight(0.006)),
                  Text(
                    s.value,
                    style: TextStyle(
                      color: kHardTextColor,
                      fontWeight: FontWeight.w900,
                      fontSize: getRelativeWidth(0.04),
                    ),
                  ),
                  Text(
                    s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blueGrey[400],
                      fontSize: getRelativeWidth(0.026),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _agendaCard(_AgendaItem item) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        getRelativeWidth(0.05),
        0,
        getRelativeWidth(0.05),
        getRelativeHeight(0.014),
      ),
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
            width: getRelativeWidth(0.13),
            height: getRelativeWidth(0.13),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimarylightColor, kPrimaryDarkColor],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite,
                color: Colors.white, size: getRelativeWidth(0.06)),
          ),
          SizedBox(width: getRelativeWidth(0.035)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: TextStyle(
                    color: kPrimaryDarkColor,
                    fontWeight: FontWeight.w800,
                    fontSize: getRelativeWidth(0.034),
                  ),
                ),
                SizedBox(height: getRelativeHeight(0.003)),
                Text(
                  "${item.patient} · ${item.service}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kHardTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: getRelativeWidth(0.036),
                  ),
                ),
                SizedBox(height: getRelativeHeight(0.004)),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: getRelativeWidth(0.034), color: kLightTextColor),
                    SizedBox(width: getRelativeWidth(0.01)),
                    Expanded(
                      child: Text(
                        item.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.blueGrey[400],
                          fontSize: getRelativeWidth(0.03),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyAgenda() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: getRelativeHeight(0.06)),
      child: Center(
        child: Text(
          "Belum ada jadwal hari ini",
          style: TextStyle(
            color: kLightTextColor,
            fontWeight: FontWeight.w800,
            fontSize: getRelativeWidth(0.04),
          ),
        ),
      ),
    );
  }
}

class _AgendaItem {
  final String time, patient, service, address;
  _AgendaItem({
    required this.time,
    required this.patient,
    required this.service,
    required this.address,
  });
}

class _Stat {
  final String value, label;
  final IconData icon;
  _Stat(this.value, this.label, this.icon);
}