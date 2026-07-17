import 'package:flutter/material.dart';

import '../constants.dart';
import '../size_confige.dart';

/// SRS-06 (US-MNC-002, FR-MNC-03): Ruang chat mitra <-> pasien
/// untuk koordinasi order aktif. Bubble UI sederhana, dummy in-memory.
class ChatPage extends StatefulWidget {
  final String name;
  final String orderCode;

  const ChatPage({Key? key, required this.name, required this.orderCode})
      : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();

  // Dummy percakapan. Integrasi realtime menyusul (FR-MNC-04).
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: "Halo, saya sudah memesan layanan. Mohon konfirmasinya ya",
      isMine: false,
      time: "09:10",
    ),
    _ChatMessage(
      text: "Baik, pesanan Anda sudah kami terima. Personil segera disiapkan",
      isMine: true,
      time: "09:11",
    ),
    _ChatMessage(
      text: "Apakah bisa datang jam 8 pagi?",
      isMine: false,
      time: "09:12",
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isMine: true, time: "Sekarang"));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              "Pesanan ${widget.orderCode}",
              style: TextStyle(
                fontSize: getRelativeWidth(0.03),
                color: Colors.blueGrey[400],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(getRelativeWidth(0.04)),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin:
                          EdgeInsets.only(bottom: getRelativeHeight(0.012)),
                      padding: EdgeInsets.symmetric(
                        horizontal: getRelativeWidth(0.04),
                        vertical: getRelativeHeight(0.012),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: getRelativeWidth(0.72),
                      ),
                      decoration: BoxDecoration(
                        color:
                            message.isMine ? kPrimaryDarkColor : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(22),
                          topRight: const Radius.circular(22),
                          bottomLeft: Radius.circular(message.isMine ? 22 : 6),
                          bottomRight:
                              Radius.circular(message.isMine ? 6 : 22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            message.text,
                            style: TextStyle(
                              color: message.isMine
                                  ? Colors.white
                                  : kHardTextColor,
                              fontSize: getRelativeWidth(0.034),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: getRelativeHeight(0.003)),
                          Text(
                            message.time,
                            style: TextStyle(
                              color: message.isMine
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : kLightTextColor,
                              fontSize: getRelativeWidth(0.024),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: getRelativeWidth(0.04),
                vertical: getRelativeHeight(0.012),
              ),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: getRelativeWidth(0.05),
                          vertical: getRelativeHeight(0.014),
                        ),
                        fillColor: kBackgroundColor,
                        filled: true,
                        hintText: "Tulis pesan...",
                        hintStyle: TextStyle(
                          fontSize: getRelativeWidth(0.034),
                          color: Colors.blueGrey.withValues(alpha: 0.9),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: getRelativeWidth(0.025)),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: EdgeInsets.all(getRelativeWidth(0.03)),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [kPrimarylightColor, kPrimaryDarkColor],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: getRelativeWidth(0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMine;
  final String time;

  _ChatMessage({
    required this.text,
    required this.isMine,
    required this.time,
  });
}