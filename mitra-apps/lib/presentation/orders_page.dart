import 'package:flutter/material.dart';

import '../constants.dart';
import '../core/api_service.dart';
import '../core/service_locator.dart';
import '../models/mitra_order.dart';
import '../services/orders_service.dart';
import '../size_confige.dart';
import 'state_views.dart';

/// SRS-02 (FR-MD-02/03/04): Manajemen pesanan mitra dengan 3 tab
/// Menunggu / Aktif / Riwayat (doc 07 §2).
///
/// Data nyata dari GET /mitra/orders via [OrdersService] (TD-08 — tanpa dummy
/// in-memory). Aksi accept/reject/status sesuai doc 07 §5-6, termasuk race
/// dispatch 409 "pesanan sudah diambil".
class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key, this.ordersService}) : super(key: key);

  /// Injectable untuk test; default composition root (doc 08 §9).
  final OrdersService? ordersService;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const _tabs = ['Menunggu', 'Aktif', 'Riwayat'];
  static const _groups = ['waiting', 'active', 'history'];

  late final OrdersService _service =
      widget.ordersService ?? Services.I.orders;

  int _selectedTab = 0;

  ViewState _state = ViewState.loading;
  String _errMsg = '';
  List<MitraOrder> _orders = const [];

  /// id pesanan yang sedang diproses aksinya → cegah double-tap (doc 00 §2.3).
  final Set<int> _busy = <int>{};

  /// Kunci idempotency per pesanan agar retry aman (doc 01 §8). Tanpa
  /// Math.random / uuid eksternal: id + tab cukup unik per aksi accept.
  String _idemKey(int orderId) => 'accept-$orderId';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = ViewState.loading);
    try {
      final page = await _service.list(statusGroup: _groups[_selectedTab]);
      if (!mounted) return;
      setState(() {
        _orders = page.items;
        _state = page.items.isEmpty ? ViewState.empty : ViewState.data;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errMsg = e.message;
        _state = ViewState.error;
      });
    }
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    _load();
  }

  Future<void> _accept(MitraOrder order) async {
    if (_busy.contains(order.id)) return;
    setState(() => _busy.add(order.id));
    try {
      await _service.accept(order.id, idempotencyKey: _idemKey(order.id));
      if (!mounted) return;
      _snack('Pesanan ${order.code} diterima', kPrimaryDarkColor);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      // Race dispatch (doc 07 §5): mitra lain sudah mengambil → 409.
      if (e.isConflict) {
        _snack('Pesanan sudah diambil mitra lain', Colors.orange);
        await _load(); // sinkronkan: pesanan hilang dari tab Menunggu.
      } else {
        _snack(e.message, Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  Future<void> _reject(MitraOrder order) async {
    if (_busy.contains(order.id)) return;
    setState(() => _busy.add(order.id));
    try {
      await _service.reject(order.id);
      if (!mounted) return;
      _snack('Pesanan ${order.code} ditolak', kHardTextColor);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(e.message, Colors.redAccent);
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  Future<void> _advance(MitraOrder order, OrderStatus to, String okMsg) async {
    if (_busy.contains(order.id)) return;
    setState(() => _busy.add(order.id));
    try {
      await _service.updateStatus(order.id, to);
      if (!mounted) return;
      _snack('Pesanan ${order.code} $okMsg', kPrimaryDarkColor);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(e.message, Colors.redAccent);
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: const Text(
          'Pesanan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: EdgeInsets.all(getRelativeWidth(0.04)),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectTab(index),
              child: Container(
                margin: EdgeInsets.only(
                  right: index < _tabs.length - 1 ? getRelativeWidth(0.02) : 0,
                ),
                padding:
                    EdgeInsets.symmetric(vertical: getRelativeHeight(0.012)),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryDarkColor : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : kHardTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: getRelativeWidth(0.032),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case ViewState.loading:
        return const LoadingView();
      case ViewState.error:
        return ErrorView(message: _errMsg, onRetry: _load);
      case ViewState.empty:
        return RefreshIndicator(
          color: kPrimaryDarkColor,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: getRelativeHeight(0.28)),
              const EmptyView(text: 'Tidak ada pesanan'),
            ],
          ),
        );
      case ViewState.data:
        return RefreshIndicator(
          color: kPrimaryDarkColor,
          onRefresh: _load,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.04)),
            itemCount: _orders.length,
            itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
          ),
        );
    }
  }

  Widget _buildOrderCard(MitraOrder order) {
    final busy = _busy.contains(order.id);
    return Container(
      margin: EdgeInsets.only(bottom: getRelativeHeight(0.018)),
      padding: EdgeInsets.all(getRelativeWidth(0.04)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                order.code,
                style: TextStyle(
                  color: kHardTextColor,
                  fontWeight: FontWeight.w800,
                  fontSize: getRelativeWidth(0.04),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: getRelativeWidth(0.025),
                  vertical: getRelativeHeight(0.004),
                ),
                decoration: BoxDecoration(
                  color: order.status.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  order.status.label,
                  style: TextStyle(
                    color: order.status.color,
                    fontWeight: FontWeight.w800,
                    fontSize: getRelativeWidth(0.028),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: getRelativeHeight(0.008)),
          Text(
            order.patientName,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: getRelativeWidth(0.042),
            ),
          ),
          SizedBox(height: getRelativeHeight(0.004)),
          Text(
            order.serviceLabel,
            style: TextStyle(
              color: Colors.blueGrey[400],
              fontSize: getRelativeWidth(0.032),
            ),
          ),
          SizedBox(height: getRelativeHeight(0.008)),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: getRelativeWidth(0.036),
                color: kLightTextColor,
              ),
              SizedBox(width: getRelativeWidth(0.01)),
              Expanded(
                child: Text(
                  order.scheduleLabel,
                  style: TextStyle(
                    color: Colors.blueGrey[400],
                    fontSize: getRelativeWidth(0.03),
                  ),
                ),
              ),
              Text(
                order.priceLabel,
                style: TextStyle(
                  color: kPrimaryDarkColor,
                  fontWeight: FontWeight.w900,
                  fontSize: getRelativeWidth(0.04),
                ),
              ),
            ],
          ),
          ..._buildActions(order, busy),
        ],
      ),
    );
  }

  /// Tombol aksi sesuai status kanonik (doc 07 §3, §5-6).
  List<Widget> _buildActions(MitraOrder order, bool busy) {
    final status = order.status;

    if (status == OrderStatus.pending) {
      return [
        SizedBox(height: getRelativeHeight(0.014)),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                'Tolak',
                Colors.redAccent,
                filled: false,
                busy: busy,
                onTap: () => _reject(order),
              ),
            ),
            SizedBox(width: getRelativeWidth(0.03)),
            Expanded(
              child: _actionButton(
                'Terima',
                kPrimaryDarkColor,
                busy: busy,
                onTap: () => _accept(order),
              ),
            ),
          ],
        ),
      ];
    }

    // Transisi berjalan (doc 07 §6). Tombol berikutnya sesuai status saat ini.
    final OrderStatus? next;
    final String label;
    switch (status) {
      case OrderStatus.accepted:
        next = OrderStatus.inProgress;
        label = 'Mulai Layanan';
        break;
      case OrderStatus.onTheWay:
        next = OrderStatus.inProgress;
        label = 'Mulai Layanan';
        break;
      case OrderStatus.inProgress:
        next = OrderStatus.completed;
        label = 'Selesaikan Layanan';
        break;
      default:
        next = null;
        label = '';
    }

    if (next == null) return const [];

    return [
      SizedBox(height: getRelativeHeight(0.014)),
      Row(
        children: [
          Expanded(
            child: _actionButton(
              label,
              kPrimaryDarkColor,
              busy: busy,
              onTap: () => _advance(
                order,
                next!,
                next == OrderStatus.completed ? 'selesai' : 'diperbarui',
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _actionButton(
    String label,
    Color color, {
    bool filled = true,
    required bool busy,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Opacity(
        opacity: busy ? 0.6 : 1,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: getRelativeHeight(0.012)),
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            border: filled ? null : Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: busy
                ? SizedBox(
                    height: getRelativeWidth(0.045),
                    width: getRelativeWidth(0.045),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: filled ? Colors.white : color,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: filled ? Colors.white : color,
                      fontWeight: FontWeight.w800,
                      fontSize: getRelativeWidth(0.032),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
