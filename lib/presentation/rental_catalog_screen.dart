import 'package:flutter/material.dart';

import '../constants.dart';
import '../data/data.dart';
import '../model.dart/equipment.dart';
import 'rental_detail_screen.dart';

class RentalCatalogScreen extends StatefulWidget {
  const RentalCatalogScreen({Key? key}) : super(key: key);

  @override
  State<RentalCatalogScreen> createState() => _RentalCatalogScreenState();
}

class _RentalCatalogScreenState extends State<RentalCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'all';

  final List<_RentalCategory> _categories = const [
    _RentalCategory('all', 'Semua'),
    _RentalCategory('bed', 'Tempat Tidur'),
    _RentalCategory('wheelchair', 'Kursi Roda'),
    _RentalCategory('oxygen', 'Oksigen'),
    _RentalCategory('monitor', 'Monitor'),
    _RentalCategory('other', 'Lainnya'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Equipment> get _filteredEquipment {
    final query = _query.trim().toLowerCase();
    return Data.equipmentList.where((equipment) {
      final matchesCategory =
          _selectedCategory == 'all' || equipment.category == _selectedCategory;
      final matchesSearch =
          query.isEmpty || equipment.name.toLowerCase().contains(query);
      return equipment.isAvailable && matchesCategory && matchesSearch;
    }).toList();
  }

  String _formatRupiah(int amount) {
    final text = amount.toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = text.length - 1; i >= 0; i--) {
      buffer.write(text[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    final equipment = _filteredEquipment;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: const Text(
          'Sewa Alat Kesehatan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Cari alat kesehatan',
                hintStyle: TextStyle(color: Colors.blueGrey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.blueGrey[400]),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        icon: Icon(Icons.close, color: Colors.blueGrey[400]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category.value;
                return ChoiceChip(
                  label: Text(category.label),
                  selected: isSelected,
                  selectedColor:
                      const Color(0xff0D9488).withValues(alpha: 0.16),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? const Color(0xff0D9488) : kHardTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xff0D9488)
                        : Colors.grey.withValues(alpha: 0.18),
                  ),
                  onSelected: (_) {
                    setState(() => _selectedCategory = category.value);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: equipment.isEmpty
                ? const _RentalEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: equipment.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final item = equipment[index];
                      return _EquipmentCard(
                        equipment: item,
                        dailyRateLabel: '${_formatRupiah(item.dailyRate)}/hari',
                        onTap: item.stock == 0
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RentalDetailScreen(
                                      equipment: item,
                                    ),
                                  ),
                                );
                              },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RentalCategory {
  final String value;
  final String label;

  const _RentalCategory(this.value, this.label);
}

class _EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final String dailyRateLabel;
  final VoidCallback? onTap;

  const _EquipmentCard({
    required this.equipment,
    required this.dailyRateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = equipment.stock == 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 3),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: kPrimarylightColor.withValues(alpha: 0.14),
                      child: Opacity(
                        opacity: outOfStock ? 0.48 : 1,
                        child: Image.asset(
                          equipment.images.first,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  if (outOfStock)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Stok Habis',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kHardTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dailyRateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: outOfStock
                          ? Colors.blueGrey[300]
                          : const Color(0xff0D9488),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    outOfStock ? 'Tidak tersedia' : 'Stok ${equipment.stock}',
                    style: TextStyle(
                      color:
                          outOfStock ? Colors.red[600] : Colors.blueGrey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RentalEmptyState extends StatelessWidget {
  const _RentalEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: Colors.blueGrey[300],
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'Alat kesehatan tidak ditemukan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kHardTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
