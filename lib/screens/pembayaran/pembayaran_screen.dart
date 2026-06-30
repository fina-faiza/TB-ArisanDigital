import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';

class PembayaranScreen extends StatefulWidget {
  final List<GrupArisan> grupList;
  final String bulanAwal;
  const PembayaranScreen(
      {super.key, required this.grupList, required this.bulanAwal});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: const Text('Pembayaran',
            style: TextStyle(color: Color(0xFFB8960C))),
        bottom: TabBar(
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
      body: Column(
        children: [
          // Filter Grup & Bulan
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
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

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Tab Belum Bayar
                _belumBayar.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 60),
                            SizedBox(height: 12),
                            Text('Semua anggota sudah membayar!',
                                style:
                                    TextStyle(color: Colors.white70)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _belumBayar.length,
                        itemBuilder: (_, i) {
                          final a = _belumBayar[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(Icons.warning_rounded,
                                    color: Colors.white, size: 20),
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
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFFB8960C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                                onPressed: () =>
                                    _tambahPembayaran(a),
                                child: const Text('Catat',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          );
                        },
                      ),

                // Tab Sudah Bayar
                _sudahBayar.isEmpty
                    ? const Center(
                        child: Text('Belum ada pembayaran',
                            style:
                                TextStyle(color: Colors.white54)))
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
                                  color:
                                      Colors.green.withOpacity(0.3)),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(Icons.check,
                                    color: Colors.white, size: 20),
                              ),
                              title: Text(p.namaAnggota ?? '-',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13)),
                              subtitle: Text(
                                '${p.metode} • ${DateFormat('d MMM yyyy').format(tgl)}',
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11),
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
      ),
    );
  }
}