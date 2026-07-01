import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';

class PembayaranScreen extends StatefulWidget {
  final List<GrupArisan> grupList;
  final String bulanAwal;
  final bool embedded;
  const PembayaranScreen({
    super.key,
    required this.grupList,
    required this.bulanAwal,
    this.embedded = false,
  });

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen>
    with SingleTickerProviderStateMixin {
  final _service = ArisanService();
  final _uuid = const Uuid();
  final _currency = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  late TabController _tabCtrl;
  GrupArisan? _grupSelected;
  List<Pembayaran> _sudahBayar = [];
  List<Anggota> _belumBayar = [];

  // Mode select
  bool _selectMode = false;
  Set<String> _selectedIds = {};

  final List<String> _bulanList = [
    'Mei', 'Juni', 'Juli', 'Agustus', 'September',
    'Oktober', 'November', 'Desember', 'Januari', 'Februari'
  ];
  late String _bulanSelected;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _bulanSelected = widget.bulanAwal;
    if (widget.grupList.isNotEmpty) {
      _grupSelected = widget.grupList.first;
      _load();
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_grupSelected == null) return;
    final bayar = await _service.getPembayaranByGrup(
        _grupSelected!.id, _bulanSelected);
    final belum = await _service.getAnggotaBelumBayar(
        _grupSelected!.id, _bulanSelected);
    setState(() {
      _sudahBayar = bayar;
      _belumBayar = belum;
      _selectedIds.clear();
      _selectMode = false;
    });
  }

  void _tambahPembayaran(Anggota anggota) {
    String metode = 'transfer';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          'Catat Pembayaran\n${anggota.nama}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8960C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nominal',
                        style: TextStyle(color: Colors.white70)),
                    Text(
                      _currency.format(anggota.nominal),
                      style: const TextStyle(
                          color: Color(0xFFB8960C),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Metode Pembayaran:',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Radio(
                    value: 'transfer',
                    groupValue: metode,
                    activeColor: const Color(0xFFB8960C),
                    onChanged: (v) => setS(() => metode = v!),
                  ),
                  const Text('Transfer',
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 16),
                  Radio(
                    value: 'tunai',
                    groupValue: metode,
                    activeColor: const Color(0xFFB8960C),
                    onChanged: (v) => setS(() => metode = v!),
                  ),
                  const Text('Tunai',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8960C)),
            onPressed: () async {
              final p = Pembayaran(
                id: _uuid.v4(),
                anggotaId: anggota.id,
                grupId: _grupSelected!.id,
                jumlah: anggota.nominal,
                metode: metode,
                tanggal: DateTime.now().toIso8601String(),
                bulan: _bulanSelected,
              );
              await _service.tambahPembayaran(p);
              if (!mounted) return;
              Navigator.pop(context);
              _load();
            },
            child: const Text('Simpan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Dialog konfirmasi pembayaran massal
  void _showBulkDialog() {
    if (_selectedIds.isEmpty) return;
    final selected = _belumBayar
        .where((a) => _selectedIds.contains(a.id))
        .toList();
    String metode = 'tunai';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          'Catat ${selected.length} Pembayaran',
          style: const TextStyle(color: Color(0xFFB8960C), fontSize: 16),
        ),
        content: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selected.length} anggota dipilih:',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    ...selected.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  size: 6, color: Color(0xFFB8960C)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(a.nama,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12)),
                              ),
                              Text(
                                _currency.format(a.nominal),
                                style: const TextStyle(
                                    color: Color(0xFFB8960C),
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Metode Pembayaran:',
                  style: TextStyle(color: Colors.white70)),
              Row(
                children: [
                  Radio(
                    value: 'tunai',
                    groupValue: metode,
                    activeColor: const Color(0xFFB8960C),
                    onChanged: (v) => setS(() => metode = v!),
                  ),
                  const Text('Tunai',
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 16),
                  Radio(
                    value: 'transfer',
                    groupValue: metode,
                    activeColor: const Color(0xFFB8960C),
                    onChanged: (v) => setS(() => metode = v!),
                  ),
                  const Text('Transfer',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8960C)),
            onPressed: () async {
              final now = DateTime.now().toIso8601String();
              final pembayaranList = selected
                  .map((a) => Pembayaran(
                        id: _uuid.v4(),
                        anggotaId: a.id,
                        grupId: _grupSelected!.id,
                        jumlah: a.nominal,
                        metode: metode,
                        tanggal: now,
                        bulan: _bulanSelected,
                      ))
                  .toList();
              await _service.tambahPembayaranBulk(pembayaranList);
              if (!mounted) return;
              Navigator.pop(context);
              _load();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${selected.length} pembayaran berhasil dicatat!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Simpan Semua',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Filter Grup & Bulan
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF16213E),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<GrupArisan>(
                  value: _grupSelected,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                  isExpanded: true,
                  items: widget.grupList
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g.namaGrup),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _grupSelected = v);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _bulanSelected,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                  isExpanded: true,
                  items: _bulanList
                      .map((b) => DropdownMenuItem(
                            value: b,
                            child: Text(b),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _bulanSelected = v!);
                    _load();
                  },
                ),
              ),
            ],
          ),
        ),

        // Tab bar
        Container(
          color: const Color(0xFF16213E),
          child: TabBar(
            controller: _tabCtrl,
            indicatorColor: const Color(0xFFB8960C),
            labelColor: const Color(0xFFB8960C),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Belum Bayar (${_belumBayar.length})'),
              Tab(text: 'Sudah Bayar (${_sudahBayar.length})'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              // ── Tab Belum Bayar ──
              _belumBayar.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 60),
                          SizedBox(height: 12),
                          Text('Semua anggota sudah membayar!',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Toolbar select mode
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          color: const Color(0xFF1A1A2E),
                          child: Row(
                            children: [
                              // Tombol select mode
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectMode = !_selectMode;
                                    if (!_selectMode) {
                                      _selectedIds.clear();
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _selectMode
                                        ? const Color(0xFFB8960C)
                                            .withOpacity(0.2)
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _selectMode
                                          ? const Color(0xFFB8960C)
                                          : Colors.white24,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _selectMode
                                            ? Icons.check_box
                                            : Icons
                                                .check_box_outline_blank,
                                        color: _selectMode
                                            ? const Color(0xFFB8960C)
                                            : Colors.white54,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectMode
                                            ? 'Pilih Mode'
                                            : 'Pilih Beberapa',
                                        style: TextStyle(
                                          color: _selectMode
                                              ? const Color(0xFFB8960C)
                                              : Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              if (_selectMode) ...[
                                const SizedBox(width: 8),
                                // Pilih semua
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_selectedIds.length ==
                                          _belumBayar.length) {
                                        _selectedIds.clear();
                                      } else {
                                        _selectedIds = _belumBayar
                                            .map((a) => a.id)
                                            .toSet();
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withOpacity(0.05),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white24),
                                    ),
                                    child: Text(
                                      _selectedIds.length ==
                                              _belumBayar.length
                                          ? 'Batal Semua'
                                          : 'Pilih Semua',
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12),
                                    ),
                                  ),
                                ),

                                const Spacer(),

                                // Tombol simpan pilihan
                                if (_selectedIds.isNotEmpty)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFB8960C),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: _showBulkDialog,
                                    icon: const Icon(Icons.save,
                                        size: 16, color: Colors.white),
                                    label: Text(
                                      'Catat (${_selectedIds.length})',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),

                        // List belum bayar
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _belumBayar.length,
                            itemBuilder: (_, i) {
                              final a = _belumBayar[i];
                              final isSelected =
                                  _selectedIds.contains(a.id);
                              return GestureDetector(
                                onTap: _selectMode
                                    ? () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedIds.remove(a.id);
                                          } else {
                                            _selectedIds.add(a.id);
                                          }
                                        });
                                      }
                                    : null,
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFB8960C)
                                            .withOpacity(0.15)
                                        : const Color(0xFF16213E),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFB8960C)
                                          : Colors.orange
                                              .withOpacity(0.3),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: _selectMode
                                        ? Checkbox(
                                            value: isSelected,
                                            activeColor:
                                                const Color(0xFFB8960C),
                                            checkColor: Colors.white,
                                            side: const BorderSide(
                                                color: Colors.white54),
                                            onChanged: (v) {
                                              setState(() {
                                                if (v == true) {
                                                  _selectedIds.add(a.id);
                                                } else {
                                                  _selectedIds
                                                      .remove(a.id);
                                                }
                                              });
                                            },
                                          )
                                        : const CircleAvatar(
                                            backgroundColor:
                                                Colors.orange,
                                            child: Icon(
                                                Icons.warning_rounded,
                                                color: Colors.white,
                                                size: 20),
                                          ),
                                    title: Text(a.nama,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13)),
                                    subtitle: Text(
                                      _currency.format(a.nominal),
                                      style: const TextStyle(
                                          color: Color(0xFFB8960C),
                                          fontSize: 12),
                                    ),
                                    trailing: _selectMode
                                        ? null
                                        : ElevatedButton(
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFB8960C),
                                              foregroundColor:
                                                  Colors.white,
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 12),
                                            ),
                                            onPressed: () =>
                                                _tambahPembayaran(a),
                                            child: const Text('Catat',
                                                style: TextStyle(
                                                    fontSize: 12)),
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

              // ── Tab Sudah Bayar ──
              _sudahBayar.isEmpty
                  ? const Center(
                      child: Text('Belum ada pembayaran',
                          style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _sudahBayar.length,
                      itemBuilder: (_, i) {
                        final p = _sudahBayar[i];
                        final tgl = DateTime.parse(p.tanggal);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16213E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.check,
                                  color: Colors.white, size: 20),
                            ),
                            title: Text(p.namaAnggota ?? '-',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            subtitle: Text(
                              '${p.metode} • ${DateFormat('d MMM yyyy').format(tgl)}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                            trailing: Text(
                              _currency.format(p.jumlah),
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Container(
          color: const Color(0xFF1A1A2E), child: _buildBody());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: const Text('Pembayaran',
            style: TextStyle(color: Color(0xFFB8960C))),
      ),
      body: _buildBody(),
    );
  }
}