import 'package:flutter/material.dart';

import '../constants.dart';
import '../core/api_service.dart';
import '../core/service_locator.dart';
import '../models/mitra_asset.dart';
import '../services/assets_service.dart';
import '../size_confige.dart';
import 'state_views.dart';

/// SRS-03/04/05: Manajemen aset mitra (Personil / Armada / Katalog).
/// Satu layar generik berbasis list-CRUD; jenis aset & endpoint ditentukan
/// dari [title] via [AssetKind].
///
/// Data nyata dari `/mitra/{caregivers|ambulances|rental/items}` lewat
/// [AssetsService] (TD-08 — tanpa dummy in-memory). List/tambah/toggle/hapus
/// semua memanggil backend.
class ManagementPage extends StatefulWidget {
  final String title;

  /// Injectable untuk test; default composition root (doc 08 §9).
  final AssetsService? assetsService;

  const ManagementPage({Key? key, required this.title, this.assetsService})
      : super(key: key);

  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  late final AssetsService _service =
      widget.assetsService ?? Services.I.assets;
  late final AssetKind _kind = AssetKind.fromTitle(widget.title);

  ViewState _state = ViewState.loading;
  String _errMsg = '';
  List<MitraAsset> _items = const [];

  /// id aset yang sedang diproses aksinya → cegah aksi ganda.
  final Set<int> _busy = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = ViewState.loading);
    try {
      final items = await _service.list(_kind);
      if (!mounted) return;
      setState(() {
        _items = items;
        _state = items.isEmpty ? ViewState.empty : ViewState.data;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errMsg = e.message;
        _state = ViewState.error;
      });
    }
  }

  Future<void> _toggle(MitraAsset item, bool value) async {
    if (_busy.contains(item.id)) return;
    setState(() => _busy.add(item.id));
    // Optimistik: perbarui UI dulu, rollback bila server menolak.
    _replace(item.id, available: value);
    try {
      await _service.setAvailable(_kind, item.id, value);
    } on ApiException catch (e) {
      if (!mounted) return;
      _replace(item.id, available: !value); // rollback.
      _snack(e.message, Colors.redAccent);
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  Future<void> _delete(MitraAsset item) async {
    if (_busy.contains(item.id)) return;
    setState(() => _busy.add(item.id));
    try {
      await _service.remove(_kind, item.id);
      if (!mounted) return;
      _snack('${item.name} dihapus', kHardTextColor);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(e.message, Colors.redAccent);
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  /// Ganti satu item pada list lokal tanpa refetch (untuk toggle optimistik).
  void _replace(int id, {required bool available}) {
    setState(() {
      _items = _items
          .map((a) => a.id == id
              ? MitraAsset(
                  id: a.id,
                  name: a.name,
                  detail: a.detail,
                  available: available,
                )
              : a)
          .toList();
    });
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg),
    );
  }

  Future<void> _openAddForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAssetSheet(kind: _kind, service: _service),
    );
    if (created == true) {
      _snack('${_kind.noun} ditambahkan', kPrimaryDarkColor);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kHardTextColor,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryDarkColor,
        onPressed: _openAddForm,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildBody(),
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
              SizedBox(height: getRelativeHeight(0.3)),
              EmptyView(text: 'Belum ada ${widget.title.toLowerCase()}'),
            ],
          ),
        );
      case ViewState.data:
        return RefreshIndicator(
          color: kPrimaryDarkColor,
          onRefresh: _load,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(getRelativeWidth(0.04)),
            itemCount: _items.length,
            itemBuilder: (context, index) => _buildCard(_items[index], index),
          ),
        );
    }
  }

  Widget _buildCard(MitraAsset item, int index) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(item),
      background: Container(
        alignment: Alignment.centerRight,
        margin: EdgeInsets.only(bottom: getRelativeHeight(0.016)),
        padding: EdgeInsets.only(right: getRelativeWidth(0.06)),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: getRelativeHeight(0.016)),
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
        child: Row(
          children: [
            Container(
              width: getRelativeWidth(0.13),
              height: getRelativeWidth(0.13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kCategoriesPrimaryColor[
                        index % kCategoriesPrimaryColor.length],
                    kCategoriesSecondryColor[
                        index % kCategoriesSecondryColor.length],
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconForKind(),
                color: Colors.white,
                size: getRelativeWidth(0.06),
              ),
            ),
            SizedBox(width: getRelativeWidth(0.035)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: kHardTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: getRelativeWidth(0.04),
                    ),
                  ),
                  SizedBox(height: getRelativeHeight(0.003)),
                  Text(
                    item.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blueGrey[400],
                      fontSize: getRelativeWidth(0.03),
                    ),
                  ),
                ],
              ),
            ),
            _busy.contains(item.id)
                ? SizedBox(
                    width: getRelativeWidth(0.05),
                    height: getRelativeWidth(0.05),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kPrimaryDarkColor,
                    ),
                  )
                : Switch(
                    value: item.available,
                    activeThumbColor: kPrimaryDarkColor,
                    onChanged: (value) => _toggle(item, value),
                  ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(MitraAsset item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title:
            const Text('Hapus?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Hapus ${item.name} dari daftar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('Batal', style: TextStyle(color: kLightTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _delete(item);
      return true;
    }
    return false;
  }

  IconData _iconForKind() {
    switch (_kind) {
      case AssetKind.caregiver:
        return Icons.person;
      case AssetKind.ambulance:
        return Icons.airport_shuttle;
      case AssetKind.rentalItem:
        return Icons.medical_services;
    }
  }
}

/// Form tambah aset (bottom sheet). Field menyesuaikan [AssetKind] agar payload
/// sesuai kontrak masing-masing endpoint (doc endpoints.md §Specific Services).
class _AddAssetSheet extends StatefulWidget {
  final AssetKind kind;
  final AssetsService service;

  const _AddAssetSheet({required this.kind, required this.service});

  @override
  State<_AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<_AddAssetSheet> {
  final _nameCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  String get _nameHint {
    switch (widget.kind) {
      case AssetKind.caregiver:
        return 'Nama caregiver';
      case AssetKind.ambulance:
        return 'Nomor polisi (mis. B 1234 AMB)';
      case AssetKind.rentalItem:
        return 'Nama alat';
    }
  }

  String get _detailHint {
    switch (widget.kind) {
      case AssetKind.caregiver:
        return 'Spesialisasi & pengalaman';
      case AssetKind.ambulance:
        return 'Tipe & peralatan (mis. ALS · Ventilator)';
      case AssetKind.rentalItem:
        return 'Stok & tarif';
    }
  }

  /// Rakit payload sesuai jenis. `name` dipetakan ke field yang tepat.
  Map<String, dynamic> _payload() {
    final name = _nameCtrl.text.trim();
    final detail = _detailCtrl.text.trim();
    switch (widget.kind) {
      case AssetKind.ambulance:
        return {'plate_number': name, 'detail': detail, 'is_available': true};
      case AssetKind.caregiver:
        return {'name': name, 'detail': detail, 'is_available': true};
      case AssetKind.rentalItem:
        return {'name': name, 'detail': detail, 'is_available': true};
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nama wajib diisi');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.service.create(widget.kind, _payload());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: EdgeInsets.all(getRelativeWidth(0.06)),
        decoration: const BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: getRelativeWidth(0.12),
                height: 4,
                decoration: BoxDecoration(
                  color: kLightTextColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(height: getRelativeHeight(0.02)),
            Text(
              'Tambah ${widget.kind.noun}',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: getRelativeWidth(0.052),
              ),
            ),
            SizedBox(height: getRelativeHeight(0.025)),
            _field(_nameCtrl, _nameHint, Icons.badge),
            SizedBox(height: getRelativeHeight(0.016)),
            _field(_detailCtrl, _detailHint, Icons.notes),
            if (_error != null) ...[
              SizedBox(height: getRelativeHeight(0.016)),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: getRelativeWidth(0.033),
                ),
              ),
            ],
            SizedBox(height: getRelativeHeight(0.03)),
            GestureDetector(
              onTap: _submitting ? null : _submit,
              child: Opacity(
                opacity: _submitting ? 0.7 : 1,
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(vertical: getRelativeHeight(0.02)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [kPrimarylightColor, kPrimaryDarkColor],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: _submitting
                        ? SizedBox(
                            height: getRelativeWidth(0.05),
                            width: getRelativeWidth(0.05),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Simpan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: getRelativeWidth(0.042),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(height: getRelativeHeight(0.01)),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    final border = OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(30),
    );
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: getRelativeHeight(0.02)),
        fillColor: Colors.white,
        filled: true,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: getRelativeWidth(0.036),
          color: Colors.blueGrey.withValues(alpha: 0.9),
        ),
        prefixIcon: Icon(icon,
            color: Colors.blueGrey.withValues(alpha: 0.9),
            size: getRelativeWidth(0.055)),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }
}
