import 'package:flutter/material.dart';

import '../constants.dart';
import '../size_confige.dart';
import 'chat_page.dart';

/// SRS-06 (US-MNC-001): Daftar notifikasi pesanan/aktivitas mitra.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  static final _notifications = [
    _MitraNotification(
      title: "Pesanan Baru #1021",
      body: "Budi Santoso memesan layanan Caregiver 8 jam",
      time: "5 menit lalu",
      icon: Icons.assignment,
      unread: true,
    ),
    _MitraNotification(
      title: "Pesanan Baru #1020",
      body: "Siti Aminah memesan layanan Caregiver 4 jam",
      time: "1 jam lalu",
      icon: Icons.assignment,
      unread: true,
    ),
    _MitraNotification(
      title: "Pembayaran Diterima",
      body: "Rp600.000 dari pesanan #1015 masuk ke saldo Anda",
      time: "Kemarin",
      icon: Icons.account_balance_wallet,
      unread: false,
    ),
    _MitraNotification(
      title: "Akun Terverifikasi",
      body: "Selamat! Akun mitra Anda telah disetujui admin",
      time: "2 hari lalu",
      icon: Icons.verified,
      unread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: const Text(
          "Notifikasi",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(getRelativeWidth(0.04)),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          return Container(
            margin: EdgeInsets.only(bottom: getRelativeHeight(0.014)),
            padding: EdgeInsets.all(getRelativeWidth(0.04)),
            decoration: BoxDecoration(
              color: notif.unread
                  ? kPrimaryDarkColor.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: notif.unread
                  ? Border.all(
                      color: kPrimaryDarkColor.withValues(alpha: 0.25))
                  : null,
              boxShadow: [
                BoxShadow(
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(getRelativeWidth(0.025)),
                  decoration: BoxDecoration(
                    color: kPrimaryDarkColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notif.icon,
                    color: kPrimaryDarkColor,
                    size: getRelativeWidth(0.05),
                  ),
                ),
                SizedBox(width: getRelativeWidth(0.03)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.title,
                        style: TextStyle(
                          color: kHardTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: getRelativeWidth(0.037),
                        ),
                      ),
                      SizedBox(height: getRelativeHeight(0.003)),
                      Text(
                        notif.body,
                        style: TextStyle(
                          color: Colors.blueGrey[400],
                          fontSize: getRelativeWidth(0.031),
                        ),
                      ),
                      SizedBox(height: getRelativeHeight(0.005)),
                      Text(
                        notif.time,
                        style: TextStyle(
                          color: kLightTextColor,
                          fontSize: getRelativeWidth(0.027),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notif.unread)
                  Container(
                    width: getRelativeWidth(0.02),
                    height: getRelativeWidth(0.02),
                    decoration: const BoxDecoration(
                      color: kPrimaryDarkColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MitraNotification {
  final String title, body, time;
  final IconData icon;
  final bool unread;

  _MitraNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.unread,
  });
}

/// SRS-06 (US-MNC-002): Daftar percakapan dengan pasien untuk order aktif.
class ChatListPage extends StatelessWidget {
  const ChatListPage({Key? key}) : super(key: key);

  static final _conversations = [
    _Conversation(
      name: "Andi Wijaya",
      orderCode: "#1019",
      lastMessage: "Baik pak, saya sudah di lobi RS ya",
      time: "10:24",
      unreadCount: 0,
    ),
    _Conversation(
      name: "Budi Santoso",
      orderCode: "#1021",
      lastMessage: "Apakah bisa datang jam 8 pagi?",
      time: "09:12",
      unreadCount: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: const Text(
          "Pesan",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(getRelativeWidth(0.04)),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final convo = _conversations[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    name: convo.name,
                    orderCode: convo.orderCode,
                  ),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: getRelativeHeight(0.014)),
              padding: EdgeInsets.all(getRelativeWidth(0.04)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: getRelativeWidth(0.06),
                    backgroundColor:
                        kPrimaryDarkColor.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.person,
                      color: kPrimaryDarkColor,
                      size: getRelativeWidth(0.06),
                    ),
                  ),
                  SizedBox(width: getRelativeWidth(0.03)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${convo.name} · ${convo.orderCode}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: kHardTextColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: getRelativeWidth(0.037),
                                ),
                              ),
                            ),
                            Text(
                              convo.time,
                              style: TextStyle(
                                color: kLightTextColor,
                                fontSize: getRelativeWidth(0.027),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: getRelativeHeight(0.004)),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                convo.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.blueGrey[400],
                                  fontSize: getRelativeWidth(0.031),
                                ),
                              ),
                            ),
                            if (convo.unreadCount > 0)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: getRelativeWidth(0.02),
                                  vertical: getRelativeHeight(0.002),
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimaryDarkColor,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  "${convo.unreadCount}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: getRelativeWidth(0.026),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Conversation {
  final String name, orderCode, lastMessage, time;
  final int unreadCount;

  _Conversation({
    required this.name,
    required this.orderCode,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
  });
}