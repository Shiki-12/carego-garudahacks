import 'package:flutter/material.dart';

import '../constants.dart';
import '../size_confige.dart';

class ComingSoonPage extends StatelessWidget {
  final String title;

  const ComingSoonPage({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(getRelativeWidth(0.06)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kPrimarylightColor, kPrimaryDarkColor],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                    color: kPrimaryDarkColor.withValues(alpha: 0.3),
                  ),
                ],
              ),
              child: Icon(
                Icons.construction_rounded,
                color: Colors.white,
                size: getRelativeWidth(0.12),
              ),
            ),
            SizedBox(height: getRelativeHeight(0.03)),
            Text(
              "Segera Hadir",
              style: TextStyle(
                color: kHardTextColor,
                fontWeight: FontWeight.w800,
                fontSize: getRelativeWidth(0.065),
              ),
            ),
            SizedBox(height: getRelativeHeight(0.012)),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: getRelativeWidth(0.12)),
              child: Text(
                "Fitur $title sedang dalam pengembangan.\nNantikan pembaruan selanjutnya!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontWeight: FontWeight.w600,
                  fontSize: getRelativeWidth(0.035),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
