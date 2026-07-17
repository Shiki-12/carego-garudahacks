import 'package:flutter/material.dart';

import '../constants.dart';
import '../size_confige.dart';

class DoctorAppBar extends StatelessWidget {
  const DoctorAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 7),
            color: Colors.black.withValues(alpha: 0.11),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          getRelativeWidth(0.04),
          topPadding + getRelativeHeight(0.018),
          getRelativeWidth(0.04),
          getRelativeHeight(0.018),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hi, Mitra",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: getRelativeWidth(0.08)),
                  ),
                  SizedBox(height: getRelativeHeight(0.003)),
                  Text(
                    "Pusat Manajemen Layanan Anda",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.blueGrey[400],
                        fontSize: getRelativeWidth(0.034)),
                  ),
                ],
              ),
            ),
            SizedBox(width: getRelativeWidth(0.03)),
            Container(
              height: getRelativeHeight(0.064),
              width: getRelativeHeight(0.064),
              padding: EdgeInsets.all(getRelativeWidth(0.008)),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: kPrimaryDarkColor.withValues(alpha: 0.18),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    color: Colors.black.withValues(alpha: 0.16),
                  )
                ],
              ),
              child: ClipOval(child: Image.asset("assets/images/person.png")),
            )
          ],
        ),
      ),
    );
  }
}
