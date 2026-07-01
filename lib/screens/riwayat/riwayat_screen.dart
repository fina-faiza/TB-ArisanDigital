import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';

class RiwayatScreen extends StatefulWidget {
  final List<GrupArisan> grupList;
  final bool embedded;
  const RiwayatScreen(
      {super.key, required this.grupList, this.embedded = false});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _service = ArisanService();
  final _currency = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  GrupArisan? _grupSelected;
  Map<int, List<Pengocokan>> _grouped = {};

  @override
  void initState() {
    super.initState();
    if (widget.grupList.isNotEmpty) {
      _grupSelected = widget.grupList.first;
      _load();
    }
  }

  Future<void> _load() async {
    if (_grupSelected == null) return;
    final data = await _service.getRiwayatByGrup(_grupSelected!.id);

    final Map<int, List<Pengocokan>> grouped = {};
    for (final r in data) {
      grouped.putIfAbsent(r.putaranKe, () => []).add(r);
    }

    setState(() => _grouped = grouped);
  }

  Future<void> _updateStatus(Pengocokan p, String status) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          status == 'diambil'
              ? 'Konfirmasi Pengambilan'
              : 'Konfirmasi Tidak Diambil',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          status == 'diambil'
              ? '${p.namaAnggota} sudah mengambil arisan?'
              : '${p.namaAnggota} TIDAK mengambil arisan bulan ini?\n\nNama akan kembali masuk ke kocokan berikutnya.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  status == 'diambil' ? Colors.green : Colors.orange,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              status == 'diambil'
                  ? 'Ya, Sudah Diambil'
                  : 'Ya, Tidak Diambil',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await _service.updateStatusPengocokan(p.id, status);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'diambil'
                  ? '${p.namaAnggota} - status: Diambil ✅'
                  : '${p.namaAnggota} - dikembalikan ke pool kocokan 🔄',
            ),
            backgroundColor: status == 'diambil' ? Colors.green : Colors.orange,
          ),
        );
      }
    }
  }

  String _buatLaporanPutaran(int putaranKe, List<Pengocokan> list) {
    final grup = _grupSelected!;
    final first = list.first;
    final tgl = DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
        .format(DateTime.parse(first.tanggalKocok));
    final potongan = first.potonganKas;
    final perPemenang = (grup.nominal *
                grup.jumlahPeserta ~/
                grup.jumlahPemenangPerPutaran) -
            potongan;

    String pemenangStr = '';
    for (final p in list) {
      pemenangStr += '✨ ${p.namaAnggota} ✨\n';
    }

    String kasStr = potongan > 0
        ? 'Kas Khadijiyyah : -${_currency.format(potongan)}\n'
        : '(kas khadijiyyah: seikhlasnya, hubungi admin)\n';

    return '''🎉 PEMENANG ARISAN 🎉
--------------------------------
Grup: ${grup.namaGrup} ARISAN KHADIJIYYAH
Tanggal: $tgl
Putaran: $putaranKe dari ${grup.totalPutaran}
Sisa Putaran: ${grup.totalPutaran - putaranKe}

Selamat kepada:
$pemenangStr
Terkumpul : ${_currency.format(grup.nominal * grup.jumlahPeserta)}
$kasStr Total Diterima : ${_currency.format(perPemenang)}
--------------------------------
Laporan iuran terbaru sudah tersedia di aplikasi.
"Arisan Khadijiyyah by Firsha"''';
  }

  void _showLaporan(int putaranKe, List<Pengocokan> list) {
    final laporan = _buatLaporanPutaran(putaranKe, list);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text('Laporan Putaran $putaranKe',
            style: const TextStyle(color: Color(0xFFB8960C))),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(laporan,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Tutup', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Salin teks laporan untuk dikirim ke WA')),
              );
            },
            icon: const Icon(Icons.share, color: Colors.white),
            label:
                const Text('Share WA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'diambil':
        color = Colors.green;
        label = 'Diambil';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.orange;
        label = 'Menunggu Konfirmasi';
        icon = Icons.hourglass_top;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF16213E),
          child: DropdownButton<GrupArisan>(
            value: _grupSelected,
            dropdownColor: const Color(0xFF16213E),
            style: const TextStyle(color: Colors.white),
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
        Expanded(
          child: _grouped.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 60, color: Colors.white24),
                      SizedBox(height: 12),
                      Text('Belum ada riwayat pengocokan',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _grouped.keys.length,
                  itemBuilder: (_, i) {
                    final putaranKe = _grouped.keys.toList()[i];
                    final list = _grouped[putaranKe]!;
                    final first = list.first;
                    final tgl = DateFormat('d MMMM yyyy', 'id_ID')
                        .format(DateTime.parse(first.tanggalKocok));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFB8960C).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB8960C).withOpacity(0.15),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14)),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.emoji_events_rounded,
                                        color: Color(0xFFB8960C), size: 18),
                                    const SizedBox(width: 8),
                                    Text('Putaran $putaranKe',
                                        style: const TextStyle(
                                            color: Color(0xFFB8960C),
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text(tgl,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                          ...list.map((r) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.white12),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: Color(0xFFB8960C),
                                            size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            r.namaAnggota ?? '-',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        _statusBadge(r.status),
                                      ],
                                    ),
                                    if (r.status == 'menunggu') ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _updateStatus(r, 'diambil'),
                                              icon: const Icon(Icons.check,
                                                  size: 14,
                                                  color: Colors.green),
                                              label: const Text('Diambil',
                                                  style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 11)),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                    color: Colors.green),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _updateStatus(
                                                  r, 'tidak_diambil'),
                                              icon: const Icon(Icons.close,
                                                  size: 14,
                                                  color: Colors.orange),
                                              label: const Text(
                                                  'Tidak Diambil',
                                                  style: TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 11)),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                    color: Colors.orange),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              )),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showLaporan(putaranKe, list),
                                icon: const Icon(Icons.share,
                                    size: 16, color: Color(0xFF25D366)),
                                label: const Text(
                                    'Lihat Laporan & Share WA',
                                    style: TextStyle(
                                        color: Color(0xFF25D366),
                                        fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color(0xFF25D366), width: 1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ),
                        ],
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
    if (widget.embedded) {
      return Container(
          color: const Color(0xFF1A1A2E), child: _buildBody());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: const Text('Riwayat Pemenang',
            style: TextStyle(color: Color(0xFFB8960C))),
      ),
      body: _buildBody(),
    );
  }
}