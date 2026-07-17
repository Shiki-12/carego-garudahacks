import 'package:flutter/material.dart';

import '../constants.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'question': 'Bagaimana cara memesan ambulans?',
        'answer':
            'Buka layanan Ambulans, pilih jenis ambulans, tentukan lokasi penjemputan dan tujuan, lalu konfirmasi pesanan.',
      },
      {
        'question': 'Metode pembayaran apa saja yang didukung?',
        'answer':
            'Untuk MVP, pembayaran menggunakan Carego Wallet secara simulasi. Integrasi pembayaran nyata akan ditambahkan berikutnya.',
      },
      {
        'question': 'Apakah saya bisa membatalkan pesanan?',
        'answer':
            'Pesanan dengan status menunggu atau dikonfirmasi dapat dibatalkan dari halaman Detail Pesanan.',
      },
      {
        'question': 'Bagaimana cara menghubungi penyedia layanan?',
        'answer':
            'Gunakan tombol chat pada detail pesanan, profil caregiver, atau detail alat kesehatan.',
      },
    ];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: const Text(
          'Pusat Bantuan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: faqs.map((faq) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              title: Text(
                faq['question']!,
                style: const TextStyle(
                  color: kHardTextColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  faq['answer']!,
                  style: TextStyle(
                    color: Colors.blueGrey[600],
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
