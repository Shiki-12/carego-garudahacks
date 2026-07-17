import 'package:doctor_app/model.dart/category.dart';
import 'package:doctor_app/model.dart/partner.dart';
import 'package:flutter/material.dart';

class Data {
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
}
