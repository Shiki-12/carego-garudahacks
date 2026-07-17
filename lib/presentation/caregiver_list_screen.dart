import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../constants.dart';
import '../data/data.dart';
import '../model.dart/caregiver.dart';
import 'caregiver_detail_screen.dart';

class CaregiverListScreen extends StatefulWidget {
  const CaregiverListScreen({Key? key}) : super(key: key);

  @override
  State<CaregiverListScreen> createState() => _CaregiverListScreenState();
}

class _CaregiverListScreenState extends State<CaregiverListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Caregiver> get _filteredCaregivers {
    final query = _query.trim().toLowerCase();
    return Data.caregiversList.where((caregiver) {
      final matchesName =
          query.isEmpty || caregiver.name.toLowerCase().contains(query);
      return caregiver.isAvailable && matchesName;
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
    final caregivers = _filteredCaregivers;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: const Text(
          'Caregiver',
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
                hintText: 'Cari nama caregiver',
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
          Expanded(
            child: caregivers.isEmpty
                ? const _CaregiverEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: caregivers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final caregiver = caregivers[index];
                      return _CaregiverCard(
                        caregiver: caregiver,
                        hourlyRateLabel:
                            '${_formatRupiah(caregiver.hourlyRate)}/jam',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CaregiverDetailScreen(
                                caregiver: caregiver,
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

class _CaregiverCard extends StatelessWidget {
  final Caregiver caregiver;
  final String hourlyRateLabel;
  final VoidCallback onTap;

  const _CaregiverCard({
    required this.caregiver,
    required this.hourlyRateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 86,
                height: 100,
                color: kPrimarylightColor.withValues(alpha: 0.16),
                child: Image.asset(
                  caregiver.photoUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caregiver.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kHardTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caregiver.specialization,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blueGrey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.work_history,
                        color: kPrimaryDarkColor,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${caregiver.experienceYears} tahun pengalaman',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.blueGrey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: caregiver.rating,
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.orange,
                        ),
                        itemCount: 5,
                        itemSize: 14,
                        unratedColor: Colors.grey.withValues(alpha: 0.35),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${caregiver.rating.toStringAsFixed(1)} (${caregiver.reviews})',
                        style: TextStyle(
                          color: Colors.blueGrey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hourlyRateLabel,
                    style: const TextStyle(
                      color: Color(0xff0D9488),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: kPrimaryDarkColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _CaregiverEmptyState extends StatelessWidget {
  const _CaregiverEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search,
              color: Colors.blueGrey[300],
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'Caregiver tidak ditemukan',
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
