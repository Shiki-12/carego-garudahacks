import 'package:flutter/material.dart';

import '../constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimarylightColor, kPrimaryDarkColor],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'CAREGO',
                style: TextStyle(
                  color: kHardTextColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'v1.0.0',
                style: TextStyle(
                  color: Colors.blueGrey[500],
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'CAREGO membantu pengguna menemukan layanan kesehatan rumah, ambulans, caregiver, dan sewa alat kesehatan dalam satu aplikasi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey[600],
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
