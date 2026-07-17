import 'package:mitra_app/model.dart/category.dart';
import 'package:flutter/material.dart';
import 'package:mitra_app/model.dart/doctor.dart';

class Data {
  static final categoriesList = [
    Category(
      title: "Pesanan Baru",
      doctorsNumber: 0,
      icon: Icons.list_alt,
    ),
    Category(
      title: "Armada/Alat",
      doctorsNumber: 0,
      icon: Icons.inventory,
    ),
    Category(
      title: "Personil",
      doctorsNumber: 0,
      icon: Icons.people,
    ),
  ];

  static final doctorsList = [
    Doctor(
        name: "Order #1021",
        speciality: "Status: Menunggu Konfirmasi",
        image: "assets/images/doctor_1.png",
        reviews: 0,
        reviewScore: 0),
    Doctor(
        name: "Order #1022",
        speciality: "Status: Sedang Berjalan",
        image: "assets/images/doctor_2.png",
        reviews: 0,
        reviewScore: 0),
    Doctor(
        name: "Order #1023",
        speciality: "Status: Selesai",
        image: "assets/images/doctor_3.png",
        reviews: 0,
        reviewScore: 0),
  ];
}
