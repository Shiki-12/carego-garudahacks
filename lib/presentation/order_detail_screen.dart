import 'package:flutter/material.dart';

import '../constants.dart';
import '../model.dart/chat_model.dart';
import '../model.dart/order_model.dart';
import 'chat_room_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isCancelling = false;

  bool get _canCancel {
    return widget.order.status == 'pending' || widget.order.status == 'confirmed';
  }

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
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }

  String get _serviceIcon {
    if (widget.order.serviceType == 'ambulance') return '🚑';
    if (widget.order.serviceType == 'caregiver') return '👥';
    return '🏥';
  }

  String get _serviceLabel {
    if (widget.order.serviceType == 'ambulance') return 'Ambulans';
    if (widget.order.serviceType == 'caregiver') return 'Caregiver';
    return 'Sewa Alkes';
  }

  String get _statusLabel {
    if (widget.order.status == 'pending') return 'Menunggu Konfirmasi';
    if (widget.order.status == 'confirmed') return 'Dikonfirmasi';
    if (widget.order.status == 'completed') return 'Selesai';
    return 'Dibatalkan';
  }

  Color get _statusColor {
    if (widget.order.status == 'completed') return const Color(0xff10B981);
    if (widget.order.status == 'cancelled') return Colors.red[600]!;
    return const Color(0xff0D9488);
  }

  String get _providerRole {
    if (widget.order.serviceType == 'ambulance') return 'Penyedia Ambulans';
    if (widget.order.serviceType == 'caregiver') return 'Caregiver';
    return 'Penyedia Sewa Alkes';
  }

  String get _providerPhoto {
    if (widget.order.serviceType == 'ambulance') {
      return 'assets/images/doctor_2.png';
    }
    if (widget.order.serviceType == 'caregiver') {
      return 'assets/images/doctor_1.png';
    }
    return 'assets/images/doctor_3.png';
  }

  void _openProviderChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversation: Conversation(
            id: 9000 + widget.order.id,
            participantName: widget.order.providerName,
            participantRole: _providerRole,
            participantPhotoUrl: _providerPhoto,
            lastMessage: 'Halo, saya ingin menanyakan pesanan ini.',
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancellation() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Batalkan Pesanan?'),
          content: const Text(
            'Pesanan aktif akan dibatalkan. Tindakan ini hanya simulasi untuk MVP.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Ya, Batalkan',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) return;
    await _performMockCancellation();
  }

  Future<void> _performMockCancellation() async {
    setState(() => _isCancelling = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isCancelling = false);
    _showCancellationSuccessDialog();
  }

  void _showCancellationSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pesanan berhasil dibatalkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kHardTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0D9488),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Kembali ke Pesanan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          'Detail Pesanan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, _canCancel ? 110 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          color: Colors.black.withValues(alpha: 0.07),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            _serviceIcon,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _serviceLabel,
                                style: const TextStyle(
                                  color: kHardTextColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.order.providerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.blueGrey[500],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _StatusBadge(
                                label: _statusLabel,
                                color: _statusColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Status Pesanan',
                    child: _StatusTimeline(status: widget.order.status),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Detail Layanan',
                    child: Column(
                      children: [
                        _InfoRow('Nomor Pesanan', '#${widget.order.id}'),
                        _InfoRow('Tanggal', _formatDate(widget.order.date)),
                        _InfoRow('Penyedia', widget.order.providerName),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: _openProviderChat,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Hubungi Penyedia'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xff0D9488),
                              side: const BorderSide(
                                color: Color(0xff0D9488),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: widget.order.serviceType == 'ambulance'
                        ? 'Lokasi'
                        : 'Alamat Layanan',
                    child: Column(
                      children: [
                        _InfoRow('Alamat', widget.order.pickupAddress),
                        if (widget.order.destinationAddress != null)
                          _InfoRow(
                            'Tujuan',
                            widget.order.destinationAddress!,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Rincian Biaya',
                    child: Column(
                      children: [
                        _InfoRow('Subtotal', _formatRupiah(widget.order.totalPrice)),
                        const Divider(height: 20),
                        _InfoRow('Total', _formatRupiah(widget.order.totalPrice)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Catatan',
                    child: Text(
                      widget.order.notes.isEmpty ? '-' : widget.order.notes,
                      style: TextStyle(
                        color: Colors.blueGrey[600],
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_canCancel)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isCancelling ? null : _confirmCancellation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      disabledBackgroundColor:
                          Colors.red[300]!.withValues(alpha: 0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    child: _isCancelling
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Membatalkan...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Batalkan Pesanan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;

  const _StatusTimeline({
    required this.status,
  });

  int get _activeStep {
    if (status == 'pending') return 0;
    if (status == 'confirmed') return 1;
    if (status == 'completed') return 2;
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Row(
        children: [
          Icon(Icons.cancel, color: Colors.red[600]),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Pesanan dibatalkan',
              style: TextStyle(
                color: kHardTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    }

    const steps = ['Menunggu Konfirmasi', 'Dikonfirmasi', 'Selesai'];

    return Column(
      children: List.generate(steps.length, (index) {
        final isDone = index <= _activeStep;
        final isLast = index == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xff0D9488) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone
                          ? const Color(0xff0D9488)
                          : Colors.blueGrey[200]!,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 15)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 34,
                    color: isDone
                        ? const Color(0xff0D9488)
                        : Colors.blueGrey[200],
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  steps[index],
                  style: TextStyle(
                    color: isDone ? kHardTextColor : Colors.blueGrey[400],
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kHardTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey[500],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: kHardTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
