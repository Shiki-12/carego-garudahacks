import 'package:flutter/material.dart';

import '../constants.dart';
import '../size_confige.dart';

/// SRS-10 (US-RN-001, FR-RN-01/02): Pemilihan alat dari KATALOG BAKU CAREGO.
/// Mitra memilih item, lalu mengisi stok/harga (bukan mengetik nama bebas).
class CatalogPickerPage extends StatelessWidget {
  const CatalogPickerPage({Key? key}) : super(key: key);

  // Katalog baku (seed) — lihat SRS-10 §5.1.
  static const _catalog = [
    _CatalogItem("Kursi Roda Standar", "Mobilitas", Icons.accessible),
    _CatalogItem("Ranjang Medis Elektrik", "Perawatan", Icons.bed),
    _CatalogItem("Tabung Oksigen", "Pernapasan", Icons.air),
    _CatalogItem("Nebulizer", "Pernapasan", Icons.healing),
    _CatalogItem("Tongkat / Kruk", "Mobilitas", Icons.elderly),
    _CatalogItem("Alat Bantu Jalan", "Mobilitas", Icons.directions_walk),
    _CatalogItem("Tensimeter Digital", "Monitoring", Icons.monitor_heart),
    _CatalogItem("Kursi Toilet", "Perawatan", Icons.chair),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: const Text(
          "Pilih dari Katalog",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              getRelativeWidth(0.05),
              getRelativeHeight(0.015),
              getRelativeWidth(0.05),
              getRelativeHeight(0.005),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Pilih jenis alat yang ingin Anda sewakan",
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: getRelativeWidth(0.034),
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(getRelativeWidth(0.04)),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: getRelativeHeight(0.016),
                crossAxisSpacing: getRelativeWidth(0.04),
                childAspectRatio: 0.95,
              ),
              itemCount: _catalog.length,
              itemBuilder: (context, index) {
                final item = _catalog[index];
                return GestureDetector(
                  onTap: () => _openAddForm(context, item),
                  child: Container(
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: getRelativeWidth(0.16),
                          height: getRelativeWidth(0.16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                kCategoriesPrimaryColor[
                                    index % kCategoriesPrimaryColor.length],
                                kCategoriesSecondryColor[
                                    index % kCategoriesSecondryColor.length],
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon,
                              color: Colors.white,
                              size: getRelativeWidth(0.08)),
                        ),
                        SizedBox(height: getRelativeHeight(0.012)),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: kHardTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: getRelativeWidth(0.034),
                          ),
                        ),
                        SizedBox(height: getRelativeHeight(0.003)),
                        Text(
                          item.category,
                          style: TextStyle(
                            color: Colors.blueGrey[400],
                            fontSize: getRelativeWidth(0.028),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openAddForm(BuildContext context, _CatalogItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(item: item),
    );
  }
}

/// Form isi stok & harga setelah memilih item katalog (US-RN-001).
class _AddItemSheet extends StatelessWidget {
  final _CatalogItem item;

  const _AddItemSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final border = OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(16),
    );
    InputDecoration deco(String hint) => InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: getRelativeWidth(0.04),
            vertical: getRelativeHeight(0.016),
          ),
          filled: true,
          fillColor: kBackgroundColor,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.blueGrey.withValues(alpha: 0.9),
            fontSize: getRelativeWidth(0.034),
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: EdgeInsets.all(getRelativeWidth(0.05)),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: getRelativeWidth(0.12),
                height: getRelativeHeight(0.006),
                decoration: BoxDecoration(
                  color: kLightTextColor,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            SizedBox(height: getRelativeHeight(0.02)),
            Row(
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
                  child: Icon(item.icon,
                      color: Colors.white, size: getRelativeWidth(0.06)),
                ),
                SizedBox(width: getRelativeWidth(0.035)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: kHardTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: getRelativeWidth(0.045),
                        ),
                      ),
                      Text(
                        item.category,
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
            SizedBox(height: getRelativeHeight(0.024)),
            _label("Stok Tersedia"),
            TextField(
                keyboardType: TextInputType.number, decoration: deco("Mis. 3")),
            SizedBox(height: getRelativeHeight(0.016)),
            _label("Harga Sewa Harian"),
            TextField(
                keyboardType: TextInputType.number,
                decoration: deco("Rp / hari")),
            SizedBox(height: getRelativeHeight(0.016)),
            _label("Harga Sewa Mingguan"),
            TextField(
                keyboardType: TextInputType.number,
                decoration: deco("Rp / minggu")),
            SizedBox(height: getRelativeHeight(0.028)),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${item.name} ditambahkan ke katalog Anda"),
                    backgroundColor: kPrimaryDarkColor,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding:
                    EdgeInsets.symmetric(vertical: getRelativeHeight(0.018)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [kPrimarylightColor, kPrimaryDarkColor],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    "Simpan ke Katalog",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: getRelativeWidth(0.042),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: getRelativeHeight(0.01)),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: EdgeInsets.only(bottom: getRelativeHeight(0.006)),
        child: Text(
          text,
          style: TextStyle(
            color: kHardTextColor,
            fontWeight: FontWeight.w800,
            fontSize: getRelativeWidth(0.034),
          ),
        ),
      );
}

class _CatalogItem {
  final String name, category;
  final IconData icon;
  const _CatalogItem(this.name, this.category, this.icon);
}