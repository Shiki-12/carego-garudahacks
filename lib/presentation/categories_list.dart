import 'package:flutter/material.dart';
import 'package:doctor_app/data/data.dart';

import '../constants.dart';
import '../size_confige.dart';
import 'ambulance_screen.dart';
import 'coming_soon_page.dart';

class CategoriesList extends StatelessWidget {
  const CategoriesList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.045)),
          child: Text(
            "Layanan Kami",
            style: TextStyle(
              color: kHardTextColor,
              fontWeight: FontWeight.w800,
              fontSize: getRelativeWidth(0.045),
            ),
          ),
        ),
        SizedBox(height: getRelativeHeight(0.015)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.035)),
          child: Row(
            children: List.generate(Data.categoriesList.length, (index) {
              final category = Data.categoriesList[index];

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    final Widget target;
                    if (category.title == 'Ambulans') {
                      target = const AmbulanceScreen();
                    } else {
                      target = ComingSoonPage(title: category.title);
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => target),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: getRelativeWidth(0.17),
                        height: getRelativeWidth(0.17),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              kCategoriesPrimaryColor[index],
                              kCategoriesSecondryColor[index],
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                              color: kCategoriesSecondryColor[index]
                                  .withValues(alpha: 0.24),
                            ),
                          ],
                        ),
                        child: Icon(
                          category.icon,
                          color: Colors.white,
                          size: getRelativeWidth(0.075),
                        ),
                      ),
                      SizedBox(height: getRelativeHeight(0.01)),
                      Text(
                        category.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kHardTextColor,
                          fontSize: getRelativeWidth(0.034),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: getRelativeHeight(0.003)),
                      Text(
                        category.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blueGrey[400],
                          fontSize: getRelativeWidth(0.026),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
