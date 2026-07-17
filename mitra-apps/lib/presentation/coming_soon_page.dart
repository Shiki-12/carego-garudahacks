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
        child: Text(
          "Segera hadir",
          style: TextStyle(
            color: kHardTextColor,
            fontWeight: FontWeight.w800,
            fontSize: getRelativeWidth(0.07),
          ),
        ),
      ),
    );
  }
}
