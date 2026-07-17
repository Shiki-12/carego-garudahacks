import 'package:flutter/material.dart';

import '../constants.dart';
import '../size_confige.dart';

/// State views bersama (doc 08 §5): setiap layar data WAJIB menangani
/// loading / empty / error. Error selalu punya pesan Indonesia + "Coba lagi".
enum ViewState { loading, data, empty, error }

class LoadingView extends StatelessWidget {
  const LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: kPrimaryDarkColor),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String text;
  final IconData icon;

  const EmptyView({
    Key? key,
    this.text = 'Belum ada data',
    this.icon = Icons.inbox_outlined,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: getRelativeWidth(0.14), color: kLightTextColor),
          SizedBox(height: getRelativeHeight(0.014)),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kLightTextColor,
              fontWeight: FontWeight.w800,
              fontSize: getRelativeWidth(0.042),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.1)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: getRelativeWidth(0.14),
              color: Colors.redAccent.withValues(alpha: 0.8),
            ),
            SizedBox(height: getRelativeHeight(0.014)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kHardTextColor,
                fontWeight: FontWeight.w700,
                fontSize: getRelativeWidth(0.038),
              ),
            ),
            SizedBox(height: getRelativeHeight(0.02)),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: getRelativeWidth(0.08),
                  vertical: getRelativeHeight(0.012),
                ),
                decoration: BoxDecoration(
                  color: kPrimaryDarkColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Coba lagi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: getRelativeWidth(0.036),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
