import 'package:flutter/material.dart';

import '../constants.dart';
import '../size_confige.dart';
import '../model.dart/mitra_role.dart';
import 'bottom_navigation_bar.dart';
import 'mitra_header.dart';
import 'notifications_page.dart';
import 'management_page.dart';
import 'catalog_picker_page.dart';

/// SRS-10: Shell khusus Medical Rental. Berpusat pada KATALOG & siklus sewa.
/// Tanpa toggle online/offline & tanpa pembedaan entitas (FR-RN-05).
/// Tombol tengah nav = "Tambah Item" (FR-RN-01).
class RentalShell extends StatefulWidget {
  final MitraRole role;

  const RentalShell({Key? key, required this.role}) : super(key: key);

  @override
  State<RentalShell> createState() => _RentalShellState();
}

class _RentalShellState extends State<RentalShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _buildHome(),
      const _RentalOrdersPage(),
      const ChatListPage(),
      const ManagementPage(title: "Katalog Rental"),
    ];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemPressed: (index) => setState(() => _selectedIndex = index),
        // FR-RN-01: tombol tengah = tambah item (bukan toggle).
        centerIcon: Icons.add,
        onCenterPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CatalogPickerPage()),
          );
        },
        itemIcons: [
          Icons.home,
          Icons.receipt_long,
          Icons.message,
          Icons.inventory_2,
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
            ),
            SizedBox(height: getRelativeHeight(0.02)),
            _summaryRow(),
            SizedBox(height: getRelativeHeight(0.024)),
            _sectionTitle("Perlu Perhatian"),
            _attentionCard(
              "Tabung Oksigen — Stok Habis",
              "Isi ulang stok agar tampil di aplikasi pasien",
              Icons.warning_amber_rounded,
              Colors.orange,
            ),
            _attentionCard(
              "Ranjang Medis — Kembali Besok",
              "Disewa Andi Wijaya, jatuh tempo besok",
              Icons.event_available,
              kPrimaryDarkColor,
            ),
            SizedBox(height: getRelativeHeight(0.02)),
            _sectionTitle("Sewa Aktif"),
            _activeRental("Kursi Roda Standar", "Budi Santoso", "3 hari lagi"),
            _activeRental("Nebulizer", "Siti Aminah", "1 hari lagi"),
            SizedBox(height: getRelativeHeight(0.02)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: EdgeInsets.fromLTRB(
          getRelativeWidth(0.05),
          0,
          getRelativeWidth(0.05),
          getRelativeHeight(0.012),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: kHardTextColor,
            fontWeight: FontWeight.w800,
            fontSize: getRelativeWidth(0.045),
          ),
        ),
      );

  Widget _summaryRow() {
    final stats = [
      _Stat("8", "Item Katalog", Icons.inventory_2),
      _Stat("2", "Sedang Disewa", Icons.outbound),
      _Stat("Rp1.2jt", "Bulan Ini", Icons.account_balance_wallet),
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

  Widget _attentionCard(String title, String body, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        getRelativeWidth(0.05),
        0,
        getRelativeWidth(0.05),
        getRelativeHeight(0.012),
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
            padding: EdgeInsets.all(getRelativeWidth(0.025)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: getRelativeWidth(0.055)),
          ),
          SizedBox(width: getRelativeWidth(0.035)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                  body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.blueGrey[400],
                    fontSize: getRelativeWidth(0.03),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeRental(String item, String renter, String due) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        getRelativeWidth(0.05),
        0,
        getRelativeWidth(0.05),
        getRelativeHeight(0.012),
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
            child: Icon(Icons.medical_services,
                color: Colors.white, size: getRelativeWidth(0.055)),
          ),
          SizedBox(width: getRelativeWidth(0.035)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item,
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
                  "Disewa $renter",
                  style: TextStyle(
                    color: Colors.blueGrey[400],
                    fontSize: getRelativeWidth(0.03),
                  ),
                ),
              ],
            ),
          ),
          Text(
            due,
            style: TextStyle(
              color: kPrimaryDarkColor,
              fontWeight: FontWeight.w800,
              fontSize: getRelativeWidth(0.03),
            ),
          ),
        ],
      ),
    );
  }
}

/// SRS-10 (US-RN-003, FR-RN-04): Pesanan sewa — Baru / Disewa / Selesai.
class _RentalOrdersPage extends StatefulWidget {
  const _RentalOrdersPage();

  @override
  State<_RentalOrdersPage> createState() => _RentalOrdersPageState();
}

class _RentalOrdersPageState extends State<_RentalOrdersPage> {
  int _tab = 0;
  static const _tabs = ["Baru", "Disewa", "Selesai"];

  final List<_RentalOrder> _orders = [
    _RentalOrder("#R-311", "Budi Santoso", "Kursi Roda Standar", "3 hari",
        "Rp75.000", 0),
    _RentalOrder("#R-310", "Rina Marlina", "Tabung Oksigen", "1 minggu",
        "Rp280.000", 0),
    _RentalOrder("#R-305", "Andi Wijaya", "Ranjang Medis Elektrik", "5 hari",
        "Rp450.000", 1),
    _RentalOrder("#R-298", "Siti Aminah", "Nebulizer", "3 hari", "Rp90.000", 2),
  ];

  List<_RentalOrder> get _filtered =>
      _orders.where((o) => o.stage == _tab).toList();

  void _advance(_RentalOrder order) {
    setState(() => order.stage += 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(order.stage == 1
            ? "Sewa ${order.code} dimulai, stok berkurang"
            : "Sewa ${order.code} selesai, stok dikembalikan"),
        backgroundColor: kPrimaryDarkColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(getRelativeWidth(0.04)),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = _tab == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = index),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < _tabs.length - 1
                            ? getRelativeWidth(0.02)
                            : 0,
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: getRelativeHeight(0.012)),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimaryDarkColor : Colors.white,
                        borderRadius: BorderRadius.circular(30),
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
                          _tabs[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : kHardTextColor,
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
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      "Tidak ada pesanan",
                      style: TextStyle(
                        color: kLightTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: getRelativeWidth(0.045),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                        horizontal: getRelativeWidth(0.04)),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) => _card(_filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(_RentalOrder order) {
    return Container(
      margin: EdgeInsets.only(bottom: getRelativeHeight(0.016)),
      padding: EdgeInsets.all(getRelativeWidth(0.04)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                order.code,
                style: TextStyle(
                  color: kHardTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: getRelativeWidth(0.04),
                ),
              ),
              const Spacer(),
              Text(
                order.price,
                style: TextStyle(
                  color: kPrimaryDarkColor,
                  fontWeight: FontWeight.w900,
                  fontSize: getRelativeWidth(0.04),
                ),
              ),
            ],
          ),
          SizedBox(height: getRelativeHeight(0.006)),
          Text(
            order.renter,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: getRelativeWidth(0.04),
            ),
          ),
          SizedBox(height: getRelativeHeight(0.004)),
          Text(
            "${order.item} · ${order.duration}",
            style: TextStyle(
              color: Colors.blueGrey[400],
              fontSize: getRelativeWidth(0.032),
            ),
          ),
          if (order.stage < 2) ...[
            SizedBox(height: getRelativeHeight(0.014)),
            GestureDetector(
              onTap: () => _advance(order),
              child: Container(
                width: double.infinity,
                padding:
                    EdgeInsets.symmetric(vertical: getRelativeHeight(0.012)),
                decoration: BoxDecoration(
                  color: kPrimaryDarkColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    order.stage == 0 ? "Terima & Sewakan" : "Tandai Dikembalikan",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: getRelativeWidth(0.034),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RentalOrder {
  final String code, renter, item, duration, price;
  int stage; // 0 Baru, 1 Disewa, 2 Selesai
  _RentalOrder(
      this.code, this.renter, this.item, this.duration, this.price, this.stage);
}

class _Stat {
  final String value, label;
  final IconData icon;
  _Stat(this.value, this.label, this.icon);
}