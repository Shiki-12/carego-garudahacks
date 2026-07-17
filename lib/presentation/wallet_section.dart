import 'package:flutter/material.dart';

import '../constants.dart';
import '../size_confige.dart';

class WalletSection extends StatelessWidget {
  const WalletSection({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: getRelativeWidth(0.84),
      padding: EdgeInsets.fromLTRB(
        getRelativeWidth(0.035),
        getRelativeHeight(0.012),
        getRelativeWidth(0.035),
        getRelativeHeight(0.012),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: const Color(0xff158A55).withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: getRelativeWidth(-0.02),
            top: getRelativeHeight(-0.018),
            child: _DotPattern(),
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(getRelativeWidth(0.019)),
                decoration: const BoxDecoration(
                  color: Color(0xff10B981),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: getRelativeWidth(0.046),
                ),
              ),
              SizedBox(width: getRelativeWidth(0.025)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Carego Wallet",
                      style: TextStyle(
                        color: kHardTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: getRelativeWidth(0.034),
                      ),
                    ),
                    SizedBox(height: getRelativeHeight(0.002)),
                    Text(
                      "Rp500.000",
                      style: TextStyle(
                        color: const Color(0xff163B2A),
                        fontWeight: FontWeight.w900,
                        fontSize: getRelativeWidth(0.05),
                      ),
                    ),
                    SizedBox(height: getRelativeHeight(0.002)),
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user,
                          color:
                              const Color(0xff158A55).withValues(alpha: 0.7),
                          size: getRelativeWidth(0.032),
                        ),
                        SizedBox(width: getRelativeWidth(0.008)),
                        Expanded(
                          child: Text(
                            "Pembayaran Aman",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w700,
                              fontSize: getRelativeWidth(0.026),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: getRelativeWidth(0.02)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xff34D399),
                      Color(0xff059669),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                      color: const Color(0xff059669).withValues(alpha: 0.24),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: getRelativeWidth(0.028),
                    vertical: getRelativeHeight(0.011),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: Colors.white,
                        size: getRelativeWidth(0.036),
                      ),
                      SizedBox(width: getRelativeWidth(0.01)),
                      Flexible(
                        child: Text(
                          "Isi Saldo",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: getRelativeWidth(0.032),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotPattern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (row) => Row(
          children: List.generate(
            5,
            (column) => Container(
              width: getRelativeWidth(0.01),
              height: getRelativeWidth(0.01),
              margin: EdgeInsets.all(getRelativeWidth(0.005)),
              decoration: BoxDecoration(
                color: const Color(0xff10B981).withValues(
                  alpha: 0.12 + (row * 0.03),
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
