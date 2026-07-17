import 'package:flutter/material.dart';

import '../constants.dart';
import '../size_confige.dart';

/// Header shell mitra yang bisa menyesuaikan judul & subjudul per peran.
/// Menyalin gaya `DoctorAppBar` template (kartu putih rounded + avatar).
class MitraHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const MitraHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    this.trailing,
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
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: getRelativeWidth(0.065)),
                  ),
                  SizedBox(height: getRelativeHeight(0.003)),
                  Text(
                    subtitle,
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
            trailing ??
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
                  child: ClipOval(
                    child: Image.asset("assets/images/person.png"),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Chip status ketersediaan (Aktif/Standby/Libur) untuk header shell.
class AvailabilityChip extends StatelessWidget {
  final bool isActive;
  final String activeLabel;
  final String inactiveLabel;

  const AvailabilityChip({
    Key? key,
    required this.isActive,
    this.activeLabel = "Aktif",
    this.inactiveLabel = "Nonaktif",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? kPrimaryDarkColor : kLightTextColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getRelativeWidth(0.03),
        vertical: getRelativeHeight(0.006),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: getRelativeWidth(0.02),
            height: getRelativeWidth(0.02),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: getRelativeWidth(0.015)),
          Text(
            isActive ? activeLabel : inactiveLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: getRelativeWidth(0.03),
            ),
          ),
        ],
      ),
    );
  }
}