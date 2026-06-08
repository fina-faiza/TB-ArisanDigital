import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';

class RiwayatScreen extends StatefulWidget {
  final String arisanId;
  const RiwayatScreen({super.key, required this.arisanId});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _service = ArisanService();
  List<Pengocokan> _riwayat = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data =
        await _service.getRiwayatPengocokan(widget.arisanId);
    setState(() => _riwayat = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Riwayat Pemenang'),
      ),
      body: _riwayat.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada riwayat pengocokan'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _riwayat.length,
              itemBuilder: (_, i) {
                final r = _riwayat[i];
                final tanggal = DateTime.parse(r.tanggalKocok);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF2E7D32),
                      child: Text('${r.periodeKe}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(r.namaAnggota ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        'Periode ke-${r.periodeKe} • ${DateFormat('d MMMM yyyy', 'id_ID').format(tanggal)}'),
                    trailing: const Icon(Icons.emoji_events_rounded,
                        color: Colors.amber),
                  ),
                );
              },
            ),
    );
  }
}