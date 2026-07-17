import 'package:flutter/material.dart';

import '../constants.dart';
import '../core/api_service.dart';
import '../core/service_locator.dart';
import '../size_confige.dart';
import '../model.dart/mitra_role.dart';
import 'bottom_navigation_bar.dart';
import 'mitra_header.dart';
import 'notifications_page.dart';
import 'management_page.dart';
import 'profile_page.dart';

/// SRS-09: Shell khusus Driver Ambulans. Beranda berpusat pada PETA &
/// permintaan darurat. Varian agency (Armada) vs independent (Profil).
class DriverShell extends StatefulWidget {
  final MitraRole role;

  const DriverShell({Key? key, required this.role}) : super(key: key);

  @override
  State<DriverShell> createState() => _DriverShellState();
}

/// Tahap perjalanan (FR-DR-04).
enum _TripStage { none, toPickup, pickedUp, toDestination }

class _DriverShellState extends State<DriverShell> {
  int _selectedIndex = 0;
  bool _isActive = true;
  bool _togglingAvailability = false;
  _TripStage _stage = _TripStage.none;

  /// FR-DR-01: toggle Standby/Aktif → PUT /mitra/availability. Optimistik +
  /// rollback bila server menolak.
  Future<void> _toggleAvailability() async {
    if (_togglingAvailability) return;
    final target = !_isActive;
    setState(() {
      _isActive = target;
      _togglingAvailability = true;
    });
    try {
      final confirmed = await Services.I.availability.setAvailable(target);
      if (!mounted) return;
      setState(() => _isActive = confirmed);
      _snack(
        confirmed
            ? "Anda AKTIF menerima panggilan"
            : "Anda sedang STANDBY",
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
      _buildTasks(),
      const ChatListPage(),
      isAgency
          ? const ManagementPage(title: "Armada/Alat")
          : ProfilePage(role: widget.role),
    ];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemPressed: (index) => setState(() => _selectedIndex = index),
        // FR-DR-01: toggle Standby/Aktif (PUT /mitra/availability).
        centerIcon: _isActive ? Icons.power_settings_new : Icons.power_off,
        onCenterPressed: _toggleAvailability,
        itemIcons: [
          Icons.home,
          Icons.assignment,
          Icons.message,
          isAgency ? Icons.airport_shuttle : Icons.account_circle,
        ],
      ),
    );
  }

  // ---- Beranda: peta + overlay status/permintaan/perjalanan ----
  Widget _buildHome() {
    return Stack(
      children: [
        const _MapPlaceholder(),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(getRelativeWidth(0.04)),
                child: _statusOverlay(),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.all(getRelativeWidth(0.04)),
                child: _bottomCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusOverlay() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getRelativeWidth(0.04),
        vertical: getRelativeHeight(0.014),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.airport_shuttle,
              color: kPrimaryDarkColor, size: getRelativeWidth(0.06)),
          SizedBox(width: getRelativeWidth(0.03)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.role.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kHardTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: getRelativeWidth(0.038),
                  ),
                ),
                Text(
                  "Unit: B 1234 AMB · ALS",
                  style: TextStyle(
                    color: Colors.blueGrey[400],
                    fontSize: getRelativeWidth(0.03),
                  ),
                ),
              ],
            ),
          ),
          AvailabilityChip(
            isActive: _isActive,
            activeLabel: "Aktif",
            inactiveLabel: "Standby",
          ),
        ],
      ),
    );
  }

  Widget _bottomCard() {
    // Saat perjalanan aktif → kartu tahap perjalanan.
    if (_stage != _TripStage.none) return _tripCard();
    // Saat standby → info standby.
    if (!_isActive) {
      return _infoCard(
        "Anda sedang Standby",
        "Aktifkan status untuk menerima panggilan darurat.",
        Icons.info_outline,
      );
    }
    // Saat aktif & tidak ada perjalanan → simulasi permintaan darurat masuk.
    return _requestCard();
  }

  Widget _infoCard(String title, String body, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(getRelativeWidth(0.045)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: kLightTextColor, size: getRelativeWidth(0.07)),
          SizedBox(width: getRelativeWidth(0.03)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: kHardTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: getRelativeWidth(0.04),
                  ),
                ),
                SizedBox(height: getRelativeHeight(0.004)),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.blueGrey[400],
                    fontSize: getRelativeWidth(0.032),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FR-DR-03: kartu permintaan darurat (warna urgen di dalam kartu).
  Widget _requestCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(getRelativeWidth(0.045)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.redAccent, width: 2),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.redAccent.withValues(alpha: 0.2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(getRelativeWidth(0.02)),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emergency,
                    color: Colors.white, size: getRelativeWidth(0.05)),
              ),
              SizedBox(width: getRelativeWidth(0.03)),
              Expanded(
                child: Text(
                  "Permintaan Darurat Masuk",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: getRelativeWidth(0.04),
                  ),
                ),
              ),
              Text(
                "2,3 km",
                style: TextStyle(
                  color: kHardTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: getRelativeWidth(0.034),
                ),
              ),
            ],
          ),
          SizedBox(height: getRelativeHeight(0.014)),
          _reqRow(Icons.my_location, "Jemput", "Jl. Mawar No. 8, Jakarta"),
          _reqRow(Icons.local_hospital, "Tujuan", "RS Harapan Bunda"),
          _reqRow(Icons.medical_services, "Jenis", "ALS · Ventilator"),
          SizedBox(height: getRelativeHeight(0.008)),
          Row(
            children: [
              Expanded(
                child: _button("Tolak", Colors.redAccent, filled: false,
                    onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Permintaan ditolak")),
                  );
                }),
              ),
              SizedBox(width: getRelativeWidth(0.03)),
              Expanded(
                child: _button("Terima", kPrimaryDarkColor, onTap: () {
                  setState(() => _stage = _TripStage.toPickup);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reqRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: getRelativeHeight(0.006)),
      child: Row(
        children: [
          Icon(icon, size: getRelativeWidth(0.04), color: kPrimaryDarkColor),
          SizedBox(width: getRelativeWidth(0.02)),
          Text(
            "$label: ",
            style: TextStyle(
              color: Colors.blueGrey[400],
              fontSize: getRelativeWidth(0.032),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: kHardTextColor,
                fontWeight: FontWeight.w700,
                fontSize: getRelativeWidth(0.032),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FR-DR-04: kartu tahap perjalanan bertahap.
  Widget _tripCard() {
    final labels = {
      _TripStage.toPickup: "Menuju Penjemputan",
      _TripStage.pickedUp: "Pasien Dijemput",
      _TripStage.toDestination: "Menuju Tujuan (RS)",
    };
    final nextLabel = {
      _TripStage.toPickup: "Pasien Dijemput",
      _TripStage.pickedUp: "Menuju Tujuan",
      _TripStage.toDestination: "Selesaikan Perjalanan",
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(getRelativeWidth(0.045)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Perjalanan Aktif",
            style: TextStyle(
              color: Colors.blueGrey[400],
              fontWeight: FontWeight.w700,
              fontSize: getRelativeWidth(0.032),
            ),
          ),
          SizedBox(height: getRelativeHeight(0.004)),
          Text(
            labels[_stage]!,
            style: TextStyle(
              color: kPrimaryDarkColor,
              fontWeight: FontWeight.w900,
              fontSize: getRelativeWidth(0.05),
            ),
          ),
          SizedBox(height: getRelativeHeight(0.014)),
          Row(
            children: [
              _circleButton(Icons.navigation, "Navigasi", () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Membuka navigasi...")),
                );
              }),
              SizedBox(width: getRelativeWidth(0.03)),
              _circleButton(Icons.phone, "Telepon", () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Menghubungi pasien...")),
                );
              }),
              const Spacer(),
            ],
          ),
          SizedBox(height: getRelativeHeight(0.014)),
          _button(nextLabel[_stage]!, kPrimaryDarkColor, onTap: () {
            setState(() {
              switch (_stage) {
                case _TripStage.toPickup:
                  _stage = _TripStage.pickedUp;
                  break;
                case _TripStage.pickedUp:
                  _stage = _TripStage.toDestination;
                  break;
                case _TripStage.toDestination:
                default:
                  _stage = _TripStage.none;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Perjalanan selesai")),
                  );
              }
            });
          }),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(getRelativeWidth(0.03)),
            decoration: BoxDecoration(
              color: kPrimaryDarkColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: kPrimaryDarkColor, size: getRelativeWidth(0.055)),
          ),
          SizedBox(height: getRelativeHeight(0.004)),
          Text(
            label,
            style: TextStyle(
              color: kHardTextColor,
              fontWeight: FontWeight.w700,
              fontSize: getRelativeWidth(0.028),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Tab Tugas: antrean & riwayat perjalanan ----
  Widget _buildTasks() {
    final tasks = [
      _Task("#A-204", "RS Harapan Bunda", "ALS · Selesai", "Kemarin"),
      _Task("#A-198", "RSUD Cipto", "BLS · Selesai", "2 hari lalu"),
      _Task("#A-187", "Klinik Sehat", "Jenazah · Selesai", "3 hari lalu"),
    ];
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(getRelativeWidth(0.05)),
            child: Text(
              "Tugas & Riwayat",
              style: TextStyle(
                color: kHardTextColor,
                fontWeight: FontWeight.w800,
                fontSize: getRelativeWidth(0.055),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.05)),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final t = tasks[index];
                return Container(
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
                        width: getRelativeWidth(0.12),
                        height: getRelativeWidth(0.12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [kPrimarylightColor, kPrimaryDarkColor],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.route,
                            color: Colors.white, size: getRelativeWidth(0.055)),
                      ),
                      SizedBox(width: getRelativeWidth(0.035)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${t.code} · ${t.destination}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: kHardTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: getRelativeWidth(0.036),
                              ),
                            ),
                            SizedBox(height: getRelativeHeight(0.003)),
                            Text(
                              t.detail,
                              style: TextStyle(
                                color: Colors.blueGrey[400],
                                fontSize: getRelativeWidth(0.03),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        t.time,
                        style: TextStyle(
                          color: kLightTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: getRelativeWidth(0.028),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(String label, Color color,
      {bool filled = true, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: getRelativeHeight(0.012)),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          border: filled ? null : Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : color,
              fontWeight: FontWeight.w800,
              fontSize: getRelativeWidth(0.034),
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder peta bergaya (tanpa SDK peta untuk MVP — FR-DR-01 catatan impl).
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffDCEFEA), Color(0xffC7E6DE)],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on,
                  color: kPrimaryDarkColor, size: getRelativeWidth(0.14)),
              Text(
                "Lokasi Anda",
                style: TextStyle(
                  color: kHardTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: getRelativeWidth(0.032),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff0D9488).withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Task {
  final String code, destination, detail, time;
  _Task(this.code, this.destination, this.detail, this.time);
}