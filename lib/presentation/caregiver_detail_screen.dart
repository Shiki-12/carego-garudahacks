import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../constants.dart';
import '../model.dart/chat_model.dart';
import '../model.dart/caregiver.dart';
import 'caregiver_booking_screen.dart';
import 'chat_room_screen.dart';

class CaregiverDetailScreen extends StatelessWidget {
  final Caregiver caregiver;

  const CaregiverDetailScreen({
    Key? key,
    required this.caregiver,
  }) : super(key: key);

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

  void _openCaregiverChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversation: Conversation(
            id: 8000 + caregiver.id,
            participantName: caregiver.name,
            participantRole: 'Caregiver',
            participantPhotoUrl: caregiver.photoUrl,
            lastMessage: 'Halo, saya ingin bertanya tentang layanan caregiver.',
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: const Text(
          'Profil Caregiver',
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
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                          child: Container(
                            width: double.infinity,
                            height: 260,
                            color: kPrimarylightColor.withValues(alpha: 0.16),
                            child: Image.asset(
                              caregiver.photoUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              Text(
                                caregiver.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: kHardTextColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                caregiver.specialization,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blueGrey[500],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  RatingBarIndicator(
                                    rating: caregiver.rating,
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.orange,
                                    ),
                                    itemCount: 5,
                                    itemSize: 18,
                                    unratedColor:
                                        Colors.grey.withValues(alpha: 0.35),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${caregiver.rating.toStringAsFixed(1)} (${caregiver.reviews} ulasan)',
                                    style: TextStyle(
                                      color: Colors.blueGrey[500],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Tentang',
                    child: Text(
                      caregiver.bio,
                      style: TextStyle(
                        color: Colors.blueGrey[600],
                        height: 1.45,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Pengalaman',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: Color(0xff0D9488),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${caregiver.experienceYears} tahun pengalaman sebagai caregiver ${caregiver.specialization.toLowerCase()}.',
                            style: TextStyle(
                              color: Colors.blueGrey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Tarif',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Biaya per jam',
                          style: TextStyle(
                            color: Colors.blueGrey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_formatRupiah(caregiver.hourlyRate)}/jam',
                          style: const TextStyle(
                            color: Color(0xff0D9488),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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
                        onPressed: () => _openCaregiverChat(context),
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
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CaregiverBookingScreen(
                                caregiver: caregiver,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0D9488),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Pesan Sekarang',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
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
