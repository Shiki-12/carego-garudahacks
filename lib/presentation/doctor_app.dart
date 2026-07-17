import 'package:flutter/material.dart';
import 'package:doctor_app/constants.dart';
import 'package:doctor_app/presentation/account_screen.dart';
import 'package:doctor_app/presentation/banner.dart';
import 'package:doctor_app/presentation/bottom_navigation_bar.dart';
import 'package:doctor_app/presentation/chat_screen.dart';
import 'package:doctor_app/presentation/doctors_list.dart';
import 'package:doctor_app/presentation/notifications_screen.dart';
import 'package:doctor_app/presentation/orders_screen.dart';
import 'package:doctor_app/presentation/wallet_section.dart';
import 'package:doctor_app/size_confige.dart';
import 'appbar.dart';
import 'categories_list.dart';

class DoctorScreen extends StatefulWidget {
  @override
  _DoctorScreenState createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  int _selectedIndex = 0;

  Widget _buildHomeContent(double headerHeight) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: headerHeight - getRelativeHeight(0.0001),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    DoctorBanner(),
                    Positioned(
                      bottom: -getRelativeHeight(0.075),
                      child: WalletSection(),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: DoctorAppBar(),
              ),
            ],
          ),
          SizedBox(height: getRelativeHeight(0.12)),
          CategoriesList(),
          SizedBox(height: getRelativeHeight(0.015)),
          DoctorsList(),
          SizedBox(height: getRelativeHeight(0.02)),
        ],
      ),
    );
  }

  Widget _buildSelectedContent(double headerHeight) {
    if (_selectedIndex == 1) {
      return const OrdersScreen(showScaffold: false);
    }
    if (_selectedIndex == 2) {
      return const ChatScreen(showScaffold: false);
    }
    if (_selectedIndex == 3) {
      return const AccountScreen(showScaffold: false);
    }

    return _buildHomeContent(headerHeight);
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight =
        MediaQuery.of(context).padding.top + getRelativeHeight(0.092);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        top: false,
        child: _buildSelectedContent(headerHeight),
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemPressed: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        centerIcon: Icons.place,
        itemIcons: [
          Icons.home,
          Icons.receipt_long,
          Icons.message,
          Icons.account_box,
        ],
      ),
    );
  }
}
