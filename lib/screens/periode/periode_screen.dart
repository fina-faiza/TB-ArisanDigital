import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';
import 'grup_screen.dart';

class PeriodeScreen extends StatefulWidget {
  const PeriodeScreen({super.key});

  @override
  State<PeriodeScreen> createState() => _PeriodeScreenState();
}

class _PeriodeScreenState extends State<PeriodeScreen> {
  final _service = ArisanService();
  final _uuid = const Uuid();
  List<Periode> _periodeList = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getAllPeriode();
    setState(() => _periodeList = data);
  }

  void _showForm({Periode? existing}) {
    final namaCtrl = TextEditingController(text: existing?.namaPeriode);
    final tahunCtrl = TextEditingController(text: existing?.tahun);
    final bulanMulaiCtrl =
        TextEditingController(text: existing?.bulanMulai);
    final bulanSelesaiCtrl =
        TextEditingController(text: existing?.bulanSelesai);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
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
            Text(
              existing == null
                  ? 'Tambah Periode Baru'
                  : 'Edit Periode',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 16),
            _field(namaCtrl, 'Nama Periode (cth: 2026/2027)'),
            const SizedBox(height: 12),
            _field(tahunCtrl, 'Tahun Mulai (cth: 2026)',
                type: TextInputType.number),
            const SizedBox(height: 12),
            _field(bulanMulaiCtrl, 'Bulan Mulai (cth: Mei)'),
            const SizedBox(height: 12),
            _field(bulanSelesaiCtrl, 'Bulan Selesai (cth: Februari)'),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8960C),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                if (namaCtrl.text.isEmpty ||
                    tahunCtrl.text.isEmpty ||
                    bulanMulaiCtrl.text.isEmpty ||
                    bulanSelesaiCtrl.text.isEmpty) return;

                final periode = Periode(
                  id: existing?.id ?? _uuid.v4(),
                  namaPeriode: namaCtrl.text,
                  tahun: tahunCtrl.text,
                  bulanMulai: bulanMulaiCtrl.text,
                  bulanSelesai: bulanSelesaiCtrl.text,
                  status: existing?.status ?? 'nonaktif',
                );

                if (existing == null) {
                  await _service.tambahPeriode(periode);
                } else {
                  await _service.updatePeriode(periode);
                }
                if (!mounted) return;
                Navigator.pop(ctx);
                _load();
              },
              child: Text(
                existing == null ? 'Tambah Periode' : 'Simpan',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFB8960C))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: const Text('Kelola Periode',
            style: TextStyle(color: Color(0xFFB8960C))),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFB8960C),
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _periodeList.isEmpty
          ? const Center(
              child: Text('Belum ada periode',
                  style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _periodeList.length,
              itemBuilder: (_, i) {
                final p = _periodeList[i];
                final isAktif = p.status == 'aktif';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isAktif
                          ? const Color(0xFFB8960C)
                          : Colors.white12,
                      width: isAktif ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          isAktif
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isAktif
                              ? const Color(0xFFB8960C)
                              : Colors.white38,
                        ),
                        title: Text(
                          'Periode ${p.namaPeriode}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${p.bulanMulai} - ${p.bulanSelesai}'
                          '${isAktif ? ' • AKTIF' : ''}',
                          style: TextStyle(
                              color: isAktif
                                  ? const Color(0xFFB8960C)
                                  : Colors.white54,
                              fontSize: 12),
                        ),
                        trailing: PopupMenuButton(
                          color: const Color(0xFF16213E),
                          itemBuilder: (_) => [
                            if (!isAktif)
                              const PopupMenuItem(
                                  value: 'aktifkan',
                                  child: Text('Jadikan Aktif',
                                      style: TextStyle(
                                          color: Color(0xFFB8960C)))),
                            const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit',
                                    style:
                                        TextStyle(color: Colors.white))),
                            const PopupMenuItem(
                                value: 'hapus',
                                child: Text('Hapus',
                                    style:
                                        TextStyle(color: Colors.red))),
                          ],
                          onSelected: (v) async {
                            if (v == 'aktifkan') {
                              await _service.setPeriodeAktif(p.id);
                              _load();
                            } else if (v == 'edit') {
                              _showForm(existing: p);
                            } else if (v == 'hapus') {
                              await _service.hapusPeriode(p.id);
                              _load();
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GrupScreen(
                                      periodeId: p.id,
                                      namaPeriode: p.namaPeriode),
                                ),
                              );
                            },
                            icon: const Icon(Icons.groups,
                                size: 16,
                                color: Color(0xFF00BCD4)),
                            label: const Text('Kelola Grup Arisan',
                                style: TextStyle(
                                    color: Color(0xFF00BCD4),
                                    fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFF00BCD4)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}