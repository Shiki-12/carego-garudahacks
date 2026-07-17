import 'package:flutter/material.dart';

import '../constants.dart';
import '../data/data.dart';
import '../model.dart/order_model.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatelessWidget {
  final bool showScaffold;

  const OrdersScreen({
    Key? key,
    this.showScaffold = true,
  }) : super(key: key);

  List<OrderModel> _ordersForTab(int index) {
    final orders = Data.ordersList.where((order) {
      if (index == 0) {
        return order.status == 'pending' || order.status == 'confirmed';
      }
      if (index == 1) return order.status == 'completed';
      return order.status == 'cancelled';
    }).toList();

    orders.sort((a, b) => b.date.compareTo(a.date));
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    final content = DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              16,
              showScaffold ? 0 : MediaQuery.of(context).padding.top + 18,
              16,
              0,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan Saya',
                  style: TextStyle(
                    color: kHardTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 12),
                TabBar(
                  labelColor: Color(0xff0D9488),
                  unselectedLabelColor: kHardTextColor,
                  indicatorColor: Color(0xff0D9488),
                  labelStyle: TextStyle(fontWeight: FontWeight.w900),
                  tabs: [
                    Tab(text: 'Aktif'),
                    Tab(text: 'Selesai'),
                    Tab(text: 'Dibatalkan'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: List.generate(3, (index) {
                final orders = _ordersForTab(index);
                if (orders.isEmpty) {
                  return _OrdersEmptyState(tabIndex: index);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, orderIndex) {
                    final order = orders[orderIndex];
                    return _OrderCard(
                      order: order,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: order),
                          ),
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );

    if (!showScaffold) {
      return content;
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
      ),
      body: content,
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  String _formatRupiah(int amount) {
    final text = amount.toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = text.length - 1; i >= 0; i--) {
      buffer.write(text[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }

  String get _serviceIcon {
    if (order.serviceType == 'ambulance') return '🚑';
    if (order.serviceType == 'caregiver') return '👥';
    return '🏥';
  }

  String get _serviceLabel {
    if (order.serviceType == 'ambulance') return 'Ambulans';
    if (order.serviceType == 'caregiver') return 'Caregiver';
    return 'Sewa Alkes';
  }

  String get _statusLabel {
    if (order.status == 'pending') return 'Menunggu';
    if (order.status == 'confirmed') return 'Dikonfirmasi';
    if (order.status == 'completed') return 'Selesai';
    return 'Dibatalkan';
  }

  Color get _statusColor {
    if (order.status == 'completed') return const Color(0xff10B981);
    if (order.status == 'cancelled') return Colors.red[600]!;
    return const Color(0xff0D9488);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 3),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _serviceIcon,
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _serviceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kHardTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _StatusBadge(label: _statusLabel, color: _statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.providerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blueGrey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.blueGrey[400]),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _formatDate(order.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.blueGrey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _formatRupiah(order.totalPrice),
                    style: const TextStyle(
                      color: Color(0xff0D9488),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: kPrimaryDarkColor),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  final int tabIndex;

  const _OrdersEmptyState({
    required this.tabIndex,
  });

  String get _message {
    if (tabIndex == 0) return 'Belum ada pesanan aktif';
    if (tabIndex == 1) return 'Belum ada pesanan selesai';
    return 'Belum ada pesanan dibatalkan';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long,
              color: Colors.blueGrey[300],
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kHardTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
