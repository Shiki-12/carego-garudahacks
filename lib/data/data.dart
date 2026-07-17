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

  static final caregiversList = [
    Caregiver(
      id: 1,
      name: "Siti Aminah",
      specialization: "Perawatan Lansia",
      experienceYears: 6,
      hourlyRate: 75000,
      rating: 4.9,
      reviews: 84,
      photoUrl: "assets/images/doctor_1.png",
      isAvailable: true,
      bio:
          "Caregiver berpengalaman untuk pendampingan lansia di rumah, termasuk bantuan aktivitas harian, pengingat obat, dan pemantauan kondisi ringan.",
    ),
    Caregiver(
      id: 2,
      name: "Rina Marlina",
      specialization: "Pasca Operasi",
      experienceYears: 5,
      hourlyRate: 85000,
      rating: 4.8,
      reviews: 67,
      photoUrl: "assets/images/doctor_2.png",
      isAvailable: true,
      bio:
          "Terbiasa mendampingi pasien masa pemulihan setelah operasi, membantu mobilisasi aman, perawatan dasar, dan koordinasi kebutuhan pasien.",
    ),
    Caregiver(
      id: 3,
      name: "Dewi Kartika",
      specialization: "Pendamping Pasien",
      experienceYears: 4,
      hourlyRate: 70000,
      rating: 4.7,
      reviews: 52,
      photoUrl: "assets/images/doctor_3.png",
      isAvailable: true,
      bio:
          "Pendamping pasien untuk kebutuhan harian di rumah sakit maupun rumah, dengan pendekatan sabar, komunikatif, dan teliti.",
    ),
    Caregiver(
      id: 4,
      name: "Maya Lestari",
      specialization: "Perawatan Ibu & Bayi",
      experienceYears: 7,
      hourlyRate: 90000,
      rating: 4.9,
      reviews: 91,
      photoUrl: "assets/images/person.png",
      isAvailable: true,
      bio:
          "Membantu ibu dan bayi dalam masa pemulihan, rutinitas harian, pemantauan dasar, serta dukungan keluarga di rumah.",
    ),
    Caregiver(
      id: 5,
      name: "Nur Fitriani",
      specialization: "Rehabilitasi Ringan",
      experienceYears: 3,
      hourlyRate: 65000,
      rating: 4.6,
      reviews: 38,
      photoUrl: "assets/images/doctor_1.png",
      isAvailable: false,
      bio:
          "Mendampingi pasien dalam latihan aktivitas ringan sesuai arahan tenaga medis dan membantu rutinitas pemulihan harian.",
    ),
  ];

  static final equipmentList = [
    Equipment(
      id: 1,
      name: "Bed Pasien Elektrik",
      category: "bed",
      description:
          "Tempat tidur pasien elektrik 3 posisi untuk perawatan di rumah, dilengkapi pengaman samping dan roda pengunci.",
      specifications: {
        "Tipe": "Elektrik 3 posisi",
        "Kapasitas": "Maks. 180 kg",
        "Fitur": "Remote, pagar samping, roda pengunci",
        "Kondisi": "Siap pakai dan disterilkan",
      },
      dailyRate: 200000,
      weeklyRate: 1200000,
      deposit: 500000,
      stock: 3,
      images: [
        "assets/images/doctor_1.png",
        "assets/images/doctor_2.png",
      ],
      isAvailable: true,
    ),
    Equipment(
      id: 2,
      name: "Kursi Roda Standar",
      category: "wheelchair",
      description:
          "Kursi roda lipat standar untuk mobilitas pasien harian, ringan dibawa dan nyaman untuk penggunaan dalam maupun luar ruangan.",
      specifications: {
        "Tipe": "Manual lipat",
        "Kapasitas": "Maks. 100 kg",
        "Material": "Rangka baja ringan",
        "Fitur": "Rem tangan dan pijakan kaki",
      },
      dailyRate: 50000,
      weeklyRate: 300000,
      deposit: 200000,
      stock: 6,
      images: [
        "assets/images/doctor_2.png",
        "assets/images/doctor_3.png",
      ],
      isAvailable: true,
    ),
    Equipment(
      id: 3,
      name: "Konsentrator Oksigen",
      category: "oxygen",
      description:
          "Konsentrator oksigen untuk terapi oksigen di rumah sesuai arahan tenaga medis, dengan aliran stabil dan penggunaan mudah.",
      specifications: {
        "Kapasitas": "5 liter per menit",
        "Daya": "350 watt",
        "Aksesori": "Selang nasal dan humidifier",
        "Kondisi": "Filter baru dan disterilkan",
      },
      dailyRate: 175000,
      weeklyRate: 1000000,
      deposit: 600000,
      stock: 2,
      images: [
        "assets/images/doctor_3.png",
        "assets/images/person.png",
      ],
      isAvailable: true,
    ),
    Equipment(
      id: 4,
      name: "Nebulizer Portable",
      category: "other",
      description:
          "Nebulizer portable untuk membantu terapi inhalasi di rumah, ringkas dan mudah digunakan oleh keluarga pasien.",
      specifications: {
        "Tipe": "Portable",
        "Daya": "Adaptor listrik",
        "Aksesori": "Masker dewasa dan anak",
        "Berat": "1.2 kg",
      },
      dailyRate: 35000,
      weeklyRate: 200000,
      deposit: 150000,
      stock: 4,
      images: [
        "assets/images/person.png",
        "assets/images/doctor_1.png",
      ],
      isAvailable: true,
    ),
    Equipment(
      id: 5,
      name: "Monitor Tekanan Darah",
      category: "monitor",
      description:
          "Monitor tekanan darah digital untuk pemantauan rutin di rumah, cocok untuk pasien hipertensi dan pemulihan pasca rawat.",
      specifications: {
        "Tipe": "Digital lengan atas",
        "Memori": "90 hasil pengukuran",
        "Daya": "Baterai AA",
        "Aksesori": "Manset dewasa",
      },
      dailyRate: 30000,
      weeklyRate: 180000,
      deposit: 100000,
      stock: 0,
      images: [
        "assets/images/doctor_2.png",
      ],
      isAvailable: true,
    ),
  ];

  static final ordersList = [
    OrderModel(
      id: 1001,
      serviceType: "ambulance",
      providerName: "RS Harapan Bunda",
      status: "pending",
      totalPrice: 230000,
      date: DateTime(2026, 7, 17, 9, 30),
      pickupAddress: "Jl. Sudirman No. 12, Jakarta Pusat",
      destinationAddress: "IGD RS Harapan Bunda",
      notes: "Pasien demam tinggi dan membutuhkan ambulans transportasi.",
    ),
    OrderModel(
      id: 1002,
      serviceType: "caregiver",
      providerName: "Siti Aminah",
      status: "confirmed",
      totalPrice: 300000,
      date: DateTime(2026, 7, 18, 8, 0),
      pickupAddress: "Jl. Kemang Raya No. 8, Jakarta Selatan",
      notes: "Pendampingan lansia selama 4 jam di rumah.",
    ),
    OrderModel(
      id: 1003,
      serviceType: "rental",
      providerName: "Rental Medika Mandiri",
      status: "completed",
      totalPrice: 1700000,
      date: DateTime(2026, 7, 10, 10, 15),
      pickupAddress: "Jl. Tebet Timur Dalam No. 21, Jakarta Selatan",
      notes: "Sewa bed pasien elektrik selama 1 minggu termasuk deposit.",
    ),
    OrderModel(
      id: 1004,
      serviceType: "ambulance",
      providerName: "Ambulans Cepat Sehat",
      status: "cancelled",
      totalPrice: 165000,
      date: DateTime(2026, 7, 9, 14, 45),
      pickupAddress: "Jl. Melati No. 4, Depok",
      destinationAddress: "RS Mitra Keluarga Depok",
      notes: "Dibatalkan karena pasien sudah dibawa keluarga.",
    ),
    OrderModel(
      id: 1005,
      serviceType: "caregiver",
      providerName: "Rina Marlina",
      status: "completed",
      totalPrice: 510000,
      date: DateTime(2026, 7, 6, 7, 30),
      pickupAddress: "Apartemen Kalibata City, Tower A",
      notes: "Perawatan pasca operasi selama 6 jam.",
    ),
    OrderModel(
      id: 1006,
      serviceType: "rental",
      providerName: "Mitra Alkes Sejahtera",
      status: "confirmed",
      totalPrice: 500000,
      date: DateTime(2026, 7, 19, 11, 0),
      pickupAddress: "Jl. Cempaka Putih Barat No. 17, Jakarta Pusat",
      notes: "Sewa kursi roda standar selama 1 minggu.",
    ),
    OrderModel(
      id: 1007,
      serviceType: "rental",
      providerName: "Oksigen Rumah Care",
      status: "cancelled",
      totalPrice: 775000,
      date: DateTime(2026, 7, 5, 16, 20),
      pickupAddress: "Jl. Margonda Raya No. 88, Depok",
      notes: "Pemesanan konsentrator oksigen dibatalkan oleh pengguna.",
    ),
  ];

  static final conversationsList = [
    Conversation(
      id: 1,
      participantName: "Siti Aminah",
      participantRole: "Caregiver",
      participantPhotoUrl: "assets/images/doctor_1.png",
      lastMessage: "Baik, saya akan datang sesuai jadwal.",
      lastMessageTime: DateTime(2026, 7, 17, 9, 45),
      unreadCount: 2,
    ),
    Conversation(
      id: 2,
      participantName: "Admin CAREGO",
      participantRole: "Bantuan Pelanggan",
      participantPhotoUrl: "assets/images/person.png",
      lastMessage: "Kami siap membantu kebutuhan layanan Anda.",
      lastMessageTime: DateTime(2026, 7, 16, 18, 20),
      unreadCount: 0,
    ),
    Conversation(
      id: 3,
      participantName: "RS Harapan Bunda",
      participantRole: "Ambulans",
      participantPhotoUrl: "assets/images/doctor_2.png",
      lastMessage: "Unit ambulans sudah dikonfirmasi.",
      lastMessageTime: DateTime(2026, 7, 15, 14, 10),
      unreadCount: 1,
    ),
    Conversation(
      id: 4,
      participantName: "Rental Medika Mandiri",
      participantRole: "Sewa Alkes",
      participantPhotoUrl: "assets/images/doctor_3.png",
      lastMessage: "Bed pasien tersedia untuk pengiriman besok.",
      lastMessageTime: DateTime(2026, 7, 14, 11, 5),
      unreadCount: 0,
    ),
  ];

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

  static final mockNotifications = [
    NotificationItem(
      id: 1,
      type: "booking_confirmed",
      title: "Pesanan Dikonfirmasi",
      message: "Caregiver Siti Aminah telah mengonfirmasi pesanan Anda.",
      timestamp: DateTime(2026, 7, 17, 10, 15),
      isRead: false,
    ),
    NotificationItem(
      id: 2,
      type: "new_message",
      title: "Pesan Baru",
      message: "Admin CAREGO mengirim pesan baru untuk Anda.",
      timestamp: DateTime(2026, 7, 17, 9, 50),
      isRead: false,
    ),
    NotificationItem(
      id: 3,
      type: "provider_arriving",
      title: "Ambulans Menuju Lokasi",
      message: "Unit ambulans akan tiba sekitar 10 menit lagi.",
      timestamp: DateTime(2026, 7, 16, 15, 25),
      isRead: true,
    ),
    NotificationItem(
      id: 4,
      type: "payment_received",
      title: "Pembayaran Berhasil",
      message: "Pembayaran Rp 300.000 untuk layanan caregiver berhasil.",
      timestamp: DateTime(2026, 7, 16, 8, 30),
      isRead: true,
    ),
    NotificationItem(
      id: 5,
      type: "promotion",
      title: "Promo Spesial",
      message: "Diskon 20% untuk sewa kursi roda minggu ini.",
      timestamp: DateTime(2026, 7, 15, 11, 0),
      isRead: false,
    ),
    NotificationItem(
      id: 6,
      type: "system",
      title: "Pembaruan Aplikasi",
      message: "CAREGO memperbarui fitur chat dan notifikasi.",
      timestamp: DateTime(2026, 7, 14, 17, 45),
      isRead: true,
    ),
  ];

  static final mockTransactions = [
    TransactionModel(
      id: 1,
      title: "Top Up Saldo",
      amount: 150000,
      isCredit: true,
      date: DateTime(2026, 7, 17, 10, 30),
    ),
    TransactionModel(
      id: 2,
      title: "Pembayaran Caregiver",
      amount: 300000,
      isCredit: false,
      date: DateTime(2026, 7, 16, 8, 15),
    ),
    TransactionModel(
      id: 3,
      title: "Pembayaran Ambulans",
      amount: 230000,
      isCredit: false,
      date: DateTime(2026, 7, 15, 14, 45),
    ),
    TransactionModel(
      id: 4,
      title: "Top Up Saldo",
      amount: 500000,
      isCredit: true,
      date: DateTime(2026, 7, 12, 9, 0),
    ),
  ];
}
