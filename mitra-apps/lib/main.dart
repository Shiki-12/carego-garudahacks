import 'package:flutter/material.dart';
import 'package:mitra_app/core/service_locator.dart';
import 'package:mitra_app/presentation/role_selection_page.dart';
import 'package:mitra_app/size_confige.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CAREGO Mitra',
      // 401 di lapisan service memakai key ini untuk kembali ke root (doc 08 §2).
      navigatorKey: Services.I.navigatorKey,
      theme: ThemeData(
        fontFamily: "Nunito",
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Builder(builder: (context) {
        SizeConfig.initSize(context);
        // SRS-01: role selection ditampilkan SEBELUM auth.
        return const RoleSelectionPage();
      }),
    );
  }
}
