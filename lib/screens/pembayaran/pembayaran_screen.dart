import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';

class PembayaranScreen extends StatefulWidget {
  final String arisanId;
  const PembayaranScreen({super.key, required this.arisanId});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen>
    with SingleTickerProviderStateMixin {
  final _service = ArisanService();
  final _uuid = const Uuid();
  final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  late TabController _tabCtrl;
  List<Pembayaran> _sudahBayar = [];
  List<Anggota> _belumBayar = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final bayar = await _service.getPembayaranByArisan(widget.arisanId);
    final belum = await _service.getAnggotaBelumBayar(widget.arisanId);
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
        title: Text('Catat Pembayaran\n${anggota.nama}'),
        content: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nominal: ${_currency.format(anggota.nominal)}'),
              const SizedBox(height: 16),
              const Text('Metode Pembayaran:'),
              Row(
                children: [
                  Radio(
                      value: 'transfer',
                      groupValue: metode,
                      onChanged: (v) => setS(() => metode = v!)),
                  const Text('Transfer'),
                  const SizedBox(width: 16),
                  Radio(
                      value: 'tunai',
                      groupValue: metode,
                      onChanged: (v) => setS(() => metode = v!)),
                  const Text('Tunai'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () async {
              final p = Pembayaran(
                id: _uuid.v4(),
                anggotaId: anggota.id,
                arisanId: widget.arisanId,
                jumlah: anggota.nominal,
                metode: metode,
                tanggal: DateTime.now().toIso8601String(),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Pembayaran'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Belum Bayar (${_belumBayar.length})'),
            Tab(text: 'Sudah Bayar (${_sudahBayar.length})'),
          ],
        ),
      ),
      body: TabBarView(
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
                      Text('Semua anggota sudah membayar!'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _belumBayar.length,
                  itemBuilder: (_, i) {
                    final a = _belumBayar[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.warning_rounded,
                              color: Colors.white),
                        ),
                        title: Text(a.nama),
                        subtitle: Text(_currency.format(a.nominal)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                          ),
                          onPressed: () => _tambahPembayaran(a),
                          child: const Text('Catat'),
                        ),
                      ),
                    );
                  },
                ),

          // Tab Sudah Bayar
          _sudahBayar.isEmpty
              ? const Center(child: Text('Belum ada pembayaran'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _sudahBayar.length,
                  itemBuilder: (_, i) {
                    final p = _sudahBayar[i];
                    final tanggal = DateTime.parse(p.tanggal);
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text(p.namaAnggota ?? '-'),
                        subtitle: Text(
                            '${_currency.format(p.jumlah)} • ${p.metode} • '
                            '${DateFormat('d MMM yyyy').format(tanggal)}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('Lunas',
                              style: TextStyle(
                                  color: Colors.green, fontSize: 12)),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}