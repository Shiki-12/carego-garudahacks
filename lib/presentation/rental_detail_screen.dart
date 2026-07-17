import 'package:flutter/material.dart';

import '../constants.dart';
import '../model.dart/chat_model.dart';
import '../model.dart/equipment.dart';
import 'chat_room_screen.dart';
import 'rental_booking_screen.dart';

class RentalDetailScreen extends StatefulWidget {
  final Equipment equipment;

  const RentalDetailScreen({
    Key? key,
    required this.equipment,
  }) : super(key: key);

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  final PageController _pageController = PageController();
  int _selectedImage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _openRentalChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversation: Conversation(
            id: 7000 + widget.equipment.id,
            participantName: 'Admin Rental',
            participantRole: 'Penyedia Sewa Alkes',
            participantPhotoUrl: 'assets/images/doctor_3.png',
            lastMessage:
                'Halo, saya ingin bertanya tentang ${widget.equipment.name}.',
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final equipment = widget.equipment;
    final isInStock = equipment.stock > 0;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: const Text(
          'Detail Alat',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          color: Colors.black.withValues(alpha: 0.07),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: equipment.images.length,
                            onPageChanged: (index) {
                              setState(() => _selectedImage = index);
                            },
                            itemBuilder: (context, index) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: kPrimarylightColor.withValues(
                                      alpha: 0.14),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(22),
                                  ),
                                ),
                                child: Image.asset(
                                  equipment.images[index],
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          ),
                        ),
                        if (equipment.images.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  List.generate(equipment.images.length, (i) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: _selectedImage == i ? 18 : 8,
                                  height: 8,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: _selectedImage == i
                                        ? const Color(0xff0D9488)
                                        : Colors.blueGrey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              }),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                equipment.name,
                                style: const TextStyle(
                                  color: kHardTextColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    isInStock
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: isInStock
                                        ? const Color(0xff10B981)
                                        : Colors.red[600],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isInStock
                                        ? 'Stok tersedia: ${equipment.stock}'
                                        : 'Stok habis',
                                    style: TextStyle(
                                      color: isInStock
                                          ? const Color(0xff10B981)
                                          : Colors.red[600],
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                equipment.description,
                                style: TextStyle(
                                  color: Colors.blueGrey[600],
                                  height: 1.45,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Spesifikasi',
                    child: Column(
                      children: equipment.specifications.entries.map((entry) {
                        return _InfoRow(entry.key, entry.value);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Rincian Tarif',
                    child: Column(
                      children: [
                        _InfoRow('Tarif Harian',
                            '${_formatRupiah(equipment.dailyRate)}/hari'),
                        _InfoRow('Tarif Mingguan',
                            '${_formatRupiah(equipment.weeklyRate)}/minggu'),
                        _InfoRow('Deposit', _formatRupiah(equipment.deposit)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _openRentalChat,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff0D9488),
                          side: const BorderSide(color: Color(0xff0D9488)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Icon(Icons.chat_bubble_outline),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isInStock
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RentalBookingScreen(
                                      equipment: equipment,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0D9488),
                          disabledBackgroundColor: Colors.blueGrey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          isInStock ? 'Sewa Sekarang' : 'Stok Habis',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kHardTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey[500],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: kHardTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
