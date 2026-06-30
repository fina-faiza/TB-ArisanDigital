import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';

class GrupScreen extends StatefulWidget {
  final String periodeId;
  final String namaPeriode;
  const GrupScreen(
      {super.key, required this.periodeId, required this.namaPeriode});

  @override
  State<GrupScreen> createState() => _GrupScreenState();
}

class _GrupScreenState extends State<GrupScreen> {
  final _service = ArisanService();
  final _uuid = const Uuid();
  final _currency = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<GrupArisan> _grupList = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getGrupByPeriode(widget.periodeId);
    setState(() => _grupList = data);
  }

  void _showForm({GrupArisan? existing}) {
    final namaCtrl = TextEditingController(text: existing?.namaGrup);
    final nominalCtrl =
        TextEditingController(text: existing?.nominal.toString());
    final pesertaCtrl = TextEditingController(
        text: existing?.jumlahPeserta.toString());
    final pemenangCtrl = TextEditingController(
        text: existing?.jumlahPemenangPerPutaran.toString());
    final putaranCtrl = TextEditingController(
        text: existing?.totalPutaran.toString());

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null
                    ? 'Tambah Grup Arisan'
                    : 'Edit Grup Arisan',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 16),
              _field(namaCtrl, 'Nama Grup (cth: GRUP A (50K))'),
              const SizedBox(height: 12),
              _field(nominalCtrl, 'Nominal per Bulan (Rp)',
                  type: TextInputType.number),
              const SizedBox(height: 12),
              _field(pesertaCtrl, 'Jumlah Peserta',
                  type: TextInputType.number),
              const SizedBox(height: 12),
              _field(pemenangCtrl, 'Pemenang per Putaran',
                  type: TextInputType.number),
              const SizedBox(height: 12),
              _field(putaranCtrl, 'Total Putaran',
                  type: TextInputType.number),
              const SizedBox(height: 8),
              const Text(
                'Tips: Jumlah Peserta ÷ Pemenang per Putaran = Total Putaran',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8960C),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  if (namaCtrl.text.isEmpty ||
                      nominalCtrl.text.isEmpty ||
                      pesertaCtrl.text.isEmpty ||
                      pemenangCtrl.text.isEmpty ||
                      putaranCtrl.text.isEmpty) return;

                  final grup = GrupArisan(
                    id: existing?.id ?? _uuid.v4(),
                    periodeId: widget.periodeId,
                    namaGrup: namaCtrl.text,
                    nominal: int.parse(nominalCtrl.text),
                    jumlahPeserta: int.parse(pesertaCtrl.text),
                    jumlahPemenangPerPutaran:
                        int.parse(pemenangCtrl.text),
                    totalPutaran: int.parse(putaranCtrl.text),
                  );

                  if (existing == null) {
                    await _service.tambahGrup(grup);
                  } else {
                    await _service.updateGrup(grup);
                  }
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _load();
                },
                child: Text(
                  existing == null ? 'Tambah Grup' : 'Simpan',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
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
        title: Text('Grup - ${widget.namaPeriode}',
            style: const TextStyle(
                color: Color(0xFFB8960C), fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFB8960C),
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _grupList.isEmpty
          ? const Center(
              child: Text('Belum ada grup arisan',
                  style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _grupList.length,
              itemBuilder: (_, i) {
                final g = _grupList[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFB8960C),
                      child: Text(
                        '${g.jumlahPemenangPerPutaran}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      g.namaGrup,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${_currency.format(g.nominal)} • ${g.jumlahPeserta} peserta • ${g.totalPutaran} putaran',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                    trailing: PopupMenuButton(
                      color: const Color(0xFF16213E),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit',
                                style:
                                    TextStyle(color: Colors.white))),
                        const PopupMenuItem(
                            value: 'hapus',
                            child: Text('Hapus',
                                style: TextStyle(color: Colors.red))),
                      ],
                      onSelected: (v) async {
                        if (v == 'edit') {
                          _showForm(existing: g);
                        } else if (v == 'hapus') {
                          await _service.hapusGrup(g.id);
                          _load();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}