import 'package:doctor_app/model.dart/category.dart';
import 'package:flutter/material.dart';
import 'package:doctor_app/model.dart/doctor.dart';

class Data {
  static final categoriesList = [
    Category(
      title: "Caregiver",
      doctorsNumber: 0,
      icon: Icons.favorite,
    ),
    Category(
      title: "Medical Rental",
      doctorsNumber: 0,
      icon: Icons.local_hospital,
    ),
    Category(
      title: "Ambulans",
      doctorsNumber: 0,
      icon: Icons.airport_shuttle,
    ),
  ];

  static final doctorsList = [
    Doctor(
        name: "Dr.Hegazy Ali",
        speciality: "Cardiology",
        image: "assets/images/doctor_1.png",
        reviews: 80,
        reviewScore: 4),
    Doctor(
        name: "Dr.Dani",
        speciality: "Dermatology",
        image: "assets/images/doctor_2.png",
        reviews: 67,
        reviewScore: 5),
    Doctor(
        name: "Dr George",
        speciality: "Ophthalmology",
        image: "assets/images/doctor_3.png",
        reviews: 19,
        reviewScore: 3),
  ];
}
