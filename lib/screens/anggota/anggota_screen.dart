import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';

class AnggotaScreen extends StatefulWidget {
  final List<GrupArisan> grupList;
  final bool embedded;
  const AnggotaScreen(
      {super.key, required this.grupList, this.embedded = false});

  @override
  State<AnggotaScreen> createState() => _AnggotaScreenState();
}

class _AnggotaScreenState extends State<AnggotaScreen> {
  final _service = ArisanService();
  final _uuid = const Uuid();
  final _currency = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _searchCtrl = TextEditingController();

  GrupArisan? _grupSelected;
  List<Anggota> _anggota = [];
  List<Anggota> _filtered = [];

  @override
  void initState() {
    super.initState();
    if (widget.grupList.isNotEmpty) {
      _grupSelected = widget.grupList.first;
      _load();
    }
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_grupSelected == null) return;
    final data = await _service.getAnggotaByGrup(_grupSelected!.id);
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
              existing == null ? 'Tambah Anggota' : 'Edit Anggota',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _grupSelected?.namaGrup ?? '',
              style:
                  const TextStyle(color: Color(0xFFB8960C), fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildTextField(namaCtrl, 'Nama Lengkap', Icons.person),
            const SizedBox(height: 12),
            _buildTextField(hpCtrl, 'No. HP', Icons.phone,
                type: TextInputType.phone),
            const SizedBox(height: 12),
            _buildTextField(
                alamatCtrl, 'Alamat (opsional)', Icons.location_on),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8960C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                if (namaCtrl.text.isEmpty || hpCtrl.text.isEmpty) {
                  return;
                }
                final anggota = Anggota(
                  id: existing?.id ?? _uuid.v4(),
                  grupId: _grupSelected!.id,
                  nama: namaCtrl.text.toUpperCase(),
                  noHp: hpCtrl.text,
                  alamat:
                      alamatCtrl.text.isEmpty ? null : alamatCtrl.text,
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

  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFF00BCD4), size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF00BCD4))),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF16213E),
          child: Row(
            children: [
              const Text('Grup:',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<GrupArisan>(
                  value: _grupSelected,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: widget.grupList
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                                '${g.namaGrup} (${g.jumlahPeserta} orang)'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _grupSelected = v);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_filtered.length} anggota',
                style:
                    const TextStyle(color: Color(0xFFB8960C), fontSize: 12),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Cari anggota...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF16213E),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Text('Belum ada anggota',
                      style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final a = _filtered[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFB8960C),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                        title: Text(a.nama,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          a.noHp,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        trailing: PopupMenuButton(
                          color: const Color(0xFF16213E),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit',
                                    style: TextStyle(color: Colors.white))),
                            const PopupMenuItem(
                                value: 'hapus',
                                child: Text('Hapus',
                                    style: TextStyle(color: Colors.red))),
                          ],
                          onSelected: (v) async {
                            if (v == 'edit') {
                              _showForm(existing: a);
                            } else {
                              await _service.hapusAnggota(a.id);
                              _load();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton(
      backgroundColor: const Color(0xFFB8960C),
      foregroundColor: Colors.white,
      onPressed: _grupSelected != null ? () => _showForm() : null,
      child: const Icon(Icons.add),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          Container(
              color: const Color(0xFF1A1A2E), child: _buildBody()),
          Positioned(bottom: 16, right: 16, child: fab),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: const Text('Data Anggota',
            style: TextStyle(color: Color(0xFFB8960C))),
      ),
      floatingActionButton: fab,
      body: _buildBody(),
    );
  }
}