import 'package:doctor_app/model.dart/category.dart';
import 'package:doctor_app/model.dart/caregiver.dart';
import 'package:doctor_app/model.dart/chat_model.dart';
import 'package:doctor_app/model.dart/equipment.dart';
import 'package:doctor_app/model.dart/notification_model.dart';
import 'package:doctor_app/model.dart/order_model.dart';
import 'package:doctor_app/model.dart/partner.dart';
import 'package:doctor_app/model.dart/transaction_model.dart';
import 'package:flutter/material.dart';

class Data {
  static int walletBalance = 250000;

  static final categoriesList = [
    Category(
      title: "Caregiver",
      subtitle: "Layanan perawat",
      icon: Icons.favorite,
    ),
    Category(
      title: "Sewa Alkes",
      subtitle: "Sewa alat kesehatan",
      icon: Icons.local_hospital,
    ),
    Category(
      title: "Ambulans",
      subtitle: "Layanan ambulans",
      icon: Icons.airport_shuttle,
    ),
  ];

  static final partnersList = [
    Partner(
      name: "Rental Medika Mandiri",
      partnerType: "rental_provider",
      image: "assets/images/doctor_3.png",
      distance: "0.8 km",
      location: "Tebet, Jakarta Selatan",
      availability: "3 kursi roda tersedia",
      rating: 4.9,
      reviews: 95,
      reviewScore: 5,
    ),
    Partner(
      name: "Panti Jompo Sejahtera",
      partnerType: "nursing_home",
      image: "assets/images/doctor_1.png",
      distance: "1.2 km",
      location: "Kemang, Jakarta Selatan",
      availability: "4 caregiver tersedia",
      rating: 4.8,
      reviews: 120,
      reviewScore: 5,
    ),
    Partner(
      name: "RS Harapan Bunda",
      partnerType: "hospital",
      image: "assets/images/doctor_2.png",
      distance: "2.5 km",
      location: "Menteng, Jakarta Pusat",
      availability: "2 ambulans tersedia",
      rating: 4.6,
      reviews: 203,
      reviewScore: 5,
    ),
  ];

  static List<Caregiver> caregiversList = [];

  static List<Equipment> equipmentList = [];

  static List<OrderModel> ordersList = [];

  static List<Conversation> conversationsList = [];

  static final mockMessages = {
    1: [
      Message(
        id: 1,
        text: "Halo Bu Siti, apakah jadwal besok pagi masih tersedia?",
        isSentByMe: true,
        timestamp: DateTime(2026, 7, 17, 9, 30),
        isRead: true,
      ),
      Message(
        id: 2,
        text: "Halo, masih tersedia. Saya bisa datang pukul 08.00.",
        isSentByMe: false,
        timestamp: DateTime(2026, 7, 17, 9, 34),
        isRead: true,
      ),
      Message(
        id: 3,
        text: "Baik, pasien membutuhkan bantuan mobilisasi ringan.",
        isSentByMe: true,
        timestamp: DateTime(2026, 7, 17, 9, 39),
        isRead: true,
      ),
      Message(
        id: 4,
        text: "Baik, saya akan datang sesuai jadwal.",
        isSentByMe: false,
        timestamp: DateTime(2026, 7, 17, 9, 45),
        isRead: false,
      ),
    ],
    2: [
      Message(
        id: 1,
        text: "Halo, saya ingin menanyakan status pesanan saya.",
        isSentByMe: true,
        timestamp: DateTime(2026, 7, 16, 18, 0),
        isRead: true,
      ),
      Message(
        id: 2,
        text: "Tentu, kami bantu cek. Mohon tunggu sebentar.",
        isSentByMe: false,
        timestamp: DateTime(2026, 7, 16, 18, 5),
        isRead: true,
      ),
      Message(
        id: 3,
        text: "Kami siap membantu kebutuhan layanan Anda.",
        isSentByMe: false,
        timestamp: DateTime(2026, 7, 16, 18, 20),
        isRead: true,
      ),
    ],
    3: [
      Message(
        id: 1,
        text: "Apakah ambulans sudah mendapatkan konfirmasi?",
        isSentByMe: true,
        timestamp: DateTime(2026, 7, 15, 13, 55),
        isRead: true,
      ),
      Message(
        id: 2,
        text: "Unit ambulans sudah dikonfirmasi.",
        isSentByMe: false,
        timestamp: DateTime(2026, 7, 15, 14, 10),
        isRead: false,
      ),
    ],
    4: [
      Message(
        id: 1,
        text: "Apakah bed pasien elektrik masih tersedia?",
        isSentByMe: true,
        timestamp: DateTime(2026, 7, 14, 10, 50),
        isRead: true,
      ),
      Message(
        id: 2,
        text: "Bed pasien tersedia untuk pengiriman besok.",
        isSentByMe: false,
        timestamp: DateTime(2026, 7, 14, 11, 5),
        isRead: true,
      ),
    ],
  };

  static List<NotificationItem> mockNotifications = [];

  static List<TransactionModel> mockTransactions = [];
}
