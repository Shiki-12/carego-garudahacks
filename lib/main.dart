import 'package:flutter/material.dart';
import 'package:doctor_app/constants.dart';
import 'package:doctor_app/model.dart/app_version_model.dart';
import 'package:doctor_app/presentation/doctor_app.dart';
import 'package:doctor_app/size_confige.dart';
import 'package:doctor_app/core/service_locator.dart';
import 'package:doctor_app/data/data.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CAREGO',
      theme: ThemeData(
        fontFamily: "Nunito",
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Builder(builder: (context) {
        SizeConfig.initSize(context);
        return const AppLaunchScreen();
      }),
    );
  }
}

class AppLaunchScreen extends StatefulWidget {
  const AppLaunchScreen({Key? key}) : super(key: key);

  @override
  State<AppLaunchScreen> createState() => _AppLaunchScreenState();
}

class _AppLaunchScreenState extends State<AppLaunchScreen> {
  static const String _currentVersion = '1.0.0';
  bool _showHome = false;

  @override
  void initState() {
    super.initState();
    Services.I.init(); // Initialize API services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppVersion();
    });
  }

  Future<void> _checkAppVersion() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    const version = AppVersionModel(
      latestVersion: '1.1.0',
      downloadUrl: 'https://carego.app/download',
      releaseNotes:
          'Versi terbaru CAREGO membawa fitur Chat dan penyewaan alat kesehatan.',
      forceUpdate: false,
    );

    if (_isNewerVersion(version.latestVersion, _currentVersion)) {
      _showUpdateDialog(version);
      return;
    }

    try {
      final caregivers = await Services.I.caregiver.getCaregivers();
      Data.caregiversList = caregivers;
      
      final equipments = await Services.I.rental.getEquipments();
      Data.equipmentList = equipments;

      // Note: Orders, Chat, Notifications, Wallet require auth token
      if (await Services.I.tokens.isLoggedIn) {
        final orders = await Services.I.order.getOrders();
        Data.ordersList = orders;
        
        final conversations = await Services.I.chat.getConversations();
        Data.conversationsList = conversations;

        final notifications = await Services.I.notification.getNotifications();
        Data.mockNotifications = notifications;

        final transactions = await Services.I.wallet.getTransactions();
        Data.mockTransactions = transactions;
      }
    } catch (e) {
      print('Failed to load dynamic data: $e');
    }

    setState(() => _showHome = true);
  }

  bool _isNewerVersion(String latestVersion, String currentVersion) {
    final latest = latestVersion.split('.').map(int.parse).toList();
    final current = currentVersion.split('.').map(int.parse).toList();
    final maxLength =
        latest.length > current.length ? latest.length : current.length;

    for (var i = 0; i < maxLength; i++) {
      final latestPart = i < latest.length ? latest[i] : 0;
      final currentPart = i < current.length ? current[i] : 0;
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }

    return false;
  }

  void _showUpdateDialog(AppVersionModel version) {
    showDialog(
      context: context,
      barrierDismissible: !version.forceUpdate,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pembaruan Tersedia'),
          content: Text(
            'Versi terbaru: ${version.latestVersion}\n\n${version.releaseNotes}',
          ),
          actions: [
            if (!version.forceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  setState(() => _showHome = true);
                },
                child: const Text('Nanti Saja'),
              ),
            ElevatedButton(
              onPressed: () {
                if (!version.forceUpdate) {
                  Navigator.of(dialogContext).pop();
                  setState(() => _showHome = true);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Membuka halaman update aplikasi...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0D9488),
              ),
              child: const Text(
                'Update Sekarang',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showHome) {
      return DoctorScreen();
    }

    return const Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xff0D9488),
        ),
      ),
    );
  }
}
