import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../constants.dart';
import 'map_picker_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Pricing configuration per SRS-03 Section 5.1
// ═══════════════════════════════════════════════════════════════════════════

class _AmbulanceType {
  final String label;
  final String description;
  final IconData icon;
  final int baseFare;
  final int perKm;

  const _AmbulanceType({
    required this.label,
    required this.description,
    required this.icon,
    required this.baseFare,
    required this.perKm,
  });
}

const _ambulanceTypes = [
  _AmbulanceType(
    label: 'Darurat',
    description: 'ICU & perawat',
    icon: Icons.emergency,
    baseFare: 150000,
    perKm: 15000,
  ),
  _AmbulanceType(
    label: 'Transportasi',
    description: 'Non-darurat',
    icon: Icons.local_shipping,
    baseFare: 100000,
    perKm: 10000,
  ),
  _AmbulanceType(
    label: 'Jenazah',
    description: 'Transportasi jenazah',
    icon: Icons.airline_seat_flat,
    baseFare: 200000,
    perKm: 12000,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({Key? key}) : super(key: key);

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  // Service type
  int _selectedType = 0;

  // Location state
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  LatLng? _pickupLatLng;
  LatLng? _destLatLng;

  // Patient details
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Distance / pricing
  double? _distanceKm;
  bool _isCalculating = false;

  // GPS
  bool _isLoadingGps = false;

  // Booking
  bool _isBooking = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _destController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Currency formatting ────────────────────────────────────────────────
  String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  int get _baseFare => _ambulanceTypes[_selectedType].baseFare;
  int get _perKm => _ambulanceTypes[_selectedType].perKm;

  int get _totalPrice {
    if (_distanceKm == null) return _baseFare;
    final km = _distanceKm!.ceil().clamp(1, 999999);
    return _baseFare + (_perKm * km);
  }

  int get _perKmCharge {
    if (_distanceKm == null) return 0;
    final km = _distanceKm!.ceil().clamp(1, 999999);
    return _perKm * km;
  }

  // ── GPS location ───────────────────────────────────────────────────────
  Future<void> _getGpsLocation() async {
    setState(() => _isLoadingGps = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('GPS tidak aktif. Aktifkan GPS di pengaturan.');
        setState(() => _isLoadingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Izin lokasi ditolak');
          setState(() => _isLoadingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
            'Buka Pengaturan untuk mengaktifkan izin lokasi');
        setState(() => _isLoadingGps = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);
      final address = await _reverseGeocode(latLng);

      if (mounted) {
        setState(() {
          _pickupLatLng = latLng;
          _pickupController.text = address;
          _isLoadingGps = false;
        });
        _calculateDistanceIfReady();
      }
    } catch (e) {
      _showSnackBar('Tidak dapat menemukan lokasi. Coba lagi.');
      setState(() => _isLoadingGps = false);
    }
  }

  // ── Reverse geocode ────────────────────────────────────────────────────
  Future<String> _reverseGeocode(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${position.latitude}&lon=${position.longitude}&format=json',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'CaregoApp/1.0',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? '${position.latitude}, ${position.longitude}';
      }
    } catch (_) {}
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  // ── Open map picker ────────────────────────────────────────────────────
  Future<void> _openMapPicker({required bool isPickup}) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialPosition: isPickup ? _pickupLatLng : _destLatLng,
        ),
      ),
    );

    if (result != null && mounted) {
      final latLng = LatLng(result['lat'] as double, result['lng'] as double);
      final address = result['address'] as String;

      setState(() {
        if (isPickup) {
          _pickupLatLng = latLng;
          _pickupController.text = address;
        } else {
          _destLatLng = latLng;
          _destController.text = address;
        }
      });
      _calculateDistanceIfReady();
    }
  }

  // ── Distance calculation ───────────────────────────────────────────────
  Future<void> _calculateDistanceIfReady() async {
    if (_pickupLatLng == null || _destLatLng == null) return;

    setState(() => _isCalculating = true);

    double? distance = await _getOsrmDistance(
      _pickupLatLng!,
      _destLatLng!,
    );

    distance ??= _haversineDistance(_pickupLatLng!, _destLatLng!) * 1.3;

    if (mounted) {
      setState(() {
        _distanceKm = distance;
        _isCalculating = false;
      });
    }
  }

  Future<double?> _getOsrmDistance(LatLng from, LatLng to) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=false',
      );
      final response =
          await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final meters = data['routes'][0]['distance'] as num;
          return meters / 1000.0;
        }
      }
    } catch (_) {}
    return null;
  }

  double _haversineDistance(LatLng a, LatLng b) {
    const R = 6371.0; // Earth radius in km
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final aCalc = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(a.latitude)) *
            cos(_degToRad(b.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(aCalc), sqrt(1 - aCalc));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  // ── Validation & Booking ───────────────────────────────────────────────
  void _submitBooking() {
    if (_pickupController.text.trim().isEmpty || _pickupLatLng == null) {
      _showSnackBar('Tentukan lokasi penjemputan');
      return;
    }
    if (_destController.text.trim().isEmpty || _destLatLng == null) {
      _showSnackBar('Tentukan lokasi tujuan');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Masukkan nama pasien');
      return;
    }

    _performMockBooking();
  }

  Future<void> _performMockBooking() async {
    setState(() => _isBooking = true);

    // Simulate POST /ambulance/book — 2 second delay
    // In production, this would be:
    // final body = {
    //   'userId': currentUser.id,
    //   'ambulanceType': _ambulanceTypes[_selectedType].label,
    //   'pickupLat': _pickupLatLng!.latitude,
    //   'pickupLng': _pickupLatLng!.longitude,
    //   'pickupAddress': _pickupController.text,
    //   'destLat': _destLatLng!.latitude,
    //   'destLng': _destLatLng!.longitude,
    //   'destAddress': _destController.text,
    //   'distanceKm': _distanceKm,
    //   'totalPrice': _totalPrice,
    //   'patientName': _nameController.text.trim(),
    //   'notes': _notesController.text.trim(),
    // };
    // final response = await http.post(
    //   Uri.parse('$BASE_URL/ambulance/book'),
    //   headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    //   body: json.encode(body),
    // );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isBooking = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xff0D9488),
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
                  'Pemesanan Berhasil!',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Color(0xff0D9488),
                  ),
                ),
                const SizedBox(height: 16),
                _summaryRow('Tipe', _ambulanceTypes[_selectedType].label),
                _summaryRow('Pasien', _nameController.text.trim()),
                _summaryRow('Jarak',
                    _distanceKm != null ? '${_distanceKm!.toStringAsFixed(1)} km' : '-'),
                _summaryRow('Total', _formatRupiah(_totalPrice)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); // close dialog
                      Navigator.of(context).pop(); // back to home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0D9488),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white,
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

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.blueGrey[600], fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red[700],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: const Text(
          'Pesan Ambulans',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section: Ambulance Type ────────────────────────────
                  const Text(
                    'Pilih Jenis Ambulans',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: kHardTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(3, (index) {
                      final type = _ambulanceTypes[index];
                      final isSelected = _selectedType == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedType = index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: EdgeInsets.only(
                              right: index < 2 ? 10 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xff0D9488).withValues(alpha: 0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xff0D9488)
                                    : Colors.grey.withValues(alpha: 0.2),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                        color: const Color(0xff0D9488)
                                            .withValues(alpha: 0.15),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  type.icon,
                                  color: isSelected
                                      ? const Color(0xff0D9488)
                                      : Colors.blueGrey[400],
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  type.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: isSelected
                                        ? const Color(0xff0D9488)
                                        : kHardTextColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  type.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blueGrey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // ── Section: Locations ──────────────────────────────────
                  const Text(
                    'Lokasi',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: kHardTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pickup
                  _buildLocationField(
                    controller: _pickupController,
                    hint: 'Lokasi penjemputan',
                    icon: Icons.trip_origin,
                    iconColor: const Color(0xff10B981),
                    showGpsButton: true,
                    onMapTap: () => _openMapPicker(isPickup: true),
                  ),
                  const SizedBox(height: 10),

                  // Destination
                  _buildLocationField(
                    controller: _destController,
                    hint: 'Lokasi tujuan',
                    icon: Icons.location_on,
                    iconColor: Colors.red[400]!,
                    showGpsButton: false,
                    onMapTap: () => _openMapPicker(isPickup: false),
                  ),

                  // ── Distance & Price Info Card ─────────────────────────
                  if (_isCalculating)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xff0D9488).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xff0D9488),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Menghitung jarak...',
                              style: TextStyle(
                                color: Color(0xff0D9488),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_distanceKm != null && !_isCalculating)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff0D9488), Color(0xff14B8A6)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              color: const Color(0xff0D9488).withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.route, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jarak: ${_distanceKm!.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Estimasi: ${_formatRupiah(_totalPrice)}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Section: Patient Details ───────────────────────────
                  const Text(
                    'Detail Pasien',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: kHardTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Patient name
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Nama pasien *',
                      hintStyle: TextStyle(color: Colors.blueGrey[400]),
                      prefixIcon:
                          Icon(Icons.person, color: Colors.blueGrey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Notes
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Catatan tambahan (opsional)',
                      hintStyle: TextStyle(color: Colors.blueGrey[400]),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 36),
                        child: Icon(Icons.notes, color: Colors.blueGrey[400]),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Section: Price Breakdown ────────────────────────────
                  const Text(
                    'Rincian Biaya',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: kHardTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _priceRow(
                          'Tarif dasar (${_ambulanceTypes[_selectedType].label})',
                          _formatRupiah(_baseFare),
                        ),
                        const Divider(height: 20),
                        _priceRow(
                          _distanceKm != null
                              ? 'Jarak (${_distanceKm!.toStringAsFixed(1)} km × ${_formatRupiah(_perKm)}/km)'
                              : 'Jarak (belum dihitung)',
                          _distanceKm != null
                              ? _formatRupiah(_perKmCharge)
                              : '-',
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Color(0xff0D9488),
                              ),
                            ),
                            Text(
                              _formatRupiah(_totalPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Color(0xff0D9488),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom bar: Pesan Sekarang ──────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  onPressed: _isBooking ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0D9488),
                    disabledBackgroundColor:
                        const Color(0xff0D9488).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  child: _isBooking
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
                              'Memproses...',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_hospital,
                                color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'Pesan Sekarang • ${_formatRupiah(_totalPrice)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable location field builder ─────────────────────────────────────
  Widget _buildLocationField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool showGpsButton,
    required VoidCallback onMapTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onMapTap,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.blueGrey[400]),
        prefixIcon: Icon(icon, color: iconColor),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showGpsButton)
              IconButton(
                icon: _isLoadingGps
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kPrimaryDarkColor,
                        ),
                      )
                    : Icon(Icons.my_location, color: kPrimaryDarkColor),
                onPressed: _isLoadingGps ? null : _getGpsLocation,
                tooltip: 'Gunakan lokasi saya',
              ),
            IconButton(
              icon: Icon(Icons.map, color: kPrimaryDarkColor),
              onPressed: onMapTap,
              tooltip: 'Pilih di peta',
            ),
          ],
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey[600],
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
