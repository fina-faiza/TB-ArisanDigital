import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';

class AnggotaScreen extends StatefulWidget {
  final String arisanId;
  const AnggotaScreen({super.key, required this.arisanId});

  @override
  State<AnggotaScreen> createState() => _AnggotaScreenState();
}

class _AnggotaScreenState extends State<AnggotaScreen> {
  final _service = ArisanService();
  final _uuid = const Uuid();
  final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _searchCtrl = TextEditingController();

  List<Anggota> _anggota = [];
  List<Anggota> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _service.getAllAnggota();
    setState(() {
      _anggota = data;
      _filtered = data;
    });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _anggota
          .where((a) =>
              a.nama.toLowerCase().contains(q) || a.noHp.contains(q))
          .toList();
    });
  }

  void _showForm({Anggota? existing}) {
    final namaCtrl = TextEditingController(text: existing?.nama);
    final hpCtrl = TextEditingController(text: existing?.noHp);
    final alamatCtrl = TextEditingController(text: existing?.alamat);
    String nominal = existing?.nominal.toString() ?? '50000';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(existing == null ? 'Tambah Anggota' : 'Edit Anggota',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hpCtrl,
              decoration: const InputDecoration(
                  labelText: 'No. HP', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: alamatCtrl,
              decoration: const InputDecoration(
                  labelText: 'Alamat (opsional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (ctx, setS) => DropdownButtonFormField<String>(
                value: nominal,
                decoration: const InputDecoration(
                    labelText: 'Nominal Arisan',
                    border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: '50000', child: Text('Rp 50.000')),
                  DropdownMenuItem(
                      value: '200000', child: Text('Rp 200.000')),
                ],
                onChanged: (v) => setS(() => nominal = v ?? '50000'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                if (namaCtrl.text.isEmpty || hpCtrl.text.isEmpty) return;
                final anggota = Anggota(
                  id: existing?.id ?? _uuid.v4(),
                  nama: namaCtrl.text,
                  noHp: hpCtrl.text,
                  alamat: alamatCtrl.text.isEmpty
                      ? null
                      : alamatCtrl.text,
                  nominal: int.parse(nominal),
                  createdAt: DateTime.now().toIso8601String(),
                );
                if (existing == null) {
                  await _service.tambahAnggota(anggota);
                } else {
                  await _service.updateAnggota(anggota);
                }
                if (!mounted) return;
                Navigator.pop(ctx);
                _load();
              },
              child: Text(existing == null ? 'Tambah' : 'Simpan'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Data Anggota'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari anggota...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('Belum ada anggota'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final a = _filtered[i