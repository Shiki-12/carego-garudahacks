import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:doctor_app/data/data.dart';

import '../constants.dart';
import '../size_confige.dart';

class DoctorsList extends StatelessWidget {
  const DoctorsList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.045)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Mitra Terdekat",
                  style: TextStyle(
                    color: kHardTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: getRelativeWidth(0.045),
                  ),
                ),
              ),
              SizedBox(width: getRelativeWidth(0.02)),
              Text(
                "Lihat Semua",
                style: TextStyle(
                  color: kPrimaryDarkColor,
                  fontWeight: FontWeight.w700,
                  fontSize: getRelativeWidth(0.032),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: getRelativeHeight(0.015)),
        // Partner cards list
        SizedBox(
          height: getRelativeHeight(0.38),
          child: ListView.builder(
            itemCount: Data.partnersList.length,
            scrollDirection: Axis.horizontal,
            padding:
                EdgeInsets.symmetric(horizontal: getRelativeWidth(0.035)),
            itemBuilder: (context, index) {
              final partner = Data.partnersList[index];
              final color = kCategoriesSecondryColor[
                  index % kCategoriesSecondryColor.length];
              final circleColor = kCategoriesPrimaryColor[
                  index % kCategoriesPrimaryColor.length];
              final cardWidth = getRelativeWidth(0.48);

              return Row(
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            // Image section with colored background
                            Stack(
                              children: [
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(25),
                                          topRight: Radius.circular(25),
                                        ),
                                        color: color,
                                      ),
                                      height: getRelativeHeight(0.14),
                                      child: Stack(
                                        children: [
                                          Align(
                                            alignment: Alignment.topCenter,
                                            child: Container(
                                              width: getRelativeHeight(0.13),
                                              height: getRelativeHeight(0.13),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  width: 15,
                                                  color: circleColor
                                                      .withValues(alpha: 0.6),
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.topLeft,
                                            child: Container(
                                              width: getRelativeHeight(0.11),
                                              height: getRelativeHeight(0.11),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  width: 15,
                                                  color: circleColor
                                                      .withValues(alpha: 0.25),
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: Container(
                                              width: getRelativeHeight(0.11),
                                              height: getRelativeHeight(0.11),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  width: 15,
                                                  color: circleColor
                                                      .withValues(alpha: 0.17),
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  height: getRelativeHeight(0.19),
                                  child: Image.asset(partner.image),
                                ),
                                // Distance badge
                                Positioned(
                                  top: getRelativeHeight(0.008),
                                  right: getRelativeWidth(0.02),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: getRelativeWidth(0.02),
                                      vertical: getRelativeHeight(0.004),
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.92),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.near_me,
                                          color: kPrimaryDarkColor,
                                          size: getRelativeWidth(0.03),
                                        ),
                                        SizedBox(
                                            width: getRelativeWidth(0.008)),
                                        Text(
                                          partner.distance,
                                          style: TextStyle(
                                            color: kHardTextColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize:
                                                getRelativeWidth(0.025),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Info section
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(25),
                                  bottomRight: Radius.circular(25),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: getRelativeHeight(0.012),
                                  horizontal: getRelativeWidth(0.04),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Partner name
                                    Text(
                                      partner.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: kHardTextColor,
                                        fontSize: getRelativeWidth(0.038),
                                      ),
                                    ),
                                    SizedBox(height: getRelativeHeight(0.004)),
                                    // Availability (AC-HOME-11)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: const Color(0xff10B981),
                                          size: getRelativeWidth(0.032),
                                        ),
                                        SizedBox(
                                            width: getRelativeWidth(0.008)),
                                        Expanded(
                                          child: Text(
                                            partner.availability,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: const Color(0xff10B981),
                                              fontWeight: FontWeight.w700,
                                              fontSize:
                                                  getRelativeWidth(0.028),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: getRelativeHeight(0.004)),
                                    // Location (FR-HOME-17)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.place,
                                          color: Colors.blueGrey[400],
                                          size: getRelativeWidth(0.032),
                                        ),
                                        SizedBox(
                                            width: getRelativeWidth(0.008)),
                                        Expanded(
                                          child: Text(
                                            partner.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.blueGrey[400],
                                              fontSize:
                                                  getRelativeWidth(0.026),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: getRelativeHeight(0.005)),
                                    // Rating + reviews
                                    Row(
                                      children: [
                                        RatingBar.builder(
                                          unratedColor: Colors.grey
                                              .withValues(alpha: 0.5),
                                          itemSize: getRelativeWidth(0.026),
                                          initialRating:
                                              partner.reviewScore.toDouble(),
                                          minRating: 0,
                                          allowHalfRating: true,
                                          direction: Axis.horizontal,
                                          itemPadding: EdgeInsets.symmetric(
                                            horizontal:
                                                getRelativeWidth(0.001),
                                          ),
                                          itemCount: 5,
                                          updateOnDrag: false,
                                          ignoreGestures: true,
                                          itemBuilder: (context, _) =>
                                              const Icon(
                                            Icons.star,
                                            color: Colors.orange,
                                          ),
                                          onRatingUpdate: (value) {},
                                        ),
                                        SizedBox(
                                            width: getRelativeWidth(0.01)),
                                        Expanded(
                                          child: Text(
                                            "${partner.rating} (${partner.reviews} ulasan)",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.black
                                                  .withValues(alpha: 0.6),
                                              fontSize:
                                                  getRelativeWidth(0.022),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Contact / action icon
                        Positioned(
                          top: getRelativeHeight(0.16),
                          right: getRelativeWidth(0.02),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                  color: Colors.black26,
                                ),
                              ],
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding:
                                EdgeInsets.all(getRelativeWidth(0.015)),
                            child: Icon(
                              Icons.phone,
                              color: color,
                              size: getRelativeWidth(0.055),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: getRelativeWidth(0.04)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
