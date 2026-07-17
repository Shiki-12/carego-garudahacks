import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mitra_app/data/data.dart';

import '../constants.dart';
import '../size_confige.dart';

class DoctorsList extends StatelessWidget {
  const DoctorsList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: getRelativeHeight(0.35),
      child: ListView.builder(
        itemCount: Data.doctorsList.length,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.035)),
        itemBuilder: (context, index) {
          final doctor = Data.doctorsList[index];
          final color = kCategoriesSecondryColor[
              (kCategoriesSecondryColor.length - index - 1)];
          final circleColor = kCategoriesPrimaryColor[
              (kCategoriesPrimaryColor.length - index - 1)];
          final cardWidth = getRelativeWidth(0.48);
          return Row(
            children: [
              Container(
                width: cardWidth,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Stack(
                          children: [
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
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
                                                    .withValues(alpha: 0.6)),
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
                                                    .withValues(alpha: 0.25)),
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
                                                    .withValues(alpha: 0.17)),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                                width: cardWidth,
                                height: getRelativeHeight(0.19),
                                child: Image.asset(doctor.image)),
                          ],
                        ),
                        Container(
                          height: getRelativeHeight(0.14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(25),
                                  bottomRight: Radius.circular(25))),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: getRelativeHeight(0.01),
                                horizontal: getRelativeWidth((0.05))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: kHardTextColor,
                                      fontSize: getRelativeWidth(0.041)),
                                ),
                                SizedBox(height: getRelativeHeight(0.005)),
                                Text(
                                  doctor.speciality,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color:
                                          Colors.black.withValues(alpha: 0.8),
                                      fontSize: getRelativeWidth(0.032)),
                                ),
                                SizedBox(height: getRelativeHeight(0.005)),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      color: Colors.orange,
                                      size: getRelativeWidth(0.035),
                                    ),
                                    SizedBox(width: getRelativeWidth(0.01)),
                                    Expanded(
                                      child: Text(
                                        "2 Jam yang lalu",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.black
                                                .withValues(alpha: 0.8),
                                            fontSize: getRelativeWidth(0.025)),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(top: getRelativeHeight(0.04))
                              .copyWith(left: cardWidth * 0.7),
                          child: Container(
                            decoration: BoxDecoration(boxShadow: [
                              BoxShadow(
                                blurRadius: 10,
                                offset: Offset(0, 3),
                                color: Colors.black26,
                              )
                            ], color: Colors.white, shape: BoxShape.circle),
                            padding: EdgeInsets.all(getRelativeWidth(0.015)),
                            child: FaIcon(
                              FontAwesomeIcons.facebookMessenger,
                              color: color,
                              size: getRelativeWidth(0.055),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(width: getRelativeWidth(0.04))
            ],
          );
        },
      ),
    );
  }
}
